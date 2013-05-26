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


#import "GreeLogger.h"

#import "GreeJSCloseCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeDashboardViewController.h"
#import "GreeJSWebViewController.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"


@interface GreeJSCloseCommand ()
-(void)closePopupWithCommandParameters:(NSDictionary*)parameters;
-(void)closeDashboardWithCommandParameters:(NSDictionary*)parameters;
-(void)closeNotificationBoardWithCommandParameters:(NSDictionary*)parameters;
@end


@implementation GreeJSCloseCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"close";
}

-(void)execute:(NSDictionary*)params
{
  UIViewController* aViewController = [self.environment viewControllerForCommand:self];

  if ([aViewController isKindOfClass:[GreePopup class]]) {
    [self closePopupWithCommandParameters:params];
  } else if ([aViewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    [self closeNotificationBoardWithCommandParameters:params];
  } else if ([aViewController isKindOfClass:[GreeDashboardViewController class]] ||
             [aViewController isKindOfClass:[GreeJSWebViewController class]]) {
    [self closeDashboardWithCommandParameters:params];
  }

  [[self.environment handler]
   callback:[params objectForKey:@"callback"]
     params:params];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}


#pragma mark - Internal Methods

-(void)closePopupWithCommandParameters:(NSDictionary*)parameters
{
  GreeLog(@"params:%@", parameters);
  GreePopup* popup = (GreePopup*)[self viewControllerWithRequiredBaseClass:[GreePopup class]];
  if ([popup.popupView.delegate respondsToSelector:@selector(popupViewDidComplete:)]) {
    [popup.popupView.delegate popupViewDidComplete:parameters];
  }
}

-(void)closeDashboardWithCommandParameters:(NSDictionary*)parameters
{
  GreeLog(@"params:%@", parameters);
  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)closeNotificationBoardWithCommandParameters:(NSDictionary*)parameters
{
  GreeLog(@"params:%@", parameters);
  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
}


@end
