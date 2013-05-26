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

#import "GreeJSWebViewController+StateCommand.h"
#import "GreeJSWebViewController+PullToRefresh.h"
#import "GreeJSInputSuccessCommand.h"
#import "GreeJSInputFailureCommand.h"
#import "GreeJSWebViewControllerPool.h"

NSString* const kGreeJSDidReady          = @"GreeJSDidReady";
NSString* const kGreeJSDidStartLoading   = @"GreeJSDidStartLoading";
NSString* const kGreeJSDidContentsReady  = @"GreeJSDidContentsReady";
NSString* const kGreeJSDidFailWithError  = @"GreeJSDidFailWithError";

@interface GreeJSWebViewController ()
@property (assign) BOOL isProton;
@property (assign) BOOL isPullLoading;
@end

@implementation GreeJSWebViewController (StateCommand)
#pragma mark - GreeJSStateCommandDelegate Methods

-(void)stateCommandReady
{
  if (self.pendingLoadRequest) {
    NSString* viewName = [self.pendingLoadRequest objectForKey:@"view"];
    NSDictionary* params = [self.pendingLoadRequest objectForKey:@"params"];
    NSDictionary* options = [self.pendingLoadRequest objectForKey:@"options"];
    [self.handler forceLoadView:viewName params:params options:options];
    [self resetPendingLoadRequest];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  NSNotification* notification = [NSNotification notificationWithName:kGreeJSDidReady object:self];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void)stateCommandStartLoading
{
  if (!self.isPullLoading) {
    [self displayLoadingIndicator:YES];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  NSNotification* notification = [NSNotification notificationWithName:kGreeJSDidStartLoading object:self];
  [[NSNotificationCenter defaultCenter] postNotification:notification];

}

-(void)stateCommandContentsReady
{
  [self stopLoading];
  [self displayLoadingIndicator:NO];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  if (self.pool) {
    GreeJSWebViewController* webViewController = [self.pool currentWebViewController];
    // iOS4 does not load URL when before addSubView. preload trick.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
      webViewController.view.frame = CGRectMake(-5000, -5000, 10, 10);
      [webViewController disableScrollsToTop];
      [self.view addSubview:webViewController.view];
    }
  }

  // Enable modal completion button
  self.navigationItem.rightBarButtonItem.enabled = YES;

  NSNotification* notification = [NSNotification notificationWithName:kGreeJSDidContentsReady object:self];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void)stateCommandFailedWithError:(NSError*)error
{
  [self stopLoading];
  [self displayLoadingIndicator:NO];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  NSNotification* notification = [NSNotification notificationWithName:kGreeJSDidFailWithError object:self userInfo:error.userInfo];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void)stateCommandInputSuccess:(NSDictionary*)params
{
  if ([params valueForKey:@"view"]) {
    NSString* viewName = [params valueForKey:@"view"];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], @"force_load_view",
                             nil];
    if (self.inputViewController) {
      [self.handler open:viewName params:params options:options];
    } else {
      [self.beforeWebViewController.handler open:viewName params:params options:options];
    }
  }

  NSNotification* notification = [NSNotification notificationWithName:[GreeJSInputSuccessCommand notificationName]
                                                               object:self
                                                             userInfo:params];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void)stateCommandInputFailure:(NSDictionary*)params
{
  NSNotification* notification = [NSNotification notificationWithName:[GreeJSInputFailureCommand notificationName]
                                                               object:self
                                                             userInfo:params];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
