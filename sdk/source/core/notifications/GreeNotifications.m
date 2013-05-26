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

#import "GreeNotifications.h"
#import "GreeInviteNotificationField.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeError+Internal.h"
#import "AFHTTPRequestOperation.h"
#import "GreeMarkasRead.h"
#import "GreeNotificationLoader.h"
#import "GreeNotificationFeed.h"

@interface GreeNotifications ()
+(NSError*)parseResponseData:(NSDictionary*)responseData
                      fields:(NSArray*)fields
                       appId:(NSString*)appId
                      offset:(NSInteger)offset
                       limit:(NSInteger)limit
               notifications:(GreeNotifications**)notifications;
+(NSString*)cachePathWithCacheKey:(NSString*)cacheKey;
@property (nonatomic, retain, readwrite) NSString* appId;
@property (nonatomic, retain, readwrite) NSString* appName;
@property (nonatomic, retain, readwrite) NSArray* fields;
@end

@implementation GreeNotifications

#pragma mark - Object Lifecyle

-(void)dealloc
{
  self.appId = nil;
  self.appName = nil;
  self.fields = nil;
  [super dealloc];
}

-(id)initWithAppId:(NSString*)appId appName:(NSString*)appName
{
  self = [super init];
  if (self) {
    self.fields = [NSMutableArray arrayWithCapacity:0];
    self.appId = appId;
    self.appName = appName;
  }
  return self;
}

#pragma mark - Public Interface

-(void)addField:(GreeNotificationField*)field
{
  if (field) {
    [(NSMutableArray*)self.fields addObject:field];
  }
}

+(void)loadFeedsWithFields:(NSArray*)fields
                     appId:(NSString*)appId
                    offset:(NSInteger)offset
                     limit:(NSInteger)limit
                   saveKey:(NSString*)saveKey
                     block:(void (^)(GreeNotifications* notifications, NSError* error))block
{
  NSString* filePath = [GreeNotifications cachePathWithCacheKey:saveKey];
  GreeHTTPSuccessBlock successBlock =^(GreeAFHTTPRequestOperation* operation, id responseObject) {
    GreeNotifications* notifications = nil;
    NSError* returnError = nil;
    if(![responseObject isKindOfClass:[NSDictionary class]]) {
      returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    } else {
      returnError =[GreeNotifications
                    parseResponseData:responseObject
                               fields:fields
                                appId:appId
                               offset:offset
                                limit:limit
                        notifications:&notifications];
    }
    if (saveKey != nil && !([saveKey isEqualToString:@""])) {
      if (!returnError&&notifications) {
        [NSKeyedArchiver archiveRootObject:notifications toFile:filePath];
      }
    }
    block(notifications, returnError);
  };

  GreeHTTPFailureBlock failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error) {
    if (operation.response.statusCode == 404) {
      block(nil, nil);
    } else {
      block(nil, [GreeError convertToGreeError:error]);
    }
  };

  NSString* endpoint = @"/api/rest/notification/@app/";
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                          [fields componentsJoinedByString:@","], @"fields",
                          [NSString stringWithFormat:@"%d", offset], @"offset",
                          [NSString stringWithFormat:@"%d", limit], @"limit",
                          nil];
  [[GreePlatform sharedInstance].httpClient
      getPath:endpoint
   parameters:params
      success:successBlock
      failure:failureBlock];
}

+(void)loadCacheFeedsWithCacheKey:(NSString*)cacheKey
                            block:(void (^)(GreeNotifications* notifications, NSError* error))block
{

  NSString* filePath = [GreeNotifications cachePathWithCacheKey:cacheKey];
  GreeNotifications* notifications = nil;
  NSError* returnError = nil;
  notifications = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
  if (notifications) {
    block(notifications, nil);
  } else {
    returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    block(nil, returnError);
  }
}

+(void)clearCacheFeedsWithCacheKey:(NSString*)cacheKey
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSString* filePath = [GreeNotifications cachePathWithCacheKey:cacheKey];
  if (![fm fileExistsAtPath:filePath]) {
    return;
  }
  [fm removeItemAtPath:filePath error:nil];
}

