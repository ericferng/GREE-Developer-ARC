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


#import "GreeJSBatchCommand.h"
#import "GreeJSCommandFactory.h"

@implementation GreeJSBatchCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"batch";
}

-(void)execute:(NSDictionary*)params
{
  NSArray* commands = [params objectForKey:@"commands"];
  if (![commands isKindOfClass:[NSArray class]]) {
    NSLog(@"commands parameter of batch command should be an array");
    return;
  }

  for (NSDictionary* command in commands) {
    if (![command isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    NSString* name = [command objectForKey:@"command"];
    NSDictionary* params = [command objectForKey:@"params"];
    if  (params && ![params isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    id commandObject = [GreeJSCommandFactory createCommand:name withCommandMap:nil];
    if (commandObject) {
      [GreeJSHandler executeCommand:commandObject
                         parameters:params
                            handler:[self.environment handler]
                        environment:self.environment];
    }
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}
@end
