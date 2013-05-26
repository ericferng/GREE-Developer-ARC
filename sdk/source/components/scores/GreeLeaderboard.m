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

#import "GreeLeaderboard.h"
#import "GreeEnumerator+Internal.h"
#import "GreeSerializer.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"

@interface GreeLeaderboard ()
@property (nonatomic, retain, readwrite) NSString* identifier;
@property (nonatomic, retain, readwrite) NSString* name;
@property (nonatomic, assign, readwrite) GreeLeaderboardFormat format;
@property (nonatomic, retain, readwrite) NSString* formatSuffix;
@property (nonatomic, assign, readwrite) NSInteger formatDecimal;
@property (nonatomic, retain, readwrite) NSString* timeFormat;
@property (nonatomic, retain, readwrite) NSURL* iconUrl;
@property (nonatomic, assign, readwrite) GreeLeaderboardSortOrder sortOrder;
@property (nonatomic, assign, readwrite) BOOL allowWorseScore;
@property (nonatomic, assign, readwrite) BOOL isSecret;
@property (nonatomic, assign, readwrite) BOOL status;
@property (nonatomic, retain, readwrite) id handle;
@end

@interface GreeLeaderboardEnumerator : GreeEnumeratorBase
@end

@implementation GreeLeaderboard

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.identifier = nil;
  self.name = nil;
  self.formatSuffix = nil;
  self.iconUrl = nil;
  self.handle = nil;
  self.timeFormat = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(id<GreeEnumerator>)loadLeaderboardsWithBlock:(void (^)(NSArray* leaderboards, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeLeaderboardEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

-(void)loadIconWithBlock:(void (^)(UIImage* image, NSError* error))block
{
  self.handle = [[GreePlatform sharedInstance].httpClient downloadImageAtUrl:self.iconUrl withBlock:block];
}

-(void)cancelIconLoad
{
  [[GreePlatform sharedInstance].httpClient cancelWithHandle:self.handle];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if(self) {
    self.identifier = [serializer objectForKey:@"id"];
    self.name = [serializer objectForKey:@"name"];
    self.format = [serializer integerForKey:@"format"];
    self.formatSuffix = [serializer objectForKey:@"format_suffix"];
    self.formatDecimal = [serializer integerForKey:@"format_decimal"];
    self.timeFormat = [serializer objectForKey:@"time_format"];
    self.iconUrl = [serializer urlForKey:@"thumbnail_url"];
    self.sortOrder = [serializer integerForKey:@"sort"];
    self.allowWorseScore = [serializer boolForKey:@"allow_worse_score"];
    self.isSecret = [serializer boolForKey:@"secret"];
    self.status = [serializer boolForKey:@"status"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.identifier forKey:@"id"];
  [serializer serializeObject:self.name forKey:@"name"];
  [serializer serializeInteger:self.format forKey:@"format"];
  [serializer serializeObject:self.formatSuffix forKey:@"format_suffix"];
  [serializer serializeInteger:self.formatDecimal forKey:@"format_decimal"];
  [serializer serializeObject:self.timeFormat forKey:@"time_format"];
  [serializer serializeUrl:self.iconUrl forKey:@"thumbnail_url"];
  [serializer serializeInteger:self.sortOrder forKey:@"sort"];
  [serializer serializeBool:self.allowWorseScore forKey:@"allow_worse_score"];
  [serializer serializeBool:self.isSecret forKey:@"secret"];
  [serializer serializeBool:self.status forKey:@"status"];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
#define PRINTBOOL(x) x ? @"YES" : @"NO"

  const static NSString* sortOrderTitles[2] =  { @"Descending", @"Ascending" };
  const static NSString* formatTitles[] =  { @"Integer", @"Unknown", @"Time" };
  return [NSString stringWithFormat:@"<%@:%p, identifier:%@, name:%@, "
          "format:%d[%@], formatSuffix:%@, formatDecimal:%d, timeFormat:%@, "
          "iconUrl:%@, sortOrder:%d[%@], "
          "allowWorseScore:%@, isSecret:%@>",
          NSStringFromClass([self class]), self, self.identifier, self.name,
          self.format, formatTitles[self.format > 2 ? 0: self.format], self.formatSuffix, self.formatDecimal, self.timeFormat,
          self.iconUrl, self.sortOrder, sortOrderTitles[self.sortOrder > 1 ? 0: self.sortOrder],
          PRINTBOOL(self.allowWorseScore), PRINTBOOL(self.isSecret)];
}

#pragma mark - Internal Methods

@end

@implementation GreeLeaderboardEnumerator

-(NSString*)httpRequestPath
{
  return @"api/rest/sgpleaderboard/@me/@app";
}

-(NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeLeaderboard class]];
}

@end
