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

#import "GreeJSLoadURLCommand.h"
#import "GreeJSWebViewController.h"
#import "GreePopup.h"

@implementation GreeJSLoadURLCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"load_url";
}

-(void)execute:(NSDictionary*)params
{
  BOOL requested = NO;
  NSURL* url = [NSURL URLWithString:[params objectForKey:@"url"]];
  if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
    requested = YES;
    UIWebView* webView = [self.environment webviewForCommand:self];
    NSString* currentUrl = [webView stringByEvaluatingJavaScriptFromString:@"document.URL"];
    UIViewController* selfViewController = [self.environment viewControllerForCommand:self];
    if ([selfViewController isKindOfClass:[GreePopup class]] &&
        [currentUrl rangeOfString:@"about://error/" options:NSCaseInsensitiveSearch].location != NSNotFound) {
      [webView reload];
    } else {
      [webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
  }
  self.result = [NSNumber numberWithBool:requested];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
