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
#import "GreePlatform.h"
#import "GreeDashboardViewController.h"
#import "GreeJSWebViewController.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeJSShowDashboardFromNotificationBoardCommand.h"
#import "GreeJSExternalWebViewController.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"

@interface GreeJSShowDashboardFromNotificationBoardCommand ()
@end


@implementation GreeJSShowDashboardFromNotificationBoardCommand
#pragma mark - Object lifecycle

+(NSString*)name
{
  return @"show_dashboard_from_notification_board";
}

-(void)execute:(NSDictionary*)params
{
  NSURL* URL = [NSURL URLWithString:[params objectForKey:@"url"]];

  GreeNotificationBoardViewController* notificationViewController = (GreeNotificationBoardViewController*)
                                                                    [self viewControllerWithRequiredBaseClass:[GreeNotificationBoardViewController class]];

  UIViewController* presentingViewController = [notificationViewController greePresentingViewController];

  [notificationViewController presentGreeDashboardWithBaseURL:URL delegate:presentingViewController animated:YES completion:nil];

  [self callback];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
