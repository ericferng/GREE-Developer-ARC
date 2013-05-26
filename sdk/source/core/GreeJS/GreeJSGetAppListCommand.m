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
#import "GreeJSGetAppListCommand.h"


@implementation GreeJSGetAppListCommand

#pragma mark - GreeJSGetAppListCommand Overrides

+(NSString*)name
{
  return @"get_app_list";
}

-(void)execute:(NSDictionary*)params
{
  NSArray* array = [params objectForKey:@"schemes"];
  NSMutableArray* resultArray = [NSMutableArray array];

  for (NSString* scheme in array) {
    NSString* url = [NSString stringWithFormat:@"%@://", scheme];
    BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]];
    if (canOpen) {
      [resultArray addObject:scheme];
    }
  }

  NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:params];
  [results setObject:resultArray forKey:@"result"];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:results forKey:@"result"];
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
