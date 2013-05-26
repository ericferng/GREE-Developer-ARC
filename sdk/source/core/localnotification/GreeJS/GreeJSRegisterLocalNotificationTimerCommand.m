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

#import "GreeJSRegisterLocalNotificationTimerCommand.h"
#import "GreeLocalNotification.h"

#define kGreeJSRegisterLocalNotificationTimerCallbackFunction @"callback"

@implementation GreeJSRegisterLocalNotificationTimerCommand

#pragma mark - Public Interface

+(NSString*)name
{
  return @"register_local_notification_timer";
}

-(void)execute:(NSDictionary*)params
{

  NSDictionary* callbackParam = [params objectForKey:@"callbackParam"];
  NSNumber* notifyId = [NSNumber numberWithInt:[[params objectForKey:@"notifyId"] intValue]];
  NSString* interval = [params objectForKey:@"interval"];
  NSString* message = [params objectForKey:@"message"];

  NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               message, @"message",
                               [NSDate dateWithTimeIntervalSinceNow:[interval doubleValue]], @"interval",
                               notifyId, @"notifyId",
                               callbackParam, @"callbackParam",
                               nil];

  BOOL isRegistered = NO;
  isRegistered = [[GreePlatform sharedInstance].localNotification registerLocalNotificationWithDictionary:aDictionary];

  NSMutableDictionary* callbackParameters = [NSMutableDictionary dictionary];

  if (isRegistered) {
    [callbackParameters setObject:@"registered" forKey:@"result"];
  } else {
    [callbackParameters setObject:@"error" forKey:@"result"];
  }

  [[self.environment handler]
   callback:[params objectForKey:kGreeJSRegisterLocalNotificationTimerCallbackFunction]
     params:callbackParameters];

}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
