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


#import "GreeJSPushViewWithUrlCommand.h"
#import "UIImage+GreeAdditions.h"
#import "UINavigationItem+GreeAdditions.h"
#import "GreePlatform.h"
#import "GreeNetworkReachability.h"

@implementation GreeJSPushViewWithUrlCommand

+(NSString*)name
{
  return @"push_view_with_url";
}

-(void)execute:(NSDictionary*)params
{
  if (![GreePlatform sharedInstance].reachability.isConnectedToInternet) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    return;
  }

  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  // This command doesn't preload next webview(always create new instance)
  // Because, WebView can't preloading contents by URL based push view.
  GreeJSWebViewController* nextViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  nextViewController.beforeWebViewController = currentViewController;
  nextViewController.pool = currentViewController.pool;
  nextViewController.preloadInitializeBlock = currentViewController.preloadInitializeBlock;

  NSURL* url = [NSURL URLWithString:[params objectForKey:@"url"]];
  [nextViewController.webView loadRequest:[NSURLRequest requestWithURL:url]];

  nextViewController.navigationItem.leftBarButtonItem = nil;
  [nextViewController.navigationItem setSameRightBarButtonItems:currentViewController.navigationItem];

  [nextViewController enableScrollsToTop];

  [currentViewController setBackButtonForNavigationItem:nextViewController.navigationItem];
  [currentViewController.navigationController pushViewController:nextViewController animated:YES];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
