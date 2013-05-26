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


#import "GreeJSOpenFromMenuCommand.h"
#import "GreeMenuNavController.h"
#import "GreeJSWebViewController+SubNavigation.h"
#import "GreePlatform+Internal.h"
#import "GreeBenchmark.h"
#import "GreeNetworkReachability.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeJSWebViewController.h"
#import "GreeAnalyticsEvent.h"

static NSString* const kGreeJSStyleColorLoading = @"#e4e5e6";
static NSString* const kGreeJSScririptOverrideBackgroundStyle = @"document.body.style.background='%@';";

@implementation GreeJSOpenFromMenuCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"open_from_menu";
}

-(void)execute:(NSDictionary*)params
{
  if (![GreePlatform sharedInstance].reachability.isConnectedToInternet) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    return;
  }

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(@"selectUMItem")];

  NSURL* url = [NSURL URLWithString:[params valueForKey:@"url"]];

  GreeMenuNavController* menuNavController = (GreeMenuNavController*)[UIViewController greeLastPresentedViewController];
  if (menuNavController.rootViewController.viewControllers.count > 1) {
    [menuNavController.rootViewController popToRootViewControllerAnimated:NO];
  }
  GreeJSWebViewController* webViewController = (GreeJSWebViewController*)
                                               [(UINavigationController*)menuNavController.rootViewController topViewController];

  if ([webViewController respondsToSelector:@selector(displayLoadingIndicator:)]) {
    [webViewController displayLoadingIndicator:YES];
  }

  [webViewController resetWebViewContents:url];

  // To avoid flash screen, override old page background
  // until new page style is loaded.'
  NSString* evalString = [NSString stringWithFormat:kGreeJSScririptOverrideBackgroundStyle, kGreeJSStyleColorLoading];
  [webViewController.webView stringByEvaluatingJavaScriptFromString:evalString];

  [webViewController configureSubnavigationMenuWithParams:nil];

  [webViewController.webView loadRequest:[NSURLRequest requestWithURL:url]];

  GreeAnalyticsEvent* event = [GreeAnalyticsEvent
                               eventWithType:@"pg"
                                        name:[[GreeJSWebViewController class] viewNameFromURL:url]
                                        from:@"universalmenu_top"
                                  parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  //For iPad, the menuController should always open
  if (![GreePlatform shouldPersistUniversalMenuForIPad]) {
    [menuNavController setIsRevealed:NO];
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
