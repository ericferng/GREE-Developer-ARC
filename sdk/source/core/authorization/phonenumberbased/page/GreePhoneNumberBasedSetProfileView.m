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
#import "GreePhoneNumberBasedSetProfileView.h"
#import "GreePhoneNumberBasedController.h"
#import "UIViewController+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeAuthorization.h"

@interface GreePhoneNumberBasedSetProfileView ()
-(IBAction)submitProfile:(id)sender;
@end

@implementation GreePhoneNumberBasedSetProfileView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.submitButton = nil;

  [super dealloc];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.profile.title")];
  self.noticeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.profile.notice");
  self.noticeLabel2.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.profile.notice2");
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel2 font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height+ self.noticeLabel2.frame.size.height];

  [GreePhoneNumberBasedPage decorateBlueButton:self.submitButton labelText:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.profile.submitButton")];
  self.navigationItem.leftBarButtonItem = nil;
  [self attachKeyImageWithLabel:self.birthdayLabel];
}

#pragma mark - Internal Methods


-(IBAction)submitProfile:(id)sender
{
  self.userInfo.nickname = self.nicknameTextField.text;

  if ([self checkBeforeSubmitWithTargets:@[kGreeNicknameKey, kGreeBirthdayKey]]) {
    return;
  }

  [self showLoadingView];
  [[GreePlatform sharedInstance].authorization updateUserProfileWithNickname:self.userInfo.nickname
                                                                    birthday:self.userInfo.birthdayDate
                                                                       block:^(NSError* anError) {
     if (anError) {
       [self handleError:anError];
       return;
     }
     [GreePhoneNumberBasedController sharedInstance].userInfo.hasBirthday = YES;
     [GreePhoneNumberBasedController sharedInstance].userInfo.hasNickname = YES;
     [self doAfterSubmit];
     [[GreePhoneNumberBasedController sharedInstance] invokeCompletionBlockWithError:nil];
     [self greeDismissViewControllerAnimated:YES completion:nil];
   }];
}

#pragma mark - override

-(void)didChangeFieldValue:(id)sender
{
  self.userInfo.nickname    = self.nicknameTextField.text;

  BOOL validateResult = [self validateWithTargets:@[kGreeNicknameKey, kGreeBirthdayKey]] ? NO : YES;
  [GreePhoneNumberBasedPage switchButton:self.submitButton enable:validateResult];
}

@end
