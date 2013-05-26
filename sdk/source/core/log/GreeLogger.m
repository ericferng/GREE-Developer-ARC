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

#import "GreeLogger.h"
#import "NSString+GreeAdditions.h"
#import "GreeLogFileInformation.h"
#import "GreePlatform.h"
#import "GreeSettings.h"
#import "GreeHTTPClient.h"
#import "GreeAuthorization.h"

@interface GreeLogger ()
-(void)deleteAdditionalLogsFolder:(NSString*)folderName;
-(NSString*)convertToJsonFormat:(NSString*)log;
-(void)sendLogToUrlWithParameters:(NSDictionary*)parameters;
-(BOOL)canSendLog;
-(void)saveSendLogTime;
@property (nonatomic, assign) NSInteger fileCount;
@end

@implementation GreeLogger

@synthesize logToFile = _logToFile;

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self != nil) {
    [self deleteAdditionalLogsFolder:kGreeLoggerAdditionalLogsFolderName];
    self.includeFileLineInfo = YES;
    self.fileCount = 0;
    self.logfileInformationList = [NSMutableArray array];
  }

  return self;
}

-(void)dealloc
{
  self.logfileInformationList = nil;
  [super dealloc];
}

#pragma mark - Public Interface

-(void)log:(NSString*)message level:(NSInteger)level fromFile:(char const*)file atLine:(int)line, ...
{
  if (0 < self.logfileInformationList.count) {
    NSMutableString* prefix = [[NSMutableString alloc] initWithCapacity:64];
    [prefix appendString:@"[Gree]"];

    if (self.includeFileLineInfo) {
      NSString* fileString = [[NSString alloc] initWithUTF8String:file];
      [prefix appendFormat:@"[%@:%d] ", [fileString lastPathComponent], line];
      [fileString release];
    }

    va_list args;
    va_start(args, line);
    NSString* formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);

    NSString* finalString = [[NSString alloc] initWithFormat:@"%@ %@", prefix, formattedMessage];
    for (int count = 0; count < self.logfileInformationList.count; count++) {
      GreeLogFileInformation* information = [self.logfileInformationList objectAtIndex:count];
      if (information.fileLogLevel >= level) {
        if (count == 0) {
          NSLog(@"%@", finalString);
        }
        if (information.logToFile) {
          NSString* filePath = information.filePath;
          if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSString* withNewline = [NSString stringWithFormat:@"'%@',", finalString];
            withNewline = [withNewline stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[withNewline dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
          }
        }
      }
    }

    [finalString release];
    [formattedMessage release];
    [prefix release];
  }
}

-(BOOL)logToFile
{
  return _logToFile;
}

-(void)setLogToFile:(BOOL)logToFile
{
  _logToFile = logToFile;

  if (logToFile) {
    self.fileCount++;
  }
}

-(void)deleteAdditionalLogsFolder:(NSString*)folderName
{
  NSString* folderPath = [NSString greeLoggingPathForRelativePath:folderName];
  if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
    [[NSFileManager defaultManager] removeItemAtPath:folderPath error:nil];
  }
}

-(void)setLoggerParameters:(NSInteger)level includeFileLineInfo:(BOOL)includeFileLineInfo logToFile:(BOOL)logToFile folder:(NSString*)additionalLogsFolder
{
  @synchronized(self) {
    GreeLogFileInformation* information = [[GreeLogFileInformation alloc] init];
    if (additionalLogsFolder) {
      information.additionalLogsFolder = additionalLogsFolder;
    }
    information.fileLogLevel = level;
    information.includeFileLineInfo = includeFileLineInfo;
    information.logToFile = logToFile;
    if (logToFile) {
      NSString* fileName = [NSString stringWithFormat:@"Log %@", [NSDate date]];
      fileName = [fileName stringByReplacingOccurrencesOfString:@":" withString:@"."];
      NSString* folderName = [NSString stringWithFormat:@"%@", information.additionalLogsFolder];
      if (0 < folderName.length) {
        fileName = [folderName stringByAppendingFormat:@"/%@", fileName];
      }
      NSString* filePath = [NSString greeLoggingPathForRelativePath:fileName];
      [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
      [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];

      information.filePath = [NSString stringWithFormat:@"%@", filePath];
      information.fileId = [NSString stringWithFormat:@"logfile_id+%d", self.fileCount];
    }
    [self.logfileInformationList addObject:information];
    [information release];
    self.level = level;
    self.includeFileLineInfo = includeFileLineInfo;
    self.logToFile = logToFile;
  }
}

-(NSString*)additionalLogFile:(NSInteger)level
{
  NSString* fileId = nil;
  if(self.fileCount < 3) {
    [self setLoggerParameters:level includeFileLineInfo:YES logToFile:YES folder:kGreeLoggerAdditionalLogsFolderName];
    GreeLogFileInformation* information = [self.logfileInformationList lastObject];
    fileId = information.fileId;
  }
  return fileId;
}

-(NSString*)stopWritingLogFile:(NSString*)logfileId
{
  NSString* errorMessage = nil;
  if (0 < self.logfileInformationList.count) {
    for (GreeLogFileInformation* information in self.logfileInformationList) {
      if ([information.fileId isEqualToString:logfileId]) {
        information.logToFile = NO;
        errorMessage = nil;
        break;
      } else {
        errorMessage = @"input logfile_id does not exist.";
      }
    }
  } else {
    errorMessage = @"logfile_id list is null.";
  }
  return errorMessage;
}

-(NSString*)sendLogToUrl:(NSString*)logfileId url:(NSString*)url
{
  NSString* errorMessage = nil;

  if (0 < self.logfileInformationList.count) {
    for (GreeLogFileInformation* information in self.logfileInformationList) {
      if ([information.fileId isEqualToString:logfileId]) {
        if (0 < information.filePath.length) {
          if ([[NSFileManager defaultManager] fileExistsAtPath:information.filePath]) {

            NSData* data = [[[NSData alloc] initWithContentsOfFile:information.filePath] autorelease];
            NSString* logs = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            NSString* logsJson = [self convertToJsonFormat:logs];
            NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                        url, kGreeLoggerSendToUrlKey,
                                        logsJson, kGreeLoggerJsonFormatLogsKey,
                                        nil];
            [self sendLogToUrlWithParameters:parameters];
            errorMessage = nil;
            break;

          } else {
            errorMessage = @"logfile does not exist into the device.";
          }
        } else {
          errorMessage = @"path of logfile does not exist.";
        }
      } else {
        errorMessage = @"logfile_id does not exist into the device.";
      }
    }
  } else {
    errorMessage = @"logfile_id list is null.";
  }
  return errorMessage;
}

