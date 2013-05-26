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

#import "NSDateFormatter+GreeAdditions.h"
@interface NSDateFormatter (GreeAdditionsPrivate)
+(id)greeDateAndZoneFormatter;
@end


@implementation NSDateFormatter (GreeAdditions)

+(id)greeStandardDateFormatter
{
  static NSDateFormatter* formatter = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
                  formatter = [[NSDateFormatter alloc] init];
                  [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                  [formatter setTimeZone:[NSTimeZone localTimeZone]];
                  [formatter setLocale:[NSLocale currentLocale]];
                  atexit_b (^{
                              [formatter release];
                              formatter = nil;
                            });
                });

  return formatter;
}

+(id)greeSystemMediumStyleDateFormatter
{
  static NSDateFormatter* formatter = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
                  formatter = [[NSDateFormatter alloc] init];
                  [formatter setDateStyle:NSDateFormatterMediumStyle];
                  [formatter setTimeStyle:NSDateFormatterMediumStyle];
                  [formatter setTimeZone:[NSTimeZone localTimeZone]];
                  [formatter setLocale:[NSLocale currentLocale]];
                  atexit_b (^{
                              [formatter release];
                              formatter = nil;
                            });
                });

  return formatter;
}

+(id)greeUTCDateFormatter
{
  return [NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

+(id)greeUTCDateFormatterWithFormat:(NSString*)format
{
  static NSMutableDictionary* formatters = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
                  formatters = [[NSMutableDictionary alloc] init];
                  atexit_b (^{
                              [formatters release];
                              formatters = nil;
                            });
                });

  __block NSDateFormatter* formatter = nil;
  @synchronized(formatters) {
    formatter = [formatters objectForKey:format];
    if (!formatter) {
      formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:format];
      [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
      [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
      [formatters setObject:formatter forKey:format];
      [formatter release];
    }
  }

  return formatter;
}

+(id)greeDateAndZoneFormatter
{
  static NSDateFormatter* formatter = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
                  formatter = [[NSDateFormatter alloc] init];
                  [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                  [formatter setLocale:[NSLocale currentLocale]];
                  atexit_b (^{
                              [formatter release];
                              formatter = nil;
                            });
                });

  return formatter;
}

@end
