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

#import "GreeJSBroadcastCommand.h"
#import "GreeJSWebViewController.h"
#import "GreeDashboardViewController.h"

@implementation GreeJSBroadcastCommand;


#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"broadcast";
}

-(void)broadcast:(NSDictionary*)params toAllAscendingViewControllers:(GreeJSWebViewController*)controller
{
  while (controller) {
    [GreeJSWebViewMessageEvent fireMessageEventName:@"ProtonBroadcast" userInfo:params inWebView:controller.webView];
    controller = controller.beforeWebViewController;
  }
}

-(void)execute:(NSDictionary*)params
{
  GreeJSWebViewController* controller = (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];
  [self broadcast:params toAllAscendingViewControllers:controller];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}
@end
