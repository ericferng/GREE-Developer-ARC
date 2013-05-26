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


#import "GreeJSDeleteCookieCommand.h"
#import "GreeLogger.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"


@implementation GreeJSDeleteCookieCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"delete_cookie";
}

-(void)execute:(NSDictionary*)params
{
  BOOL succeeded = NO;
  NSString* aKey = [params objectForKey:@"key"];
  NSArray* parametersForDeletingCookie = [[[GreePlatform sharedInstance] settings] objectValueForSetting:GreeSettingParametersForDeletingCookie];

  for (id item in parametersForDeletingCookie) {
    NSString* allowedKey = [item objectForKey:@"key"];
    if ([allowedKey isEqualToString:aKey]) {
      NSString* domainString = [item objectForKey:@"domain"];
      NSArray* cookieNames = [item objectForKey:@"names"];

      // also we want to delete cookies for subdomain
      NSError* error = NULL;
      NSString* patternString = [NSString stringWithFormat:@"%@$", domainString];
      NSRegularExpression* regex = [NSRegularExpression
                                    regularExpressionWithPattern:patternString
                                                         options:NSRegularExpressionCaseInsensitive
                                                           error:&error];
      if (error) {
        break;
      }

      NSArray* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
      for (NSHTTPCookie* aCookie in cookies) {
        if ([cookieNames containsObject:aCookie.name]) {
          [regex
           enumerateMatchesInString:aCookie.domain
                            options:0
                              range:NSMakeRange(0, [aCookie.domain length])
                         usingBlock:^(NSTextCheckingResult* result, NSMatchingFlags flags, BOOL* stop) {
             [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
             GreeLog(@"delete cookie name:%@ in:%@", aCookie.name, aCookie.domain);
           }];
        }
      }
      succeeded = YES;
      break;
    }
  }

  NSString* aResultString = (succeeded) ? @"success" : @"error";
  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:aResultString forKey:@"result"];
  [[self.environment handler]
   callback:[params objectForKey:@"callback"]
     params:callbackParameters];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
