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

#import "GreeDeviceIdentifier.h"
#import "JSONKit.h"
#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#import "NSData+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import <CommonCrypto/CommonHMAC.h>
#import "GreeKeyChain.h"

NSString* const GreeDeviceIdentifierKeyUUID       = @"UUID";
NSString* const GreeDeviceIdentifierKeySecureUDID = @"SecureUDID";

static char* greeGetMacAddress(char* macAddress, char* ifName);

static NSString* kOpenFeintUserOptionLocalUser = @"OpenFeintUserOptionLocalUser";
static NSString* kOpenFeintUserOptionClientApplicationId = @"OpenFeintSettingClientApplicationId";
static NSString* kOpenFeintAPIServer = @"api.openfeint.com";
static NSString* kOpenFeintTokenKey  = @"oauth_token_access";


@interface GreeOFUser : NSObject<NSCoding>
@property (nonatomic, retain) NSString* userId;
-(void)encodeWithCoder:(NSCoder*)aCoder;
-(id)initWithCoder:(NSCoder*)aDecoder;
@end

@implementation GreeOFUser

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super init];
  if (self != nil) {
    self.userId = [aDecoder decodeObjectForKey:@"resourceId"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self.userId forKey:@"resourceId"];
}

-(void)dealloc
{
  self.userId = nil;
  [super dealloc];
}

@end

@interface GreeDeviceIdentifier ()
+(NSString*)urlencodeForBase64:(NSString*)aString;
+(NSString*)secureUDID;
+(void)addData:(NSData*)data toContextArray:(NSMutableArray*)contextArray;
@end

@implementation GreeDeviceIdentifier

+(void)addData:(NSData*)data toContextArray:(NSMutableArray*)contextArray
{
  NSString* base64 = [data greeBase64EncodedString];
  [contextArray addObject:[GreeDeviceIdentifier urlencodeForBase64:base64]];
}

+(NSString*)macAddress
{
  char* macAddressString = (char*)malloc(18);
  greeGetMacAddress(macAddressString, "en0");
  NSString* macAddress = [[[NSString alloc] initWithCString:macAddressString
                                                   encoding:NSMacOSRomanStringEncoding] autorelease];
  free(macAddressString); macAddressString = NULL;
  return (macAddress) ? [macAddress stringByReplacingOccurrencesOfString:@":" withString:@""] : @"";
}

+(NSString*)secureUDID
{
  NSString* secureUDIDString = nil;
  Class klass = NSClassFromString(@"SecureUDID");
  if(klass) {
    if([klass respondsToSelector:@selector(UDIDForDomain:salt:)]) {
      secureUDIDString = [klass performSelector:@selector(UDIDForDomain:salt:)withObject:@"com.openfeint" withObject:@"dk25alfjdfki234aklsdf45hdhasfh"];
    } else if([klass respondsToSelector:@selector(UDIDForDomain:usingKey:)]) {
      secureUDIDString = [klass performSelector:@selector(UDIDForDomain:usingKey:)withObject:@"com.openfeint" withObject:@"dk25alfjdfki234aklsdf45hdhasfh"];
    }
    if (secureUDIDString) {
      secureUDIDString = [secureUDIDString greeUUIDString];
      if (secureUDIDString.length) {
        return [NSString stringWithFormat:@"sudid-%@", secureUDIDString];
      }
    }
  }
  return nil;
}

+(NSString*)ofAccessToken
{
  static NSDictionary* findQuery = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
                  findQuery = [@{
                                 (id)kSecClass: (id)kSecClassInternetPassword,
                                 (id)kSecAttrSecurityDomain: kOpenFeintAPIServer,
                                 (id)kSecAttrServer: kOpenFeintAPIServer,
                                 (id)kSecAttrAccount: kOpenFeintTokenKey,
                                 (id)kSecAttrAuthenticationType: (id)kSecAttrAuthenticationTypeDefault,
                                 (id)kSecAttrType: @'oaut',
                                 (id)kSecMatchLimit: (id)kSecMatchLimitOne,
                                 (id)kSecReturnData: (id)kCFBooleanTrue
                               } retain];
                  atexit_b (^{
                              [findQuery release];
                              findQuery = nil;
                            });
                });

  NSData* keychainValueData = nil;
  OSStatus returnStatus = SecItemCopyMatching((CFDictionaryRef)findQuery, (CFTypeRef*)&keychainValueData);

  NSString* foundValue = nil;
  if(returnStatus == errSecSuccess) {
    foundValue = [[[NSString alloc] initWithBytes:[keychainValueData bytes] length:[keychainValueData length]  encoding:NSUTF8StringEncoding] autorelease];
    [keychainValueData release];
  }
  return foundValue;
}

+(NSString*)ofUserId
{
  NSData* encoded = [[NSUserDefaults standardUserDefaults] objectForKey:kOpenFeintUserOptionLocalUser];
  GreeOFUser* ofUser = nil;
  if (encoded) {
    NSKeyedUnarchiver* archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:encoded];
    [archiver setClass:[GreeOFUser class] forClassName:@"OFUser"];
    ofUser = (GreeOFUser*)[archiver decodeObjectForKey:@"root"];
    [archiver release];
  }
  return ofUser.userId;
}

