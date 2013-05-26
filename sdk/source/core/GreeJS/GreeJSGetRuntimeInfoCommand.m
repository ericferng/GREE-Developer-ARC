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


#import <UIKit/UIKit.h>
#import "GreeJSGetRuntimeInfoCommand.h"
#import "GreeRuntimeInformation.h"


@implementation NSMutableDictionary (Internal)

-(void)setAvailableObject:(id)anObject forKey:(id)aKey
{
  if (anObject) {
    [self setObject:anObject forKey:aKey];
  } else {
    [self setObject:@"" forKey:aKey];
  }
}

@end

@implementation GreeJSGetRuntimeInfoCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_runtime_info";
}

-(void)execute:(NSDictionary*)params
{
  NSMutableDictionary* result = [NSMutableDictionary dictionary];

  [result setAvailableObject:[GreeRuntimeInformation deviceName]         forKey:@"device_name"];
  [result setAvailableObject:[GreeRuntimeInformation deviceArchitecture] forKey:@"device_arch"];
  [result setAvailableObject:[GreeRuntimeInformation deviceVersion]      forKey:@"device_version"];
  [result setAvailableObject:[GreeRuntimeInformation OSName]             forKey:@"os_name"];
  [result setAvailableObject:[GreeRuntimeInformation OSVersion]          forKey:@"os_version"];
  [result setAvailableObject:[GreeRuntimeInformation SDKVersion]         forKey:@"sdk_version"];
  [result setAvailableObject:[GreeRuntimeInformation SDKBuild]           forKey:@"sdk_build"];
  [result setAvailableObject:[GreeRuntimeInformation middlewareName]     forKey:@"middleware_name"];
  [result setAvailableObject:[GreeRuntimeInformation middlewareVersion]  forKey:@"middleware_version"];
  [result setAvailableObject:[GreeRuntimeInformation applicationName]    forKey:@"app_name"];
  [result setAvailableObject:[GreeRuntimeInformation applicationVersion] forKey:@"app_version"];
  [result setAvailableObject:[GreeRuntimeInformation URLScheme]          forKey:@"url_scheme"];
  [result setAvailableObject:[GreeRuntimeInformation userAgent]          forKey:@"user_agent"];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:result forKey:@"result"];
  [[self.environment handler]
   callback:[params objectForKey:@"callback"]
     params:callbackParameters];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
