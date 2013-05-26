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


#import "GreeJSGetConfigListCommand.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

@implementation GreeJSGetConfigListCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_config_list";
}

-(void)execute:(NSDictionary*)params
{
  NSMutableDictionary* settings = [[[GreePlatform sharedInstance] settings] performSelector:@selector(settings)];
  NSMutableDictionary* cloningSettings = [NSMutableDictionary dictionaryWithDictionary:settings];
  NSArray* blackList = [GreeSettings blackListForGetConfig];
  for (id item in blackList) {
    [cloningSettings removeObjectForKey:item];
  }

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:cloningSettings forKey:@"result"];
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
