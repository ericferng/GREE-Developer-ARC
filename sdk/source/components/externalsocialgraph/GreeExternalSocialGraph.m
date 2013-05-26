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


#import "AFHTTPRequestOperation.h"
#import "GreeAPI+Internal.h"
#import "GreeAuthorization.h"
#import "GreeError+Internal.h"
#import "GreeExternalSocialGraph.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "GreeSerializer.h"
#import "GreeSettings.h"


NSString* const GreeExternalSocialGraphParameterKeyToken               = @"token";
NSString* const GreeExternalSocialGraphParameterKeyType                = @"type";
NSString* const GreeExternalSocialGraphParameterKeyServiceType         = @"service_type";
NSString* const GreeExternalSocialGraphParameterServiceTypeFacebook    = @"facebook";
NSString* const GreeExternalSocialGraphParameterServiceTypeGreeFriends = @"greefriends";
NSString* const GreeExternalSocialGraphParameterServiceTypeAddressBook = @"addressbook";


@interface GreeExternalSocialGraphEnumerator : GreeAPIEnumeratorBase
@end


@interface GreeExternalSocialGraph ()
@property (nonatomic, retain) NSMutableArray* facebookFriends;
@property (nonatomic, retain) NSMutableArray* addressbookFriends;
@property (nonatomic, retain) NSMutableArray* greeFriends;
@end


@implementation GreeExternalSocialGraphEnumerator

#pragma mark - GreeAPIEnumeratorBase Overrides

-(NSString*)httpRequestResourceSpecifier
{
  return @"friends/extended";
}

-(BOOL)shouldConvertManually
{
  return YES;
}

-(id)convertDataManually:(id)input
{
  GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:input];
  GreeExternalSocialGraph* object = [[GreeExternalSocialGraph alloc] initWithGreeSerializer:serializer];
  return [object autorelease];
}

@end



@implementation GreeExternalSocialGraph

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.facebookFriends = nil;
  self.addressbookFriends = nil;
  self.greeFriends = nil;
  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, Facebook Friends:%@, Addressbook Friends:%@, GREE Friends:%@>",
          NSStringFromClass([self class]),
          self,
          self.facebookFriends,
          self.addressbookFriends,
          self.greeFriends];
}

#pragma mark - GreeAPI Overrides

+(id<GreeAPIEnumerator>)getWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  GreeExternalSocialGraphEnumerator* enumerator = [[GreeExternalSocialGraphEnumerator alloc] init];
  [enumerator setParameters:parameters];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

+(void)postWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  if (!block) {
    return;
  }

  if (![[GreeAuthorization sharedInstance] isAuthorized]) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeNotAuthorized]);
                   });
    return;
  }

  if (![GreePlatform sharedInstance].localUserId) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeUserRequired]);
                   });
    return;
  }

  GreeHTTPSuccessBlock successBlock =^(GreeAFHTTPRequestOperation* operation, id responseObject) {
    block(nil, nil);
  };

  GreeHTTPFailureBlock failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error) {
    NSInteger statusCode = operation.response.statusCode;
    switch (statusCode) {
    case 400:
      block(nil, [GreeError localizedGreeErrorWithCode:GreeExternalSocialGraphUpdateInvalidParameter]);
      break;
    case 403:
      block(nil, [GreeError localizedGreeErrorWithCode:GreeExternalSocialGraphUpdateAccessDenied]);
      break;
    case 500:
      block(nil, [GreeError localizedGreeErrorWithCode:GreeExternalSocialGraphUpdateOperationFailed]);
      break;
    default:
      block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer]);
      break;
    }
  };

  NSString* path = @"user/me/friends/facebook/:update";
  NSDictionary* requestParameters = [NSDictionary
                                     dictionaryWithObject:[parameters objectForKey:GreeExternalSocialGraphParameterKeyToken]
                                                   forKey:GreeExternalSocialGraphParameterKeyToken];
  [[GreePlatform sharedInstance].httpsClientForApi
     postPath:path
   parameters:requestParameters
      success:successBlock
      failure:failureBlock];
}


#pragma mark - GreeSerializable Overrides

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [self init];
  if (self) {
    self.facebookFriends = [NSMutableArray arrayWithArray:[serializer objectForKey:@"facebook_friends"]];
    self.addressbookFriends = [NSMutableArray arrayWithArray:[serializer objectForKey:@"addressbook_friends"]];
    self.greeFriends = [NSMutableArray arrayWithArray:[serializer objectForKey:@"gree_friends"]];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

@end
