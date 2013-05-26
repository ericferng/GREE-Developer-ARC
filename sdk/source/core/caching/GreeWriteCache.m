//
// Copyright 2012 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GreeWriteCache.h"
#import "GreeSerializer.h"
#import "GreeSqlQuery.h"
#import "GreeLogger.h"
#import "JSONKit.h"
#import "NSString+GreeAdditions.h"
#import "NSData+GreeAdditions.h"
#import <dispatch/queue.h>
#import <UIKit/UIKit.h>
#import "GreeAuthorization.h"

NSInteger GreeWriteCacheCategorySizeUnlimited = -1;

typedef enum
{
  GreeWriteCacheCommittingFlag  = (1 << 0),  // Object is being committed
} GreeWriteCacheFlags;

@interface GreeWriteCache ()
@property (nonatomic, retain, readwrite) NSString* userId;
@property (nonatomic, assign, readwrite) dispatch_queue_t queue;
@property (nonatomic, assign, readwrite) BOOL cancelled;
@property (nonatomic, assign, readwrite) GreeDatabaseHandle databaseHandle;
@property (nonatomic, retain, readwrite) GreeSqlQuery* readCategoriesForClassQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* readCacheEntryQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* writeCacheEntryQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* deleteCacheEntryQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* purgeAllCacheEntriesOfClassAndCategoryQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* trimCacheEntriesQuery;
@property (nonatomic, retain, readwrite) GreeSqlQuery* setFlagsQuery;
@property (nonatomic, retain, readwrite) NSString* hashKey;
-(void)immediatelyWriteObject:(id<GreeWriteCacheable>)object;
-(void)immediatelyCommitAllObjectsOfClass:(Class)klass inCategory:(NSString*)category usingDispatchGroup:(dispatch_group_t)dispatchGroup;
-(void)immediatelyDeleteAllObjectsOfClass:(Class)klass inCategory:(NSString*)category;
-(void)immediatelyDeleteObjectWithRowId:(int64_t)rowId;
-(void)immediatelySetFlags:(int)flags onObjectWithRowId:(int64_t)rowId;
-(NSInteger)immediatelyCountObjectOfClass:(Class)klass inCategory:(NSString*)category;
-(id)immediatelyReadNewestObjectOfClass:(Class)klass inCategory:(NSString*)category;
-(id)immediatelyReadOldestObjectOfClass:(Class)klass inCategory:(NSString*)category;
-(int64_t)immediatelyReadNewestRowIdOfClass:(Class)klass inCategory:(NSString*)category;
-(void)immediatelyWriteHash:(NSString*)hash forRowId:(int64_t)rowId;
-(NSString*)immediatelyReadHashForRowId:(int64_t)rowId;
-(id)objectOfClass:(Class)klass fromCacheData:(NSData*)data;
-(void)dispatchCacheOperation:(GreeWriteCacheOperationHandle)handle withBlock:(void (^)(void))block;
-(void)bootstrapDatabase;
@end

@implementation GreeWriteCache

#pragma mark - Object Lifecycle

-(id)initWithUserId:(NSString*)userId
{
  self = [super init];
  if (self != nil) {
    self.userId = userId;
    self.hashKey = @"net.gree.sdk.writecache";

    NSString* path = [NSString greeCachePathForRelativePath:[NSString stringWithFormat:@"writeCache_%@", self.userId]];
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];

    self.databaseHandle = [GreeSqlQuery openDatabaseAtPath:path];

    NSString* queueLabel = [NSString stringWithFormat:@"net.gree.sdk.writecache_%@", self.userId];
    self.queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);

    if ([self.userId length] > 0 && self.databaseHandle != NULL && self.queue != NULL) {
      [self bootstrapDatabase];
    } else {
      [self release];
      self = nil;
    }
  }

  return self;
}

