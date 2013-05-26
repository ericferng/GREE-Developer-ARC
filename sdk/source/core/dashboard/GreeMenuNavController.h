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

#define OPEN_MENU_OFFSET 270

#define OPEN_MENU_OFFSET_RIGHT_MARGIN 30
#define NAV_BAR_HEIGHT_iPad 44

extern NSString* const GreeDashboardWillShowUniversalMenuNotification;
extern NSString* const GreeDashboardDidShowUniversalMenuNotification;
extern NSString* const GreeDashboardWillHideUniversalMenuNotification;
extern NSString* const GreeDashboardDidHideUniversalMenuNotification;

@class GreeMenuNavController;

@protocol GreeMenuNavControllerDelegate<NSObject>
@optional
-(void)menuController:(GreeMenuNavController*)controller willShowViewController:(UIViewController*)leftViewController;
-(void)menuController:(GreeMenuNavController*)controller didShowViewController:(UIViewController*)leftViewController;
-(void)menuController:(GreeMenuNavController*)controller willHideViewController:(UIViewController*)leftViewController;
-(void)menuController:(GreeMenuNavController*)controller didHideViewController:(UIViewController*)leftViewController;
@end

@interface GreeMenuNavController : UIViewController<UINavigationBarDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, retain) UINavigationController* rootViewController;
@property (nonatomic, retain) UIViewController* menuViewController;
@property (nonatomic, assign) id<GreeMenuNavControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isRevealed;
@property (nonatomic, assign) BOOL allowPanGesture;
@property (nonatomic, assign) BOOL allowSingleTapGesture;

-(id)initWithRootViewController:(UINavigationController*)rootViewController leftViewController:(UIViewController*)leftViewController;
-(BOOL)navigationBar:(UINavigationBar*)navigationBar shouldPushItem:(UINavigationItem*)item;
-(void)revealButtonPushed;
@end
