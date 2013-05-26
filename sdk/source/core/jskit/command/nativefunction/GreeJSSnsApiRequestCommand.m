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

#import "GreeJSSnsApiRequestCommand.h"
#import "GreeSNSAPI.h"
#import "JSONKit.h"

@interface GreeJSSnsApiRequestCommand ()
@property (nonatomic, retain) GreeSNSAPI* snsapi;
@end

@implementation GreeJSSnsApiRequestCommand

-(void)dealloc
{
  self.snsapi = nil;
  [super dealloc];
}

+(NSString*)name
{
  return @"snsapi_request";
}

-(void)execute:(NSDictionary*)params
{
  __block GreeJSSnsApiRequestCommand* command = [self retain]; // Released when result is returned.

  NSString* requestData = [params objectForKey:@"request"];
  self.snsapi = [[[GreeSNSAPI alloc] init] autorelease];
  [self.snsapi postWithRequestData:requestData success:^(NSString* responseString) {
     NSDictionary* results = [responseString greeMutableObjectFromJSONString];
     [[command.environment handler] callback:[params objectForKey:@"success"] params:results];
     [command callback];
     [command release];
   } failure:^(int statusCode, NSError* error, NSString* responseString) {
     NSArray* results = [NSArray arrayWithObjects:
                         [[NSNumber numberWithInteger:statusCode] stringValue],
                         [error localizedDescription],
                         [responseString greeMutableObjectFromJSONString], nil];
     [[command.environment handler] callback:[params objectForKey:@"failure"] arguments:results];
     [command callback];
     [command release];
   }];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
