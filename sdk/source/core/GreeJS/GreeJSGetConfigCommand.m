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


#import "GreeAuthorization.h"
#import "GreeJSGetConfigCommand.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"


@implementation GreeJSGetConfigCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_config";
}

-(void)execute:(NSDictionary*)params
{
  NSString* aKey = [params objectForKey:@"key"];
  id aValue = nil;

  if (![[GreeSettings blackListForGetConfig] containsObject:aKey]) {
    aValue = [[[GreePlatform sharedInstance] settings] objectValueForSetting:aKey];
  }
  aValue = (aValue) ? aValue : [NSDictionary dictionary];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:aValue forKey:@"result"];
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
