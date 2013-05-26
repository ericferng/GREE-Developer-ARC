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


#import "GreeBenchmark.h"
#import "GreePlatform+Internal.h"
#import "NSString+GreeAdditions.h"
#import <mach/mach.h>

#pragma mark - GreeBenchmark

NSString* const kGreeBenchmarkLogPath = @"performance/";


@interface GreeBenchmark ()
@property (nonatomic, retain) NSMutableDictionary* flowIndexs;
@property (nonatomic, retain) GreeBenchmarkMapping* benchmarkMapping;
-(void)saveToLogFile:(NSArray*)flow;
-(void)checkBeforeNextWithKeyName:(NSString*)keyName pointName:(NSString*)pointName pointRole:(GreeBenchmarkPointRole)pointRole;
-(void)checkAfterNextWithKeyName:(NSString*)keyName pointName:(NSString*)pointName pointRole:(GreeBenchmarkPointRole)pointRole;
-(NSString*)convertTimeFormatWithAbsoluteTime:(CFAbsoluteTime)absoluteTime;
-(NSUInteger)getMemoryUsage;
@end

@implementation GreeBenchmark

#pragma mark - Object Life Cycle

-(void)dealloc
{
  self.allResult = nil;
  self.flowIndexs = nil;
  self.benchmarkMapping = nil;

  [super dealloc];
}

-(id)init
{
  if ((self = [super init])) {
    self.allResult = [NSMutableDictionary dictionary];
    self.flowIndexs = [NSMutableDictionary dictionary];
    self.benchmarkMapping = [[[GreeBenchmarkMapping alloc] init] autorelease];
  }
  return self;
}

#pragma mark - public

+(id)benchmark
{
  return [[[GreeBenchmark alloc] init] autorelease];
}

-(void)registerWithKey:(NSString*)keyName position:(NSString*)position
{
  [self registerWithKey:keyName position:position pointRole:0 pointTime:CFAbsoluteTimeGetCurrent()];
}

-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole
{
  [self registerWithKey:keyName position:position pointRole:pointRole pointTime:CFAbsoluteTimeGetCurrent()];
}

-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointTime:(CFAbsoluteTime)pointTime
{
  [self registerWithKey:keyName position:position pointRole:0 pointTime:pointTime];
}

-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole pointTime:(CFAbsoluteTime)pointTime
{
  @synchronized(self) {
    NSArray* positionArray = [position componentsSeparatedByString:@":"];
    NSString* pointName = [positionArray objectAtIndex:0];
    NSString* indexKeyName = keyName;

    if ([keyName isEqualToString:kGreeBenchmarkOs]
        || [keyName isEqualToString:kGreeBenchmarkOpen]
        || [keyName isEqualToString:kGreeBenchmarkPaymentApi]
        || [keyName isEqualToString:kGreeBenchmarkApiUsage]) {
      NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+)(Get|Post|Put|Delete|Load|Enumerator).+" options:0 error:nil];
      NSTextCheckingResult* match = [regex firstMatchInString:pointName options:0 range:NSMakeRange(0, [pointName length])];
      if (match) {
        indexKeyName = [keyName stringByAppendingString:[pointName substringWithRange:[match rangeAtIndex:1]]];
      }
    }

    [self checkBeforeNextWithKeyName:indexKeyName pointName:pointName pointRole:pointRole];

    //self.allResult -> flowBundle -> flow (get with flowIndex) -> profile
    NSMutableArray* flowBundle = [self.allResult objectForKey:indexKeyName];
    if (!flowBundle) {
      flowBundle = [NSMutableArray array];
      [flowBundle addObject:[NSMutableArray array]];
      [self.flowIndexs setObject:[NSNumber numberWithInt:0] forKey:indexKeyName];
    }
    NSNumber* flowIndex = [self.flowIndexs objectForKey:indexKeyName];
    if ([flowIndex intValue] == [flowBundle count]) {
      [flowBundle addObject:[NSMutableArray array]];
    }
    NSMutableArray* flow = [flowBundle objectAtIndex:[flowIndex intValue]];

    //with point role
    if (pointRole) {
      if([flow count] == 0 && pointRole == GreeBenchmarkPointRoleEnd) {
        return;
      }
    }

    //exclude the serial same point profile
    if ([flow count] > 0) {
      GreeBenchmarkProfile* beforeProfile = [flow objectAtIndex:([flow count] - 1)];
      if ([beforeProfile.keyName isEqualToString:indexKeyName]
          && [beforeProfile.pointName isEqualToString:pointName]) {
        return;
      }
    }

    //for the parallel access of badge and image
    if ([pointName hasPrefix:@"badge"] || [pointName hasPrefix:@"image"] || [pointName hasPrefix:@"sgpRanking"]) {
      if ([flow count] == 0 && ![pointName hasSuffix:@"Start"]) {
        return;
      }
    }

    GreeBenchmarkProfile* profile = [[[GreeBenchmarkProfile alloc] init] autorelease];
    profile.keyName = indexKeyName;
    profile.flowName = keyName;
    profile.pointTime = pointTime;
    profile.position = position;
    profile.pointName = pointName;
    profile.index = [flow count];
    profile.count = [flowBundle count];
    profile.reachabilityStatus = [GreePlatform sharedInstance].reachability.status;
    profile.memoryUsage = [self getMemoryUsage];

    [flow addObject:profile];
    [self.allResult setObject:flowBundle forKey:profile.keyName];

    [self checkAfterNextWithKeyName:indexKeyName pointName:pointName pointRole:pointRole];
  }
}

