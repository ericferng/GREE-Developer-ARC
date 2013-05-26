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


#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "GreePlatform+GreeMiddlewareAdditions.h"
#import "GreeRuntimeInformation.h"
#import "GreeSettings.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"


@interface GreeRuntimeInformation ()
+(NSString*)getSystemInformationByName:(char*)name;
@end


@implementation GreeRuntimeInformation

+(NSString*)getSystemInformationByName:(char*)name
{
  size_t size;
  sysctlbyname(name, NULL, &size, NULL, 0);

  char* result = malloc(size);
  sysctlbyname(name, result, &size, NULL, 0);
  NSString* infoString = [NSString stringWithCString:result encoding: NSUTF8StringEncoding];
  free(result);

  return infoString;
}

// "iPhone"
+(NSString*)deviceName
{
  return [[UIDevice currentDevice] model];
}

// "iPhone4,1"
+(NSString*)deviceArchitecture
{
  return [self getSystemInformationByName:"hw.machine"];
}

// "N94AP"
+(NSString*)deviceVersion
{
  return [self getSystemInformationByName:"hw.model"];
}

+(NSString*)OSName
{
  return [[UIDevice currentDevice] systemName];
}

+(NSString*)OSVersion
{
  return [[UIDevice currentDevice] systemVersion];
}

+(NSString*)SDKVersion
{
  return [GreePlatform version];
}

+(NSString*)SDKBuild
{
  return [GreePlatform build];
}

+(NSString*)middlewareName
{
  NSString* greeDomain = [[[GreePlatform sharedInstance] settings] stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* name = [NSHTTPCookieStorage greeGetCookieValueWithName:GreeCookieKeyMiddlewareName domain:greeDomain];
  return name;
}

+(NSString*)middlewareVersion
{
  NSString* greeDomain = [[[GreePlatform sharedInstance] settings] stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* version = [NSHTTPCookieStorage greeGetCookieValueWithName:GreeCookieKeyMiddlewareVersion domain:greeDomain];
  return version;
}

+(NSString*)applicationName
{
  NSString* name = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey];
  return name;
}

+(NSString*)applicationVersion
{
  return [GreePlatform bundleVersion];
}

+(NSString*)URLScheme
{
  return [GreePlatform greeApplicationURLScheme];
}

+(NSString*)userAgent
{
  NSString* userAgent = [GreeHTTPClient performSelector:@selector(userAgentString)];
  return userAgent;
}

@end
