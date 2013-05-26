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

#import "GreeBadgeValues.h"
#import "GreeSerializer.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeError+Internal.h"
#import "GreeSerializable.h"
#import "GreeNotificationLoader.h"
#import "GreeBenchmark.h"

NSString* const GreeBadgeValuesDidUpdateNotification = @"GreeBadgeValuesDidUpdateNotification";

@interface GreeBadgeValues ()<GreeSerializable>
@property (nonatomic, assign) NSUInteger snsBadgeCount;
@property (nonatomic, assign) NSUInteger friendBadgeCount;
@property (nonatomic, assign) NSInteger socialNetworkingServiceBadgeCount;
@property (nonatomic, assign) NSInteger applicationBadgeCount;
@end

@implementation GreeBadgeValues

-(id)initWithSocialNetworkingServiceBadgeCount:(NSInteger)socialNetworkingServiceBadgeCount
                         applicationBadgeCount:(NSInteger)applicationBadgeCount
{
  if ((self = [super init])) {
    self.socialNetworkingServiceBadgeCount = socialNetworkingServiceBadgeCount;
    self.applicationBadgeCount = applicationBadgeCount;
  }

  return self;
}

-(id)initWithSocialNetworkingServiceBadgeCount:(NSInteger)socialNetworkingServiceBadgeCount
                         applicationBadgeCount:(NSInteger)appBadgeCount
                                 snsBadgeCount:(NSUInteger)snsBadgeCount
                              friendBadgeCount:(NSUInteger)friendBadgeCount
{
  self = [self initWithSocialNetworkingServiceBadgeCount:socialNetworkingServiceBadgeCount applicationBadgeCount:appBadgeCount];
  if (self) {
    self.snsBadgeCount = snsBadgeCount;
    self.friendBadgeCount = friendBadgeCount;
  }
  return self;
}

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  return [self initWithSocialNetworkingServiceBadgeCount:[serializer integerForKey:@"sns"]
                                   applicationBadgeCount:[serializer integerForKey:@"app"]
                                           snsBadgeCount:[serializer integerForKey:@"sns_sns"]
                                        friendBadgeCount:[serializer integerForKey:@"sns_friend"]];
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeInteger:self.socialNetworkingServiceBadgeCount forKey:@"sns"];
  [serializer serializeInteger:self.applicationBadgeCount forKey:@"app"];
  [serializer serializeInteger:self.snsBadgeCount forKey:@"sns_sns"];
  [serializer serializeInteger:self.friendBadgeCount forKey:@"sns_friend"];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, sns:%d, app:%d, sns_sns:%d, sns_friend:%d>",
          NSStringFromClass([self class]),
          self,
          self.socialNetworkingServiceBadgeCount,
          self.applicationBadgeCount,
          self.snsBadgeCount,
          self.friendBadgeCount];
}

#pragma mark - Public Interface

+(void)loadBadgeValuesWithPath:(NSString*)path block:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block;
{
  if (!block) {
    return;
  }

  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
     GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:responseObject];
     GreeBadgeValues* badgeValues = [serializer objectOfClass:[GreeBadgeValues class] forKey:@"entry"];

     [[NSNotificationCenter defaultCenter]
      postNotificationName:GreeBadgeValuesDidUpdateNotification
                    object:badgeValues];
     block(badgeValues, nil);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }

      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     block(nil, [GreeError convertToGreeError:error]);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

+(void)loadBadgeValuesForCurrentApplicationWithBlock:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block
{
  [self loadBadgeValuesWithPath:@"/api/rest/badge/@app/@self" block:block];
}

+(void)loadBadgeValuesForAllApplicationsWithBlock:(void (^)(GreeBadgeValues* badgeValues, NSError* error))block
{
  [self loadBadgeValuesWithPath:@"/api/rest/badge/@app/@all" block:block];
}

+(void)resetBadgeValues
{
  GreeBadgeValues* badgeValues = [[GreeBadgeValues alloc]
                                  initWithSocialNetworkingServiceBadgeCount:0
                                                      applicationBadgeCount:0];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeBadgeValuesDidUpdateNotification object:badgeValues];
  [badgeValues release];
}

@end
