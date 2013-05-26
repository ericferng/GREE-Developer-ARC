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

@class GreeNotificationField;

@interface GreeNotifications : NSObject<NSCoding>

@property (nonatomic, retain, readonly) NSString* appId;
@property (nonatomic, retain, readonly) NSString* appName;
@property (nonatomic, retain, readonly) NSArray* fields;

+(void)loadFeedsWithFields:(NSArray*)fields
                     appId:(NSString*)appId
                    offset:(NSInteger)offset
                     limit:(NSInteger)limit
                   saveKey:(NSString*)saveKey
                     block:(void (^)(GreeNotifications* notifications, NSError* error))block;
+(void)loadCacheFeedsWithCacheKey:(NSString*)cacheKey
                            block:(void (^)(GreeNotifications* notifications, NSError* error))block;
+(void)clearCacheFeedsWithCacheKey:(NSString*)cacheKey;
+(void)updateCacheFeedMarkReadWithType:(NSString*)type
                              cacheKey:(NSString*)cacheKey;
+(void)deleteCacheFeedFriendWithFeedKey:(NSString*)feedkey
                               cacheKey:(NSString*)cacheKey;
-(id)initWithAppId:(NSString*)appId appName:(NSString*)appName;
-(void)addField:(GreeNotificationField*)field;
@end
