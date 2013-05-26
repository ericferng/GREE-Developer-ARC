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


#import "GreeJSGetContactListCommand.h"
#import <AddressBook/AddressBook.h>
#import "JSONKit.h"

static NSString* const kGreeJSGetContactListParamsResultKey       = @"result";
static NSString* const kGreeJSGetContactListParamsCallbackKey     = @"callback";
static NSString* const kGreeJSGetContactListFirstNameKey          = @"firstName";
static NSString* const kGreeJSGetContactListLastNameKey           = @"lastName";
static NSString* const kGreeJSGetContactListHomePhoneNumberKey    = @"homePhoneNumber";
static NSString* const kGreeJSGetContactListMobilePhoneNumberKey  = @"mobilePhoneNumber";
static NSString* const kGreeJSGetContactListEmailKey              = @"emails";
static NSString* const kGreeJSGetContactListParamsDeniedAccess    = @"deniedAccess";

@interface GreeJSGetContactListCommand ()
@property (nonatomic, retain) NSDictionary* params;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@end

@implementation GreeJSGetContactListCommand

# pragma mark - Object Lifecycle

-(void)dealloc
{
  self.params = nil;
  [super dealloc];
}

# pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_contact_list";
}

-(void)execute:(NSDictionary*)params
{
  self.params = params;

  ABAddressBookRef addressBook;
  if ([self isABAddressBookCreateWithOptionsAvailable]) {
    [self retain];
    CFErrorRef error = nil;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    self.addressBook = addressBook;
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                                               // callback can occur in background, address book must be accessed on thread it was created on
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                if (error || !granted) {
                                                                  [self.params setValue:@"[]" forKey:kGreeJSGetContactListParamsResultKey];
                                                                  [self.params setValue:@"true" forKey:kGreeJSGetContactListParamsDeniedAccess];
                                                                  [[self.environment handler]
                                                                   callback:[self.params objectForKey:kGreeJSGetContactListParamsCallbackKey]
                                                                     params:self.params];
                                                                } else {
                                                                  // access granted
                                                                  [self granted];
                                                                  CFRelease(addressBook);
                                                                }
                                                                [self release];
                                                              });
                                             });
  } else {
    addressBook = ABAddressBookCreate();
    self.addressBook = addressBook;
    [self granted];
    CFRelease(addressBook);
  }
}

# pragma mark - Internal Methods

-(BOOL)isABAddressBookCreateWithOptionsAvailable
{
  return &ABAddressBookCreateWithOptions != NULL;
}

-(void)granted
{
  NSArray* contactArray = (NSArray*)ABAddressBookCopyArrayOfAllPeople(self.addressBook);
  NSMutableArray* contacts = [NSMutableArray arrayWithCapacity:[contactArray count]];

  for (int index = 0; index < [contactArray count]; index++) {

    ABRecordRef recordRef = (ABRecordRef)[contactArray objectAtIndex : index];
    NSMutableDictionary* contact = [[NSMutableDictionary alloc] initWithCapacity:5];

    // First and last name.
    ABMultiValueRef firstName = ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
    if (firstName != nil) {
      [contact setObject:(id)firstName forKey:kGreeJSGetContactListFirstNameKey];
      CFRelease(firstName);
    }

    ABMultiValueRef lastName = ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
    if (lastName != nil) {
      [contact setObject:(id)lastName forKey:kGreeJSGetContactListLastNameKey];
      CFRelease(lastName);
    }


    // Email address (just take the first one available)
    ABMultiValueRef emailAddresses = ABRecordCopyValue(recordRef, kABPersonEmailProperty);
    if (emailAddresses != nil) {
      int numberOfAddresses = ABMultiValueGetCount(emailAddresses);
      if (numberOfAddresses > 0) {
        NSMutableArray* addresses = [NSMutableArray arrayWithCapacity:numberOfAddresses];
        for (int i = 0; i < numberOfAddresses; i++) {
          ABMultiValueRef address = ABMultiValueCopyValueAtIndex(emailAddresses, i);
          [addresses addObject:(id)address];
          CFRelease(address);
        }
        [contact setObject:addresses
                    forKey:kGreeJSGetContactListEmailKey];
      }
      CFRelease(emailAddresses);
    }

    // Phone numbers.
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
    NSUInteger numberOfPhones = ABMultiValueGetCount(phoneNumbers);
    for (int phoneIndex = 0; phoneIndex < numberOfPhones; phoneIndex++) {
      CFStringRef phoneNumberLabel = ABMultiValueCopyLabelAtIndex(phoneNumbers, phoneIndex);
      if (phoneNumberLabel != nil) {
        NSString* phoneNumberValue = (NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, phoneIndex);

        if (CFStringCompare(phoneNumberLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {
          [contact setObject:phoneNumberValue forKey:kGreeJSGetContactListMobilePhoneNumberKey];
        } else if (CFStringCompare(phoneNumberLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
          [contact setObject:phoneNumberValue forKey:kGreeJSGetContactListHomePhoneNumberKey];
        }

        CFRelease(phoneNumberLabel);
        CFRelease(phoneNumberValue);
      }
    }
    CFRelease(phoneNumbers);

    [contacts addObject:contact];
    [contact release];
  }

  // Set params and perform callback.
  [self.params setValue:[contacts greeJSONString] forKey:kGreeJSGetContactListParamsResultKey];
  [[self.environment handler]
   callback:[self.params objectForKey:kGreeJSGetContactListParamsCallbackKey]
     params:self.params];

  [contactArray release];
}

@end
