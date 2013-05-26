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

#import "GreeGlobalization.h"
#import "GreeNotificationTableViewCellLabel.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "GreeNotificationMessage.h"
#import "GreeNotificationFeed.h"

@interface GreeNotificationTableViewCellLabel ()
+(NSString*)localizeHours:(NSInteger)hour;
+(NSString*)localizeWeekdays:(NSInteger)day;
+(NSString*)localizeMonths:(NSInteger)month;
@end

static NSString* const kTextKey = @"text";
static NSString* const kFontKey = @"font";
static NSString* const kBoldKey = @"bold";
static NSString* const kColorKey = @"color";
static NSString* const kColorRedKey = @"r";
static NSString* const kColorGreenKey = @"g";
static NSString* const kColorBlueKey = @"b";
static NSString* const kTrueValue = @"true";
static NSString* const kFalseValue = @"false";

static NSDateFormatter* CurrentDateFormatter = nil;
static NSString* CurrentLaungage = nil;
static NSString* CurrentLocaleIdentifier = nil;
static NSString* CurrentTimeZoneName = nil;

static double const kMinute = 60.0;
static double const kHour = kMinute * 60.0;
static double const kDay = kHour * 24.0;

@implementation GreeNotificationMessage

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}


#pragma mark - Public Interface

+(void)decorateMessage:(NSString*)message data:(NSDictionary*)data label:(GreeNotificationTableViewCellLabel*)label
{

  int currentPosition = 0;
  NSError* error   = nil;

  NSRegularExpression* regexp = [NSRegularExpression
                                 regularExpressionWithPattern:@"\\{[^{]+?\\}"
                                                      options:0
                                                        error:&error];

  NSArray* reqResult = [regexp matchesInString:message options:0 range:NSMakeRange(0, message.length)];

  for ( int i = 0; i < [reqResult count]; i++ ) {
    NSTextCheckingResult* match = [reqResult objectAtIndex: i];

    if (match != nil ) {
      NSRange matchRange = [match range];

      if(currentPosition < matchRange.location) {
        NSString* preStr = [message substringWithRange:NSMakeRange(currentPosition, matchRange.location - currentPosition)];
        [label addStringWithAttribute:preStr font:nil color:nil];
      }

      NSString* key = [message substringWithRange:NSMakeRange(matchRange.location+1, matchRange.length-2)];

      GreeNotificationMessageData* messageData = (GreeNotificationMessageData*)[data objectForKey:key];
      if (messageData) {

        if(messageData.text != nil && ![messageData.text isEqualToString:@""]) {
          UIFont* decoFont;
          if(messageData.bold) {
            decoFont = [UIFont boldSystemFontOfSize:label.font.pointSize];
          } else {
            decoFont = [label font];
          }
          [label addStringWithAttribute:messageData.text font:decoFont color:messageData.color];
        } else {
          NSString* matchStr = [message substringWithRange:NSMakeRange(matchRange.location, matchRange.length)];
          [label addStringWithAttribute:matchStr font:nil color:nil];
        }
      } else {
        NSString* matchStr = [message substringWithRange:NSMakeRange(matchRange.location, matchRange.length)];
        [label addStringWithAttribute:matchStr font:nil color:nil];
      }
      currentPosition = matchRange.location + matchRange.length;
    }
  }

  if (currentPosition < message.length) {
    int lastStrCount = message.length - currentPosition;
    NSString* lastStr = [message substringWithRange:NSMakeRange(currentPosition, lastStrCount)];
    [label addStringWithAttribute:lastStr font:nil color:nil];
  }
}