-(void)nextWithKey:(NSString*)keyName
{
  @synchronized(self) {
    NSMutableArray* flowBundle = [self.allResult objectForKey:keyName];
    NSNumber* flowIndex = [self.flowIndexs objectForKey:keyName];

    if ([flowIndex intValue] < [flowBundle count]) {
      [self saveToLogFile:[flowBundle objectAtIndex:[flowIndex intValue]]];
      [flowBundle replaceObjectAtIndex:[flowIndex intValue] withObject:[NSNull null]];
      [self.flowIndexs setObject:[NSNumber numberWithInt:([flowIndex intValue] + 1)] forKey:keyName];
    }
  }
}

-(void)finish
{
  [self.allResult enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop){
     [self finishWithKey:key];
   }];
}

-(void)finishWithKey:(NSString*)keyName
{
  NSMutableArray* flowBundle = [self.allResult objectForKey:keyName];

  [flowBundle enumerateObjectsUsingBlock:^(id flowObj, NSUInteger flowIdx, BOOL* flowStop){

     CFAbsoluteTime startTime = ((GreeBenchmarkProfile*)[(NSMutableArray*) flowObj objectAtIndex:0]).pointTime;
     __block CFAbsoluteTime beforeTime = startTime;

     [((NSMutableArray*)flowObj) enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        GreeBenchmarkProfile* profile = ((GreeBenchmarkProfile*)obj);
        profile.diffTime = profile.pointTime - beforeTime;
        profile.totalTime = profile.pointTime - startTime;
        beforeTime = profile.pointTime;
      }];
   }];
}

# pragma mark - private

-(void)checkBeforeNextWithKeyName:(NSString*)keyName pointName:(NSString*)pointName pointRole:(GreeBenchmarkPointRole)pointRole
{
  if ([pointName isEqualToString:kGreeBenchmarkPopupStart]
      || [pointName isEqualToString:@"dashboardStart"]) {
    [self nextWithKey:keyName];

  } else if ([keyName hasPrefix:kGreeBenchmarkOs]
             || [keyName hasPrefix:kGreeBenchmarkOpen]
             || [keyName hasPrefix:kGreeBenchmarkPaymentApi]) {

    if ([pointName isEqualToString:@"badgeGetStart"]
        || [pointName isEqualToString:@"imageGetStart"]
        || [pointName isEqualToString:@"sgpRankingGetStart"]) {
      return; // parallel access case
    }
    if ([pointName hasSuffix:@"Start"]) {
      [self nextWithKey:keyName];
    }
  } else if (pointRole == GreeBenchmarkPointRoleStart) {
    [self nextWithKey:keyName];
  }
}

-(void)checkAfterNextWithKeyName:(NSString*)keyName pointName:(NSString*)pointName pointRole:(GreeBenchmarkPointRole)pointRole
{
  if ([keyName hasPrefix:kGreeBenchmarkOpen]
      || [keyName hasPrefix:kGreeBenchmarkPaymentApi]) {

    if ([pointName hasSuffix:@"Error"]
        || [pointName hasSuffix:@"End"]) {
      [self nextWithKey:keyName];
    }

  } else if ([pointName hasSuffix:kGreeBenchmarkDismiss]) {
    [self nextWithKey:keyName];

  } else if ([keyName isEqualToString:kGreeBenchmarkLogout]
             && [pointName isEqualToString:kGreeBenchmarkPostStart]) {
    [self nextWithKey:keyName];
  } else if (pointRole == GreeBenchmarkPointRoleEnd) {
    [self nextWithKey:keyName];
  }
}

