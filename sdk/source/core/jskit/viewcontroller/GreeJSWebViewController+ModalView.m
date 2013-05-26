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

#import "GreeJSWebViewController+ModalView.h"
#import "GreeJSShowModalViewCommand.h"
#import "GreeJSInputViewController.h"
#import "GreeJSInputSuccessCommand.h"
#import "GreeJSInputFailureCommand.h"
#import "GreeJSModalViewControllable.h"

#import "GreePlatform+Internal.h"
#import "GreeNetworkReachability.h"
#import "GreeGlobalization.h"
#import "UIViewController+GreeAdditions.h"

NSString* const kGreeJSErrorKey = @"error";
NSString* const kGreeJSErrorTitleKey = @"error_title";

@interface GreeJSWebViewController (ModalViewInternal)<GreeJSModalViewControllable>
-(id<GreeJSModalViewControllable>)presentModalViewControllable;
-(void)lockUI;
-(void)unlockUI;
-(void)addGreeJSInputObserver;
-(void)removeGreeJSInputObserver;
@end

@implementation GreeJSWebViewController (ModalView)

#pragma mark - UIViewController Overrides

-(void)dismissModalViewControllerAnimated:(BOOL)animated
{
  GreeJSModalNavigationController* navigationController;
  if (self.inputViewController) {
    navigationController = (GreeJSModalNavigationController*)self.inputViewController.navigationController;
  } else if (self.nextWebViewController) {
    navigationController = (GreeJSModalNavigationController*)self.nextWebViewController.navigationController;
  } else {
    navigationController = (GreeJSModalNavigationController*)self.navigationController;
  }
  if (navigationController.block)
    navigationController.block();

  if (self.inputViewController) {
    self.inputViewController = nil;
  }
  if (self.modalRightButtonCallback) {
    self.modalRightButtonCallback = nil;
  }
  if (self.modalRightButtonCallbackInfo) {
    self.modalRightButtonCallbackInfo = nil;
  }

  [super dismissModalViewControllerAnimated:animated];
}


#pragma mark - GreeJSModalViewControllable Interface

-(void)greeJSModalDisplayLoadingIndicator:(BOOL)show
{
  [self displayLoadingIndicator:show];
}

-(void)greeJSModalSetUserInteractionEnabled:(BOOL)enable
{
  self.navigationItem.rightBarButtonItem.enabled = enable;
  self.navigationItem.leftBarButtonItem.enabled = enable;
  self.view.userInteractionEnabled = enable;
}

-(void)greeJSModalSetCallback:(NSString*)callback toHandler:(GreeJSHandler*)handler
{
  if (self.modalRightButtonCallbackInfo) {
    NSString* namespace = [self.modalRightButtonCallbackInfo valueForKey:@"namespace"];
    NSString* method = [self.modalRightButtonCallbackInfo valueForKey:@"method"];
    [self.handler addCallback:namespace method:method];
  }
  [self.handler callback:callback params:nil];
}


#pragma mark - Internal Methods

-(void)greeJSPresentModalNavigationController:(GreeJSModalNavigationController*)navigationController
                                     animated:(BOOL)animated
{
  __block void (^oldBlock)(void) = navigationController.block;

  navigationController.block =^{
    UIViewController* lastPresentedViewController = [[UIViewController greeLastPresentedViewController] retain];
    [lastPresentedViewController greeDismissViewControllerAnimated:YES completion:oldBlock];
    [lastPresentedViewController release];
  };

  [[UIViewController greeLastPresentedViewController] greePresentViewController:navigationController animated:YES completion:nil];
}

-(void)greeJSModalRightButtonFailure:(NSNotification*)notification
{
  [self removeGreeJSInputObserver];

  [self unlockUI];

  NSString* errorTitle = [notification.userInfo objectForKey:kGreeJSErrorTitleKey];
  if (!errorTitle) {
    errorTitle = GreePlatformString(@"GreeJS.InputViewController.InputFailure.Alert.Title", @"An Error Occurred");
  }
  NSString* errorMessage = [notification.userInfo objectForKey:kGreeJSErrorKey];

  if ([errorMessage isEqual:[NSNull null]]) {
    // Use preset error messages if none provided by userInfo.
    if (![[GreePlatform sharedInstance].reachability isConnectedToInternet]) {
      errorMessage = GreePlatformString(@"GreeJS.InputViewController.InputFailure.NoConnection",
                                        @"Could not establish a network connection. Please make sure your network connection "
                                        @"is active and try again.");
    } else {
      errorMessage = GreePlatformString(@"GreeJS.InputViewController.InputFailure.UnknownError",
                                        @"An error occurred that prevented completion of your request. Please try again.");
    }
  }

  UIAlertView* av = [[UIAlertView alloc] initWithTitle:errorTitle
                                               message:errorMessage
                                              delegate:nil
                                     cancelButtonTitle:GreePlatformString(@"GreeJS.InputViewController.InputFailure.Alert.Confirm",
                                                          @"OK")
                                     otherButtonTitles:nil];
  [av show];
  [av release];
}

-(void)greeJSModalRightButtonSucceed:(NSNotification*)notification
{
  [self removeGreeJSInputObserver];

  [self unlockUI];
  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)greeJSDismissModalViewController:(UIButton*)sender
{
  if (sender.tag == kModalTypeInputTextViewCancel &&
      [[[self.inputViewController data] objectForKey:@"text"] length] > 0) {

    UIAlertView* av = [[UIAlertView alloc] initWithTitle:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Title", @"Cancel")
                                                 message:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Message", @"Are you sure you want to cancel?")
                                                delegate:self
                                       cancelButtonTitle:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Button.No", @"No")
                                       otherButtonTitles:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Button.Yes", @"Yes"), nil];
    [av show];
    [av release];

  } else {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  }
}

-(void)greeJSModalRightButtonPressed:(UIButton*)sender
{
  if (!self.modalRightButtonCallback) {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
    return;
  }

  [self addGreeJSInputObserver];

  [self lockUI];
  [[self presentModalViewControllable] greeJSModalSetCallback:self.modalRightButtonCallback toHandler:self.handler];
}

-(void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != 0) {
    UIViewController* lastPresentedViewController = [[UIViewController greeLastPresentedViewController] retain];
    [lastPresentedViewController greeDismissViewControllerAnimated:YES completion:nil];
    [lastPresentedViewController release];
  }
}

-(id<GreeJSModalViewControllable>)presentModalViewControllable
{
  if (self.inputViewController) {
    return self.inputViewController;
  } else {
    return self;
  }
}

-(void)lockUI
{
  id<GreeJSModalViewControllable> modalViewControllable = [self presentModalViewControllable];
  [modalViewControllable greeJSModalDisplayLoadingIndicator:YES];
  [modalViewControllable greeJSModalSetUserInteractionEnabled:NO];
}

-(void)unlockUI
{
  id<GreeJSModalViewControllable> modalViewControllable = [self presentModalViewControllable];
  [modalViewControllable greeJSModalDisplayLoadingIndicator:NO];
  [modalViewControllable greeJSModalSetUserInteractionEnabled:YES];
}

-(void)addGreeJSInputObserver
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(greeJSModalRightButtonSucceed:)
                                               name:[GreeJSInputSuccessCommand notificationName]
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(greeJSModalRightButtonFailure:)
                                               name:[GreeJSInputFailureCommand notificationName]
                                             object:nil];
}

-(void)removeGreeJSInputObserver
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputSuccessCommand notificationName] object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputFailureCommand notificationName] object:nil];
}

@end
