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
 * @file GreeLocalNotification.h
 * GreeLocalNotification Interface
 */

#import <Foundation/Foundation.h>
#import <UIKit/UILocalNotification.h>
#import <UIKit/UIKit.h>
#import "GreePlatform.h"

extern NSString* const GreeLocalNotificationDidReceiveNotification;

@class GreeSettings;

/**
 * @brief The GreeLocalNotification interface is used for interacting with the local notification service.
 * 
 * GreeLocalNotification is a wrapper class for Apple's local notification feature.
 *
 */
@interface GreeLocalNotification : NSObject
/**
 * @brief Initializes the local notification feature with the given settings object.
 * @note Designated initializer
 */
-(id)initWithSettings:(GreeSettings*)settings;
/**
 * @brief Register a local notification event.
 * @param aDictionary available key & values
 * <table>
 * <tr><th>key</th><th>value</th></tr>
 * <tr><td>@@"message"</td><td>Specify notification message in NSString</td></tr>
 * <tr><td>@@"interval"</td><td>Specify when timer is fired. Set difference time from now in NSDate</td></tr>
 * <tr><td>@@"notifyId"</td><td>Set notification ID in NSNumber</td></tr>
 * <tr><td>@@"callbackParam"</td><td>Set a parameter that is passed to the application when timer is fired.</td></tr>
 * </table>
 * @return @c YES if LocalNotification is registered successfully, @c NO otherwise.
 */
-(BOOL)registerLocalNotificationWithDictionary:(NSDictionary*)aDictionary;
/**
 * @brief Cancel a local notification event.
 * @param identifier Specify target notification ID in NSNumber.
 * @return @c YES if LocalNotification is cancelled successfully, @c NO otherwise.
 */
-(BOOL)cancelNotification:(NSNumber*)identifier;
/**
 * A flag which controls whether or not the local notification is enabled.  If YES, notifications will be set.  If NO,
 * notifications will not be set.
 */
@property BOOL localNotificationsEnabled;

@end

@interface GreePlatform (GreeLocalNotification)
/**
 * @brief Gives access to the main local notification feature.
 */
-(GreeLocalNotification*)localNotification;
@end
