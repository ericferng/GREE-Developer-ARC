//
// Copyright 2011 GREE, Inc.
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

#import "GreeHTTPClient.h"
#import "GreeSettings.h"
#import "GreeAgreementPopup.h"
#import "GreeLogger.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeError+Internal.h"
#import "GreeWebSession.h"
#import "AFNetworking.h"
#import "GreeBenchmark.h"

static NSString* const GreeWebSessionDidUpdateNotification = @"GreeWebSessionDidUpdateNotification";

static const char touchsession[] = "tns`dn_lk`ec"; // encoded touchsession
static const char gssid[] = "grqf`"; // encoded touchsession

@implementation GreeWebSession

+(id)s:(const char*)encoded
{
  int n = strlen(encoded);

  char* bf = (char*)malloc(n + 1);
  strncpy(bf, encoded, n);
  int i;
  for (i = 0; i < n; i++) {
    *(bf + i) += i;
  }
  bf[n] = 0;
  NSString* servicename = [NSString stringWithCString:bf encoding:NSUTF8StringEncoding];
  free(bf);

  return servicename;
}

+(id)observeWebSessionChangesWithBlock:(void (^)(void))block
{
  id handle = nil;

  if (block != nil) {
    handle = [[NSNotificationCenter defaultCenter]
              addObserverForName:GreeWebSessionDidUpdateNotification
                          object:nil
                           queue:nil
                      usingBlock:^(NSNotification* note) {
                block();
              }];
  }

  return handle;
}

+(void)stopObservingWebSessionChanges:(id)handle
{
  if (handle != nil) {
    [[NSNotificationCenter defaultCenter] removeObserver:handle name:GreeWebSessionDidUpdateNotification object:nil];
  }
}

+(void)regenerateWebSessionWithBlock:(void (^)(NSError* error))block
{
  NSString* endpoint = [NSString stringWithFormat:@"/api/rest/%@/@%@/@%@", [self s:touchsession], @"me", @"self"];
  GreeHTTPClient* httpClient = [GreePlatform sharedInstance].httpClient;

  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:endpoint position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  [httpClient
      getPath:endpoint
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:endpoint position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }

     do {
       id entry = [responseObject objectForKey:@"entry"];
       if (!entry) {
         // entry field is mandatory
         break;
       }

       id gssidValue = [entry objectForKey:[self s:gssid]];
       if (!gssidValue || ![gssidValue isKindOfClass:[NSString class]] || [gssidValue isEqualToString:@""]) {
         // gssid field is mandatory and must be a non-empty string
         break;
       }
       NSString* sgssid = (NSString*)gssidValue;

       id agreementUrlValue = [entry objectForKey:@"agreementUrl"];
       NSURL* agreementUrl = nil;
       if (agreementUrlValue) {
         // agreementUrl is optional, but must be a non-empty string if provided
         if (![agreementUrlValue isKindOfClass:[NSString class]] || [agreementUrlValue isEqualToString:@""]) {
           break;
         }

         agreementUrl = [NSURL URLWithString:agreementUrlValue];
         if (!agreementUrl) {
           break;
         }
       }

       GreeSettings* settings = [GreePlatform sharedInstance].settings;
       NSString* greeDomain = [settings stringValueForSetting:GreeSettingServerUrlDomain];
       NSString* developmentMode = [settings stringValueForSetting:GreeSettingDevelopmentMode];
       NSString* cookieKey = settings.usesSandbox ? @"gssid_smsandbox": @"gssid";

       [NSHTTPCookieStorage greeSetCookie:sgssid forName:cookieKey domain:greeDomain];
       if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop]) {
         [NSHTTPCookieStorage greeSetCookie:sgssid forName:cookieKey domain:@"gree.jp"];
       }

       [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebSessionDidUpdateNotification object:nil];

#if 0
       if (agreementUrl) {
         GreeLog(@"agreementUrl: %@", agreementUrl);
         [GreeAgreementPopup launchWithURL:agreementUrl];
       }
#endif
       if (block) {
         block(nil);
       }

       // All done
       return;

     } while(false);

     // Broke out because the response was malformed
     if (block) {
       block([NSError errorWithDomain:GreeErrorDomain code:GreeErrorCodeWebSessionResponseUnrecognized userInfo:nil]);
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:endpoint position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
     if(operation.response.statusCode == 401) {
       error = [[[NSError alloc]
                 initWithDomain:GreeErrorDomain
                           code:GreeErrorCodeWebSessionNeedReAuthorize
                       userInfo:nil] autorelease];
     }
     if (block) {
       block([GreeError convertToGreeError:error]);
     }
   }];
}

+(BOOL)hasWebSession
{
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  NSString* greeDomain = [settings stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* sgssid = settings.usesSandbox ? @"gssid_smsandbox" : [self s:gssid];
  NSString* value = [NSHTTPCookieStorage greeGetCookieValueWithName:sgssid domain:greeDomain];
  return (BOOL)value;
}

@end
