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
#import "GreeJSShowRequestDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"

#define kGreeJSShowRequestDialogCommandCallbackFunction @"callback"

@interface GreeJSShowRequestDialogCommand ()
-(void)callbackWithParameters:(NSDictionary*)params results:(NSDictionary*)results;
@end


@implementation GreeJSShowRequestDialogCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_request_dialog";
}

-(void)execute:(NSDictionary*)params
{
  if (![[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    [self callbackWithParameters:params results:nil];
    return;
  }

  __block GreeJSShowRequestDialogCommand* command = self;
  UIViewController* viewController = [self viewControllerWithRequiredBaseClass:nil];
  if ( [[viewController greeCurrentPopup] isKindOfClass:[GreeRequestServicePopup class]] ) {
    [self callbackWithParameters:params results:nil];
    return;
  }
  
  NSDictionary* request = [params objectForKey:@"request"];

  GreeRequestServicePopup* popup = [GreeRequestServicePopup popupWithParameters:request];

  NSDictionary* incentivePayload = [request objectForKey:@"incentive_payload"];
  if (incentivePayload != nil) {
    GreeIncentive* incentive = [[[GreeIncentive alloc] initWithType:GreeIncentiveTypeRequest payloadDictionary:incentivePayload] autorelease];
    popup.incentivePayload = incentive;
  }


  popup.didDismissBlock =^(GreePopup* sender) {
    GreeRequestServicePopup* popup = (GreeRequestServicePopup*)sender;
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
   callback:[params objectForKey:kGreeJSShowRequestDialogCommandCallbackFunction]
     params:callbackParameters];
  [self callback];
}

@end
