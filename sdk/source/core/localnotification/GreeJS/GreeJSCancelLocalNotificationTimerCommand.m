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

#import "GreeJSCancelLocalNotificationTimerCommand.h"
#import "GreeLocalNotification.h"

#define kGreeJSCancelLocalNotificationTimerCallbackFunction @"callback"

@implementation GreeJSCancelLocalNotificationTimerCommand

#pragma mark - Public Interface

+(NSString*)name
{
  return @"cancel_local_notification_timer";
}

-(void)execute:(NSDictionary*)params
{
  NSNumber* notifyId = [NSNumber numberWithInteger:[[params objectForKey:@"notifyId"] integerValue]];

  BOOL isCancelled = [[GreePlatform sharedInstance].localNotification cancelNotification:notifyId];

  NSMutableDictionary* callbackParameters = [NSMutableDictionary dictionary];

  if (isCancelled) {
    [callbackParameters setObject:@"cancelled" forKey:@"result"];
  } else {
    [callbackParameters setObject:@"error" forKey:@"result"];
  }

  [[self.environment handler]
   callback:[params objectForKey:kGreeJSCancelLocalNotificationTimerCallbackFunction]
     params:callbackParameters];

}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
