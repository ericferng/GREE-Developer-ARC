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

#import "GreeJSStopLogCommand.h"
#import "GreeLogger.h"
#import "GreeLogFileInformation.h"

@interface GreeJSStopLogCommand ()
@end

@implementation GreeJSStopLogCommand

+(NSString*)name
{
  return @"stop_log";
}

-(void)execute:(NSDictionary*)parameters
{
  id errorMessage = [NSNull null];
  NSString* inputFileId = [parameters objectForKey:@"logfile_id"];
  if (inputFileId.length == 0) {
    errorMessage = @"input value is null.";
    inputFileId = (NSString*)[NSNull null];
  } else {
    NSString* error = [[GreePlatform sharedInstance].logger stopWritingLogFile:inputFileId];
    if (error) {
      errorMessage = [NSString stringWithString:error];
    }
  }

  NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [results setObject:errorMessage forKey:@"error"];
  [results setObject:inputFileId forKey:@"logfile_id"];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:results forKey:@"result"];
  [[self.environment handler]
   callback:[parameters objectForKey:@"callback"]
     params:callbackParameters];

}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
