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

#import "GreeLogFileInformation.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

@interface GreeLogFileInformation ()
@end

@implementation GreeLogFileInformation

-(id)init
{
  self = [super init];
  if (self != nil) {
    self.fileId = [NSString string];
    self.filePath = [NSString string];
    self.additionalLogsFolder = [NSString string];
    self.fileLogLevel = 0;
    self.logToFile = NO;
    self.includeFileLineInfo = NO;
  }
  return self;
}

-(void)dealloc
{
  self.fileId = nil;
  self.filePath = nil;
  self.additionalLogsFolder = nil;
  [super dealloc];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