-(NSString*)convertToJsonFormat:(NSString*)log
{
  NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  NSString* dateOfCreation = [dateFormat stringFromDate:[NSDate date]];
  [dateFormat release];
  NSString* reportDate = [NSString stringWithFormat:@"'date':'%@'", dateOfCreation];
  NSString* appId = [NSString stringWithFormat:@"'app_id':%@", [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId]];
  NSString* userId = [NSString stringWithFormat:@"'user_id':%@", [GreePlatform sharedInstance].localUserId];
  NSString* sdkVersion = [NSString stringWithFormat:@"'sdk_version':'%@'", [GreePlatform version]];
  NSString* finalReport = [NSString stringWithString:log];
  finalReport = [finalReport substringToIndex:finalReport.length - 1];
  finalReport = [NSString stringWithFormat:@"report:[%@]", finalReport];
  NSString* logsJsonFormat = [NSString stringWithFormat:@"{%@,%@,%@,%@,%@}", reportDate, appId, userId, sdkVersion, finalReport];
  logsJsonFormat = [logsJsonFormat stringByReplacingOccurrencesOfString:@"(null)" withString:@"null"];
  return logsJsonFormat;
}

-(void)sendLogToUrlWithParameters:(NSDictionary*)parameters
{
  NSString* logs = [parameters objectForKey:kGreeLoggerJsonFormatLogsKey];
  NSString* url = [parameters objectForKey:kGreeLoggerSendToUrlKey];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                   [[GreePlatform sharedInstance].httpClient
                    performTwoLeggedRequestWithMethod:@"POST"
                                                 path:url
                                           parameters:[NSDictionary dictionaryWithObject:logs forKey:@"logs"]
                                              success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
                      [self deleteAdditionalLogsFolder:kGreeLoggerExceptionLogsFolderName];
                      [self saveSendLogTime];
                      return;
                    }
                                              failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
                      return;
                    }];
                 });
}

-(void)sendExceptionLog
{
  NSString* filePath = [NSString greeLoggingPathForRelativePath:[NSString stringWithFormat:@"%@/%@", kGreeLoggerExceptionLogsFolderName, kGreeLoggerCrashReportFileName]];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    NSData* data = [[[NSData alloc] initWithContentsOfFile:filePath] autorelease];
    NSString* crashLogs = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    NSString* appId = [NSString stringWithFormat:@"%@", [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId]];
    NSString* userId = [NSString stringWithFormat:@"%@", [GreePlatform sharedInstance].localUserId];
    NSString* url = [NSString stringWithFormat:@"/api/rest/sdklog/fatal/%@/%@", appId, userId];

    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                crashLogs, kGreeLoggerJsonFormatLogsKey,
                                url, kGreeLoggerSendToUrlKey,
                                nil];
    if ([self canSendLog]) {
      [self sendLogToUrlWithParameters:parameters];
    }
  }
}

-(BOOL)canSendLog
{
  NSUserDefaults* sendData = [NSUserDefaults standardUserDefaults];
  NSString* sendTimeString = [sendData stringForKey:kGreeLoggerCrashReportSendTimeKey];
  if (sendTimeString) {
    NSDate* currentTime = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone] secondsFromGMT]];
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZZ"];
    NSDate* sendTime = [dateFormat dateFromString:sendTimeString];
    [dateFormat release];
    double differenceTime = [currentTime timeIntervalSinceDate:sendTime] / (60 * 60);
    return (differenceTime <= 24.0f) ? NO : YES;
  }
  return YES;
}

-(void)saveSendLogTime
{
  NSDate* date = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone] secondsFromGMT]];
  NSString* dateString = date.description;
  NSUserDefaults* saveData = [NSUserDefaults standardUserDefaults];
  [saveData setObject:dateString forKey:kGreeLoggerCrashReportSendTimeKey];
  [saveData synchronize];
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, level:%d, includeFileLineInfo:%@>",
          NSStringFromClass([self class]),
          self,
          self.level,
          self.includeFileLineInfo ? @"YES": @"NO"];
}

@end
