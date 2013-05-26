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

#import "GreeLoggerExceptionHandler.h"
#import "NSString+GreeAdditions.h"
#import "GreeLogger.h"
#import "GreeLogFileInformation.h"
#import "GreeSettings.h"


@interface GreeLoggerExceptionHandler ()
void uncaughtException(NSException* pException);
void saveExceptionLog(char* pLog);
@end

@implementation GreeLoggerExceptionHandler

#pragma mark - Public Methods

+(void)setUncaughtExceptionHandler
{
  NSSetUncaughtExceptionHandler(&uncaughtException);
}

#pragma mark - Internal Methods

void uncaughtException(NSException* pException)
{
  NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  NSString* dateOfCreation = [dateFormat stringFromDate:[NSDate date]];
  [dateFormat release];

  NSString* reportDate = [NSString stringWithFormat:@"'date':'%@'", dateOfCreation];
  NSString* appId = [NSString stringWithFormat:@"'app_id':%@", [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId]];
  NSString* userId = [NSString stringWithFormat:@"'user_id':%@", [GreePlatform sharedInstance].localUserId];
  NSString* sdkVersion = [NSString stringWithFormat:@"'sdk_version':'%@'", [GreePlatform version]];
  NSString* crashReport = [NSString stringWithFormat:@"'crash_report':'%@'", pException];

  NSMutableString* tokStackTrace = [NSMutableString string];
  char* cStackTrace = (char*)[[[pException callStackSymbols] componentsJoinedByString:@","] UTF8String];
  [pException release];
  char* cTokStackTrace = strtok(cStackTrace, ",");
  while (cTokStackTrace != NULL) {
    [tokStackTrace appendFormat:@"'%@',", [NSString stringWithCString:cTokStackTrace encoding:NSUTF8StringEncoding]];
    cTokStackTrace = strtok(NULL, ",");
  }
  tokStackTrace = (NSMutableString*)[tokStackTrace substringToIndex:(tokStackTrace.length - 1)];
  NSString* stackTrace = [NSString stringWithFormat:@"'stack_trace':[%@]", tokStackTrace];

  NSMutableString* exceptionString = [NSMutableString stringWithFormat:@"{%@,%@,%@,%@,%@,%@}", reportDate, appId, userId, sdkVersion, crashReport, stackTrace];
  [exceptionString replaceOccurrencesOfString:@"'(null)'" withString:@"null" options:0 range:NSMakeRange(0, exceptionString.length)];

  char* pLog = (char*)[exceptionString UTF8String];
  saveExceptionLog(pLog);
}

void saveExceptionLog(char* pLog)
{
  NSString* exceptionLog = [NSString stringWithCString:pLog encoding:NSUTF8StringEncoding];
  NSString* filePath = [NSString greeLoggingPathForRelativePath:[NSString stringWithFormat:@"%@/%@", kGreeLoggerExceptionLogsFolderName, kGreeLoggerCrashReportFileName]];
  [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
  [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
  NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
  [fileHandle writeData:[exceptionLog dataUsingEncoding:NSUTF8StringEncoding]];
  [fileHandle closeFile];
}

#pragma mark - Object Lifecycle

-(void)dealloc
{
  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
