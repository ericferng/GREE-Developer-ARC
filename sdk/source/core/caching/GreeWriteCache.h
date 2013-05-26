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

#import <Foundation/Foundation.h>
#import "GreeWriteCacheable.h"

typedef dispatch_group_t GreeWriteCacheOperationHandle;

// GreeWriteCache stores serialized object representations of any compatible class grouped by category.
// Objects are stored in the cache until they are evicted.
// Cache eviction occurs when:
//  * An object is successfully committed.
//  * The maximum number of objects is cached and a new object is written.
//    (This will evict the oldest object in the cache.)
@interface GreeWriteCache : NSObject

// designated initializer
-(id)initWithUserId:(NSString*)userId;

// Set the key used when hashing cache entries
-(void)setHashKey:(NSString*)key;

// Write an object to the cache.
-(GreeWriteCacheOperationHandle)writeObject:(id<GreeWriteCacheable>)object;

// Commit objects of a given class (and category, if desired) to the server.
-(GreeWriteCacheOperationHandle)commitAllObjectsOfClass:(Class<GreeWriteCacheable>)klass;
-(GreeWriteCacheOperationHandle)commitAllObjectsOfClass:(Class<GreeWriteCacheable>)klass inCategory:(NSString*)category;

// Delete objects of a given class (and category, if desired.)
-(GreeWriteCacheOperationHandle)deleteAllObjectsOfClass:(Class<GreeWriteCacheable>)klass;
-(GreeWriteCacheOperationHandle)deleteAllObjectsOfClass:(Class<GreeWriteCacheable>)klass inCategory:(NSString*)category;

// Use this method to observe the completion of a cache operation with the given block.
-(void)observeWriteCacheOperation:(GreeWriteCacheOperationHandle)handle forCompletionWithBlock:(void (^)(void))block;

// Cancels all operations which have not yet started.
-(void)cancelOutstandingOperations;

@end
