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


#import "GreeWebAppCacheLog.h"

@implementation GreeWebAppCacheLog

+(void)log:(NSString*)fmt, ...
{
#if TARGET_IPHONE_SIMULATOR
  static id fh = nil;

  NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];

  if (fh == nil) {
    NSString* logdir = @"/tmp/ggpappcache";
    [[NSFileManager defaultManager] createDirectoryAtPath:logdir withIntermediateDirectories:YES attributes:nil error:nil];

    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString* today = [dateFormatter stringFromDate:[NSDate date]];

    NSString* path = [logdir stringByAppendingFormat:@"/%@.txt", today];

    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
      [fm createFileAtPath:path contents:nil attributes:nil];
    }
    fh = [[NSFileHandle fileHandleForWritingAtPath:path] retain];
    [fh seekToEndOfFile];
  }

  va_list args;
  va_start(args, fmt);

  [dateFormatter setDateFormat:@"HH:mm:ss"];
  NSString* now = [dateFormatter stringFromDate:[NSDate date]];

  fmt = [NSString stringWithFormat:@"%@ %@\n", now, fmt];

  NSString* text = [[[NSString alloc] initWithFormat:fmt arguments:args] autorelease];
  NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
  [fh writeData:data];

  [fh synchronizeFile];

  va_end(args);
#endif
}

@end
