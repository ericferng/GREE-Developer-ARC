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


#import "GreeJSLaunchNativeAppCommand.h"
#import <MessageUI/MessageUI.h>
#import "NSURL+GreeAdditions.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeDashboardViewController.h"
#import "GreePlatform+Internal.h"
#import "NSString+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeBenchmark.h"
#import "GreeAnalyticsEvent.h"

#define kGreeJSLaunchNativeAppCommand @"callback"

@interface GreeJSLaunchNativeAppCommand ()
-(NSDictionary*)callbackDictionaryWithResult:(id)result error:(NSString*)error;
-(void)callbackWithErrorMessage:(NSString*)message params:(NSDictionary*)params;
@end

@implementation GreeJSLaunchNativeAppCommand
#pragma mark - GreeJSCommand Overrides
+(NSString*)name
{
  return @"launch_native_app";
}

-(void)execute:(NSDictionary*)params
{
  NSString* urlString = [params objectForKey:@"URL"];

  if (urlString == nil) {
    [self callbackWithErrorMessage:@"No URL Provided" params:params];
    return;
  }

  NSURL* URL = [NSURL URLWithString:urlString];

  if (URL == nil) {
    [self callbackWithErrorMessage:@"Invalid URL Provided" params:params];
    return;
  }

  if([URL isSelfGreeURLScheme]) {
    NSString* handledCommand = [URL host];
    if([handledCommand isEqualToString:@"start"]) {
      NSString* handledCommandType = nil;
      if([[URL pathComponents] count] > 1) handledCommandType = [[URL pathComponents] objectAtIndex:1];

      // Request - greeappXXXX://start/request?.id=xxx&.type=xxx&...
      // Message - greeappXXXX://start/message?.id=xxx&.type=xxx&...
      if([handledCommandType isEqualToString:@"request"] || [handledCommandType isEqualToString:@"message"]) {

        // If launched by Notification board, close & send params to app.
        UIViewController* viewController = (UIViewController*)[self.environment viewControllerForCommand:self];
        if ([viewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
          UIViewController* presentingViewController = [viewController greePresentingViewController];

          if ([presentingViewController isKindOfClass:[GreeDashboardViewController class]]) {
            [presentingViewController dismissGreeNotificationBoardAnimated:YES completion:^(id results){
               UIViewController* presentingPresentingViewController = [presentingViewController greePresentingViewController];
               [presentingPresentingViewController dismissGreeDashboardAnimated:YES completion:^(id results){
                  NSDictionary* query = [URL.query greeDictionaryFromQueryString];
                  NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [query objectForKey:@".id"], @"info-key", query, @"params", nil];
                  [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];
                }];
             }];
          } else {
            [presentingViewController dismissGreeNotificationBoardAnimated:YES completion:^(id results){
               NSDictionary* query = [URL.query greeDictionaryFromQueryString];
               NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [query objectForKey:@".id"], @"info-key", query, @"params", nil];
               [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];
             }];
          }

          return;
        }
      }
    }
  }

  if (![[UIApplication sharedApplication] canOpenURL:URL]) {
    NSString* appStoreLink = [params objectForKey:@"ios_src"];
    URL = [NSURL URLWithString:appStoreLink];

    if (URL == nil) {
      [self callbackWithErrorMessage:@"Invalid URL and applicationName Provided" params:params];
      return;
    }
    // get app id
    NSString* launchAppId = @"";
    NSURL* url = [NSURL URLWithString:appStoreLink];
    if (url) {
      NSMutableDictionary* handledParams = [[url query] greeDictionaryFromQueryString];
      launchAppId = [handledParams valueForKey:@"app_id"];
    }
    if (launchAppId == nil) {
      launchAppId = @"";
    }
    GreeAnalyticsEvent* event =[GreeAnalyticsEvent
                                eventWithType:@"evt"
                                         name:@"boot_app"
                                         from:@"universalmenu_top"
                                   parameters:[NSDictionary dictionaryWithObject:launchAppId forKey:@"app_id"]];
    [[GreePlatform sharedInstance] addAnalyticsEvent:event];


    [[UIApplication sharedApplication] openURL:URL];
    return;
  }

  if ([GreePlatform sharedInstance].benchmark) {
    UIWebView* webview = [self.environment webviewForCommand:self];
    if ([webview.request.URL.path isEqualToString:@"/um"]) {
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(kGreeBenchmarkLaunchNativeApp)];
    } else if ([self.environment isKindOfClass:[GreeNotificationBoardViewController class]]) {
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkNotificationBoard position:GreeBenchmarkPosition(kGreeBenchmarkLaunchNativeApp)];
    }
  }

  [[UIApplication sharedApplication] openURL:URL];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

#pragma mark - Internal Methods
-(NSDictionary*)callbackDictionaryWithResult:(id)result error:(NSString*)error
{
  return [NSDictionary dictionaryWithObjectsAndKeys:result, @"result", error, @"error", nil];
}

-(void)callbackWithErrorMessage:(NSString*)message params:(NSDictionary*)params
{
  NSString* callback = [params objectForKey:@"callback"];
  if ([callback length] <= 0) {
    return;
  }
  [[self.environment handler]
   callback:callback
     params:[self callbackDictionaryWithResult:[NSNumber numberWithBool:NO] error:message]];
}

@end
