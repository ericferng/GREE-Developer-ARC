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

#import "GreeSNSAPI.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeSettings.h"
#import "AFNetworking.h"
#import "JSONKit.h"

@implementation GreeSNSAPI

static NSString* snsApiEndpoint = @"/";

-(void)postWithRequestData:(NSString*)requestData
                   success:(GreeSNSAPISuccessBlock)success
                   failure:(GreeSNSAPIFailureBlock)failure
{
  NSString* url = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSnsApi];
  NSURL* u = [NSURL URLWithString:snsApiEndpoint relativeToURL:[NSURL URLWithString:url]];
  const char* dataBytes = [requestData UTF8String];
  NSData* data = requestData ? [NSData dataWithBytes:dataBytes length:strlen(dataBytes)] : [NSData data];

  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:u];
  request.HTTPMethod = @"POST";
  request.HTTPShouldHandleCookies = YES;
  request.HTTPBody = data;
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  GreeHTTPClient* client = [GreePlatform sharedInstance].httpClient;

  [client
   performRequest:request parameters:nil
          success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
     NSString* responseString = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] autorelease];
     success(responseString);
   }
          failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     NSString* responseString = operation.responseString ? operation.responseString : nil;
     failure(operation.response.statusCode, error, responseString);
   }];
}
@end
