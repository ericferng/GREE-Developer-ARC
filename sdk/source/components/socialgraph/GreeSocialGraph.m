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
#import "GreeAuthorization.h"
#import "GreeEnumerator+Internal.h"
#import "GreeError+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeLogger.h"
#import "GreePlatform+Internal.h"
#import "GreeSerializer.h"
#import "GreeSerializable.h"
#import "GreeSocialGraph.h"


NSString* const GreeSocialGraphParameterKeyStartIndex  = @"startIndex";
NSString* const GreeSocialGraphParameterKeyPageSize    = @"count";
NSString* const GreeSocialGraphParameterKeyOrderBy     = @"orderBy";
NSString* const GreeSocialGraphParameterKeyUserId      = @"userId";
NSString* const GreeSocialGraphParameterKeySelector    = @"selector";

NSString* const GreeSocialGraphParameterUserIdMe       = @"@me";
NSString* const GreeSocialGraphParameterSelectorApp    = @"@app";
NSString* const GreeSocialGraphParameterOrderByWeight  = @"weight";
NSString* const GreeSocialGraphParameterOrderByCTime   = @"ctime";
NSString* const GreeSocialGraphParameterOrderByMTime   = @"mtime";

static NSString* const GreeSocialGraphParameterKeyResponsePageSize = @"itemsPerPage";
static NSString* const GreeSocialGraphParameterFriendAll           = @"@all";
static NSString* const GreeSocialGraphResultHasRelationship        = @"friend";

@interface GreeSocialGraphEnumerator : GreeEnumeratorBase
@property (nonatomic, retain, readwrite) NSString* selector;
@property (nonatomic, retain, readwrite) NSMutableDictionary* requestParameters;
@end


@interface GreeSocialGraph ()<GreeSerializable>
@property (nonatomic, retain, readwrite) NSString* userId;
@property (nonatomic, retain, readwrite) NSString* graphId;
@property (nonatomic, retain, readwrite) NSString* relationId;
@end


@implementation GreeSocialGraph

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.userId = nil;
  self.graphId = nil;
  self.relationId = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(id<GreeEnumerator>)loadFriendListWithParameters:(NSDictionary*)parameters block:(GreeEnumeratorResponseBlock)block
{
  id<GreeEnumerator> enumerator = [[GreeSocialGraphEnumerator alloc] initWithStartIndex:0 pageSize:0];

  NSString* userId = [parameters objectForKey:GreeSocialGraphParameterKeyUserId];
  if (0 < [userId length]) {
    [enumerator setGuid:userId];
  } else {
    [enumerator setGuid:GreeSocialGraphParameterUserIdMe];
  }

  NSString* selector = [parameters objectForKey:GreeSocialGraphParameterKeySelector];
  if (0 < [selector length]) {
    [enumerator performSelector:@selector(setSelector:)withObject:selector];
  } else {
    [enumerator performSelector:@selector(setSelector:)withObject:GreeSocialGraphParameterSelectorApp];
  }

  NSMutableDictionary* newParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [newParameters removeObjectForKey:GreeSocialGraphParameterKeyUserId];
  [newParameters removeObjectForKey:GreeSocialGraphParameterKeySelector];

  [enumerator performSelector:@selector(setRequestParameters:)withObject:newParameters];

  [enumerator loadNext:block];

  return [enumerator autorelease];
}

+(void)requestNumberOfFriendsWithParameters:(NSDictionary*)parameters block:(void (^)(NSInteger count, NSError* error))block
{
  if (!block) {
    return;
  }

  NSString* userId = [parameters objectForKey:GreeSocialGraphParameterKeyUserId];
  if ([userId length] == 0) {
    userId = GreeSocialGraphParameterUserIdMe;
  }

  NSString* selector = [parameters objectForKey:GreeSocialGraphParameterKeySelector];
  if ([selector length] == 0) {
    selector = GreeSocialGraphParameterSelectorApp;
  }

  void (^successBlock)(GreeAFHTTPRequestOperation*, id) =^(GreeAFHTTPRequestOperation* operation, id responseObject){
    id entry = [responseObject objectForKey:@"entry"];
    int returnValue = 0;
    if ([entry respondsToSelector:@selector(intValue)]) {
      returnValue = [entry intValue];
    }
    block(returnValue, nil);
  };

  void (^failureBlock)(GreeAFHTTPRequestOperation*, NSError*) =^(GreeAFHTTPRequestOperation* operation, NSError* error){
    block(0, [GreeError convertToGreeError:error]);
  };

  NSString* path = [NSString stringWithFormat:@"/api/rest/friend_count/%@/%@/%@",
                    userId, selector, GreeSocialGraphParameterFriendAll];
  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:nil
      success:successBlock
      failure:failureBlock];
}

