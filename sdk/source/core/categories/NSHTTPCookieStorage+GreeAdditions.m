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

#import "NSHTTPCookieStorage+GreeAdditions.h"

@implementation NSHTTPCookieStorage (GreeAdditions)

+(NSString*)greeAdditionalDomain:(NSString*)domain
{
  // the following implementation means that [GreePlatform sharedInstance] method returns nil
  // when this procedure run at the timing.
  if ([domain isEqualToString:@"gree.net"] || [domain isEqualToString:@"dev.gree-dev.net"])
    return @"gree.jp";

  return nil;
}

+(NSDictionary*)greeDictionaryForCookiePropertyWithValue:(NSString*)value forName:(NSString*)name domain:(NSString*)domain
{
  NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@".%@", domain], @"Domain",
                              @"2031-03-05 08:03:02 +0900", @"Expires",
                              @"/", @"Path",
                              name, @"Name",
                              value, @"Value",
                              nil];
  return dictionary;
}

+(void)greeDuplicateCookiesForAdditionalDomains
{
  void (^block)(NSString*) =^(NSString* _domain) {
    NSString* additonalDomain = [self greeAdditionalDomain:_domain];
    if (additonalDomain) {
      NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
      NSArray* cookies = [self greeCookiesWithDomain:_domain];
      for (NSHTTPCookie* cookie in cookies) {
        NSHTTPCookie* newCookie = [NSHTTPCookie cookieWithProperties:
                                   [self greeDictionaryForCookiePropertyWithValue:[cookie value] forName:[cookie name] domain:additonalDomain]];
        [cookieStorage setCookie:newCookie];
      }
    }
  };

  block(@"gree.net");
  block(@"dev.gree-dev.net");
}

+(void)greeSetCookieWithParams:(NSDictionary*)params domain:(NSString*)domain
{
  NSArray* keys = [params allKeys];
  for (int n=0; n< keys.count; ++n) {
    NSString* key = [keys objectAtIndex:n];
    NSString* value = [params objectForKey:key];
    [self greeSetCookie:value forName:key domain:domain];
  }
}

+(void)greeSetCookie:(NSString*)value forName:(NSString*)name domain:(NSString*)domain
{
  void (^block)(NSString*) =^(NSString* _domain) {
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:
                            [self greeDictionaryForCookiePropertyWithValue:value forName:name domain:_domain]];
    [cookieStorage setCookie:cookie];
  };

  block(domain);

  NSString* additonalDomain = [self greeAdditionalDomain:domain];
  if (additonalDomain) {
    block(additonalDomain);
  }
}

+(NSString*)greeGetCookieValueWithName:(NSString*)name domain:(NSString*)domain
{
  NSArray* cookies = [self greeCookiesWithDomain:domain];
  for (NSHTTPCookie* cookie in cookies) {
    if ([[cookie name] isEqualToString:name]) {
      return [cookie value];
    }
  }
  return nil;
}

+(void)greeDeleteCookieWithName:(NSString*)name domain:(NSString*)domain
{
  void (^block)(NSString*) =^(NSString* _domain) {
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* cookies = [self greeCookiesWithDomain:_domain];
    for (NSHTTPCookie* cookie in cookies) {
      if ([[cookie name] isEqualToString:name]) {
        [cookieStorage deleteCookie:cookie];
      }
    }
  };

  block(domain);

  NSString* additonalDomain = [self greeAdditionalDomain:domain];
  if (additonalDomain) {
    block(additonalDomain);
  }
}

+(NSArray*)greeCookiesWithDomain:(NSString*)domain
{
  NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSString* urlString = [NSString stringWithFormat:@"http://%@/", domain];
  NSURL* url = [NSURL URLWithString:urlString];
  return [cookieStorage cookiesForURL:url];
}

@end
