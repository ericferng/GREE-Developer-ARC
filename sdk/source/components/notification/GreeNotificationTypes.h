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
 * @file GreeNotificationTypes.h
 * GreeNotificationTypes
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * @brief Display position of queued notifications.
 */
typedef enum {
  //#indoc "GreeNotificationDisplayBottomPosition"
/**
 * @brief Display notifications at the bottom of the display boundary.
 */
  GreeNotificationDisplayBottomPosition,
/**
 * @brief Display notifications at the top of the display boundary.
 */
  GreeNotificationDisplayTopPosition
} GreeNotificationDisplayPosition;

/**
 * @return A string representation of a GreeNotificationDisplayPosition.
 */
NSString* NSStringFromGreeNotificationDisplayPosition(GreeNotificationDisplayPosition position);

/**
 * @return A string representation of a UIInterfaceOrientation.
 */
NSString* NSStringFromInterfaceOrientation(UIInterfaceOrientation interfaceOrientation);


/**
 * @brief Display types for a GreeNotification.
 */
typedef enum {
/**
 * @brief Default display type.
 */
  GreeNotificationViewDisplayDefaultType,
/**
 * @brief Adds a close button.
 */
  GreeNotificationViewDisplayCloseType
} GreeNotificationViewDisplayType;

/**
 * @return A string representation of a GreeNotificationButtonDisplayType.
 */
NSString* NSStringFromGreeNotificationViewDisplayType(GreeNotificationViewDisplayType type);

/**
 * @brief A value to represent the time duration for a GreeNotification which does not expire.
 */
extern NSTimeInterval const GreeNotificationInfiniteDuration;
