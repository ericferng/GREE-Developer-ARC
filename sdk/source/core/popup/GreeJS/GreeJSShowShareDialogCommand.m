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
#import "GreeNetworkReachability.h"
#import "GreeJSShowShareDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreeAdditions.h"  
#import "UIViewController+GreePlatform.h"
#import "JSONKit.h"

#define kGreeJSShowShareDialogCommandCallbackFunction @"callback"

@interface GreeJSShowShareDialogCommand ()
-(void)callbackWithParameters:(NSDictionary*)params results:(NSDictionary*)results;
@end


@implementation GreeJSShowShareDialogCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_share_dialog";
}

-(void)execute:(NSDictionary*)params
{
  if (![[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    [self callbackWithParameters:params results:nil];
    return;
  }

  __block GreeJSShowShareDialogCommand* command = self;
  UIViewController* viewController = [self viewControllerWithRequiredBaseClass:nil];
  if ( [[viewController greeCurrentPopup] isKindOfClass:[GreeSharePopup class]] ) {
    [self callbackWithParameters:params results:nil];
    return;
  }
  
  GreeSharePopup* popup = [GreeSharePopup popupWithParameters:params];

  NSString* popupType = [params objectForKey:@"type"];

  if ([popupType isEqualToString:@"noclose"]) {
    popup.popupView.closeButton.hidden = YES;
  }

  NSString* text = [params objectForKey:@"message"];

  if (text != nil) {
    popup.text = text;
  }

  id imageUrls = [params objectForKey:@"image_urls"];

  if (imageUrls) {
    if ([imageUrls isKindOfClass:[NSString class]]) {
      popup.imageUrls = imageUrls;
    } else if ([imageUrls isKindOfClass:[NSDictionary class]]) {
      NSString* encodedStr = [imageUrls greeJSONString];
      if (encodedStr) {
        NSMutableDictionary* fixedParams = [params mutableCopy];
        [fixedParams setObject:encodedStr forKey:@"image_urls"];
        popup.parameters = fixedParams;
        [fixedParams release];
        params = fixedParams;
      }
    }
  }

  popup.didDismissBlock =^(GreePopup* popup){
    [command callbackWithParameters:params results:popup.results];
  };

  [viewController showGreePopup:popup];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]),
          self];
}

#pragma mark - internal methods

-(void)callbackWithParameters:(NSDictionary*)params results:(NSDictionary*)results
{
  NSMutableDictionary* callbackParameters = [NSMutableDictionary dictionary];
  [callbackParameters setObject:@"close" forKey:@"result"];

  if (results != nil) {
    [callbackParameters setObject:results forKey:@"param"];
  }

  [[self.environment handler]
   callback:[params objectForKey:kGreeJSShowShareDialogCommandCallbackFunction]
     params:callbackParameters];

  [self callback];
}

@end