+(NSString*)createTimeMessage:(NSDate*)notificationDate
{
  NSString* message = @"";
  NSCalendar* currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDate* currentDate = [NSDate date];
  NSCalendarUnit outPutStrUnit = NSYearCalendarUnit |
                                 NSMonthCalendarUnit |
                                 NSDayCalendarUnit |
                                 NSHourCalendarUnit |
                                 NSMinuteCalendarUnit |
                                 NSWeekdayCalendarUnit;

  NSCalendarUnit diffUnit = NSYearCalendarUnit |
                            NSMonthCalendarUnit |
                            NSDayCalendarUnit;

  NSDateComponents* notificationDateComponents = [currentCalendar components:outPutStrUnit fromDate:notificationDate];
  NSDateComponents* diffNotificationDateComponents = [currentCalendar components:diffUnit fromDate:notificationDate];
  NSDateComponents* diffCurrentDateComponents = [currentCalendar components:diffUnit fromDate:currentDate];
  NSInteger diffYearCount = [diffCurrentDateComponents year] - [diffNotificationDateComponents year];

  NSDate* diffNotificationDay = [currentCalendar dateFromComponents:diffNotificationDateComponents];
  NSDate* currentDay = [currentCalendar dateFromComponents:diffCurrentDateComponents];
  NSDateComponents* diffDateComponents = [currentCalendar components:NSDayCalendarUnit fromDate:diffNotificationDay toDate:currentDay options:0];
  NSInteger diffDayCount = [diffDateComponents day];

  NSTimeInterval interval = [currentDate timeIntervalSinceDate:notificationDate];
  double seconds = (double)interval;

  if (seconds < 0) {
    seconds = 0;
  }

  BOOL initFlag = NO;
  NSTimeZone* timeZone = [NSTimeZone localTimeZone];
  NSLocale* locale = [NSLocale currentLocale];
  NSArray* laungages = [NSLocale preferredLanguages];

  if (!CurrentDateFormatter) {
    initFlag = YES;
  } else {
    if (![CurrentTimeZoneName isEqualToString:timeZone.name]) {
      initFlag = YES;
    }
    if (![CurrentLaungage isEqualToString:[laungages objectAtIndex:0]]) {
      initFlag = YES;
    }
    if (![CurrentLocaleIdentifier isEqualToString:locale.localeIdentifier]) {
      initFlag = YES;
    }
  }

  if (initFlag) {
    CurrentTimeZoneName = timeZone.name;
    CurrentLocaleIdentifier = locale.localeIdentifier;
    if(CurrentLaungage) {
      [CurrentLaungage release];
    }
    CurrentLaungage = [[laungages objectAtIndex:0] copy];

    CurrentDateFormatter = [[NSDateFormatter alloc] init];
    [CurrentDateFormatter setTimeZone:timeZone];
    [CurrentDateFormatter setLocale:locale];
    [CurrentDateFormatter setDateFormat:@"mm"];
  }

  NSString* minuitesStr = [CurrentDateFormatter stringFromDate:notificationDate];
  NSString* monthStr = [GreeNotificationMessage localizeMonths:[notificationDateComponents month]];
  NSString* dayStr = [[NSString alloc] initWithFormat:@"%d", [notificationDateComponents day]];
  NSString* yearStr = [[NSString alloc] initWithFormat:@"%d", [notificationDateComponents year]];
  NSString* weekdayStr = [GreeNotificationMessage localizeWeekdays:[notificationDateComponents weekday]];
  NSString* hourStr = [GreeNotificationMessage localizeHours:[notificationDateComponents hour]];

  if (seconds <= 0) {

  } else if (seconds < kMinute) {
    message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Just_now", @"Just now");
  } else if (seconds < kHour) {
    int diffMinutes = (int)floor(interval/kMinute);
    NSString* diffMinutesStr = [[NSString alloc] initWithFormat:@"%d", diffMinutes];
    message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Minutes_age", @"%@ minutes ago");
    message = [NSString stringWithFormat:message, diffMinutesStr];
    [diffMinutesStr release];
  } else if (diffDayCount == 0) {
    int diffHours = (int)floor(interval/kHour);
    NSString* diffHoursStr = [[NSString alloc] initWithFormat:@"%d", diffHours];
    message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Hours_ago", @"%@ hours ago");
    message = [NSString stringWithFormat:message, diffHoursStr];
    [diffHoursStr release];
  } else if (diffDayCount == 1) {
    if ([notificationDateComponents hour] >= 0 && [notificationDateComponents hour] <= 11) {
      message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Yesterday_am", @"Yesterday at %@:%@am");
    } else {
      message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Yesterday_pm", @"Yesterday at %@:%@pm");
    }

    message = [NSString stringWithFormat:message, hourStr, minuitesStr];

  } else if (diffDayCount == 2) {
    if ([notificationDateComponents hour] >= 0 && [notificationDateComponents hour] <= 11) {
      message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Day_am", @"%@ at %@:%@am");
    } else {
      message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Day_pm", @"%@ at %@:%@pm");
    }

    message = [NSString stringWithFormat:message, weekdayStr, hourStr, minuitesStr];

  } else if (diffDayCount >= 3 && diffYearCount == 0) {
    message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Monthly_at", @"%1$@ %2$@");
    message = [NSString stringWithFormat:message, monthStr, dayStr];
  } else if (diffYearCount >= 1) {
    message = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Dateformat.Different_year", @"%1$@ %2$@,%3$@");
    message = [NSString stringWithFormat:message, monthStr, dayStr, yearStr];
  }
  [currentCalendar release];
  [dayStr release];
  [yearStr release];

  return message;
}

