//
// Copyright 2010-2011 GREE, inc.
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

#import "GreeSSO.h"
#import "GreeAES128.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "NSData+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "NSDictionary+GreeAdditions.h"
#import <UIKit/UIKit.h>


@interface GreeSSO ()

-(void)aes128Setup:(NSString*)seedKey;
-(NSString*)encryptGssId;
-(NSString*)encryptString:(NSString*)aString key:(NSString*)key;
-(NSString*)decryptString:(NSString*)aString key:(NSString*)key;
-(NSString*)generateClientSeedKey;

@property (nonatomic, retain) GreeAES128* aes128;
@property (nonatomic, retain) NSString* clientSeedKey;
@property (nonatomic, retain) NSString* clientApplicationId;
@end

@implementation GreeSSO

#pragma mark - Object Lifecycle
-(id)initAsClient
{
  self = [super init];
  if (self) {
    self.aes128 = [[[GreeAES128 alloc] init] autorelease];
    self.clientSeedKey = [self generateClientSeedKey];
    return self;
  }
  return nil;
}

-(id)initAsServerWithSeedKey:(NSString*)seedKey clientApplicationId:(NSString*)applicationId
{
  self = [super init];
  if (self) {
    self.aes128 = [[[GreeAES128 alloc] init] autorelease];
    self.clientSeedKey = seedKey;
    self.clientApplicationId = applicationId;
    return self;
  }
  return nil;
}

-(void)dealloc
{
  self.clientApplicationId = nil;
  self.clientSeedKey = nil;
  self.aes128 = nil;
  [super dealloc];
}

#pragma mark - Public Interface
//sso client
-(NSURL*)ssoRequireUrlWithServerApplicationId:(NSString*)serverApplicationId
                                 requestToken:(NSString*)requestToken
                                      context:(NSString*)context
                                   parameters:(NSDictionary*)parameters
{
  NSString* developmentMode = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingDevelopmentMode];
  NSString* selfApplicationId = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId];

  NSMutableDictionary* queryDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [queryDictionary addEntriesFromDictionary:
   [NSDictionary dictionaryWithObjectsAndKeys:
    selfApplicationId, @"app_id",
    self.clientSeedKey, @"key",
    requestToken, @"oauth_token",
    context, @"context",
    nil]];
  NSString* query = [queryDictionary greeBuildQueryString];

  NSString* urlString;
  if (([serverApplicationId isEqualToString:kSNSApplicationId]
       && ([developmentMode isEqualToString:GreeDevelopmentModeProduction] || [developmentMode isEqualToString:GreeDevelopmentModeStaging]))
      || ([serverApplicationId isEqualToString:kSNSApplicationIdOnDevelop] && [developmentMode isEqualToString:GreeDevelopmentModeDevelop])) {
    NSString* appUrlScheme = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationUrlScheme];
    urlString = [NSString stringWithFormat:@"%@://authorize/request?%@", appUrlScheme, query];
  } else {
    urlString = [NSString stringWithFormat:@"%@%@://authorize/request?%@", kNotSNSApplicationUrlScheme, serverApplicationId, query];
  }
  return [NSURL URLWithString:urlString];
}

//sso client
-(void)setDecryptGssIdWithEncryptedGssId:(NSString*)encryptedGssId
{
  NSString* greeDomain = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* decryptedGssId = [self decryptString:encryptedGssId key:self.clientSeedKey];
  if (decryptedGssId && [decryptedGssId length] > 0) {
    [NSHTTPCookieStorage greeSetCookie:decryptedGssId forName:@"gssid" domain:greeDomain];
  }
}

//sso client
-(NSString*)openAvailableApplicationWithApps:(NSArray*)apps
{
  NSString* appUrlScheme = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationUrlScheme];
  NSString* developmentMode = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingDevelopmentMode];
  NSString* selfApplicationId = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId];

  for (NSString* aAppId in apps) {
    if ([aAppId isEqualToString:selfApplicationId]) {
      continue;
    }
    if ([aAppId isEqualToString:kSelfId] || [aAppId isEqualToString:kBrowserId]) {
      return aAppId;
    }
    NSString* urlString;
    if (([aAppId isEqualToString:kSNSApplicationId]
         && ([developmentMode isEqualToString:GreeDevelopmentModeProduction] || [developmentMode isEqualToString:GreeDevelopmentModeStaging]))
        || ([aAppId isEqualToString:kSNSApplicationIdOnDevelop] && [developmentMode isEqualToString:GreeDevelopmentModeDevelop])) {
      urlString = [NSString stringWithFormat:@"%@://", appUrlScheme]; //SNS app
    } else {
      urlString = [NSString stringWithFormat:@"%@%@://", kNotSNSApplicationUrlScheme, aAppId];
    }
    NSURL* url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
      return aAppId;
    }
  }
  return nil;
}

//sso server
-(NSURL*)acceptPageUrl
{
  return [NSURL URLWithString:
          [NSString stringWithFormat:@"%@/?action=sso_authorize&app_id=%@",
           [[[GreePlatform sharedInstance] settings] stringValueForSetting:GreeSettingServerUrlOpen],
           self.clientApplicationId]];
}

//sso server
-(NSURL*)ssoAcceptUrlWithFlag:(BOOL)flag
{
  NSString* appUrlScheme = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationUrlScheme];
  NSString* encryptedGssid = (flag) ? [NSString stringWithFormat:@"?key=%@", [self encryptGssId]] : @"";
  NSString* urlString = [NSString stringWithFormat:@"%@%@://sso/%@", appUrlScheme, self.clientApplicationId, encryptedGssid];
  return [NSURL URLWithString:urlString];
}

#pragma mark - Internal Method
-(void)aes128Setup:(NSString*)seedKey
{
  NSData* keydata = [seedKey greeHexStringFormatInBinary];
  [self.aes128 setKey:[keydata bytes]];
  [self.aes128 setInitializationVector:[keydata bytes]];
}

-(NSString*)encryptGssId
{
  NSString* greeDomain = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* gssid = [NSHTTPCookieStorage greeGetCookieValueWithName:@"gssid" domain:greeDomain];
  if (!gssid) {
    return nil;
  }
  return [self encryptString:gssid key:self.clientSeedKey];
}

-(NSString*)encryptString:(NSString*)aString key:(NSString*)key
{
  [self aes128Setup:key];
  NSData* gssidData = [aString greeHexStringFormatInBinary];
  NSData* encryptedGssidData = [self.aes128 encrypt:[gssidData bytes] length:[gssidData length]];
  return [encryptedGssidData greeFormatInHex];
}

-(NSString*)decryptString:(NSString*)aString key:(NSString*)key
{
  [self aes128Setup:key];
  NSData* gssidData = [aString greeHexStringFormatInBinary];
  NSData* decryptedGssidData = [self.aes128 decrypt:[gssidData bytes] length:[gssidData length]];
  return [decryptedGssidData greeFormatInHex];
}

-(NSString*)generateClientSeedKey
{
  return [[self.aes128 generateKey] greeFormatInHex];
}

#pragma mark - NSObject Overrides
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, %@:%p, clientSeedKey:%@, clientApplicationId:%@>",
          NSStringFromClass([self class]),
          self,
          NSStringFromClass([self.aes128 class]),
          self.aes128,
          self.clientSeedKey,
          self.clientApplicationId];
}

@end
