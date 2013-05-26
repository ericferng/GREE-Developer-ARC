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

#import "NSDictionary+GreeAdditions.h"
#import "NSString+GreeAdditions.h"

@implementation NSDictionary (GreeAdditions)

-(NSString*)greeBuildQueryString
{
  NSString* s = @"";
  int n = 0;
  for (NSString* name in self) {
    id value = [self objectForKey:name];
    if ( [value isKindOfClass:[NSNull class]] ) {
      continue;
    } else if ([value isKindOfClass:[NSArray class]]) {
      NSString* anEntriesString = [value componentsJoinedByString:@","];
      NSString* aFormatString = (n > 0) ? @"&%@=%@" : @"%@=%@";
      s = [s stringByAppendingFormat:aFormatString, [name greeURLEncodedString], [anEntriesString greeURLEncodedString]];
    } else {
      NSString* format = (n > 0) ? @"&%@=%@" : @"%@=%@";
      NSString* valueString;
      if ( [value isKindOfClass:[NSNumber class]] ) {
        valueString = [value stringValue];
      } else {
        valueString = value;
      }
      s = [s stringByAppendingFormat:format, [name greeURLEncodedString], [valueString greeURLEncodedString]];
    }
    n++;
  }
  return s;
}

@end