-(void)dealloc
{
  self.readCategoriesForClassQuery = nil;
  self.readCacheEntryQuery = nil;
  self.writeCacheEntryQuery = nil;
  self.deleteCacheEntryQuery = nil;
  self.purgeAllCacheEntriesOfClassAndCategoryQuery = nil;
  self.trimCacheEntriesQuery = nil;
  self.setFlagsQuery = nil;
  [GreeSqlQuery closeDatabase:&_databaseHandle];
  dispatch_release(_queue);
  self.userId = nil;
  self.hashKey = nil;
  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, userId:%@>",
          NSStringFromClass([self class]),
          self,
          self.userId];
}

#pragma mark - Public Interface

-(GreeWriteCacheOperationHandle)writeObject:(id<GreeWriteCacheable>)object;
{
  NSAssert([object conformsToProtocol:@protocol(GreeWriteCacheable)], @"Object must conform to GreeWriteCacheable!");
  NSAssert([[object writeCacheCategory] length] > 0, @"Object must have a category!");

  if (![[GreeAuthorization sharedInstance] isAuthorized]) {
    return nil;
  }

  GreeWriteCacheOperationHandle handle = dispatch_group_create();
  [self dispatchCacheOperation:handle withBlock:^{
     [self immediatelyWriteObject:object];
   }];
  dispatch_release(handle);
  return handle;
}

-(GreeWriteCacheOperationHandle)commitAllObjectsOfClass:(Class<GreeWriteCacheable>)klass
{
  GreeWriteCacheOperationHandle handle = dispatch_group_create();
  [self dispatchCacheOperation:handle withBlock:^{
     [self.readCategoriesForClassQuery reset];
     [self.readCategoriesForClassQuery bindString:NSStringFromClass(klass) named:@"class"];
     for (NSDictionary* row in self.readCategoriesForClassQuery) {
       NSString* category = [row objectForKey:@"category"];
       [self immediatelyCommitAllObjectsOfClass:klass inCategory:category usingDispatchGroup:handle];
     }
   }];
  dispatch_release(handle);
  return handle;
}

-(GreeWriteCacheOperationHandle)commitAllObjectsOfClass:(Class<GreeWriteCacheable>)klass inCategory:(NSString*)category
{
  GreeWriteCacheOperationHandle handle = dispatch_group_create();
  [self dispatchCacheOperation:handle withBlock:^{
     [self immediatelyCommitAllObjectsOfClass:klass inCategory:category usingDispatchGroup:handle];
   }];
  dispatch_release(handle);
  return handle;
}

-(GreeWriteCacheOperationHandle)deleteAllObjectsOfClass:(Class<GreeWriteCacheable>)klass
{
  GreeWriteCacheOperationHandle handle = dispatch_group_create();
  [self dispatchCacheOperation:handle withBlock:^{
     [self.readCategoriesForClassQuery reset];
     [self.readCategoriesForClassQuery bindString:NSStringFromClass(klass) named:@"class"];
     for (NSDictionary* row in self.readCategoriesForClassQuery) {
       NSString* category = [row objectForKey:@"category"];
       [self immediatelyDeleteAllObjectsOfClass:klass inCategory:category];
     }
   }];
  dispatch_release(handle);
  return handle;
}

-(GreeWriteCacheOperationHandle)deleteAllObjectsOfClass:(Class<GreeWriteCacheable>)klass inCategory:(NSString*)category
{
  GreeWriteCacheOperationHandle handle = dispatch_group_create();
  [self dispatchCacheOperation:handle withBlock:^{
     [self immediatelyDeleteAllObjectsOfClass:klass inCategory:category];
   }];
  dispatch_release(handle);
  return handle;
}

-(void)observeWriteCacheOperation:(GreeWriteCacheOperationHandle)handle forCompletionWithBlock:(void (^)(void))block
{
  NSAssert(handle != NULL && block != NULL, @"You must specify both an operation handle and a completion block!");
  dispatch_group_notify(handle, self.queue, block);
}

-(void)cancelOutstandingOperations
{
  self.cancelled = YES;
}

#pragma mark - Internal Methods

#pragma mark Core Database Operations

