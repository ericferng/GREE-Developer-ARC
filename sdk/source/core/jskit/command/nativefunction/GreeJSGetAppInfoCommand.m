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

#import "GreeJSGetAppInfoCommand.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import <mach/mach.h>

@implementation GreeJSGetAppInfoCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"get_app_info";
}

static int count = 0;

-(void)execute:(NSDictionary*)params
{
  NSString* applicationId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSString* version = [GreePlatform bundleVersion];
  NSString* sdkVersion = [GreePlatform version];
  vm_size_t residentSize = 0;
  vm_size_t virtualSize = 0;

  struct task_basic_info t_info;
  mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
  if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count) == KERN_SUCCESS) {
    residentSize = t_info.resident_size;
    virtualSize = t_info.virtual_size;
  }

  NSDictionary* appInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                           applicationId, @"id",
                           version, @"version",
                           sdkVersion, @"sdk_version",
                           @"ios", @"platform",
                           [UIDevice currentDevice].model, @"model",
                           [UIDevice currentDevice].systemVersion, @"version",
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%u", residentSize], @"resident_size",
                            [NSString stringWithFormat:@"%u", virtualSize], @"virtual_size",
                            [NSString stringWithFormat:@"%p", self], @"instance",
                            nil
                           ], @"process",
                           [NSString stringWithFormat:@"%d", count++], @"count",
                           nil];

  [[self.environment handler] callback:[params objectForKey:@"callback"] params:appInfo];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
