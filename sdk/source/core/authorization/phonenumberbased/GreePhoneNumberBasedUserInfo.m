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

#import "GreePhoneNumberBasedUserInfo.h"
#import "GreePlatform+Internal.h"
#import "GreeCountryCodes.h"
#import "GreeGlobalization.h"
#import "NSDateFormatter+GreeAdditions.h"

NSString* const kGreePhoneNumberKey  = @"telno";
NSString* const kGreeCountryCodeKey  = @"countryCode";
NSString* const kGreeCountryNameKey  = @"countryName";
NSString* const kGreePincodeKey      = @"pincode";
NSString* const kGreeNicknameKey     = @"username";
NSString* const kGreeBirthdayKey     = @"birth";


@interface GreePhoneNumberBasedUserInfo ()
@property (nonatomic, retain) NSDictionary* countryPhoneNumbers;
-(void)validateWithTarget:(NSString*)aTarget key:(NSString*)aKey Regex:(NSString*)aRegex errorMessage:(NSString*)anErrorMessage;
@end


@implementation GreePhoneNumberBasedUserInfo


#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.phoneNumber = nil;
  [_countryCode release];
  _countryCode = nil;
  self.countryName = nil;
  self.pincode = nil;
  self.nickname = nil;
  [_birthdayDate release];
  _birthdayDate = nil;
  [_birthday release];
  _birthday = nil;
  self.validateResults = nil;
  self.countryPhoneNumber = nil;
  self.countryPhoneNumbers = nil;

  [super dealloc];
}

-(id)init
{
  if ((self = [super init])) {
    self.validateResults = [NSMutableDictionary dictionary];
    self.countryPhoneNumbers = [GreeCountryCodes phoneNumberPrefixes];
  }
  return self;
}

#pragma mark - Public Interface

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, phoneNumber:%@, countryCode:%@, countryName:%@, pincode:%@, nickname:%@, birthday:%@, countryPhoneNumber:%@>",
          NSStringFromClass([self class]), self, self.phoneNumber, self.countryCode, self.countryName, self.pincode, self.nickname, self.birthday, self.countryPhoneNumber];
}

-(NSDictionary*)validate
{
  [self validateWithTarget:self.nickname key:kGreeNicknameKey
                     Regex:@"^.{1,60}$"
              errorMessage:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.validationError.nickname")];
  [self validateWithTarget:self.phoneNumber key:kGreePhoneNumberKey
                     Regex:@"^[0-9]{6,20}$"
              errorMessage:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.validationError.phoneNumber")];
  [self validateWithTarget:self.pincode key:kGreePincodeKey
                     Regex:@"^[0-9]{4}$"
              errorMessage:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.validationError.pincode")];
  [self validateWithTarget:self.birthday key:kGreeBirthdayKey
                     Regex:@"^[0-9\\-]{10}$"
              errorMessage:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.validationError.birthday")];

  return self.validateResults;
}

#pragma mark - Internal Methods

-(void)validateWithTarget:(NSString*)aTarget key:(NSString*)aKey Regex:(NSString*)aRegex errorMessage:(NSString*)anErrorMessage
{
  if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", aRegex] evaluateWithObject:aTarget]) {
    [self.validateResults removeObjectForKey:aKey];
  } else {
    [self.validateResults setObject:anErrorMessage forKey:aKey];
  }

}

#pragma mark - Property Methods

-(void)setCountryCode:(NSString*)countryCode
{
  [countryCode retain];
  [_countryCode release];
  _countryCode = countryCode;

  [_countryName release];
  _countryName = [[GreeCountryCodes localizedNameForCountryCode:_countryCode] retain];

  [_countryPhoneNumber release];
  _countryPhoneNumber = [[self.countryPhoneNumbers objectForKey:countryCode] retain];

}

-(void)setBirthdayDate:(NSDate*)birthdayDate
{
  [birthdayDate retain];
  [_birthdayDate release];
  _birthdayDate = birthdayDate;

  [_birthday release];
  _birthday = [[[NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy-MM-dd"] stringFromDate:_birthdayDate] retain];
}

-(void)setBirthday:(NSString*)birthday
{
  [birthday retain];
  [_birthday release];
  _birthday = birthday;

  [_birthdayDate release];
  _birthdayDate = [[[NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy-MM-dd"] dateFromString:_birthday] retain];
}

@end
