//
// Copyright 2012年 GREE, Inc.
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

#import "GreeMarkasRead.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import "GreeError+Internal.h"
#import "GreeSettings.h"

NSString* const GreeMarkasReadTypeGame      = @"game";
NSString* const GreeMarkasReadTypeInvite    = @"invite";
NSString* const GreeMarkasReadTypeTarget    = @"target";
NSString* const GreeMarkasReadTypeSNS       = @"sns";
NSString* const GreeMarkasReadTypeActivity  = @"activity";
NSString* const GreeMarkasReadTypeFriend    = @"friend";


@implementation GreeMarkasRead

+(void)markasReadWithType:(NSString*)type
                   endkey:(NSString*)endKey
                    appId:(NSInteger)appId
             successBlock:(void (^)(void))successBlock
             failureBlock:(void (^)(NSError* error))failureBlock
{
  NSString* urlstring = @"/api/rest/markasread/";
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                          type, @"type",
                          endKey, @"end_key",
                          [NSString stringWithFormat:@"%d", appId], @"app_id", nil];

  [[GreePlatform sharedInstance].httpClient postPath:urlstring
                                          parameters:params
                                             success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if (successBlock) {
       successBlock();
     }
   }
                                             failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if (failureBlock) {
       failureBlock([GreeError convertToGreeError:error]);
     }
   }];
}

@end
