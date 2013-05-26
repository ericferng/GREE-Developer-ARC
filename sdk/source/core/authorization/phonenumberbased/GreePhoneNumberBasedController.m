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


#import "GreePhoneNumberBasedController.h"
#import "GreePlatform+Internal.h"
#import "UIViewController+GreeAdditions.h"
#import "GreePhoneNumberBasedNavigationController.h"
#import "GreePhoneNumberBasedSignUpView.h"
#import "GreePhoneNumberBasedSetProfileView.h"
#import "GreePhoneNumberBasedUpgradeView.h"
#import "GreeKeyChain.h"
#import "GreeAuthorization.h"

@interface GreePhoneNumberBasedController ()
// Last user for whom we successfully retrieved the auth bits
@property (nonatomic, copy) NSString* lastAuthBitsUser;
@property (nonatomic, copy) NSString* currentAuthBitsUser;
@end

@implementation GreePhoneNumberBasedController

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.userInfo = nil;
  self.completionBlock = nil;
  self.pincodeVerifiedBlock = nil;
  [super dealloc];
}

-(id)init
{
  if ((self = [super init])) {
    self.userInfo = [[[GreePhoneNumberBasedUserInfo alloc] init] autorelease];
  }
  return self;
}

-(BOOL)isNewRegistration
{
  id value = [GreeKeyChain readWithKey:GreeKeyChainIsNewRegistration];
  return (BOOL)value;
}

-(void)setIsNewRegistration:(BOOL)value
{
  if (value) {
    [GreeKeyChain saveWithKey:GreeKeyChainIsNewRegistration value:@"YES"];
  } else {
    [GreeKeyChain removeWithKey:GreeKeyChainIsNewRegistration];
  }
}

#pragma mark - Public Interface

+(GreePhoneNumberBasedController*)sharedInstance
{
  return [GreePlatform sharedInstance].phoneNumberBasedController;
}

-(void)showSignUpView
{
  GreePhoneNumberBasedSignUpView* signUp = [[[GreePhoneNumberBasedSignUpView alloc] initWithUserInfo:self.userInfo] autorelease];
  [(UINavigationController*)[UIViewController greeLastPresentedViewController] pushViewController:signUp animated:YES];
}

-(void)showSetProfileView
{
  GreePhoneNumberBasedSetProfileView* profile = [[[GreePhoneNumberBasedSetProfileView alloc] initWithUserInfo:self.userInfo] autorelease];

  UINavigationController* controller = [[[GreePhoneNumberBasedNavigationController alloc] initWithRootViewController:profile] autorelease];

  [[UIViewController greeLastPresentedViewController]
   greePresentViewController:controller
                    animated:YES completion:nil];
}

-(void)showUpgradeView
{
  GreePhoneNumberBasedUpgradeView* upgrade = [[[GreePhoneNumberBasedUpgradeView alloc] initWithUserInfo:self.userInfo] autorelease];

  UINavigationController* controller = [[[GreePhoneNumberBasedNavigationController alloc] initWithRootViewController:upgrade] autorelease];

  [[UIViewController greeLastPresentedViewController]
   greePresentViewController:controller
                    animated:YES completion:nil];
}

-(void)updateUserProfileIfNeeded
{
  // If we already have the auth bits for that user, skip this.
  // Otherwise, get them from server and call this method again.
  NSString* localUserId = [GreePlatform sharedInstance].localUserId;
  if (![self.lastAuthBitsUser isEqualToString:localUserId]) {

    // Simple guard against race condition: if we're already requesting
    // auth bits for the user, do nothing (this method will get called
    // again when er get the response from the server)
    if ([localUserId isEqualToString:self.currentAuthBitsUser]) {
      return;
    }
    self.currentAuthBitsUser = localUserId;

    self.userInfo.hasPhoneNumber = NO;
    self.userInfo.hasBirthday    = NO;
    self.userInfo.hasNickname    = NO;

    [[GreeAuthorization sharedInstance] getUserAuthBitsWithBlock:^(NSNumber* authBits, NSError* error) {
       self.currentAuthBitsUser = nil;

       if (error) {
         
         [self invokeCompletionBlockWithError:error];
         return;
       }
       NSUInteger bits = [authBits unsignedIntegerValue];

       self.userInfo.hasPhoneNumber = bits & GreeUserAuthBitsPhoneNumberSet;
       self.userInfo.hasBirthday    = bits & GreeUserAuthBitsBirthDaySet;
       self.userInfo.hasNickname    = bits & GreeUserAuthBitsNicknameSet;

       self.lastAuthBitsUser = [GreePlatform sharedInstance].localUserId;
       [self updateUserProfileIfNeeded];
     }];
    return;
  }

  GreeUser* user = [GreePlatform sharedInstance].localUser;

  // Update the information used for pre-fills with fields
  // from the user profile when they could be retrieved.
  if (user.nickname.length > 0) {
    self.userInfo.nickname = user.nickname;
  }

  if (user.birthday.length > 0) {
    self.userInfo.birthday = user.birthday;
  }

  if (!self.userInfo.hasPhoneNumber) {
    // This catches:
    // * Grade 1 users.
    // * Grade 2 users.
    // * Grade 3 users who haven't registered their phone number yet.
    [self showUpgradeView];
  } else if (!self.userInfo.hasBirthday || !self.userInfo.hasNickname) {
    // This catches:
    // * Grade 3 users who have registered their phone number but
    //   haven't completed their profile yet (new registration).
    [self showSetProfileView];
  } else {
    // This catches:
    // * Grade 3 users with a complete profile.
    [self invokeCompletionBlockWithError:nil];
  }
}

#pragma mark view

+(UILabel*)navigationLabelWithText:(NSString*)aText
{
  UILabel* label        = [[[UILabel alloc] init] autorelease];
  label.backgroundColor = [UIColor clearColor];
  label.shadowOffset    = CGSizeMake(0, -1);
  label.shadowColor     = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorTitleShadow];
  label.textColor       = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorTitleText];
  label.font            = [GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNavigationLabel];
  label.text            = aText;
  [label sizeToFit];

  return label;
}

#pragma mark delegate

-(void)invokeCompletionBlockWithError:(NSError*)error
{
  self.isNewRegistration = NO;
  [GreeKeyChain removeWithKey:GreeKeyChainIsNewRegistration];
  if (self.completionBlock) {
    self.completionBlock(error);
  }
}

-(void)invokePincodeVerifiedBlockWithError:(NSError*)error
{
  if (self.pincodeVerifiedBlock) {
    self.pincodeVerifiedBlock(error);
  }
}

@end
