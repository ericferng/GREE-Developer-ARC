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

/**
 * @file GreeWriteCacheable.h
 * GreeWriteCacheable Protocol
 */

#import <Foundation/Foundation.h>
#import "GreeSerializable.h"

/**
 * A write cacheable class should return this value if they wish to store an unlimited number of objects.
 */
extern NSInteger GreeWriteCacheCategorySizeUnlimited;

/**
 * @brief Adopting this protocol allows a given class to be cached in a GreeWriteCache.
 * @note GreeWriteCacheable objects must also be GreeSerializable.
 *
 * GreeWriteCache stores objects grouped by class, and further, category. The methods in
 * this protocol facilitate discovery by the cache to which category a given instance 
 * belongs, the maximum cache size for each category, etc. It also defines the interface
 * by which a write cacheable object commits itself to the server.
 */
@protocol GreeWriteCacheable<NSObject, GreeSerializable>
@required

/**
 * Sent to the receiver to decide which category the receiver belongs in. Cannot be nil.
 */
-(NSString*)writeCacheCategory;

/**
 * Sent to the receiver to determine the maximum number of objects that can be stored in the cache.
 * @note When this number would be exceeded the cache discards the oldest object.
 * @see GreeWriteCacheCategorySizeUnlimited
 */
+(NSInteger)writeCacheMaxCategorySize;

/**
 * Sent to the receiver when the write cache is committing its objects. The implementation
 * is expected to attempt to commit the receiver to more permanent storage (the remote server)
 * and, upon completion, invoke the given block to notify the cache of commit success or failure.
 */ 
-(void)writeCacheCommitAndExecuteBlock:(void (^)(BOOL commitDidSucceed))block;

@end
