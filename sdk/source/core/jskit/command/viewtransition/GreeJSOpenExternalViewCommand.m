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


#import "GreeJSOpenExternalViewCommand.h"
#import "GreeJSExternalWebViewController.h"

@implementation GreeJSOpenExternalViewCommand


#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"open_external_view";
}

-(void)execute:(NSDictionary*)params
{
  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  NSMutableDictionary* parameters = [[params mutableCopy] autorelease];
  NSURL* url = [NSURL URLWithString:[parameters valueForKey:@"url"]];

  GreeJSExternalWebViewController* externalWebViewController = [[[GreeJSExternalWebViewController alloc] initWithURL:url] autorelease];

  [currentViewController setBackButtonForNavigationItem:externalWebViewController.navigationItem];
  [currentViewController.navigationController pushViewController:externalWebViewController
                                                        animated:YES];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
