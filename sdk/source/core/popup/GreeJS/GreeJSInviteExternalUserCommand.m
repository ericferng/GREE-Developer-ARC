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


#import "GreePopup.h"
#import "GreeJSInviteExternalUserCommand.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeBenchmark.h"
#import "GreePlatform+Internal.h"

@interface GreeJSInviteExternalUserCommand ()
@end

@implementation GreeJSInviteExternalUserCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"invite_external_user";
}

-(void)execute:(NSDictionary*)params
{
  if ([self.environment isKindOfClass:[GreeInvitePopup class]]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkInvite position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];
  } else if ([self.environment isKindOfClass:[GreeRequestServicePopup class]]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkRequest position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];
  }

  GreePopup* popup = (GreePopup*)[self viewControllerWithRequiredBaseClass:[GreePopup class]];
  GreePopupBlock originalDismissBlock = popup.didDismissBlock;

  UIViewController* popupHostViewController = popup.hostViewController;
  NSURL* URL = [NSURL URLWithString:[params objectForKey:@"URL"]];

  popup.didDismissBlock =^(GreePopup* sender){
    if (originalDismissBlock) {
      originalDismissBlock(sender);
    }

    [popupHostViewController presentGreeDashboardWithBaseURL:URL delegate:popupHostViewController animated:YES completion:nil];
  };

  [popupHostViewController dismissGreePopup];
  [self callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>", NSStringFromClass([self class]), self, self.environment];
}

@end