+(NSString*)ofApplicationId
{
  return [[NSUserDefaults standardUserDefaults] stringForKey:kOpenFeintUserOptionClientApplicationId];
}

+(void)removeOfAccessToken
{
  if (![self ofAccessToken]) {
    return;
  }

  static NSDictionary* findQuery = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
                  findQuery = [@{
                                 (id)kSecClass: (id)kSecClassInternetPassword,
                                 (id)kSecAttrSecurityDomain: kOpenFeintAPIServer,
                                 (id)kSecAttrServer: kOpenFeintAPIServer,
                                 (id)kSecAttrAccount: kOpenFeintTokenKey
                               } retain];
                  atexit_b (^{
                              [findQuery release];
                              findQuery = nil;
                            });
                });

  SecItemDelete((CFDictionaryRef)findQuery);
}

+(void)removeOfUserId
{
  if (![self ofUserId]) {
    return;
  }

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOpenFeintUserOptionLocalUser];
}

+(void)removeOfApplicationId
{
  if (![self ofApplicationId]) {
    return;
  }

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOpenFeintUserOptionClientApplicationId];
}

+(NSString*)deviceContextIdWithSecret:(NSString*)secret greeUUID:(NSString*)greeUUID keys:(NSArray*)keys
{
  // Build an array with enough space for a header, a payload and a signature (3 elements)
  NSMutableArray* context = [NSMutableArray arrayWithCapacity:3];

  // header
  [self addData:[[@{@"alg": @"HS256"} greeJSONString] dataUsingEncoding:NSUTF8StringEncoding] toContextArray:context];

  //
  // payload
  //
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];

  // keys
  NSMutableArray* keyArray = [NSMutableArray arrayWithCapacity:keys.count];
  for (NSString* key in keys) {
    NSString* value = nil;

    if ([key isEqualToString:GreeDeviceIdentifierKeyUUID]) {
      value = greeUUID;
    } else if ([key isEqualToString:GreeDeviceIdentifierKeySecureUDID]) {
      value = [self secureUDID];
    } else {
      NSAssert1(NO, @"Unsupported key: %@", key);
    }

    if (value.length) {
      [keyArray addObject:value];
    }
  }
  payload[@"key"] = keyArray;

  // okey
  NSString* ofAccessTokenString = [self ofAccessToken];
  if (ofAccessTokenString) {
    payload[@"okey"] = ofAccessTokenString;
  }

  // ouid
  NSString* ofUserIdString = [self ofUserId];
  if (ofUserIdString) {
    payload[@"ouid"] = ofUserIdString;
  }

  // ogid
  NSString* ofApplicationIdString = [self ofApplicationId];
  if (ofApplicationIdString) {
    payload[@"ogid"] = ofApplicationIdString;
  }

  // timestamp
  payload[@"timestamp"] = @((long long)floor([[NSDate date] timeIntervalSince1970]));

  [self addData:[[payload greeJSONString] dataUsingEncoding:NSUTF8StringEncoding] toContextArray:context];

  //
  //signature
  //

  NSData* msgData = [[context componentsJoinedByString:@"."] dataUsingEncoding:NSUTF8StringEncoding];
  NSData* secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableData* result = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, [secretData bytes], [secretData length], [msgData bytes], [msgData length], [result mutableBytes]);
  [self addData:result toContextArray:context];

  return [context componentsJoinedByString:@"."];
}

+(NSString*)urlencodeForBase64:(NSString*)aString
{
  aString = [aString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  aString = [aString stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  aString = [aString stringByReplacingOccurrencesOfString:@"=" withString:@""];
  return aString;
}

@end

#define IFT_ETHER 6
// This code was based from http://stackoverflow.com/questions/677530/how-can-i-programmatically-get-the-mac-address-of-an-iphone/6104162#6104162
// We distribute under the CC-BY SA3.0.
char* greeGetMacAddress(char* macAddress, char* ifName)
{
  int success;
  struct ifaddrs* addrs;
  struct ifaddrs* cursor;
  const struct sockaddr_dl* dlAddr;
  const unsigned char* base;
  int i;

  success = getifaddrs(&addrs) == 0;
  if (success) {
    cursor = addrs;
    while (cursor != 0) {
      dlAddr = (const struct sockaddr_dl*)cursor->ifa_addr;
      if (cursor->ifa_addr->sa_family == AF_LINK && dlAddr->sdl_type == IFT_ETHER && strcmp(ifName, cursor->ifa_name) == 0) {
        base = (const unsigned char*)&dlAddr->sdl_data[dlAddr->sdl_nlen];
        strcpy(macAddress, "");
        for (i = 0; i < dlAddr->sdl_alen; i++) {
          if (i != 0) {
            strcat(macAddress, ":");
          }
          char partialAddr[3];
          sprintf(partialAddr, "%02X", base[i]);
          strcat(macAddress, partialAddr);
        }
      }
      cursor = cursor->ifa_next;
    }
    freeifaddrs(addrs);
  }
  return macAddress;
}