-(NSString*)convertTimeFormatWithAbsoluteTime:(CFAbsoluteTime)absoluteTime
{
  NSString* formatTime = nil;
  CFDateFormatterRef formatter = CFDateFormatterCreate(NULL, NULL, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
  CFDateFormatterSetFormat(formatter, CFSTR("YYYY/MM/dd HH:mm:ss.SSS"));
  formatTime = [((NSString*)CFDateFormatterCreateStringWithAbsoluteTime(NULL, formatter, absoluteTime))autorelease];
  CFRelease(formatter);

  return formatTime;
}

-(void)saveToLogFile:(NSArray*)flow
{
  NSDate* date = [NSDate date];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"YYYYMMdd"];
  NSString* dateTime = [formatter stringFromDate:date];
  [formatter release];
  NSString* logPath = [NSString stringWithFormat:@"%@log.performance.%@", kGreeBenchmarkLogPath, dateTime];
  NSString* filePath = [NSString greeLoggingPathForRelativePath:logPath];

  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
  }
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    __block NSMutableString* flowLogString = [NSMutableString string];
    [flow enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
       GreeBenchmarkProfile* profile = (GreeBenchmarkProfile*)obj;

       //for debug
//      NSString *lineString = [NSString stringWithFormat:@"%@, %@, %d, %@, %@, %@\n",
//        profile.keyName, profile.pointName, profile.count, [self convertTimeFormatWithAbsoluteTime:profile.pointTime], NSStringFromGreeNetworkReachabilityStatus(profile.reachabilityStatus), profile.position];
//      [flowLogString appendString:lineString];

       if ([profile.keyName isEqualToString:kGreeBenchmarkPayment]
           && [profile.pointName isEqualToString:kGreeBenchmarkDismiss]) {
         return;
       }
       NSString* milliseconds = [NSString stringWithFormat:@"%.0f", (profile.pointTime + kCFAbsoluteTimeIntervalSince1970)*1000];
       NSString* line = [NSString stringWithFormat:@"%@, %@, %d, %@, %d, %d\n",
                         [self.benchmarkMapping convertFlowIndexWithFlowName:profile.flowName],
                         [self.benchmarkMapping convertPointIndexWithFlowName:profile.flowName pointName:profile.pointName],
                         profile.count, milliseconds, profile.reachabilityStatus, profile.memoryUsage];
       [flowLogString appendString:line];
     }];

    NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (fileHandle) {
      [fileHandle seekToEndOfFile];
      [fileHandle writeData:[flowLogString dataUsingEncoding:NSUTF8StringEncoding]];
      [fileHandle closeFile];
    }
  }
}

-(NSUInteger)getMemoryUsage
{
  NSInteger memoryUsage = 0;
  vm_size_t residentSize = 0;

  struct task_basic_info t_info;
  mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
  if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count) == KERN_SUCCESS) {
    residentSize = t_info.resident_size;
    memoryUsage = (NSUInteger)(residentSize / 1024);
  }

  return memoryUsage;
}

+(NSString*)pointNamePrefix:(NSString*)path
{
  if (!path) return nil;

  NSString* slashTruncatedPath = [path stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
  NSString* prefix = nil;

  if ([slashTruncatedPath hasPrefix:@"api/rest/people"]) {
    prefix = @"people";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/ignorelist"]) {
    prefix = @"ignoreList";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/sgpscore"]) {
    prefix = @"sgpScore";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/sgpranking"]) {
    prefix = @"sgpRanking";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/sgpleaderboard"]) {
    prefix = @"sgpLeaderboard";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/sgpachievement"]) {
    prefix = @"sgpAchievement";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/touchsession"]) {
    prefix = @"touchSession";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/badge"]) {
    prefix = @"badge";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/sdkbootstrap"]) {
    prefix = @"sdkbootstrap";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/moderation"]) {
    prefix = @"moderation";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/friendcode"]) {
    prefix = @"friendcode";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/product/entries"]) {
    prefix = @"productEntries";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/userstatus"]) {
    prefix = @"userStatus";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/product/transaction"]) {
    prefix = @"productTransactionCommit";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/balance"]) {
    prefix = @"balance";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/price"]) {
    prefix = @"price";
  } else if ([slashTruncatedPath hasPrefix:@"api/rest/register"]) {
    prefix = @"register";
  }
  return prefix;
}

-(void)benchmarkWithParameters:(NSString*)method path:(NSString*)path position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole;
{
  if (![GreePlatform sharedInstance].benchmark) {
    return;
  }
  NSString* pointNamePrefix = [GreeBenchmark pointNamePrefix:path];
  if (pointNamePrefix) {
    NSString* pointName = [NSString stringWithFormat:@"%@%@%@", pointNamePrefix, [method capitalizedString], position];
    [self registerWithKey:kGreeBenchmarkOs position:GreeBenchmarkPosition(pointName) pointRole:pointRole];
  }
}

@end
