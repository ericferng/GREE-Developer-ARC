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
#import "GreePhoneNumberBasedSignUpView.h"
#import "GreePhoneNumberBasedPincodeView.h"
#import "GreeAuthorization.h"
#import "GreePlatform+Internal.h"
#import "GreePhoneNumberBasedController.h"
#import "GreeSettings.h"

@interface GreePhoneNumberBasedSignUpView ()
-(IBAction)submitSignUp:(id)sender;
-(IBAction)touchTermsLink:(id)sender;
@end

@implementation GreePhoneNumberBasedSignUpView


#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.submitButton = nil;
  self.terms1Label = nil;
  self.termsLinkLabel = nil;
  self.termsLinkButton = nil;

  [super dealloc];
}

-(id)initWithUserInfo:(GreePhoneNumberBasedUserInfo*)userInfo
{
  self = [super initWithUserInfo:userInfo];
  if (self) {
    self.countryIndex     = [NSIndexPath indexPathForRow:0 inSection:0];
    self.thisPageCellInformation = @{self.countryIndex : [self.cellInformation objectForKey:kGreeCountryCodeKey]};
  }
  return self;
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.signUp.title")];
  self.noticeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.signUp.notice");
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height];

  self.terms1Label.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.signUp.terms1");
  [self.termsLinkButton setTitle:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.signUp.terms2") forState:UIControlStateNormal];

  [GreePhoneNumberBasedPage decorateBlueButton:self.submitButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.signUp.submitButton")];

  self.countryCell = [self.tableView cellForRowAtIndexPath:self.countryIndex];

  self.navigationController.navigationBarHidden = NO;

  [self selectDefaultCountry];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  self.countryCell.textLabel.text     =  [self countryLabelText];
  if (self.userInfo.countryName.length > 0) {
    self.countryCell.textLabel.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormInput];
  }

  [self.tableView reloadData];
}

#pragma mark - Internal Methods

-(IBAction)submitSignUp:(id)sender
{
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]]) {
    return;
  }

  [self showLoadingView];
  [[GreePlatform sharedInstance].authorization registerBySMSWithPhoneNumber:self.userInfo.phoneNumber
                                                                countryCode:self.userInfo.countryCode
                                                                      block:^(NSError* anError){
     if (anError) {
       [self handleError:anError];
       return;
     }
     [self doAfterSubmit];
     GreePhoneNumberBasedPincodeView* pin = [[[GreePhoneNumberBasedPincodeView alloc] initWithUserInfo:self.userInfo] autorelease];
     [self.navigationController pushViewController:pin animated:YES];
   }];
}

-(IBAction)touchTermsLink:(id)sender
{
  [[UIApplication sharedApplication] openURL:
   [NSURL URLWithString:
    [NSString stringWithFormat:@"http://id.gree.net/?action=misc_tos_generic&page=terms&app_id=%@",
      [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId]]]];
}

#pragma mark - override

-(void)didChangeFieldValue:(id)sender
{
  self.userInfo.nickname    = self.nicknameTextField.text;
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  BOOL validateResult = [self validateWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]] ? NO : YES;
  [GreePhoneNumberBasedPage switchButton:self.submitButton enable:validateResult];
}

@end
