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

#import "NSBundle+GreeAdditions.h"
#import <UIKit/UIKit.h>

@implementation NSBundle (GreeAdditions)

+(NSBundle*)greePlatformCoreBundle
{
  static NSBundle* bundle = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
                  NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"GreePlatformCoreResources" ofType:@"bundle"];
                  if ([bundlePath length] > 0) {
                    bundle = [[NSBundle alloc] initWithPath:bundlePath];
                  }

                  if (!bundle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                                     [[[[UIAlertView alloc]
                                        initWithTitle:nil
                                        // [adill] not localized because if we do not have a core bundle we won't have any other language anyway!
                                        message:@"GreePlatformCoreResources could not be found! You must include this bundle for GreePlatformSDK to function!"
                                        delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil] autorelease] show];
                                   });
                  }

                  atexit_b (^{
                              [bundle release];
                              bundle = nil;
                            });
                });

  return bundle;
}

@end
