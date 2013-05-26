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

#import "GreeJSShowInputViewCommand.h"
#import "GreeJSInputViewController.h"
#import "GreeJSFormViewController.h"
#import "GreeJSWebViewController+ModalView.h"
#import "GreePlatform+Internal.h"
#import "GreeGlobalization.h"
#import "GreeLogger.h"
#import "UIViewController+GreeAdditions.h"

@interface GreeJSShowInputViewCommand ()
-(void)showModalView:(id)sender;
@end

@implementation GreeJSShowInputViewCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_input_view";
}

-(void)execute:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  if ([[UIViewController greeLastPresentedViewController] isKindOfClass:[GreeJSModalNavigationController class]]) {
    GreeLogWarn(@"%@ cannot execute, currentViewController is already presenting a modal view controller.", [self class]);
    return;
  }

  NSString* type = [params valueForKey:@"type"];
  if ([type isEqualToString:@"form"]) {
    currentViewController.inputViewController =
      [[[GreeJSFormViewController alloc] initWithParams:params] autorelease];
  } else {
    currentViewController.inputViewController =
      [[[GreeJSInputViewController alloc] initWithParams:params] autorelease];
  }

  GreeJSModalNavigationController* modalNavigationController =
    [self createModalNavigationController:currentViewController.inputViewController params:params];
  currentViewController.inputViewController.beforeViewController = currentViewController;
  currentViewController.modalRightButtonCallback = [params valueForKey:@"callback"];

  [self showModalView:modalNavigationController];
}

#pragma mark - GreeJSShowModalViewCommand Overrides

-(UINavigationController*)createModalNavigationController:(UIViewController*)viewController
                                                   params:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  UINavigationController* navigationController =
    [self createNavigationController:viewController params:params];
  viewController.navigationItem.leftBarButtonItem = nil;


  UIBarButtonItem* cancelButton =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:currentViewController
                                                  action:@selector(greeJSDismissModalViewController:)];
  cancelButton.tag = kModalTypeInputTextViewCancel;
  viewController.navigationItem.leftBarButtonItem = cancelButton;
  [cancelButton release];

  NSString* doneButtonLabel = [params valueForKey:@"button"];
  NSString* title =
    doneButtonLabel ? doneButtonLabel : GreePlatformString(@"GreeJS.ShowInputViewCommand.DoneButton.Title", @"Done");
  UIBarButtonItem* doneButton =
    [[UIBarButtonItem alloc] initWithTitle:title
                                     style:UIBarButtonItemStyleDone
                                    target:currentViewController
                                    action:@selector(greeJSModalRightButtonPressed:)];
  doneButton.tag = kModalTypeInputTextView;
  viewController.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];

  return navigationController;
}

#pragma mark - Internal Methods

-(void)showModalView:(id)sender
{
  GreeJSModalNavigationController* modalViewController = (GreeJSModalNavigationController*)sender;
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  [currentViewController greeJSPresentModalNavigationController:modalViewController animated:YES];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
