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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GreeNotificationTypes.h"
@class GreeNotification;

/**
 * @internal
 * @brief A button object which displays the content of single notification object, including its icon, title,
 * message, and possibly a close button.  This is an internal class, so there is not reason to interact with
 * it directly.
 */
@interface GreeNotificationView : UIView

/**
 * @brief A UIImageView to display the user icon of the notification.
 */
@property (nonatomic, retain) IBOutlet UIImageView* iconView;

/**
 * @brief A label to display the message of the notification.
 */
@property (nonatomic, retain) IBOutlet UILabel* messageLabel;

/**
 * @brief An (optional) button which allows the user to dismiss the notification.  Whether or not this button is
 * displayed is controlled by the value of showsCloseButton.
 */
@property (nonatomic, retain) IBOutlet UIButton* closeButton;

/**
 * @brief A BOOL flag which indicates whether or not the close button is displayed.
 */
@property (nonatomic) BOOL showsCloseButton;


/**
 * @brief The notification object
 */
@property (nonatomic, retain) GreeNotification* notification;

/**
 * @brief Initializes a new GreeNotificationView.
 *
 * Initializes a new GreeNotificationView with a given title, message, icon, and frame.  This is the
 * designated initializer.
 *
 * @param message The notification message
 * @param icon The user icon
 * @param frame The frame the button will be displayed in.
 * @return a new GreeNotificationView
 */
-(id)initWithMessage:(NSString*)message
                icon:(UIImage*)image
               frame:(CGRect)frame;

/**
 * @brief Initializes a new GreeNotificationView.
 *
 * Initializes a new GreeNotificationView with a given title, message, badge string, icon, and frame.
 * This is the designated initializer.
 *
 * @param message The notification message
 * @param icon The user icon
 * @param badgeString The string in the badge
 * @param frame The frame the button will be displayed in.
 * @return a new GreeNotificationView
 */
-(id)initWithMessage:(NSString*)message
                icon:(UIImage*)image
         badgeString:(NSString*)badgeString
               frame:(CGRect)frame;

@end
