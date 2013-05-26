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

#import "GreeJSGetValueCommand.h"
#import "GreeJSSetValueCommand.h"

static NSString* const kGreeJSGetValueParamsCallbackKey = @"callback";

@implementation GreeJSGetValueCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_value";
}

-(void)execute:(NSDictionary*)params
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSString* userDefaultsPath = [GreeJSSetValueCommand userDefaultsPathForKey:[params objectForKey:kGreeJSSetValueParamsKey]];
  NSString* retval = [defaults objectForKey:userDefaultsPath];

  NSMutableDictionary* mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
  [mutableParams setValue:retval forKeyPath:kGreeJSSetValueParamsValue];

  [[self.environment handler]
   callback:[params objectForKey:kGreeJSGetValueParamsCallbackKey]
     params:mutableParams];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
