//
// Copyright 2010-2011 GREE, inc.
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

#import "GreeLike.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import "GreeError+Internal.h"
#import "GreeSettings.h"

NSString* const GreeLikeContentTypeMood  = @"mood";
NSString* const GreeLikeContentTypePhoto = @"photo";

@implementation GreeLike

+(void)postLikeWithUserId:(NSInteger)userId
                contentId:(NSInteger)contentId
              contentType:(GreeLikeContentType*)type
             successBlock:(void (^)(void))successBlock
             failureBlock:(void (^)(NSError* error))failureBlock
{
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  NSString* connectUrl = [settings objectValueForSetting:GreeSettingServerUrlConnect];
  NSString* developmentMode = [settings stringValueForSetting:GreeSettingDevelopmentMode];
  if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] ||
      [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
    connectUrl = [connectUrl stringByReplacingOccurrencesOfString:@"gree-dev.net" withString:@"gree.jp"];
  }

  NSString* endpoint = @"/api/rest/like";
  NSString* urlString = [NSString stringWithFormat:@"%@%@/%d/%d/%@", connectUrl, endpoint, userId, contentId, type];
  [[GreePlatform sharedInstance].httpClient postPath:urlString
   //MARK: Result in an 400 error and the parameter is nil.
                                          parameters:[NSDictionary dictionaryWithObject:@"" forKey:@""]
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

+(void)removeLikeWithUserId:(NSInteger)userId
                  contentId:(NSInteger)contentId
                contentType:(GreeLikeContentType*)type
               successBlock:(void (^)(void))successBlock
               failureBlock:(void (^)(NSError* error))failureBlock
{
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  NSString* connectUrl = [settings objectValueForSetting:GreeSettingServerUrlConnect];
  NSString* developmentMode = [settings stringValueForSetting:GreeSettingDevelopmentMode];
  if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] ||
      [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
    connectUrl = [connectUrl stringByReplacingOccurrencesOfString:@"gree-dev.net" withString:@"gree.jp"];
  }
  NSString* endpoint = @"/api/rest/like";
  NSString* urlString = [NSString stringWithFormat:@"%@%@/%d/%d/%@", connectUrl, endpoint, userId, contentId, type];
  [[GreePlatform sharedInstance].httpClient deletePath:urlString
                                            parameters:nil
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
