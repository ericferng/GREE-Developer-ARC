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
#import "GreePhoneNumberBasedUpgradeView.h"
#import "GreePhoneNumberBasedPincodeView.h"
#import "GreeAuthorization.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreePhoneNumberBasedController.h"


@interface GreePhoneNumberBasedUpgradeView ()
-(IBAction)submitSignUp:(id)sender;
@end

@implementation GreePhoneNumberBasedUpgradeView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.submitButton = nil;
  self.birthdayCellField = nil;
  self.profileContainer = nil;
  self.registerContainer = nil;
  self.noticeLabelNickname = nil;
  self.noticeContainer = nil;

  [super dealloc];
}

-(id)initWithUserInfo:(GreePhoneNumberBasedUserInfo*)userInfo
{
  self = [super initWithUserInfo:userInfo];
  if (self) {
    self.countryIndex     = [NSIndexPath indexPathForRow:0 inSection:0];
    self.thisPageCellInformation = @{self.countryIndex : [self.cellInformation objectForKey:kGreeCountryCodeKey]};

    if (self.userInfo.nickname.length > 0) {
      [self.filledCells addObject:kGreeNicknameKey];
    }
    if (self.userInfo.birthday.length > 0) {
      [self.filledCells addObject:kGreeBirthdayKey];
    }
    if (self.userInfo.phoneNumber.length > 0) {
      [self.filledCells addObject:kGreePhoneNumberKey];
    }
    if (self.userInfo.countryCode.length > 0) {
      [self.filledCells addObject:kGreeCountryCodeKey];
    } else {
      [self selectDefaultCountry];
    }
  }
  return self;
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.upgrade.title")];
  self.noticeLabel.text  = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.upgrade.notice");
  self.noticeLabel2.text  = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.upgrade.notice2");
  self.noticeLabelNickname.text  = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.upgrade.noticeUpgrade");
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel2 font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabelNickname font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];

  [GreePhoneNumberBasedPage decorateBlueButton:self.submitButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.upgrade.submitButton")];
  self.navigationItem.leftBarButtonItem = nil;

  self.countryCell     = [self.tableView cellForRowAtIndexPath:self.countryIndex];

  [self attachKeyImageWithLabel:self.phoneNumberLabel];
  [self attachKeyImageWithLabel:self.birthdayLabel];
  [self attachKeyImageWithLabel:self.countryLabel];
  [self attachKeyImageWithLabel2:self.noticeLabel2];

  if ([self shouldShowProfileContainer]) {
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 650);
    [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height + self.noticeLabel2.frame.size.height + self.noticeLabelNickname.frame.size.height];
  } else {
    self.registerContainer.frame = CGRectMake(0, self.profileContainer.frame.origin.y, self.registerContainer.frame.size.width, self.registerContainer.frame.size.height);
    self.noticeContainer.frame = CGRectMake(0, self.noticeContainer.frame.origin.y - self.profileContainer.frame.size.height, self.noticeContainer.frame.size.width, self.noticeContainer.frame.size.height);
    [self.profileContainer removeFromSuperview];

    self.noticeLabel2.frame      = CGRectMake(self.noticeLabel2.frame.origin.x, self.noticeLabelNickname.frame.origin.y, self.noticeLabel2.frame.size.width, self.noticeLabel2.frame.size.height);
    [self.noticeLabelNickname removeFromSuperview];
    [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height + self.noticeLabel2.frame.size.height];
  }
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (self.userInfo.nickname.length > 0) {
    self.nicknameTextField.text    = self.userInfo.nickname;
  }
  if (self.userInfo.birthday.length > 0) {
    self.birthdayField.text    = [self.userInfo.birthday stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
  }
  self.countryCell.textLabel.text     =  [self countryLabelText];
  if (self.userInfo.countryName.length > 0) {
    self.countryCell.textLabel.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormInput];
  }
  [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
  self.userInfo.nickname    = self.nicknameTextField.text;
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;
  [super viewWillDisappear:animated];
}

#pragma mark - Internal Methods

-(BOOL)shouldShowProfileContainer
{
  GreePhoneNumberBasedUserInfo* userInfo = [GreePhoneNumberBasedController sharedInstance].userInfo;
  return !userInfo.hasBirthday || !userInfo.hasNickname;
}

-(IBAction)submitSignUp:(id)sender
{
  self.userInfo.nickname    = self.nicknameTextField.text;
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]]) {
    return;
  }

  [self showLoadingView];

  if ([self shouldShowProfileContainer]) {
    [self submitWithProfile];
  } else {
    [self submitWithoutProfile];
  }
}

-(void)submitWithProfile
{
  __block GreePhoneNumberBasedUpgradeView* mySelf = self;
  [[GreePlatform sharedInstance].authorization updateUserProfileWithNickname:self.userInfo.nickname
                                                                    birthday:self.userInfo.birthdayDate
                                                                       block:^(NSError* anError) {
     if (anError) {
       [mySelf handleError:anError];
       return;
     }
     [GreePhoneNumberBasedController sharedInstance].userInfo.hasBirthday = YES;
     [GreePhoneNumberBasedController sharedInstance].userInfo.hasNickname = YES;

     [[GreePlatform sharedInstance].authorization upgradeBySMSWithPhoneNumber:mySelf.userInfo.phoneNumber
                                                                  countryCode:mySelf.userInfo.countryCode
                                                                        block:^(NSError* error){
        if (error) {
          [mySelf handleError:error];
          return;
        }
        [mySelf doAfterSubmit];
        GreePhoneNumberBasedPincodeView* pin = [[[GreePhoneNumberBasedPincodeView alloc] initWithUserInfo:mySelf.userInfo] autorelease];
        [mySelf.navigationController pushViewController:pin animated:YES];
      }];
   }];
}

-(void)submitWithoutProfile
{
  __block GreePhoneNumberBasedUpgradeView* mySelf = self;
  [[GreePlatform sharedInstance].authorization upgradeBySMSWithPhoneNumber:mySelf.userInfo.phoneNumber
                                                               countryCode:mySelf.userInfo.countryCode
                                                                     block:^(NSError* anError){
     if (anError) {
       [mySelf handleError:anError];
       return;
     }
     [mySelf doAfterSubmit];
     GreePhoneNumberBasedPincodeView* pin = [[[GreePhoneNumberBasedPincodeView alloc] initWithUserInfo:mySelf.userInfo] autorelease];
     [mySelf.navigationController pushViewController:pin animated:YES];
   }];
}

#pragma mark - override

-(void)didChangeFieldValue:(id)sender
{
  self.userInfo.nickname    = self.nicknameTextField.text;
  self.userInfo.phoneNumber = self.phoneNumberTextField.text;

  BOOL validateResult;
  if ([self shouldShowProfileContainer]) {
    validateResult = [self validateWithTargets:@[kGreeNicknameKey, kGreeBirthdayKey, kGreeCountryCodeKey, kGreePhoneNumberKey]] ? NO : YES;
  } else {
    validateResult = [self validateWithTargets:@[kGreeCountryCodeKey, kGreePhoneNumberKey]] ? NO : YES;
  }
  [GreePhoneNumberBasedPage switchButton:self.submitButton enable:validateResult];
}

@end
