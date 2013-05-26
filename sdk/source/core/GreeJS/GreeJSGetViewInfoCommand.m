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
#import "GreeJSGetViewInfoCommand.h"
#import "GreePopup.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeJSWebViewController.h"
#import "GreeDashboardViewController.h"

@implementation GreeJSGetViewInfoCommand

#pragma mark - GreeJSGetViewInfoCommand Overrides

+(NSString*)name
{
  return @"get_view_info";
}

-(void)execute:(NSDictionary*)params
{
  NSString* viewControllerName = nil;
  UIViewController* aViewController = [self.environment viewControllerForCommand:self];

  if ([aViewController isKindOfClass:[GreePopup class]]) {
    viewControllerName = @"popup";
  } else if ([aViewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    viewControllerName = @"notificationboard";
  } else if ([aViewController isKindOfClass:[GreeJSWebViewController class]] ||
             [aViewController isKindOfClass:[GreeDashboardViewController class]]) {
    viewControllerName = @"dashboard";
  } else {
    viewControllerName = @"viewcontroller";
  }

  NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:params];
  [results setObject:viewControllerName forKey:@"view"];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:results forKey:@"result"];
  [[self.environment handler]
   callback:[params objectForKey:@"callback"]
     params:callbackParameters];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
