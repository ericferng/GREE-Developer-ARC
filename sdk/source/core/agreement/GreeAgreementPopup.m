//
// Copyright 2010-2012 GREE, inc.
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

#import "GreeAgreementPopup.h"
#import "GreeAuthorization.h"
#import "GreeAuthorization+Internal.h"
#import "GreeLogger.h"
#import "GreePlatform.h"
#import "GreeSettings.h"
#import "UIViewController+GreePlatform.h"
#import "UIViewController+GreeAdditions.h"

static BOOL currentlyShowing = NO;

@interface GreeAgreementPopup ()
+(NSString*)makeSilentKey;
+(BOOL)isSilent;

@property (nonatomic) BOOL agreed;
@end

@implementation GreeAgreementPopup

+(void)launchWithURL:(NSURL*)url
{
  if (currentlyShowing || [GreeAgreementPopup isSilent])
    return;
  currentlyShowing = YES;

  GreeAgreementPopup* popup = [GreeAgreementPopup popup];
  UIViewController* viewController = [UIViewController greeLastPresentedViewController];

  // Close previous popup
  GreePopup* currentPopup = [viewController greeCurrentPopup];
  if (currentPopup) {
    GreePopupBlock originalBlock = currentPopup.didDismissBlock;
    currentPopup.didDismissBlock =^(GreePopup* aSender) {
      originalBlock(aSender);

      [viewController showGreePopup:popup];
      [popup loadRequest:[NSURLRequest requestWithURL:url]];
    };
    [currentPopup dismiss];
  } else {
    [viewController showGreePopup:popup];
    [popup loadRequest:[NSURLRequest requestWithURL:url]];
  }
}

+(NSString*)makeSilentKey
{
  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  return [NSString stringWithFormat:@"gree.%@.agreementPopup.silent", appId];
}

+(BOOL)isSilent
{
  NSString* key = [GreeAgreementPopup makeSilentKey];
  BOOL silent = [[NSUserDefaults standardUserDefaults] boolForKey:[GreeAgreementPopup makeSilentKey]];

  GreeLog(@"[GreeAgreementPopup] %@=%@", key, [NSValue valueWithBytes:&silent objCType:@encode(BOOL)]);
  return silent;
}

+(void)makeSilent
{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[GreeAgreementPopup makeSilentKey]];
}

-(void)setup
{
  self.popupView.backButton.hidden  = YES;
  self.popupView.closeButton.hidden = YES;
  self.didDismissBlock =^(GreePopup* sender) {
    GreeAgreementPopup* thisPopup = (GreeAgreementPopup*)sender;

    currentlyShowing = NO;

    // We don't need to do anything if the user agreed
    if (thisPopup.agreed)
      return;

    [[GreeAuthorization sharedInstance] logout];
  };
}

-(BOOL)popupURLHandlerShouldRegenerateWebSession
{
  return NO;
}

-(void)popupURLHandlerReceivedSelfURLSchemeRequest:(NSURLRequest*)aRequest
{
  NSString* command = aRequest.URL.host;

  // Agree case
  if ([command isEqualToString:@"close"]) {
    self.agreed = YES;
    [self dismiss];
  }

  // Disagree case
  if ([command isEqualToString:@"logout"]) {
    self.agreed = NO;
    [self dismiss];
  }
}

-(GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle
{
  return GreePopupViewTitleSettingMethodLogoOnly;
}

@end
