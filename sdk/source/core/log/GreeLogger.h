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

#import <Foundation/Foundation.h>
#import "GreePlatform+Internal.h"
#import "GreePlatformSettings.h"


@interface GreeLogger : NSObject

@property (assign) BOOL includeFileLineInfo;
@property (assign) BOOL logToFile;
@property (assign) NSInteger level;
@property (retain) NSMutableArray* logfileInformationList;

-(void)log:(NSString*)message level:(NSInteger)level fromFile:(char const*)file atLine:(int)line, ...;
-(void)setLoggerParameters:(NSInteger)level includeFileLineInfo:(BOOL)includeFileLineInfo logToFile:(BOOL)logToFile folder:(NSString*)additionalLogsFolder;
-(NSString*)additionalLogFile:(NSInteger)level;
-(NSString*)stopWritingLogFile:(NSString*)logfileId;
-(NSString*)sendLogToUrl:(NSString*)logfileId url:(NSString*)url;
-(void)sendExceptionLog;

@end

#define GreeLogWithLevel(logLevel, message, ...) \
  [[[GreePlatform sharedInstance] logger] log : message level : logLevel fromFile : __FILE__ atLine : __LINE__, ## __VA_ARGS__];

#define GreeLogPublic(message, ...) GreeLogWithLevel([GreeLogLevelPublic integerValue], message, ## __VA_ARGS__)
#define GreeLogWarn(message, ...)   GreeLogWithLevel([GreeLogLevelWarn integerValue], message, ## __VA_ARGS__)
#define GreeLog(message, ...)       GreeLogWithLevel([GreeLogLevelInfo integerValue], message, ## __VA_ARGS__)
