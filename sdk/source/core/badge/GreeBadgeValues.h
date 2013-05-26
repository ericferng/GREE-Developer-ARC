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
 * @file GreeBadgeValues.h
 * A data class for accessing the values of the notification badges.
 */

#import <Foundation/Foundation.h>

/**
 * The name of a notification which is posted when the badge values have been updated.
 */
extern NSString* const GreeBadgeValuesDidUpdateNotification;

/**
 * The GreeBadgeValues class provides socialNetworkingServiceBadgeCount and applicationBadgeCount.
 */
@interface GreeBadgeValues : NSObject

/**
 * The count of badges related to the social networking service.
 */
@property (nonatomic, readonly, assign) NSInteger socialNetworkingServiceBadgeCount;

/**
 * The count of badges related to the application.
 */
@property (nonatomic, readonly, assign) NSInteger applicationBadgeCount;

@end
