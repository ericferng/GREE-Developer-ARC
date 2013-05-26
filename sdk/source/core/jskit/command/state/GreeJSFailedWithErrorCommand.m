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

#import "GreeJSFailedWithErrorCommand.h"
#import "GreeJSWebViewController.h"

@implementation GreeJSFailedWithErrorCommand
+(NSString*)name
{
  return @"failed_with_error";
}

-(void)execute:(NSDictionary*)params
{

  self.delegate = [self.environment instanceOfProtocol:@protocol(GreeJSStateCommandDelegate)];

  if ([self.delegate respondsToSelector:@selector(stateCommandFailedWithError:)]) {
    id errorInfo = [params valueForKey:@"error"];
    if ([errorInfo isKindOfClass:[NSDictionary class]]) {
      [self.delegate stateCommandFailedWithError:[NSError errorWithDomain:@"GreeJSCommandError" code:0 userInfo:errorInfo]];
    } else {
      [self.delegate stateCommandFailedWithError:nil];
    }
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