-(void)immediatelyWriteObject:(id<GreeWriteCacheable>)object
{
  GreeSerializer* serializer = [GreeSerializer serializer];
  [object serializeWithGreeSerializer:serializer];
  NSDictionary* serialized = [serializer rootDictionary];
  NSData* data = [serialized greeJSONData];

  NSString* hash = [data greeHashWithKey:self.hashKey];

  NSString* class = NSStringFromClass([object class]);
  NSString* category = [object writeCacheCategory];

  [self.writeCacheEntryQuery reset];
  [self.writeCacheEntryQuery bindData:data named:@"data"];
  [self.writeCacheEntryQuery bindInt:0x0 named:@"flags"];
  [self.writeCacheEntryQuery bindString:class named:@"class"];
  [self.writeCacheEntryQuery bindString:[object writeCacheCategory] named:@"category"];
  [self.writeCacheEntryQuery bindString:hash named:@"hash"];
  [self.writeCacheEntryQuery step];

  NSInteger categorySize = [[object class] writeCacheMaxCategorySize];
  if (categorySize != GreeWriteCacheCategorySizeUnlimited) {
    [self.trimCacheEntriesQuery reset];
    [self.trimCacheEntriesQuery bindString:class named:@"class"];
    [self.trimCacheEntriesQuery bindString:category named:@"category"];
    [self.trimCacheEntriesQuery bindInt:categorySize named:@"categorySize"];
    [self.trimCacheEntriesQuery step];
  }
}

-(void)immediatelyCommitAllObjectsOfClass:(Class)klass inCategory:(NSString*)category usingDispatchGroup:(dispatch_group_t)dispatchGroup
{
  [self.readCacheEntryQuery reset];
  [self.readCacheEntryQuery bindString:NSStringFromClass(klass) named:@"class"];
  [self.readCacheEntryQuery bindString:category named:@"category"];
  for (NSDictionary* row in self.readCacheEntryQuery) {
    NSData* objectData = [row objectForKey:@"data"];
    int64_t rowId = [[row objectForKey:@"id"] longLongValue];
    int flags = [[row objectForKey:@"flags"] intValue];
    if ((flags & GreeWriteCacheCommittingFlag) != GreeWriteCacheCommittingFlag) {
      BOOL hashMatch = [objectData isKindOfClass:[NSData class]] && [[objectData greeHashWithKey:self.hashKey] isEqualToString:[row objectForKey:@"hash"]];
      if (hashMatch) {
        [self immediatelySetFlags:(flags | GreeWriteCacheCommittingFlag) onObjectWithRowId:rowId];
        id object = [self objectOfClass:klass fromCacheData:objectData];
        dispatch_retain(dispatchGroup);
        dispatch_group_enter(dispatchGroup);
        [self retain];
        [object writeCacheCommitAndExecuteBlock:^(BOOL commitDidSucceed) {
           dispatch_async(self.queue, ^{
                            if (commitDidSucceed) {
                              [self immediatelyDeleteObjectWithRowId:rowId];
                            } else {
                              [self immediatelySetFlags:flags onObjectWithRowId:rowId];
                            }
                            [self release];
                            dispatch_group_leave(dispatchGroup);
                            dispatch_release(dispatchGroup);
                          });
         }];
      } else {
        [self immediatelyDeleteObjectWithRowId:rowId];
      }
    }
  }
}

-(void)immediatelyDeleteAllObjectsOfClass:(Class)klass inCategory:(NSString*)category
{
  [self.purgeAllCacheEntriesOfClassAndCategoryQuery reset];
  [self.purgeAllCacheEntriesOfClassAndCategoryQuery bindString:NSStringFromClass(klass) named:@"class"];
  [self.purgeAllCacheEntriesOfClassAndCategoryQuery bindString:category named:@"category"];
  [self.purgeAllCacheEntriesOfClassAndCategoryQuery step];
}

-(void)immediatelyDeleteObjectWithRowId:(int64_t)rowId
{
  [self.deleteCacheEntryQuery reset];
  [self.deleteCacheEntryQuery bindInt64:rowId named:@"id"];
  [self.deleteCacheEntryQuery step];
}

