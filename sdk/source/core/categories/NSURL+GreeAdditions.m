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


#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "NSString+GreeAdditions.h"
#import "NSURL+GreeAdditions.h"


@interface NSURL (GreePrivateAdditions)
+(NSString*)EthnaActionNameFromDictionary:(NSDictionary*)aDictionary;
+(NSString*)EthnaActionNameFromURL:(NSURL*)aURL;
@end


@implementation NSURL (GreeAdditions)
@dynamic appAction;


#pragma mark - Property Methods

-(NSString*)appAction
{
  return [[[self fragment] greeDictionaryFromQueryString] objectForKey:@"appaction"];
}


#pragma mark - Public Interface

-(BOOL)isGreeDomain
{
  NSString* greeDomain = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlDomain];
  if ([[self host] hasSuffix:greeDomain]) {
    return YES;
  }

  NSString* developmentMode = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingDevelopmentMode];
  if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop]) {
    return [[self host] hasSuffix:@"gree.jp"];
  }
  return NO;
}

-(BOOL)isGreeLoginURL
{
  if ([self isGreeDomain]) {
    NSString* action = [NSURL EthnaActionNameFromURL:self];
    if ([action isEqualToString:@"login"] ||
        [action isEqualToString:@"id_login"] ||
        [action isEqualToString:@"reg_opt_top"] ||
        [action isEqualToString:@"common_login"]) {
      return YES;
    }
  }

  return NO;
}

-(BOOL)hasGreeAppAction
{
  if ([self isGreeDomain]) {
    if (self.appAction) {
      return YES;
    }
  }

  return NO;
}

-(BOOL)isSelfGreeURLScheme
{
  NSString* aGreeURLScheme = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationUrlScheme];
  NSString* applicationId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSString* selfURLScheme = [NSString stringWithFormat:@"%@%@", aGreeURLScheme, applicationId];
  return [[self scheme] isEqualToString:selfURLScheme];
}

-(BOOL)isGreeAdRedirectorURL
{
  if ([self isGreeDomain]) {
    return [self.path isEqualToString:@"/ard.php"];
  }

  return NO;
}

-(BOOL)isRequestServiceURL
{
  NSString* anEthnaActionName = [[self class] EthnaActionNameFromURL:self];
  if ([anEthnaActionName isEqualToString:@"service_request_app_static_list"]) {
    NSMutableDictionary* aParsedQueryDictionary = [self.query greeDictionaryFromQueryString];
    if ([aParsedQueryDictionary objectForKey:@"url"] && [aParsedQueryDictionary objectForKey:@"verify_token"]) {
      return YES;
    }
  }
  return NO;
}

-(NSURL*)URLByDeletingQuery
{
  NSString* urlString = [[[self absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
  return [NSURL URLWithString:urlString];
}

-(BOOL)isGreeErrorURL
{
  if ([[self absoluteString] rangeOfString:@"about://error/" options:NSCaseInsensitiveSearch].location == NSNotFound) {
    return NO;
  } else {
    return YES;
  }
}

@end

#pragma mark - Internal Methods
@implementation NSURL (GreePrivateAdditions)
+(NSString*)EthnaActionNameFromDictionary:(NSDictionary*)aDictionary
{
  if ([aDictionary objectForKey:@"act"]) {
    return [NSString stringWithFormat:@"%@_%@",
            [aDictionary objectForKey:@"mode"],
            [aDictionary objectForKey:@"act"]];
  } else {
    return [aDictionary objectForKey:@"action"];
  }
}

+(NSString*)EthnaActionNameFromURL:(NSURL*)aURL
{
  NSString* queryString = [aURL query];
  if (!queryString) {
    queryString = [aURL fragment];
  }
  NSDictionary* params = [queryString greeDictionaryFromQueryString];

  return [self EthnaActionNameFromDictionary:params];
}


@end
