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

#import "UIViewController+GreeAdditions.h"
#import "GreeDashboardViewController.h"
#import "GreeNotificationBoardViewController.h"
#import "UIViewController+GreePlatform.h"
#import "GreeNotificationBoard+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeAuthorization.h"
#import "GreeCampaignCode.h"
#import "GreePopup.h"
#import "GreeNSNotification.h"
#import "GreeCategoryProperty.h"
#import "GreeLogger.h"

#import <QuartzCore/QuartzCore.h>

static char PopupKey;
static char PopupParentKey;

@interface UIViewController (GreeAdditionsInternal)
@property (nonatomic, getter=greeIsBeingDismissed, setter=greeSetBeingDismissed:) BOOL greeBeingDismissed;
@property (nonatomic, getter=greeIsBeingPresented, setter=greeSetBeingPresented:) BOOL greeBeingPresented;
-(void)greeNotifyDelegateWillDisplay;
-(void)greeNotifyDelegateDidDismiss;
@end

@implementation UIViewController (GreeAdditions)

#pragma mark Dashboard Methods

-(void)presentGreeDashboardWithBaseURL:(NSURL*)URL
                              delegate:(id<GreeDashboardViewControllerDelegate>)delegate
                              animated:(BOOL)animated
                            completion:(void (^)(void))completion
{
  UIViewController* viewController = [self greePresentedViewController];
  if ([viewController isKindOfClass:[GreeDashboardViewController class]]) {
    // Dashboard is already being presented
    return;
  }

  if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeDashboard]) {
    // Is going to perform authorization first
    return;
  }

  GreeDashboardViewController* dashboard = [[GreeDashboardViewController alloc] initWithBaseURL:URL];
  dashboard.dashboardDelegate = delegate;
  [self greePresentViewController:dashboard animated:YES completion:completion];
  [GreePlatform sharedInstance].dashboardViewController = dashboard;
  [dashboard release];
}

-(void)dismissGreeDashboardAnimated:(BOOL)animated completion:(void (^)(id results))completion
{
  UIViewController* viewController = [self greePresentedViewController];

  if (![viewController isKindOfClass:[GreeDashboardViewController class]]) {
    return;
  }

  GreeDashboardViewController* dashboard = (GreeDashboardViewController*)viewController;
  __block id results = [dashboard.results retain];

  [self greeDismissViewControllerAnimated:animated completion:^{
     if (completion) {
       completion(results);
     }
     [GreePlatform sharedInstance].dashboardViewController = nil;
     [results release];
   }];
}

-(void)dashboardCloseButtonPressed:(GreeDashboardViewController*)dashboardViewController
{
  [self dismissGreeDashboardAnimated:YES completion:nil];
}

#pragma mark Notification Board Methods

-(void)presentGreeNotificationBoardWithType:(GreeNotificationBoardLaunchType)type
                                 parameters:(NSDictionary*)parameters
                                   delegate:(id<GreeNotificationBoardViewControllerDelegate>)delegate
                                   animated:(BOOL)animated
                                 completion:(void (^)(void))completion
{
  if (type == GreeNotificationBoardLaunchWithSns) {
    if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeSNSNotificationBoard]) {
      return;
    }
  } else {
    if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeGameNotificationBoard]) {
      return;
    }
  }

  NSURL* URL = [GreeNotificationBoardViewController URLForLaunchType:type withParameters:parameters];
  GreeNotificationBoardViewController* viewController = [[GreeNotificationBoardViewController alloc] initWithURL:URL];
  viewController.delegate = delegate;
  [self greePresentViewController:viewController animated:animated completion:completion];
  [viewController release];
}

