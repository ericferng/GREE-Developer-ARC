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

#import "GreeJSUpdateUserCommand.h"
#import "GreeUser.h"
#import "GreePlatform.h"
#import "GreeLogger.h"


@implementation GreeJSUpdateUserCommand
+(NSString*)name
{
  return @"update_user";
}

-(void)execute:(NSDictionary*)parameters
{
  __block id mySelf = self;
  [GreeUser loadUserWithId:@"@me" block:^(GreeUser* user, NSError* error) {
     NSString* resultString = nil;
     if (!error && user.userId) {
       resultString = @"success";
       [[GreePlatform sharedInstance] performSelector:@selector(updateLocalUser:) withObject:user];
     } else {
       resultString = @"error";
       GreeLog(@"UpdateUser error: %@", error.localizedDescription);
     }

     NSMutableDictionary* result = [NSMutableDictionary dictionaryWithDictionary:parameters];
     [result setObject:resultString forKey:@"result"];

     //this delay is needed for executing the callback of JavaScript normally.
     [mySelf performSelector:@selector(executeCallback:)
                  withObject:result
                  afterDelay:0.1f];
   }];
}
-(void)executeCallback:(NSDictionary*)parameters
{
  [[self.environment handler]
   callback:[parameters objectForKey:@"callback"]
     params:parameters];
  [self callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