+(void)requestRelationshipWithUserId:(NSString*)userId friendId:(NSArray*)friendIds block:(void (^)(BOOL hasRelationship, NSError* error))block
{
  if (!block) {
    return;
  }

  if ([userId length] == 0) {
    block(NO, [GreeError localizedGreeErrorWithCode:GreeSocialGraphInvalidParameter]);
    return;
  }

  if ([friendIds count] != 1) {
    block(NO, [GreeError localizedGreeErrorWithCode:GreeSocialGraphInvalidParameter]);
    return;
  }

  NSString* friendId = [friendIds objectAtIndex:0];
  if ([friendId isEqualToString:GreeSocialGraphParameterFriendAll]) {
    block(NO, [GreeError localizedGreeErrorWithCode:GreeSocialGraphInvalidParameter]);
    return;
  }

  void (^successBlock)(GreeAFHTTPRequestOperation*, id) =^(GreeAFHTTPRequestOperation* operation, id responseObject){
    NSString* relationship = [responseObject objectForKey:@"entry"];
    BOOL returnValue = NO;
    if ([relationship isEqualToString:GreeSocialGraphResultHasRelationship]) {
      returnValue = YES;
    }
    block(returnValue, nil);
  };

  void (^failureBlock)(GreeAFHTTPRequestOperation*, NSError*) =^(GreeAFHTTPRequestOperation* operation, NSError* error){
    block(0, [GreeError convertToGreeError:error]);
  };

  NSString* path = [NSString stringWithFormat:@"/api/rest/friend/%@/%@/%@",
                    userId, GreeSocialGraphParameterSelectorApp, friendId];
  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:nil
      success:successBlock
      failure:failureBlock];
}


#pragma mark - NSObject overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, userId:%@, graphId:%@, relationId:%@>",
          NSStringFromClass([self class]),
          self,
          self.userId,
          self.graphId,
          self.relationId];
}

#pragma mark - GreeSerializable Overrides

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if(self) {
    self.userId = [serializer objectForKey:@"user_id"];
    self.graphId = [serializer objectForKey:@"graph_id"];
    self.relationId = [serializer objectForKey:@"relation_id"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - Internal Methods

@end


@implementation GreeSocialGraphEnumerator

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.selector = nil;
  self.requestParameters = nil;
  [super dealloc];
}

#pragma mark - GreeEnumeratorBase Overrides

-(NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/friend/%@/%@/@all",
          self.guid,
          self.selector];
}

-(NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeSocialGraph class]];
}

-(void)updateParams:(NSMutableDictionary*)params
{
  NSArray* orderByParameters = [self.requestParameters objectForKey:GreeSocialGraphParameterKeyOrderBy];
  if (0 < [orderByParameters count]) {
    NSString* orderByValue = [orderByParameters componentsJoinedByString:@","];
    [self.requestParameters setObject:orderByValue forKey:GreeSocialGraphParameterKeyOrderBy];
  }

  [params addEntriesFromDictionary:self.requestParameters];
}

-(void)loadFromIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize block:(GreeEnumeratorResponseBlock)block
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

  //make the http request, this will return an array and error message
  if([GreePlatform sharedInstance].localUser == nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeUserRequired]);
                   });
    return;
  }

  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", startIndex] forKey:GreeSocialGraphParameterKeyStartIndex];
  if (pageSize > 0) {
    [params setObject:[NSString stringWithFormat:@"%d", pageSize] forKey:GreeSocialGraphParameterKeyPageSize];
  }
  [self updateParams:params];

  GreeHTTPSuccessBlock successBlock =^(GreeAFHTTPRequestOperation* operation, id responseObject){
    NSArray* returnArray = nil;
    NSError* returnError = nil;

    if (![responseObject isKindOfClass:[NSDictionary class]]) {
      returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    } else {
      returnArray = [responseObject objectForKey:@"entry"];
      if(![returnArray isKindOfClass:[NSArray class]]) {
        returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
        returnArray = nil;
      } else {
        returnArray = [self convertData:returnArray];
        if (returnArray.count == 0) {
          returnArray = [NSArray array];
        }
        if (self.pageSize == 0) {
          self.pageSize = [[responseObject objectForKey:GreeSocialGraphParameterKeyResponsePageSize] intValue];
        }

        self.startIndex = startIndex + self.pageSize;
      }
    }
    block(returnArray, returnError);
  };

  GreeHTTPFailureBlock failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error) {
    if (operation.response.statusCode == 404) {
      block(nil, nil);
    } else {
      block(nil, [self convertError:error]);
    }
  };

  [[GreePlatform sharedInstance].httpClient
      getPath:[self httpRequestPath]
   parameters:params
      success:successBlock
      failure:failureBlock];
}


@end
