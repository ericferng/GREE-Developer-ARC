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

#import "GreeJSShowModalViewCommand.h"
#import "GreeJSWebViewController+ModalView.h"
#import "GreeJSWebViewControllerPool.h"
#import "UIImage+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreeLogger.h"
#import "UINavigationBar+GreeAdditions.h"

@implementation GreeJSShowModalViewCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_modal_view";
}

-(void)execute:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  if ([[UIViewController greeLastPresentedViewController] isKindOfClass:[GreeJSModalNavigationController class]]) {
    GreeLogWarn(@"%@ cannot execute, currentViewController is already presenting a modal view controller.", [self class]);
    return;
  }

  GreeJSWebViewController* nextViewController = [currentViewController preloadNextWebViewController];
  nextViewController.beforeWebViewController = currentViewController;

  NSString* viewName = [params valueForKey:@"view"];
  NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"record_analytics"];
  [nextViewController enableScrollsToTop];

  if ([nextViewController.handler isReady]) {
    [nextViewController.handler forceLoadView:viewName params:params options:options];
  } else {
    [nextViewController setPendingLoadRequest:viewName params:params options:options];
    if (nextViewController.deadlyProtonErrorOccured) {
      // it can be stuck on network error or something so that never get ready.
      // try reload and wish it works this time.
      [nextViewController retryToInitializeProton];
    }
  }

  GreeJSModalNavigationController* modalViewController =
    [self createModalNavigationController:nextViewController params:params];
  [currentViewController greeJSPresentModalNavigationController:modalViewController animated:YES];
}


#pragma mark - Public Interface

-(GreeJSModalNavigationController*)createNavigationController:(UIViewController*)viewController
                                                       params:(NSDictionary*)params
{
  GreeJSModalNavigationController* navigationController =
    [[[GreeJSModalNavigationController alloc] initWithRootViewController:viewController] autorelease];
  [navigationController.navigationBar greeApplyGreeAppearance];

  viewController.navigationItem.titleView = navigationController.navigationItem.titleView;
  viewController.navigationItem.title = [params valueForKey:@"title"];

  return navigationController;
}

-(GreeJSModalNavigationController*)createModalNavigationController:(UIViewController*)viewController
                                                            params:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];
  GreeJSWebViewController* nextViewController = (GreeJSWebViewController*)viewController;
  GreeJSModalNavigationController* navigationController =
    [self createNavigationController:nextViewController params:params];

  NSString* namespace = [params valueForKey:@"ns"];
  NSString* method = [params valueForKey:@"method"];
  if (namespace && method) {
    nextViewController.modalRightButtonCallback = [NSString stringWithFormat:@"%@.%@", namespace, method];
    nextViewController.modalRightButtonCallbackInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       namespace, @"namespace",
                                                       method, @"method",
                                                       nil];

    UIBarButtonItem* cancelButton =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                    target:currentViewController
                                                    action:@selector(greeJSDismissModalViewController:)];
    viewController.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    NSString* doneButtonLabel = [params valueForKey:@"button"];
    UIBarButtonItem* doneButton =
      [[UIBarButtonItem alloc] initWithTitle:doneButtonLabel ? doneButtonLabel : GreePlatformString(@"GreeJS.ShowModalViewCommand.DoneButton.Title", @"Done")
                                       style:UIBarButtonItemStyleDone
                                      target:nextViewController
                                      action:@selector(greeJSModalRightButtonPressed:)];
    doneButton.enabled = NO; // Disable button until contents ready
    doneButton.tag = kModalTypeModalView;
    viewController.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
  } else {
    viewController.navigationItem.leftBarButtonItem = nil;
    UIBarButtonItem* closeItem =
      [[UIBarButtonItem alloc] initWithTitle:GreePlatformString(@"GreeJS.ShowModalViewCommand.CloseButton.Title", @"Close")
                                       style:UIBarButtonItemStylePlain
                                      target:currentViewController
                                      action:@selector(greeJSDismissModalViewController:)];
    viewController.navigationItem.rightBarButtonItem = closeItem;
    [closeItem release];
  }

  return navigationController;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
