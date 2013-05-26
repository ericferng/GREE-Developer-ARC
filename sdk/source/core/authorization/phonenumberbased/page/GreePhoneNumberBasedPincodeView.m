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

#import "GreeGlobalization.h"
#import "GreePhoneNumberBasedPincodeView.h"
#import "GreePhoneNumberBasedController.h"
#import "GreeAuthorization.h"
#import "GreePlatform+Internal.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeNSNotification.h"

static int const kGreePincodeTextFieldTag = 101;

@interface GreePhoneNumberBasedPincodeView ()
@property (nonatomic, retain) NSIndexPath* pincodeIndex;
-(IBAction)submitPinNumber:(id)sender;
-(IBAction)submitResendPin:(id)sender;
-(IBAction)submitIVR:(id)sender;
@end

@implementation GreePhoneNumberBasedPincodeView


#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.submitButton = nil;
  self.resendButton = nil;
  self.pincodeIndex = nil;
  self.callButton = nil;

  [super dealloc];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.title")];
  self.noticeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.notice");
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height];

  [GreePhoneNumberBasedPage decorateBlueButton:self.submitButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.button.verify")];
  [GreePhoneNumberBasedPage decorateWhiteButton:self.resendButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.button.resendPincode") fontSize:14];
  [GreePhoneNumberBasedPage decorateWhiteButton:self.callButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.button.callVerification") fontSize:14];
  self.pincodeTextField.tag = kGreePincodeTextFieldTag;
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.phoneNumberTextField.text = self.userInfo.phoneNumber;
}

#pragma mark - Internal Methods

-(IBAction)submitPinNumber:(id)sender
{
  self.userInfo.pincode = self.pincodeTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreePincodeKey]]) {
    return;
  }

  [self showLoadingView];

  if ([GreePhoneNumberBasedController sharedInstance].isNewRegistration) {
    [[GreePlatform sharedInstance].authorization confirmRegisterWithPincode:self.userInfo.pincode
                                                                phoneNumber:self.userInfo.phoneNumber
                                                                countryCode:self.userInfo.countryCode
                                                                      block:^(NSError* anError) {
       if (anError) {
         [self handleError:anError];
         return;
       }
       [GreePhoneNumberBasedController sharedInstance].userInfo.hasPhoneNumber = YES;
       [self doAfterSubmit];
       [[GreePhoneNumberBasedController sharedInstance] invokePincodeVerifiedBlockWithError:nil];

     }];
  } else {
    [[GreePlatform sharedInstance].authorization confirmUpgradeWithPincode:self.userInfo.pincode
                                                               phoneNumber:self.userInfo.phoneNumber
                                                               countryCode:self.userInfo.countryCode
                                                                     block:^(NSError* anError) {
       if (anError) {
         [self handleError:anError];
         return;
       }

       [GreePhoneNumberBasedController sharedInstance].userInfo.hasPhoneNumber = YES;
       [self doAfterSubmit];
       __block id observer;
       observer = [[NSNotificationCenter defaultCenter]
                   addObserverForName:GreeNSNotificationKeyDidUpdateLocalUserNotification
                               object:nil
                                queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification* note) {
                     [[NSNotificationCenter defaultCenter] removeObserver:observer];
                     [self greeDismissViewControllerAnimated:YES completion:nil];
                     [[GreePhoneNumberBasedController sharedInstance] invokePincodeVerifiedBlockWithError:nil];
                   }];
     }];
  }
}

-(IBAction)submitResendPin:(id)sender
{
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]]) {
    return;
  }

  [self showLoadingView];

  void (^block)(NSError*) =^(NSError* anError){
    if (anError) {
      [self handleError:anError];
      return;
    }
    [self showAlert:@"" title:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.alert.sms")];
    [self doAfterSubmit];
  };

  if ([GreePhoneNumberBasedController sharedInstance].isNewRegistration) {
    [[GreePlatform sharedInstance].authorization registerBySMSWithPhoneNumber:self.userInfo.phoneNumber
                                                                  countryCode:self.userInfo.countryCode block:block];
  } else {
    [[GreePlatform sharedInstance].authorization upgradeBySMSWithPhoneNumber:self.userInfo.phoneNumber
                                                                 countryCode:self.userInfo.countryCode block:block];
  }
}

-(IBAction)submitIVR:(id)sender
{
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]]) {
    return;
  }

  [self showLoadingView];

  void (^block)(NSError*) =^(NSError* anError){
    if (anError) {
      [self handleError:anError];
      return;
    }
    [self showAlert:@"" title:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.pincode.alert.ivr")];
    [self doAfterSubmit];
  };

  if ([GreePhoneNumberBasedController sharedInstance].isNewRegistration) {
    [[GreePlatform sharedInstance].authorization registerByIVRWithPhoneNumber:self.userInfo.phoneNumber
                                                                  countryCode:self.userInfo.countryCode block:block];
  } else {
    [[GreePlatform sharedInstance].authorization upgradeByIVRWithPhoneNumber:self.userInfo.phoneNumber
                                                                 countryCode:self.userInfo.countryCode block:block];
  }
}

#pragma mark - override

-(void)didChangeFieldValue:(id)sender
{
  BOOL validateResult;

  UITextField* target = ((NSNotification*)sender).object;

  if (target.tag) {
    self.userInfo.pincode = self.pincodeTextField.text;
    validateResult = [self validateWithTargets:@[kGreePincodeKey]] ? NO : YES;
    [GreePhoneNumberBasedPage switchButton:self.submitButton enable:validateResult];

  } else {
    NSString* tmpForValidation = self.userInfo.phoneNumber;
    self.userInfo.phoneNumber = self.phoneNumberTextField.text;
    validateResult = [self validateWithTargets:@[kGreePhoneNumberKey]] ? NO : YES;
    [GreePhoneNumberBasedPage switchButton:self.resendButton enable:validateResult];
    [GreePhoneNumberBasedPage switchButton:self.callButton enable:validateResult];
    self.userInfo.phoneNumber = tmpForValidation;
  }
}

@end
