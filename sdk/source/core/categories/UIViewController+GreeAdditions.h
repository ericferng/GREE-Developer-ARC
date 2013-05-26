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

#import <UIKit/UIKit.h>
#import "GreeDashboardViewControllerDelegate.h"
#import "GreeNotificationBoardViewControllerDelegate.h"
#import "GreeNotificationBoard+Internal.h"
#import "GreeWidget.h"

@class GreePopup;

@interface UIViewController (GreeAdditions)<GreeDashboardViewControllerDelegate, GreeNotificationBoardViewControllerDelegate>

// Dashboard specific internal methods

-(void)presentGreeDashboardWithBaseURL:(NSURL*)URL
                              delegate:(id<GreeDashboardViewControllerDelegate>)delegate
                              animated:(BOOL)animated
                            completion:(void (^)(void))completion;

-(void)dismissGreeDashboardAnimated:(BOOL)animated completion:(void (^)(id results))completion;

// Notification board specific internal methods

-(void)presentGreeNotificationBoardWithType:(GreeNotificationBoardLaunchType)type
                                 parameters:(NSDictionary*)parameters
                                   delegate:(id<GreeNotificationBoardViewControllerDelegate>)delegate
                                   animated:(BOOL)animated
                                 completion:(void (^)(void))completion;

-(void)dismissGreeNotificationBoardAnimated:(BOOL)animated completion:(void (^)(id results))completion;

// Popup helper methods

-(GreePopup*)greeCurrentPopup;
-(void)greeAddPopup:(GreePopup*)popup;
-(void)greeRemovePopup;
// Widget helper methods

-(GreeWidget*)greeCurrentWidget;
-(void)greeSetCurrentWidget:(GreeWidget*)widget;

// Notification helper methods
-(BOOL)greeShouldShowGreeNotification;


// Core methods
//
// All internal UIViewController display should route through here, if not
// call it directly.
-(void)greePresentViewController:(UIViewController*)viewController
                        animated:(BOOL)animated
                      completion:(void (^)(void))completion;
// Similar to greePresent -- all UIViewController dismissal routes through
// this method.
-(void)greeDismissViewControllerAnimated:(BOOL)animated
                              completion:(void (^)(void))completion;

// Convenient accessors for traversing the presented view controller chain
+(UIViewController*)greeLastPresentedViewController;
-(UIViewController*)greeLastPresentedViewController;
-(UIViewController*)greePresentingViewController;
-(UIViewController*)greePresentedViewController;

// notify "open" notification from aViewController
-(void)greeNotifyWillOpenNSNotificationForViewController:(UIViewController*)aViewController;
// notify "close" notification with parameters
-(void)greeNotifyDidCloseNSNotificationWithParameters:(NSDictionary*)parameters;

-(BOOL)isAbleToAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@end

