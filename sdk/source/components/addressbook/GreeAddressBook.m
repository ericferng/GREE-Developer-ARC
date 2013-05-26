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


#import <AddressBook/AddressBook.h>
#import "AFHTTPRequestOperation.h"
#import "GreeAuthorization+Internal.h"
#import "GreeAddressBook.h"
#import "GreeError+Internal.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeCountryCodes.h"
#import "GreeLogger.h"
#import "GreeNetworkReachability.h"
#import "GreeWriteCache.h"
#import "GreeSerializer.h"
#import "NSString+GreeAdditions.h"


static NSString* const kMD5KeyInUserDefaults = @"GreeAddressBook.md5";

@interface GreeAddressBook ()
@property (nonatomic, retain, readwrite) NSArray* contacts;

-(id)initWithContacts:(NSArray*)contacts;
+(void)requestAddressBookAccess:(ABAddressBookRef*)addressBook block:(void (^)(bool granted, CFErrorRef error))block;
+(void)contactsFromDevice:(void (^)(NSArray* contacts))block;
@end

@implementation GreeAddressBook

#pragma mark - Object Lifecycle

-(id)initWithContacts:(NSArray*)contacts
{
  self = [self init];

  if (self != nil) {
    self.contacts = contacts;
  }

  return self;
};

-(void)dealloc
{
  [_contacts release];
  [super dealloc];
}

#pragma mark - Public Interface

+(void)uploadWithParameters:(NSDictionary*)parameters block:(void (^)(GreeAddressBook* addressBook, NSError* error))block
{
  if (!block) return;

  if (![[GreeAuthorization sharedInstance] isAuthorized]) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeNotAuthorized]);
                   });
    return;
  }

  if (![GreePlatform sharedInstance].localUserId) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeUserRequired]);
                   });
    return;
  }

  [self contactsFromDevice:^(NSArray* contacts) {
     if (!contacts) {
       block(nil, [GreeError localizedGreeErrorWithCode:GreeAddressBookNoRecordInDevice]);
       return;
     }

     GreeLog(@"GreeAddressBook: Contact List\n%@", contacts);

     NSString* md5OfContacts = [[contacts description] MD5String];
     NSString* savedMD5OfContacts = [[NSUserDefaults standardUserDefaults] objectForKey:kMD5KeyInUserDefaults];
     if ([savedMD5OfContacts isEqualToString:md5OfContacts]) {
       block(nil, [GreeError localizedGreeErrorWithCode:GreeAddressBookNoNeedUpload]);
       return;
     }

     GreeWriteCache* cache = [[GreePlatform sharedInstance] writeCache];
     GreeAddressBook* addressBook = [[[GreeAddressBook alloc] initWithContacts:contacts] autorelease];
     GreeWriteCacheOperationHandle handleToObserve = [cache writeObject:addressBook];
     if ([[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
       handleToObserve = [cache commitAllObjectsOfClass:self inCategory:[addressBook writeCacheCategory]];
     }

     [[[GreePlatform sharedInstance] writeCache] observeWriteCacheOperation:handleToObserve forCompletionWithBlock:^(void) {
        block(addressBook, nil);
      }];
   }];
}

#pragma mark - GreeWriteCacheable Protocol

-(NSString*)writeCacheCategory
{
  return NSStringFromClass([self class]);
}

+(NSInteger)writeCacheMaxCategorySize
{
  return 1;
}

-(void)writeCacheCommitAndExecuteBlock:(void (^)(BOOL commitDidSucceed))block
{
  GreeLog(@"GreeAddressBook: Trying to get country code...");
  [GreeCountryCodes getCurrentCountryCodeWithBlock:^(NSString* countryCode) {
     GreeLog(@"GreeAddressBook: Country code is %@", countryCode);
     NSString* endpoint = @"user/me/friends/addressbook/:update";
     NSDictionary* requestParameters = [NSDictionary dictionaryWithObjectsAndKeys :
                                        self.contacts, @"addressbook",
                                        countryCode ?                 countryCode : @"", @"country_code",
                                        nil];

     GreeLog(@"GreeAddressBook: Trying to send Address Book...");
     [[GreePlatform sharedInstance].httpsClientForApi
        postPath:endpoint
      parameters:requestParameters
         success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
        if (block) {
          GreeLog(@"GreeAddressBook: Address Book is sent");
          [[NSUserDefaults standardUserDefaults] setObject:[[self.contacts description] MD5String] forKey:kMD5KeyInUserDefaults];
          [[NSUserDefaults standardUserDefaults] synchronize];
          block(YES);
        }
      }
         failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
        if (block) {
          GreeLog(@"GreeAddressBook: Address Book is not sent");
          block(NO);
        }
      }
     ];
   }];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];

  if (self != nil) {
    self.contacts = [serializer objectForKey:@"addressBook"];
  }

  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.contacts forKey:@"addressBook"];
}

#pragma mark - Internal Methods

+(void)requestAddressBookAccess:(ABAddressBookRef*)addressBook block:(void (^)(bool granted, CFErrorRef error))block
{
  if (&ABAddressBookCreateWithOptions) {
    GreeLog(@"GreeAddressBook: iOS 6 or newer");

    CFErrorRef error;

    *addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (*addressBook) {
      ABAddressBookRequestAccessWithCompletion(*addressBook, ^(bool granted, CFErrorRef error) {
                                                 block(granted, error);
                                               });
    } else {
      block(NO, error);
    }
  } else {
    GreeLog(@"GreeAddressBook: iOS 5 or older");

    *addressBook = ABAddressBookCreate();
    if (*addressBook) {
      block(YES, NULL);
    } else {
      block(NO, NULL);
    }
  }
}

+(void)contactsFromDevice:(void (^)(NSArray* contacts))block
{
  __block ABAddressBookRef addressBook = NULL;

  [self requestAddressBookAccess:&addressBook block:^(bool granted, CFErrorRef error) {
     if (granted) {
       NSArray* contacts = (NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);
       NSMutableArray* resultContacts = [NSMutableArray array];

       for (int index = 0; index < [contacts count]; index++) {
         ABRecordRef recordRef = (ABRecordRef)[contacts objectAtIndex:index];
         NSMutableDictionary* contact = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @"", @"email",
                                         @"", @"tel",
                                         nil];

         ABMultiValueRef emailAddresses = ABRecordCopyValue(recordRef, kABPersonEmailProperty);
         if (emailAddresses) {
           if (0 < ABMultiValueGetCount(emailAddresses)) {
             NSString* email = ABMultiValueCopyValueAtIndex(emailAddresses, 0);
             [contact setObject:email forKey:@"email"];
             CFRelease(email);
           }
           CFRelease(emailAddresses);
         }

         ABMultiValueRef phoneNumbers = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
         if (phoneNumbers) {
           if (0 < ABMultiValueGetCount(phoneNumbers)) {
             NSString* phoneNumber = (NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
             [contact setObject:phoneNumber forKey:@"tel"];
             CFRelease(phoneNumber);
           }
           CFRelease(phoneNumbers);
         }

         // both keys need to be in a record
         if (0 < [[contact objectForKey:@"email"] length] || 0 < [[contact objectForKey:@"tel"] length]) {
           [resultContacts addObject:contact];
         }
       }

       CFRelease(contacts);
       block((0 < [resultContacts count]) ? resultContacts : nil);
     } else {
       GreeLog(@"GreeAddressBook: Couldn't Access to Address Book [%@]", [(NSError*) error description]);
       block(nil);
     }

     if (addressBook) {
       CFRelease(addressBook);
     }
   }];
}

@end
