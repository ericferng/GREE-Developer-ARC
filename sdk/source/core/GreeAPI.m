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
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"


NSString* const GreeAPIParameterKeyStartIndex   = @"offset";
NSString* const GreeAPIParameterKeyPageSize     = @"limit";
NSString* const GreeAPIParameterKeyHasMore      = @"has_more";
NSString* const GreeAPIParameterKeyThumbnail    = @"thumbnail";
NSString* const GreeAPIParameterKeyLanguageCode = @"language";
NSString* const GreeAPIParameterKeyUserIds      = @"user_ids";
static NSString* const kKeyData    = @"data";


@interface NSArray (GreeAPIInternal)
-(NSString*)pathString;
@end

@implementation NSArray (GreeAPIInternal)

-(NSString*)pathString
{
  if ([self count] == 0) {
    return nil;
  }

  NSMutableString* returnString = [NSMutableString stringWithString:@"user/"];

  for (id object in self) {
    [returnString appendFormat:@"%@,", object];
  }
  if (0 < [returnString length]) {
    [returnString deleteCharactersInRange:NSMakeRange([returnString length] - 1, 1)];
  }

  return returnString;
}

@end


@implementation GreeAPIEnumeratorBase

@synthesize startIndex = _startIndex;
@synthesize pageSize = _pageSize;

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.startIndex = 0;
    self.pageSize = 0;
    self.hasMore = NO;
    self.requestParameters = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];
    self.userIds = [NSMutableArray array];
  }
  return self;
}

-(void)dealloc
{
  self.requestParameters = nil;
  self.userIds = nil;
  [super dealloc];
}

#pragma mark - GreeAPIEnumerator Overrides

-(NSInteger)startIndex
{
  return _startIndex;
}

-(void)setStartIndex:(NSInteger)startIndex
{
  _startIndex = startIndex;
}

-(NSInteger)pageSize
{
  return _pageSize;
}

-(void)setPageSize:(NSInteger)pageSize
{
  _pageSize = pageSize;
}

-(BOOL)canLoadNext
{
  return self.hasMore;
}

-(BOOL)canLoadPrevious
{
  return NO;
}

-(void)loadNext:(GreeAPIResponseBlock)block
{
  if(!block) {
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
    id returnObject = nil;
    NSDictionary* responseEntries = nil;
    NSError* returnError = nil;

    if (![responseObject isKindOfClass:[NSDictionary class]]) {
      returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    } else {
      responseEntries = [responseObject objectForKey:@"entry"];
      if (![responseEntries isKindOfClass:[NSDictionary class]]) {
        returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
        responseEntries = nil;
      } else {
        if ([self shouldConvertManually]) {
          returnObject = [self convertDataManually:responseEntries];
        } else {
          returnObject = [NSMutableDictionary dictionary];
          for (NSString* userId in responseEntries) {
            NSArray* returnArray = [self convertData:[responseEntries objectForKey:userId]];
            if (!returnArray) {
              returnArray = [NSArray array];
            }
            [returnObject setObject:returnArray forKey:userId];
          }
          if ([returnObject count] == 0) {
            returnObject = nil;
          }
        }

        if (self.pageSize == 0) {
          self.pageSize = [[responseObject objectForKey:GreeAPIParameterKeyPageSize] intValue];
        }
        self.startIndex = self.startIndex + self.pageSize;
        self.hasMore = [[responseObject objectForKey:GreeAPIParameterKeyHasMore] boolValue];
      }
    }
    block(returnObject, returnError);
  };

  GreeHTTPFailureBlock failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error) {
    block(nil, [self convertError:error]);
  };

  NSArray* userIdsInRequestParameters = [self.requestParameters objectForKey:GreeAPIParameterKeyUserIds];
  if (0 < [userIdsInRequestParameters count]) {
    [self.userIds setArray:userIdsInRequestParameters];
  } else {
    if ([self.userIds count] == 0) {
      [self.userIds addObject:[GreePlatform sharedInstance].localUserId];
    }
  }
  [self.requestParameters removeObjectForKey:GreeAPIParameterKeyUserIds];

  NSString* path = [NSString stringWithFormat:@"%@/%@",
                    [self.userIds pathString],
                    [self httpRequestResourceSpecifier]];
  [[GreePlatform sharedInstance].httpClientForApi
      getPath:path
   parameters:self.requestParameters
      success:successBlock
      failure:failureBlock];
}

-(void)loadPrevious:(GreeAPIResponseBlock)block
{

}

-(NSString*)httpRequestResourceSpecifier
{
  return nil;
}

-(NSArray*)convertData:(NSArray*)input
{
  return input;
}

-(NSError*)convertError:(NSError*)input
{
  return input;
}

-(BOOL)shouldConvertManually
{
  return NO;
}

-(id)convertDataManually:(id)input
{
  return input;
}


#pragma mark - GreeAPIDefaultParameters Overrides

-(NSDictionary*)parameters
{
  return self.requestParameters;
}

-(void)setParameters:(NSDictionary*)parameters
{
  if (self.requestParameters != parameters) {
    if (parameters) {
      [self.requestParameters setDictionary:parameters];
      self.startIndex = [[self.requestParameters objectForKey:GreeAPIParameterKeyStartIndex] intValue];
      self.pageSize = [[self.requestParameters objectForKey:GreeAPIParameterKeyPageSize] intValue];
    } else {
      self.requestParameters = nil;
    }
  }
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p startIndex:%d pageSize:%d, userIds:%@, requestParameters:%@>",
          NSStringFromClass([self class]),
          self,
          self.startIndex,
          self.pageSize,
          self.userIds,
          self.requestParameters];
}

@end


@implementation GreeAPIBase

+(id<GreeAPIEnumerator>)getWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  if (block) {
    block(nil, [GreeError localizedGreeErrorWithCode:GreeAPINotAllowed]);
  }
  return nil;
}

+(void)postWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  if (block) {
    block(nil, [GreeError localizedGreeErrorWithCode:GreeAPINotAllowed]);
  }
}

+(void)putWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  if (block) {
    block(nil, [GreeError localizedGreeErrorWithCode:GreeAPINotAllowed]);
  }
}

+(void)deleteWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  if (block) {
    block(nil, [GreeError localizedGreeErrorWithCode:GreeAPINotAllowed]);
  }
}

@end
