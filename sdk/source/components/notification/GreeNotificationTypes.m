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

#import "GreeNotificationTypes+Internal.h"

NSTimeInterval const GreeNotificationInfiniteDuration = DBL_MAX;

NSString* NSStringFromGreeNotificationViewDisplayType(GreeNotificationViewDisplayType type)
{
  NSString* returnValue = nil;

  switch (type) {
  case GreeNotificationViewDisplayDefaultType:
    returnValue = @"GreeNotificationTypeDefaultType";
    break;
  case GreeNotificationViewDisplayCloseType:
    returnValue = @"GreeNotificationTypeCloseType";
    break;
  default:
    NSCAssert(YES, @"Passed NSStringFromGreeNotificationViewDisplayType an unknown display type");
    break;
  }

  return returnValue;
}

NSString* NSStringFromGreeNotificationDisplayPosition(GreeNotificationDisplayPosition position)
{
  NSString* returnValue = nil;

  switch (position) {
  case GreeNotificationDisplayTopPosition:
    returnValue = @"GreeNotificationDisplayTopPosition";
    break;
  case GreeNotificationDisplayBottomPosition:
    returnValue = @"GreeNotificationDisplayBottomPosition";
    break;
  default:
    NSCAssert(YES, @"Passed NSStringFromGreeNotificationDisplayPosition an unknown position");
    break;
  }

  return returnValue;
}

NSString* NSStringFromInterfaceOrientation(UIInterfaceOrientation interfaceOrientation)
{
  NSString* returnValue = nil;

  switch (interfaceOrientation) {
  case UIInterfaceOrientationLandscapeLeft:
    returnValue = @"UIInterfaceOrientationLandscapeLeft";
    break;
  case UIInterfaceOrientationLandscapeRight:
    returnValue = @"UIInterfaceOrientationLandscapeRight";
    break;
  case UIInterfaceOrientationPortrait:
    returnValue = @"UIInterfaceOrientationPortrait";
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
    returnValue = @"UIInterfaceOrientationPortraitUpsideDown";
    break;
  default:
    NSCAssert(YES, @"Passed NSStringFromInterfaceOrientation an unknown orientation");
    break;
  }

  return returnValue;
}


NSString* NSStringFromGreeNotificationSource(GreeNotificationSource type)
{
  NSString* returnValue = nil;

  switch (type) {
  case GreeNotificationSourceNone:
    returnValue = @"GreeNotificationSourceNone";
    break;
  case GreeNotificationSourceCustomMessage:
    returnValue = @"GreeNotificationSourceCustomMessage";
    break;
  case GreeNotificationSourceMyLogin:
    returnValue = @"GreeNotificationSourceMyLogin";
    break;
  case GreeNotificationSourceFriendLogin:
    returnValue = @"GreeNotificationSourceFriendLogin";
    break;
  case GreeNotificationSourceMyAchievementUnlocked:
    returnValue = @"GreeNotificationSourceMyAchievementUnlocked";
    break;
  case GreeNotificationSourceFriendAchievementUnlocked:
    returnValue = @"GreeNotificationSourceFriendAchievementUnlocked";
    break;
  case GreeNotificationSourceMyHighScore:
    returnValue = @"GreeNotificationSourceMyHighScore";
    break;
  case GreeNotificationSourceFriendHighScore:
    returnValue = @"GreeNotificationSourceFriendHighScore";
    break;
  case GreeNotificationSourceServiceMessage:
    returnValue = @"GreeNotificationSourceServiceMessage";
    break;
  case GreeNotificationSourceServiceRequest:
    returnValue = @"GreeNotificationSourceServiceRequest";
    break;
  default:
    NSCAssert(YES, @"Passed NSStringFromGreeNotificationSource an unknown source");
    break;
  }

  return returnValue;
}

NSString* NSStringFromGreeAPSNotificationIconType(GreeAPSNotificationIconType type)
{
  NSString* returnValue = nil;

  switch (type) {
  case GreeAPSNotificationIconGreeType:
    returnValue = @"GreeAPSNotificationIconGreeType";
    break;
  case GreeAPSNotificationIconApplicationType:
    returnValue = @"GreeAPSNotificationIconApplicationType";
    break;
  case GreeAPSNotificationIconDownloadType:
    returnValue = @"GreeAPSNotificationIconDownloadType";
    break;
  default:
    NSCAssert(YES, @"Passed NSStringFromGreeAPSNotificationIconType an unknown icon type");
    break;
  }

  return returnValue;
}