-(void)immediatelySetFlags:(int)flags onObjectWithRowId:(int64_t)rowId
{
  [self.setFlagsQuery reset];
  [self.setFlagsQuery bindInt:flags named:@"flags"];
  [self.setFlagsQuery bindInt64:rowId named:@"id"];
  [self.setFlagsQuery step];
}

#pragma mark Testing Operations

-(NSInteger)immediatelyCountObjectOfClass:(Class)klass inCategory:(NSString*)category
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"SELECT COUNT(*) AS count FROM write_cache WHERE class = :class AND category = :category"];
  [query bindString:NSStringFromClass(klass) named:@"class"];
  [query bindString:category named:@"category"];
  [query step];
  NSInteger d = [query integerValueAtColumnNamed:@"count"];
  [query release];
  return d;
}

-(id)immediatelyReadNewestObjectOfClass:(Class)klass inCategory:(NSString*)category
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"SELECT * FROM write_cache WHERE class = :class AND category = :category ORDER BY id DESC LIMIT 1"];
  [query bindString:NSStringFromClass(klass) named:@"class"];
  [query bindString:category named:@"category"];
  [query step];

  NSData* objectData = [query dataValueAtColumnNamed:@"data"];
  id object = [self objectOfClass:klass fromCacheData:objectData];

  [query release];
  return object;
}

-(id)immediatelyReadOldestObjectOfClass:(Class)klass inCategory:(NSString*)category
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"SELECT * FROM write_cache WHERE class = :class AND category = :category ORDER BY id ASC LIMIT 1"];
  [query bindString:NSStringFromClass(klass) named:@"class"];
  [query bindString:category named:@"category"];
  [query step];

  NSData* objectData = [query dataValueAtColumnNamed:@"data"];
  id object = [self objectOfClass:klass fromCacheData:objectData];

  [query release];
  return object;
}

-(int64_t)immediatelyReadNewestRowIdOfClass:(Class)klass inCategory:(NSString*)category
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"SELECT id FROM write_cache WHERE class = :class AND category = :category ORDER BY id DESC LIMIT 1"];
  [query bindString:NSStringFromClass(klass) named:@"class"];
  [query bindString:category named:@"category"];
  [query step];

  int64_t rowId = [query int64ValueAtColumnNamed:@"id"];
  [query release];

  return rowId;
}

-(void)immediatelyWriteHash:(NSString*)hash forRowId:(int64_t)rowId
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"UPDATE write_cache SET hash = :hash WHERE id = :id"];
  [query bindString:hash named:@"hash"];
  [query bindInt64:rowId named:@"id"];
  [query step];
  [query release];
}

-(NSString*)immediatelyReadHashForRowId:(int64_t)rowId
{
  GreeSqlQuery* query = [[GreeSqlQuery alloc]
                         initWithDatabase:self.databaseHandle
                                statement:@"SELECT hash FROM write_cache WHERE id = :id"];
  [query bindInt64:rowId named:@"id"];
  [query step];

  NSString* rowHash = [query stringValueAtColumnNamed:@"hash"];
  [query release];

  return rowHash;
}

#pragma mark Other Utility Methods

-(id)objectOfClass:(Class)klass fromCacheData:(NSData*)data
{
  id root = [[GreeJSONDecoder decoder] objectWithData:data];
  NSDictionary* wrapper = [NSDictionary dictionaryWithObject:root forKey:@"object"];
  GreeSerializer* deserializer = [[GreeSerializer alloc] initWithSerializedDictionary:wrapper];
  id object = [[deserializer objectOfClass:klass forKey:@"object"] retain];
  [deserializer release];
  return [object autorelease];
}

-(void)dispatchCacheOperation:(GreeWriteCacheOperationHandle)handle withBlock:(void (^)(void))block
{
  // retain the group for the life of the operation
  dispatch_retain(handle);

  void (^endTask)(void) =^(void){
    UIBackgroundTaskIdentifier taskId = (UIBackgroundTaskIdentifier)dispatch_get_context(handle);
    [[UIApplication sharedApplication] endBackgroundTask:taskId];
  };

  // begin background task, stash the ID in the group's context
  UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:endTask];
  dispatch_set_context(handle, (void*)taskId);

  // queue the work block
  dispatch_group_async(handle, self.queue, ^{
                         if (!self.cancelled) {
                           block();
                         }
                       });

  // when it finishes... end the background task and release the group
  dispatch_group_notify(handle, self.queue, ^{
                          endTask();
                          dispatch_release(handle);
                        });
}

