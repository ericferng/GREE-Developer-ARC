//
// Copyright 2011 GREE, Inc.
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
 * @file GreeNotificationQueue.h
 * GreeNotificationQueue class
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeNotificationTypes.h"
#import "GreePlatform.h"
#import "GreePlatformComponent.h"

@class GreeNotification;
@class GreeSettings;

/**
 * The GreeNotificationQueue interface manages a queue of GreeNotifications and their
 * display. It exposes methods to queue a notification as well as various properties
 * relating to their presentation.
 *
 * @note You can access the platform's notification queue via GreePlatform
 */
@interface GreeNotificationQueue : NSObject<UIGestureRecognizerDelegate, GreePlatformComponent>

-(id)initWithSettings:(GreeSettings*)settings;

/**
 * The location on the screen where the notifications should be drawn.  Changing this value will draw the
 * notification on the top or bottom of the screen.  The drawing action takes into account the values of this
 * property and interfaceOrientation, so that if the device is rotated, the top and bottom position will change
 * to the top and bottom appropriate for the given orientation.
 */
@property (nonatomic) GreeNotificationDisplayPosition displayPosition;

/**
 * A flag which controls whether or not the notification is enabled.  If YES, notifications will be displayed.  If NO,
 * notifications will not be displayed.  Any notifications received while the flag is NO will be discarded by the
 * queue.
 */
@property BOOL notificationsEnabled;

/**
 * Adds a GreeNotification to the queue of notifications.
 * @param notification a GreeNotification
 */
-(void)addNotification:(GreeNotification*)notification;

@end

@interface GreePlatform (GreeNotifications)
/**
 * @brief Gives access to the main notification queue
 */
-(GreeNotificationQueue*)notificationQueue;
@end



