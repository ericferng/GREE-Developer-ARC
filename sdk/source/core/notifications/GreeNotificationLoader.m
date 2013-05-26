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

#import "GreeNotificationLoader.h"
#import "GreeNotifications.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

NSString* const GreeNotificationApplicationDidBecomActive = @"GreeNotificationApplicationDidBecomActive";
NSString* const GreeGameNotificationCacheKey = @"GreeGameNotificationJsonDataCacheKey";
NSString* const GreeFriendNotificationCacheKey = @"GreeFriendNotificationJsonDataCacheKey";
NSString* const GreeSNSNotificationCacheKey = @"GreeSNSNotificationJsonDataCacheKey";

@implementation GreeNotificationLoader

#pragma mark - Public Interface

+(void)loadFeeds
{
  [GreeNotificationLoader loadGameFeeds];
  [GreeNotificationLoader loadSNSFeeds];
  [GreeNotificationLoader loadFriendFeeds];
}

+(void)loadGameFeeds
{
  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSArray* gameArray = [NSArray arrayWithObjects:@"invite", @"target", @"other", nil];
  [GreeNotifications
   loadFeedsWithFields:gameArray
                 appId:appId
                offset:0
                 limit:GreeMaxLoadNotificationFeed
               saveKey:GreeGameNotificationCacheKey
                 block:^(GreeNotifications* notifications, NSError* error) {}
  ];
}

+(void)loadSNSFeeds
{
  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSArray* snsArray = [NSArray arrayWithObject:@"activity"];
  [GreeNotifications
   loadFeedsWithFields:snsArray
                 appId:appId
                offset:0
                 limit:GreeMaxLoadNotificationFeed
               saveKey:GreeSNSNotificationCacheKey
                 block:^(GreeNotifications* notifications, NSError* error) {}
  ];
}

+(void)loadFriendFeeds
{
  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSArray* friendArray = [NSArray arrayWithObject:@"friend"];
  [GreeNotifications
   loadFeedsWithFields:friendArray
                 appId:appId
                offset:0
                 limit:GreeMaxLoadNotificationFeed
               saveKey:GreeFriendNotificationCacheKey
                 block:^(GreeNotifications* notifications, NSError* error) {}
  ];
}

+(void)clearFeedsCache
{
  [GreeNotifications clearCacheFeedsWithCacheKey:GreeGameNotificationCacheKey];
  [GreeNotifications clearCacheFeedsWithCacheKey:GreeSNSNotificationCacheKey];
  [GreeNotifications clearCacheFeedsWithCacheKey:GreeFriendNotificationCacheKey];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

@end
