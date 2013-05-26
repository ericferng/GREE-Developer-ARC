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


#import "GreeJSPopViewCommand.h"

#import "GreePlatform+Internal.h"
#import "GreeBenchmark.h"

@implementation GreeJSPopViewCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"pop_view";
}

-(void)execute:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];
  GreeJSWebViewController* nextTopController = currentViewController.beforeWebViewController;

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(@"startPopView")];

  NSString* countString = [params objectForKey:@"count"];
  if (countString) {
    int count = [countString intValue];
    if (count < 0) {
      count = INT_MAX;
    }
    count--;
    while (nextTopController.beforeWebViewController != nil) {
      if (count <= 0) {
        break;
      }
      nextTopController = nextTopController.beforeWebViewController;
    }
  }
  [currentViewController.navigationController popToViewController:nextTopController animated:YES];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