#pragma mark - Internal Methods

+(NSString*)localizeHours:(NSInteger)hour
{
  NSString* hoursStr = @"";

  switch (hour) {
  case 0:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Twelve_am", @"12");
    break;
  case 1:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.One_am", @"1");
    break;
  case 2:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Two_am", @"2");
    break;
  case 3:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Three_am", @"3");
    break;
  case 4:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Four_am", @"4");
    break;
  case 5:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Five_am", @"5");
    break;
  case 6:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Six_am", @"6");
    break;
  case 7:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Seven_am", @"7");
    break;
  case 8:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Eight_am", @"8");
    break;
  case 9:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Nine_am", @"9");
    break;
  case 10:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Ten_am", @"10");
    break;
  case 11:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Eleven_am", @"11");
    break;
  case 12:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Twelve_pm", @"12");
    break;
  case 13:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.One_pm", @"1");
    break;
  case 14:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Two_pm", @"2");
    break;
  case 15:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Three_pm", @"3");
    break;
  case 16:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Four_pm", @"4");
    break;
  case 17:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Five_pm", @"5");
    break;
  case 18:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Six_pm", @"6");
    break;
  case 19:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Seven_pm", @"7");
    break;
  case 20:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Eight_pm", @"8");
    break;
  case 21:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Nine_pm", @"9");
    break;
  case 22:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Ten_pm", @"10");
    break;
  case 23:
    hoursStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Eleven_pm", @"11");
    break;
  default:
    break;
  }

  return hoursStr;
}

+(NSString*)localizeWeekdays:(NSInteger)weekday
{
  NSString* weekdayStr = @"";

  switch (weekday) {
  case 1:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Sunday", @"Sunday");
    break;
  case 2:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Monday", @"Monday");
    break;
  case 3:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Tuesday", @"Thuesday");
    break;
  case 4:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Wednesday", @"Wednesday");
    break;
  case 5:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Thursday", @"Thursday");
    break;
  case 6:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Friday", @"Friday");
    break;
  case 7:
    weekdayStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.Saturday", @"Saturday");
    break;
  default:
    break;
  }

  return weekdayStr;
}

+(NSString*)localizeMonths:(NSInteger)month
{
  NSString* monthStr = @"";

  switch (month) {
  case 1:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.January", @"Jan");
    break;
  case 2:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.February", @"Feb");
    break;
  case 3:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.March", @"Mar");
    break;
  case 4:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.April", @"Apr");
    break;
  case 5:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.May", @"May");
    break;
  case 6:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.June", @"Jun");
    break;
  case 7:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.July", @"Jul");
    break;
  case 8:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.August", @"Aug");
    break;
  case 9:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.September", @"Sep");
    break;
  case 10:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.October", @"Oct");
    break;
  case 11:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.November", @"Nov");
    break;
  case 12:
    monthStr = GreePlatformString(@"core.NotificationBoard.NotificationMessage.December", @"Dec");
    break;
  default:
    break;
  }

  return monthStr;
}

@end
