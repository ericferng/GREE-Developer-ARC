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


#import "GreePlatform.h"
#import "GreeJSShowWebViewDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreePlatform.h"
#import "GreeNetworkReachability.h"

#define kGreeJSShowPopupDialogCommandCallbackFunction @"callback"

@implementation GreeJSShowWebViewDialogCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_webview_dialog";
}

-(void)execute:(NSDictionary*)params
{
  if (![[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];

    NSDictionary* callbackParamters = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithBool:NO], @"result",
                                       nil];
    [[self.environment handler]
     callback:[params objectForKey:kGreeJSShowPopupDialogCommandCallbackFunction]
       params:callbackParamters];
    [self callback];
    return;
  }

  __block GreeJSShowWebViewDialogCommand* command = self;

  UIViewController* viewController = [self viewControllerWithRequiredBaseClass:nil];
  GreePopup* popup = [GreePopup popupWithParameters:params];

  popup.didDismissBlock =^(GreePopup* sender){
    NSDictionary* callbackParameters = nil;
    NSNumber* result = (sender == nil) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];

    if (!sender) {
      callbackParameters = [NSDictionary dictionaryWithObject:result forKey:@"result"];
    } else {
      if (!sender.results) {
        callbackParameters = [NSDictionary dictionaryWithObject:result forKey:@"result"];
      } else {
        callbackParameters = [NSDictionary dictionaryWithObjectsAndKeys:result, @"result", sender.results, @"data", nil];
      }
    }

    [[command.environment handler]
     callback:[params objectForKey:kGreeJSShowPopupDialogCommandCallbackFunction]
       params:callbackParameters];
    [command callback];
  };

  NSString* URLString = [params objectForKey:@"URL"];

  if (URLString == nil) {
    popup.didDismissBlock(nil);
    return;
  }

  NSURL* URL = [NSURL URLWithString:URLString];

  if (URL == nil) {
    popup.didDismissBlock(nil);
    return;
  }

  NSURLRequest* request = [NSURLRequest requestWithURL:URL];
  [popup loadRequest:request];
  [viewController showGreePopup:popup];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]),
          self];
}

@end
