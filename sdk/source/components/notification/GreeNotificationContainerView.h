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
#import "GreeNotificationTypes+Internal.h"

/**
 * @internal
 * A UIView subclass which draws the notification view on the screen in the application's key window.  As new
 * notifications arrive, they are added to the queue in GreeNotificationManager and displayed as
 * GreeNotificationButtons, which are added to the content view of this view.  A new GreeNotificationContainerView is
 * created each time the queue of notifications changes from being empty to non-empty, and its released after
 * the queue becomes empty again.  This class is an internal class.
 */
@interface GreeNotificationContainerView : UIView

/*
 * The view which new GreeNotificationButtons are added to.
 */
@property (nonatomic, retain, readonly) UIView* contentView;
@property (nonatomic) GreeNotificationDisplayPosition displayPosition;

-(id)initWithDisplayPosition:(GreeNotificationDisplayPosition)displayPosition;

@end