-(void)bootstrapDatabase
{
  dispatch_async(self.queue, ^{
                   GreeSqlQuery* version = [[GreeSqlQuery alloc] initWithDatabase:self.databaseHandle statement:@"PRAGMA user_version"];
                   [version step];
                   NSInteger schemaVersion = [version integerValueAtColumnNamed:@"user_version"];

                   GreeSqlQuery* query = nil;

    #define EXECUTE_QUERY_ONCE(queryString) \
  query = [[GreeSqlQuery alloc] initWithDatabase:self.databaseHandle statement:queryString]; \
  [query step]; \
  [query release];

                   if (schemaVersion < 1) {
                     EXECUTE_QUERY_ONCE(@"BEGIN TRANSACTION")

                     EXECUTE_QUERY_ONCE(@"CREATE TABLE write_cache ("
                                        @"id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                        @"class TEXT NOT NULL, "
                                        @"category TEXT NOT NULL, "
                                        @"data BLOB NOT NULL, "
                                        @"flags INT NOT NULL, "
                                        @"hash TEXT NOT NULL)")

                     EXECUTE_QUERY_ONCE(@"CREATE INDEX write_cache_class_idx ON write_cache (class)")
                     EXECUTE_QUERY_ONCE(@"CREATE INDEX write_cache_class_category_idx ON write_cache (class, category)")
                     EXECUTE_QUERY_ONCE(@"CREATE INDEX write_cache_class_category_id_idx ON write_cache (class, category, id)")

                     EXECUTE_QUERY_ONCE(@"PRAGMA user_version = 1")

                     EXECUTE_QUERY_ONCE(@"COMMIT TRANSACTION")

                     [version reset];
                     [version step];
                   }

    #undef EXECUTE_QUERY_ONCE

                   [version release];

                   self.readCategoriesForClassQuery = [[[GreeSqlQuery alloc]
                                                        initWithDatabase:self.databaseHandle
                                                               statement:@"SELECT DISTINCT category FROM write_cache WHERE class = :class"] autorelease];

                   self.readCacheEntryQuery = [[[GreeSqlQuery alloc]
                                                initWithDatabase:self.databaseHandle
                                                       statement:@"SELECT * FROM write_cache WHERE class = :class AND category = :category ORDER BY id ASC"] autorelease];

                   self.writeCacheEntryQuery = [[[GreeSqlQuery alloc]
                                                 initWithDatabase:self.databaseHandle
                                                        statement:@"INSERT INTO write_cache (class, category, data, flags, hash) VALUES (:class, :category, :data, :flags, :hash)"] autorelease];

                   self.deleteCacheEntryQuery = [[[GreeSqlQuery alloc]
                                                  initWithDatabase:self.databaseHandle
                                                         statement:@"DELETE FROM write_cache WHERE id = :id"] autorelease];

                   self.purgeAllCacheEntriesOfClassAndCategoryQuery = [[[GreeSqlQuery alloc]
                                                                        initWithDatabase:self.databaseHandle
                                                                               statement:@"DELETE FROM write_cache WHERE class = :class AND category = :category"] autorelease];

                   self.trimCacheEntriesQuery = [[[GreeSqlQuery alloc]
                                                  initWithDatabase:self.databaseHandle
                                                         statement:@"DELETE FROM write_cache WHERE class = :class AND category = :category "
                                                  @"AND id <= ( SELECT id FROM write_cache ORDER BY id DESC LIMIT :categorySize, 1 )"] autorelease];

                   self.setFlagsQuery = [[[GreeSqlQuery alloc]
                                          initWithDatabase:self.databaseHandle
                                                 statement:@"UPDATE write_cache SET flags = :flags WHERE id = :id"] autorelease];
                 });
}

@end
