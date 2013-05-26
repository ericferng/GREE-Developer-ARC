//
// Copyright 2011 GREE, Inc.
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

#import "GreeEnumerator+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeError+Internal.h"
#import "AFHTTPRequestOperation.h"
#import "GreeAuthorization.h"
#import "GreeBenchmark.h"

@interface GreeEnumeratorBase ()
@property (nonatomic, readwrite, assign) BOOL hasNextPage;
@property (nonatomic, readwrite,  assign) NSInteger count;
-(void)loadFromIndex:(NSInteger)startIndex pageSize:(NSInteger)count block:(GreeEnumeratorResponseBlock)block;
-(void)benchmarkWithPosition:(NSString*)position;
@end

@implementation GreeEnumeratorBase

#pragma mark - Object Lifecycle
-(id)initWithStartIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize
{
  self = [super init];
  if(self) {
    self.startIndex = startIndex;
    self.enumeratorStartIndex = startIndex;
    self.pageSize = pageSize;
    self.guid = @"me";
  }
  return self;
}

-(void)dealloc
{
  self.guid = nil;
  [super dealloc];
}

#pragma mark - Public Interface
-(void)loadNext:(GreeEnumeratorResponseBlock)block
{
  [self loadFromIndex:self.startIndex pageSize:self.pageSize block:block];
}

-(void)loadPrevious:(GreeEnumeratorResponseBlock)block
{
  NSInteger newStart = self.startIndex - self.pageSize * 2;
  if(newStart < self.enumeratorStartIndex) {
    newStart = self.enumeratorStartIndex;
  }
  [self loadFromIndex:newStart pageSize:self.pageSize block:block];
}

-(BOOL)canLoadPrevious
{
  if (self.startIndex <= self.enumeratorStartIndex + self.pageSize) {
    return NO;
  } else {
    return YES;
  }
}

-(BOOL)canLoadNext
{
  return self.hasNextPage;
}


#pragma mark - Advanced enumerator properties
-(NSString*)guid
{
  if(!_guid) {
    return @"me";
  }
  return _guid;
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p startIndex:%d pageSize:%d>", NSStringFromClass([self class]), self, self.startIndex, self.pageSize];
}

#pragma mark - Internal Methods
-(NSString*)httpRequestPath
{
  NSAssert(0, @"You must override httpRequestPath in a GreeEnumerator");
  return nil;
}

-(NSArray*)convertData:(NSArray*)input
{
  NSAssert(0, @"You must override convertData in a GreeEnumerator");
  return nil;
}

//this is to allow a subclass to define other error handling capabilities
//by default, it calls the master error handler
-(NSError*)convertError:(NSError*)input
{
  return [GreeError convertToGreeError:input];
}

-(void)updateParams:(NSMutableDictionary*)params
{
}

-(NSString*)retryService
{
  return nil;
}

-(void)loadFromIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize block:(GreeEnumeratorResponseBlock)block
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

  //make the http request, this will return an array and error message
  if([GreePlatform sharedInstance].localUser == nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeUserRequired]);
                   });
    return;
  }

  [self benchmarkWithPosition:kGreeBenchmarkStart];
  NSString* path = [self httpRequestPath];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", startIndex] forKey:@"startIndex"];
  if(pageSize > 0) {
    [params setObject:[NSString stringWithFormat:@"%d", pageSize] forKey:@"count"];
  }
  [self updateParams:params];

  GreeHTTPSuccessBlock successBlock =^(GreeAFHTTPRequestOperation* operation, id responseObject){
    NSArray* returnArray = nil;
    NSError* returnError = nil;

    if(![responseObject isKindOfClass:[NSDictionary class]]) {
      returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    } else {
      returnArray = [responseObject objectForKey:@"entry"];
      if(![returnArray isKindOfClass:[NSArray class]]) {
        returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
        returnArray = nil;
      } else {
        returnArray = [self convertData:returnArray];
        if(returnArray.count == 0) {
          returnArray = nil;
        }

        if(self.pageSize == 0) {
          self.pageSize = [[responseObject objectForKey:@"itemsPerPage"] intValue];
        }

        self.startIndex = startIndex + self.pageSize;
        self.count = [[responseObject objectForKey:@"totalResults"] intValue];

        if ([responseObject objectForKey:@"hasNext"] != nil) {
          self.hasNextPage = [[responseObject objectForKey:@"hasNext"] boolValue];
        } else {
          int lastResultIndex = self.enumeratorStartIndex + self.count - 1;
          if (self.startIndex <= lastResultIndex) {
            self.hasNextPage = YES;
          } else {
            self.hasNextPage = NO;
          }
        }

      }
    }
    block(returnArray, returnError);

    [self benchmarkWithPosition:kGreeBenchmarkEnd];
    if ([GreePlatform sharedInstance].benchmark) {
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
    }
  };

  GreeHTTPFailureBlock failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error) {
    if (operation.response.statusCode == 404) {
      block(nil, nil);
    } else {
      block(nil, [self convertError:error]);
    }

    [self benchmarkWithPosition:kGreeBenchmarkError];
    if ([GreePlatform sharedInstance].benchmark) {
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
    }
  };



  [[GreePlatform sharedInstance].httpClient getPath:path
                                         parameters:params
                                            success:successBlock
                                            failure:failureBlock
  ];
}

-(void)benchmarkWithPosition:(NSString*)position
{
  if (![GreePlatform sharedInstance].benchmark) {
    return;
  }

  NSString* pointName = nil;
  GreeBenchmarkPointRole pointRole = GreeBenchmarkPointRoleNone;

  if ([position isEqualToString:kGreeBenchmarkStart]) {
    pointRole = GreeBenchmarkPointRoleStart;
  } else {
    pointRole = GreeBenchmarkPointRoleEnd;
  }

  if ([[NSString stringWithUTF8String:object_getClassName(self)] isEqualToString:@"GreeLeaderboardEnumerator"]) {
    pointName = [@"leaderboardEnumerator" stringByAppendingString:position];
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkApiUsage position:GreeBenchmarkPosition(pointName) pointRole:pointRole];
  } else if ([[NSString stringWithUTF8String:object_getClassName(self)] isEqualToString:@"GreeAchievementEnumerator"]) {
    pointName = [@"achievementEnumerator" stringByAppendingString:position];
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkApiUsage position:GreeBenchmarkPosition(pointName) pointRole:pointRole];
  } else if ([[NSString stringWithUTF8String:object_getClassName(self)] isEqualToString:@"GreeFriendEnumerator"]) {
    pointName = [@"friendEnumerator" stringByAppendingString:position];
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkApiUsage position:GreeBenchmarkPosition(pointName) pointRole:pointRole];
  }

}

@end
