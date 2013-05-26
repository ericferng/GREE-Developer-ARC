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

#import "GreeBadgeValues.h"
#import "GreeSerializable.h"

@interface GreeBadgeValues (Internal)<GreeSerializable>
+(void)loadBadgeValuesWithPath:(NSString*)path block:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block;
+(void)loadBadgeValuesForCurrentApplicationWithBlock:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block;
+(void)loadBadgeValuesForAllApplicationsWithBlock:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block;
+(void)resetBadgeValues;

-(id)initWithSocialNetworkingServiceBadgeCount:(NSInteger)snsBadgeCount applicationBadgeCount:(NSInteger)appBadgeCount;
-(id)initWithSocialNetworkingServiceBadgeCount:(NSInteger)socialNetworkingServiceBadgeCount
                         applicationBadgeCount:(NSInteger)appBadgeCount
                                 snsBadgeCount:(NSUInteger)snsBadgeCount
                              friendBadgeCount:(NSUInteger)friendBadgeCount;
@property (nonatomic, assign, readonly) NSUInteger snsBadgeCount;
@property (nonatomic, assign, readonly) NSUInteger friendBadgeCount;

@end
