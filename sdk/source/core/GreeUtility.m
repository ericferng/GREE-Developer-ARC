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

#import "GreeUtility.h"
#import <UIKit/UIKit.h>

NSString* GreeApplicationUuid(void)
{
  static NSString* cachedUuid = nil;
  if (!cachedUuid) {
    NSString* applicationUuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"GreeApplicationUUID"];
    if ([applicationUuid length] == 0) {
      CFUUIDRef uuid = CFUUIDCreate(NULL);
      NSString* uuidString = (NSString*)CFUUIDCreateString(NULL, uuid);
      CFRelease(uuid);
      [[NSUserDefaults standardUserDefaults] setObject:uuidString forKey:@"GreeApplicationUUID"];
      applicationUuid = [uuidString autorelease];
    }

    cachedUuid = [applicationUuid retain];
  }

  return cachedUuid;
}

NSString* GreeSdkRelativePath(void)
{
  static NSString* cachedPath = nil;
  if (!cachedPath) {
    cachedPath = [[NSString alloc] initWithFormat:@"greePlatformSdk/%@/", GreeApplicationUuid()];
  }

  return cachedPath;
}

BOOL GreeDeviceOsVersionIsAtLeast(NSString* minimumVersion)
{
  BOOL isAtLeast = YES;

  NSScanner* minimum = [[NSScanner alloc] initWithString:minimumVersion];
  NSScanner* current = [[NSScanner alloc] initWithString:[[UIDevice currentDevice] systemVersion]];

  NSMutableCharacterSet* skipSet = [NSMutableCharacterSet decimalDigitCharacterSet];
  [skipSet invert];

  [minimum setCharactersToBeSkipped:skipSet];
  [current setCharactersToBeSkipped:skipSet];

  while (![minimum isAtEnd] || ![current isAtEnd]) {
    int minPiece = 0;
    int curPiece = 0;

    [minimum scanInt:&minPiece];
    [current scanInt:&curPiece];

    if (curPiece < minPiece) {
      isAtLeast = NO;
      break;
    } else if (curPiece > minPiece) {
      isAtLeast = YES;
      break;
    }
  }

  [minimum release];
  [current release];

  return isAtLeast;
}


void GreeRetry(NSInteger maxTryCount, void(^retryBlock)(NSInteger, double, void(^)(BOOL, double)))
{
  void (^__block wrapBlock)(NSInteger, double);
  wrapBlock = [^(NSInteger count, double previousDelay){

    void(^handler)(BOOL, double) = [[^(BOOL retry, double delay){
      if (!retry) {
        [wrapBlock release];
        wrapBlock = nil;
        return;
      }
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        wrapBlock(count + 1, delay);
      });
    } copy] autorelease];

    if (count > maxTryCount && maxTryCount != 0) {
      handler(NO, 0);
      return;
    }

    retryBlock(count, previousDelay, handler);
  } copy];

  wrapBlock(1, 0);

  atexit_b(^{
    [wrapBlock release];
    wrapBlock = nil;
  });
}