-(void)dismissGreeNotificationBoardAnimated:(BOOL)animated completion:(void (^)(id))completion
{
  UIViewController* viewController = [self greePresentedViewController];

  if (![viewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    return;
  }

  GreeNotificationBoardViewController* notificationBoard = (GreeNotificationBoardViewController*)viewController;
  __block id results = [notificationBoard.results retain];

  [self greeDismissViewControllerAnimated:animated completion:^{
     if (completion) {
       completion(results);
     }

     [results release];
   }];
}

-(void)notificationBoardCloseButtonPressed:(GreeNotificationBoardViewController*)notificationBoardController
{
  [self dismissGreeNotificationBoardAnimated:YES completion:nil];
}

#pragma mark Popup helper methods

-(GreePopup*)greeCurrentPopup
{
  GreePopup* popup = objc_getAssociatedObject(self, &PopupKey);

  if (!popup && [self isKindOfClass:[GreePopup class]]) {
    return (GreePopup*)self;
  }

  return [popup greeCurrentPopup];
}

-(void)greeAddPopup:(GreePopup*)popup
{
  UIViewController* parent = [self greeCurrentPopup];
  if (!parent) {
    parent = self;
  }

  objc_setAssociatedObject(parent, &PopupKey, popup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(popup, &PopupParentKey, parent, OBJC_ASSOCIATION_ASSIGN);
}

-(void)greeRemovePopup
{
  GreePopup* currentPopup = [self greeCurrentPopup];
  UIViewController* parent = objc_getAssociatedObject(currentPopup, &PopupParentKey);

  objc_setAssociatedObject(currentPopup, &PopupParentKey, nil, OBJC_ASSOCIATION_ASSIGN);
  objc_setAssociatedObject(parent, &PopupKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Notification helper methods

-(BOOL)greeShouldShowGreeNotification
{
  // We should show the notification if the view controller is a dashboard or a notification board or the view controller
  // is any view controller except one from GreePlatform.  The last is hard to detect, but the best way I have come up
  // with is to exclude those using the Gree namespace.

  return [self isKindOfClass:[GreeNotificationBoardViewController class]] ||
         [self isKindOfClass:[GreeDashboardViewController class]] ||
         ![NSStringFromClass ([self class]) hasPrefix:@"Gree"];
}

#pragma mark Core Methods

-(void)greePresentViewController:(UIViewController*)viewController
                        animated:(BOOL)animated
                      completion:(void (^)(void))completion
{
  if ([viewController greeIsBeingDismissed] ||
      [viewController greeIsBeingPresented]) {
    GreeLogPublic(@"Cannot present view controller (%@) while it is being dismissed or presented", viewController);
    return;
  }

  UIInterfaceOrientation presentInterfaceOrientation;
  NSString* transitionDirection;

  if ([GreePlatform sharedInstance].manuallyRotate) {
    presentInterfaceOrientation = [GreePlatform sharedInstance].interfaceOrientation;
  } else {
    presentInterfaceOrientation = self.interfaceOrientation;
  }

  switch (presentInterfaceOrientation) {
  default:    // fall through to portrait if things go horribly wrong
  case UIInterfaceOrientationPortrait:
    transitionDirection = kCATransitionFromTop;
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
    transitionDirection = kCATransitionFromBottom;
    break;
  case UIInterfaceOrientationLandscapeLeft:
    transitionDirection = kCATransitionFromRight;
    break;
  case UIInterfaceOrientationLandscapeRight:
    transitionDirection = kCATransitionFromLeft;
    break;
  }

  // Since we are not using an animation, we must make sure toBeDismissed is always in memory
  // while the transaction takes place. The completion block retain it for us now
  [viewController greeSetBeingPresented:YES];
  void (^onCompletion)(void) = ^{
    [viewController greeSetBeingPresented:NO];
    if (completion) {
      completion();
    }
  };

  if (animated) {
    // In this case, to get the completion block called properly we need a nested transaction.
    // One for the custom animation and a wrapper for the animation done inside
    // presentViewController:animated:completion: or presentModalViewController:animated: methods
    [CATransaction begin];
    [CATransaction begin];
    [CATransaction setCompletionBlock:onCompletion];

    CATransition* transition = [CATransition animation];
    transition.type = kCATransitionMoveIn;
    transition.subtype = transitionDirection;
    transition.duration = 0.3f;
    transition.fillMode = kCAFillModeForwards;
    transition.removedOnCompletion = YES;

    [self.view.window.layer addAnimation:transition forKey:@"transition"];
    [CATransaction commit];
  }

  // Present the controller
  if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
    [self presentViewController:viewController animated:NO completion:nil];
  } else {
    [self presentModalViewController:viewController animated:NO];
  }
  if ([viewController isKindOfClass:[GreeDashboardViewController class]] ||
    [viewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    viewController.view.frame = [[UIScreen mainScreen] applicationFrame];
  }

  if (animated) {
    [CATransaction commit];
  } else {
    onCompletion();
  }

  [self greeNotifyDelegateWillDisplay];
  [self greeNotifyWillOpenNSNotificationForViewController:viewController];
}

-(void)greeDismissViewControllerAnimated:(BOOL)animated
                              completion:(void (^)(void))completion
{
  UIViewController* toBeDismissed = [self greePresentedViewController];

  if (toBeDismissed == nil) {
    toBeDismissed = self;
  }

  if ([toBeDismissed greeIsBeingDismissed] ||
      [toBeDismissed greeIsBeingPresented]) {
    GreeLogPublic(@"Cannot dismiss view controller (%@) while it is being presented or dismissed", toBeDismissed);
    return;
  }

  UIInterfaceOrientation dismissInterfaceOrientation;
  NSString* transitionDirection;

  if ([GreePlatform sharedInstance].manuallyRotate) {
    dismissInterfaceOrientation = [GreePlatform sharedInstance].interfaceOrientation;
  } else {
    dismissInterfaceOrientation = toBeDismissed.interfaceOrientation;
  }

  switch (dismissInterfaceOrientation) {
  default:    // fall through to portrait if things go horribly wrong
  case UIInterfaceOrientationPortrait:
    transitionDirection = kCATransitionFromBottom;
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
    transitionDirection = kCATransitionFromTop;
    break;
  case UIInterfaceOrientationLandscapeLeft:
    transitionDirection = kCATransitionFromLeft;
    break;
  case UIInterfaceOrientationLandscapeRight:
    transitionDirection = kCATransitionFromRight;
    break;
  }

  // Since we are not using an animation, we must make sure toBeDismissed is always in memory
  // while the transaction takes place. The completion block retain it for us now
  [toBeDismissed greeSetBeingDismissed:YES];
  void (^onCompletion)(void) = ^{
    [toBeDismissed greeSetBeingDismissed:NO];
    [self greeNotifyDelegateDidDismiss];
    [toBeDismissed greeNotifyDidCloseNSNotificationWithParameters:nil];
    if (completion) {
      completion();
    }
  };

  if (animated) {
    [CATransaction begin];
    [CATransaction setCompletionBlock:onCompletion];

    CATransition* transition = [CATransition animation];
    transition.type = kCATransitionReveal;
    transition.subtype = transitionDirection;
    transition.duration = 0.3f;
    transition.fillMode = kCAFillModeForwards;
    transition.removedOnCompletion = YES;
    [toBeDismissed.view.window.layer addAnimation:transition forKey:@"transition"];
  }

  // Dismiss the controller
  UIViewController* presentingViewController = [toBeDismissed greePresentingViewController];
  if ([presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
    [presentingViewController dismissViewControllerAnimated:NO completion:^{}];
  } else {
    [presentingViewController dismissModalViewControllerAnimated:NO];
  }
  if (([presentingViewController isKindOfClass:[GreeDashboardViewController class]]) ) {
    presentingViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
  }

  if (animated) {
    [CATransaction commit];
  } else {
    onCompletion();
  }
}

+(UIViewController*)greeLastPresentedViewController
{
  UIWindow* window = [[UIApplication sharedApplication] keyWindow];
  UIViewController* rootViewController = [window rootViewController];
  if (!rootViewController) {
    window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    rootViewController = [window rootViewController];
  }

  NSAssert(rootViewController != nil, @"Error: UIWindow's rootViewController is NIL, thus popup system, dashboard and notification board cannot be presented!");
  return [rootViewController greeLastPresentedViewController];
}

-(UIViewController*)greeLastPresentedViewController
{
  UIViewController* parentController = self;
  UIViewController* modalController = [parentController greePresentedViewController];

  while (modalController != nil) {
    parentController = modalController;
    modalController = [parentController greePresentedViewController];
  }

  return parentController;
}

-(UIViewController*)greePresentingViewController
{
  SEL parentSelector = @selector(parentViewController);

  if ([self respondsToSelector:@selector(presentingViewController)]) {
    parentSelector = @selector(presentingViewController);
  }

  return [self performSelector:parentSelector];
}

-(UIViewController*)greePresentedViewController
{
  SEL modalSelector = @selector(modalViewController);

  if ([self respondsToSelector:@selector(presentedViewController)]) {
    modalSelector = @selector(presentedViewController);
  }

  return [self performSelector:modalSelector];
}

-(BOOL)isAbleToAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation == toInterfaceOrientation;
  }

  return YES;
}

-(void)greeNotifyWillOpenNSNotificationForViewController:(UIViewController*)aViewController
{
  NSMutableDictionary* userInfo = [GreePlatform dictionaryWithTypeForViewController:aViewController];

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyWillOpenNotification
   object:aViewController
   userInfo:userInfo];
}

-(void)greeNotifyDidCloseNSNotificationWithParameters:(NSDictionary*)parameters;
{
  NSMutableDictionary* userInfo = [GreePlatform dictionaryWithTypeForViewController:self];

  if (parameters) {
    [userInfo addEntriesFromDictionary:parameters];
  }

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyDidCloseNotification
   object:self
   userInfo:userInfo];
}

GREE_SYNTHESIZE(greeCurrentWidget, greeSetCurrentWidget, GreeWidget*, retain)

@end

@implementation UIViewController (GreeAdditionsInternal)

GREE_SYNTHESIZE_PRIMITIVE(greeIsBeingPresented, greeSetBeingPresented, BOOL)
GREE_SYNTHESIZE_PRIMITIVE(greeIsBeingDismissed, greeSetBeingDismissed, BOOL)

-(void)greeNotifyDelegateWillDisplay
{
  if (![self greeCurrentPopup]) {
    id platform = [GreePlatform sharedInstance];
    [[platform delegate] greePlatformWillShowModalView:platform];
  }
}

-(void)greeNotifyWillOpenNSNotificationForViewController:(UIViewController*)aViewController
{
  NSMutableDictionary* userInfo = [GreePlatform dictionaryWithTypeForViewController:aViewController];

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyWillOpenNotification
                 object:aViewController
               userInfo:userInfo];
}

-(void)greeNotifyDelegateDidDismiss
{
  if (![self greeCurrentPopup]) {
    id platform = [GreePlatform sharedInstance];
    [[platform delegate] greePlatformDidDismissModalView:platform];
  }
}

-(void)greeNotifyDidCloseNSNotificationWithParameters:(NSDictionary*)parameters;
{
  NSMutableDictionary* userInfo = [GreePlatform dictionaryWithTypeForViewController:self];

  if (parameters) {
    [userInfo addEntriesFromDictionary:parameters];
  }

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyDidCloseNotification
                 object:self
               userInfo:userInfo];
}

@end
