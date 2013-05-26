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

#import "GreeLocalNotification+Internal.h"
#import "GreePlatform.h"
#import <UIKit/UIApplication.h>
#import "GreeLogger.h"
#import "GreeGlobalization.h"
#import "GreeSettings.h"

NSString* const GreeLocalNotificationDidReceiveNotification = @"GreeLocalNotificationDidReceiveNotification";

@implementation GreeLocalNotification

#pragma mark - Object Lifecycle
-(id)initWithSettings:(GreeSettings*)settings
{
  if ((self = [super init])) {

    self.localNotificationsEnabled = YES;

    if([settings settingHasValue:GreeSettingEnableLocalNotification]) {
      self.localNotificationsEnabled = [settings boolValueForSetting:GreeSettingEnableLocalNotification];
    }
  }

  return self;
}

-(void)dealloc
{
  [super dealloc];
}

#pragma mark - Public APIs

-(BOOL)registerLocalNotificationWithDictionary:(NSDictionary*)aDictionary
{

  if (!self.localNotificationsEnabled) {
    GreeLog(@"Local Notification feature has been disabled. Registration Cancelled.");
    return NO;
  }

  NSNumber* notifyId = [aDictionary objectForKey:@"notifyId"];

  // check for avoiding from duplicated registration
  [self cancelNotification:notifyId];

  Class localNotificationClass = NSClassFromString(@"UILocalNotification");
  if (localNotificationClass != nil) {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [aDictionary objectForKey:@"interval"];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = [aDictionary objectForKey:@"message"];
    localNotification.alertAction = GreePlatformString(@"localnotification.notice.view", @"View");
    localNotification.userInfo = aDictionary;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    [localNotification release];
  }

  return YES;

}

-(BOOL)cancelNotification:(NSNumber*)identifier
{
  UIApplication* application = [UIApplication sharedApplication];
  Class localNotificationClass = NSClassFromString(@"UILocalNotification");

  if (localNotificationClass != nil) {
    if (![application respondsToSelector:@selector(scheduledLocalNotifications)]) {
      return NO;
    }

    for (UILocalNotification* notification in application.scheduledLocalNotifications) {
      NSDictionary* userInfo = notification.userInfo;
      NSNumber* registeredIdentifier = [userInfo objectForKey:@"notifyId"];
      if ([registeredIdentifier intValue] == [identifier intValue]) {
        GreeLog(@"Cancelling registered notification: %@", [userInfo description]);
        [application cancelLocalNotification:notification];
      }
    }

    return YES;
  }
  return NO;
}

#pragma mark - Internal Methods
-(void)handleLocalNotification:(UILocalNotification*)aNotification application:(UIApplication*)application
{
  if (!aNotification) return;

  GreeLog(@"%s userInfo:%@", __FUNCTION__, aNotification.userInfo);

  if (!self.localNotificationsEnabled) {
    GreeLog(@"Local Notification feature has been disabled. Handler is cancelled.");
    return;
  }

  // notify to the user application
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeLocalNotificationDidReceiveNotification
                                                      object:nil
                                                    userInfo:aNotification.userInfo];
}

@end
