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


#import "GreeJSSetPullToRefreshEnabledCommand.h"
#import "GreeJSWebViewController.h"
#import "GreeJSWebViewController+PullToRefresh.h"

@implementation GreeJSSetPullToRefreshEnabledCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"set_pull_to_refresh_enabled";
}

-(void)execute:(NSDictionary*)params
{
  //If this command is executed on non-GreeJSWebViewController, do nothing
  if(![[self.environment viewControllerForCommand:self] isKindOfClass:[GreeJSWebViewController class]]) {
    return;
  }

  GreeJSWebViewController* currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  BOOL enabled = [[params valueForKey:@"enabled"] boolValue];
  if (enabled) {
    [currentViewController setCanPullToRefresh:YES];
  } else {
    [currentViewController setCanPullToRefresh:NO];
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