+(void)updateCacheFeedMarkReadWithType:(NSString*)type
                              cacheKey:(NSString*)cacheKey
{
  NSString* filePath = [GreeNotifications cachePathWithCacheKey:cacheKey];
  GreeNotifications* notifications = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
  BOOL rewriteFlag = NO;
  if (notifications) {
    for (GreeNotificationField* field in notifications.fields) {
      BOOL matchFlag = NO;
      if ([type isEqualToString:GreeMarkasReadTypeGame]) {
        if ([field.fieldName isEqualToString:@"target"] || [field.fieldName isEqualToString:@"other"]) {
          matchFlag = YES;
        }
      } else if ([type isEqualToString:GreeMarkasReadTypeSNS]) {
        if ([field.fieldName isEqualToString:@"activity"] || [field.fieldName isEqualToString:@"friend"]) {
          matchFlag = YES;
        }
      } else if ([type isEqualToString:GreeMarkasReadTypeInvite]) {
        if ([field.fieldName isEqualToString:@"invite"]) {
          matchFlag = YES;
        }
      } else if ([type isEqualToString:GreeMarkasReadTypeTarget]) {
        if ([field.fieldName isEqualToString:@"target"]) {
          matchFlag = YES;
        }
      } else if ([type isEqualToString:GreeMarkasReadTypeActivity]) {
        if ([field.fieldName isEqualToString:@"activity"]) {
          matchFlag = YES;
        }
      } else if ([type isEqualToString:GreeMarkasReadTypeFriend]) {
        if ([field.fieldName isEqualToString:@"friend"]) {
          matchFlag = YES;
        }
      }
      if (matchFlag) {
        for (GreeNotificationFeed* feed in field.feeds) {
          if (feed.unread) {
            feed.unread = NO;
            rewriteFlag = YES;
          }
        }
      }
    }
    if (rewriteFlag) {
      [NSKeyedArchiver archiveRootObject:notifications toFile:filePath];
    }
  }
}

+(void)deleteCacheFeedFriendWithFeedKey:(NSString*)feedKey
                               cacheKey:(NSString*)cacheKey
{
  NSString* filePath = [GreeNotifications cachePathWithCacheKey:cacheKey];
  GreeNotifications* notifications = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
  if (notifications) {
    for (GreeNotificationField* field in notifications.fields) {
      if ([field.fieldName isEqualToString:kGreeFriendNotificationField]) {
        for (GreeNotificationFeed* feed in field.feeds) {
          if ([feed.feedKey isEqualToString:feedKey]) {
            NSMutableArray* mutableFeeds = [field.feeds mutableCopy];
            [mutableFeeds removeObject:feed];
            field.feeds = (NSArray*)mutableFeeds;
            [NSKeyedArchiver archiveRootObject:notifications toFile:filePath];
            [mutableFeeds release];
            return;
          }
        }
      }
    }
  }
}

#pragma mark Internal Methoads

+(NSError*)parseResponseData:(NSDictionary*)responseData
                      fields:(NSArray*)fields
                       appId:(NSString*)appId
                      offset:(NSInteger)offset
                       limit:(NSInteger)limit
               notifications:(GreeNotifications**)notifications
{
  NSDictionary* rootDictionary = [responseData objectForKey:@"entry"];
  NSError* error = nil;
  if(![rootDictionary isKindOfClass:[NSDictionary class]]) {
    error = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
  } else {
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:rootDictionary];
    for (NSString* field in fields) {
      NSDictionary* fieldDict = [serializer objectForKey:field];
      if(![fieldDict isKindOfClass:[NSDictionary class]]) {
        error = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
      } else {
        NSArray* entries = [fieldDict objectForKey:@"entries"];
        if(![entries isKindOfClass:[NSArray class]]) {
          error = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
        } else {
          NSArray* feeds = [GreeSerializer deserializeArray:entries withClass:[GreeNotificationFeed class]];
          NSInteger offset = [serializer integerForKey:@"offset"];
          NSInteger limit = [serializer integerForKey:@"limit"];
          NSString* appId = [serializer objectForKey:@"app_id"];
          NSString* appName = [serializer objectForKey:@"app_name"];
          BOOL hasMore =[[fieldDict objectForKey:@"has_more"] boolValue];
          NSString* url =[fieldDict objectForKey:@"url"];
          NSString* message =[fieldDict objectForKey:@"message"];
          GreeNotificationField* notifyField;
          if ([field isEqualToString:kGreeInviteNotificationField]) {
            BOOL unreadInvite =[[fieldDict objectForKey:@"unread_count"] integerValue];
            notifyField = [[GreeInviteNotificationField alloc]
                           initWithName:field
                                    url:url
                                message:message
                                  feeds:feeds
                                 offset:offset
                                  limit:limit
                                hasMore:hasMore
                           unreadInvite:unreadInvite];
          } else {
            notifyField = [[GreeNotificationField alloc]
                           initWithName:field
                                    url:url
                                message:message
                                  feeds:feeds
                                 offset:offset
                                  limit:limit
                                hasMore:hasMore];
          }
          if (*notifications == nil) {
            *notifications = [[[GreeNotifications alloc] initWithAppId:appId appName:appName] autorelease];
          }
          [*notifications addField:notifyField];
          [notifyField release];
        }
      }
    }
  }
  return error;
}

+(NSString*)cachePathWithCacheKey:(NSString*)cacheKey
{
  NSArray* cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  return [[cache objectAtIndex:0] stringByAppendingPathComponent:cacheKey];
}

#pragma mark - NSCoding Protocol

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self.appId forKey:@"appId"];
  [aCoder encodeObject:self.appName forKey:@"appName"];
  [aCoder encodeObject:self.fields forKey:@"fields"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super init];
  if (self) {
    self.appId = [aDecoder decodeObjectForKey:@"appId"];
    self.appName = [aDecoder decodeObjectForKey:@"appName"];
    self.fields = [aDecoder decodeObjectForKey:@"fields"];
  }
  return self;
}

@end
