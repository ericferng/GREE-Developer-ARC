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


#import "GreeJSSetConfigCommand.h"
#import "GreeLogger.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"


@implementation GreeJSSetConfigCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"set_config";
}

-(void)execute:(NSDictionary*)params
{
  NSString* aKey = [params objectForKey:@"key"];

  if ((aKey == nil) || [[GreeSettings blackListForSetConfig] containsObject:aKey]) {
    GreeLogWarn(@"Can not overwrite %@", aKey);
    return;
  }

  id aValue = [params objectForKey:@"value"];
  aValue = (aValue) ? aValue : [NSDictionary dictionary];

  NSDictionary* aNewSetting = [NSDictionary dictionaryWithObject:aValue forKey:aKey];
  [[[GreePlatform sharedInstance] settings] applySettingDictionary:aNewSetting caching:YES];

  aValue = [[[GreePlatform sharedInstance] settings] stringValueForSetting:aKey];
  aValue = (aValue) ? aValue : [NSDictionary dictionary];
  NSDictionary* resultDictionary = [NSDictionary dictionaryWithObject:aValue forKey:aKey];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:resultDictionary forKey:@"result"];
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
