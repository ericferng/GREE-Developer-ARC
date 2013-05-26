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
#import "GreeJSShowInviteDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeIncentive.h"

#define kGreeJSShowInviteDialogCommandCallbackFunction @"callback"

@interface GreeJSShowInviteDialogCommand ()
-(void)callbackWithParameters:(NSDictionary*)params results:(NSDictionary*)results;
@end


@implementation GreeJSShowInviteDialogCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_invite_dialog";
}

-(void)execute:(NSDictionary*)params
{
  if (![[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    [self callbackWithParameters:params results:nil];
    return;
  }

  __block GreeJSShowInviteDialogCommand* command = self;
  UIViewController* viewController = [self viewControllerWithRequiredBaseClass:nil];
  if ( [[viewController greeCurrentPopup] isKindOfClass:[GreeInvitePopup class]] ) {
    [self callbackWithParameters:params results:nil];
    return;
 }
  NSDictionary* invite = [params objectForKey:@"invite"];

  GreeInvitePopup* popup = [GreeInvitePopup popupWithParameters:invite];

  NSString* message = [invite objectForKey:@"body"];

  if (message != nil) {
    popup.message = message;
  }

  NSString* callbackurl = [invite objectForKey:@"callbackurl"];
  if (callbackurl != nil) {
    popup.callbackURL = [NSURL URLWithString:callbackurl];
  }

  NSArray* toUserIds = [invite objectForKey:@"to_user_id"];
  if (toUserIds != nil) {
    popup.toUserIds = toUserIds;
  }

  NSDictionary* incentivePayload = [invite objectForKey:@"incentive_payload"];
  if (incentivePayload != nil) {
    GreeIncentive* incentive = [[[GreeIncentive alloc] initWithType:GreeIncentiveTypeInvite payloadDictionary:incentivePayload] autorelease];
    popup.incentivePayload = incentive;
  }

  popup.didDismissBlock =^(GreePopup* sender){
    GreeInvitePopup* popup = (GreeInvitePopup*)sender;
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
   callback:[params objectForKey:kGreeJSShowInviteDialogCommandCallbackFunction]
     params:callbackParameters];
  [self callback];
}

@end
