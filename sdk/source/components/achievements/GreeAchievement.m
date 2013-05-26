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

#import "GreeAchievement.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeEnumerator+Internal.h"
#import "AFImageRequestOperation.h"
#import "GreeError.h"
#import "GreeSerializer.h"
#import "NSString+GreeAdditions.h"
#import "GreeWriteCache.h"
#import "GreeNetworkReachability.h"
#import "GreeSettings.h"
#import <GameKit/GameKit.h>
#import "GreeUser.h"
#import "GreeBenchmark.h"

@interface GreeAchievement ()
@property (nonatomic, retain, readwrite) NSString* identifier;
@property (nonatomic, retain, readwrite) NSString* name;
@property (nonatomic, retain, readwrite) NSString* descriptionText;
@property (nonatomic, retain, readwrite) NSURL* iconUrl;
@property (nonatomic, retain, readwrite) NSURL* lockedIconUrl;
@property (nonatomic, assign, readwrite) BOOL isSecret;
@property (nonatomic, assign, readwrite) BOOL isUnlocked;
@property (nonatomic, assign, readwrite) NSInteger score;
@property (nonatomic, copy, readwrite) void (^gameCenterResponseBlock)(NSError*);
@property (nonatomic, retain, readwrite) id handle;
-(GKAchievement*)gameCenterAchievement;
-(void)updateWriteCacheWithBlock:(void (^)(void))block;
@end

@interface GreeAchievementEnumerator : GreeEnumeratorBase
@end

@implementation GreeAchievement

#pragma mark - Object Lifecycle

-(id)initWithIdentifier:(NSString*)identifier
{
  self = [super init];
  if (self != nil) {
    self.identifier = identifier;
  }

  return self;
}

-(void)dealloc
{
  self.identifier = nil;
  self.name = nil;
  self.descriptionText = nil;
  self.iconUrl = nil;
  self.lockedIconUrl = nil;
  self.gameCenterResponseBlock = nil;
  self.handle = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(id<GreeEnumerator>)loadAchievementsWithBlock:(void (^)(NSArray* achievements, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeAchievementEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

-(void)loadIconWithBlock:(void (^)(UIImage* image, NSError* error))block
{
  NSURL* url = self.isUnlocked ? self.iconUrl : self.lockedIconUrl;
  self.handle = [[GreePlatform sharedInstance].httpClient downloadImageAtUrl:url withBlock:block];
}

-(void)cancelIconLoad
{
  [[GreePlatform sharedInstance].httpClient cancelWithHandle:self.handle];
  self.handle = nil;
}

-(void)unlockWithBlock:(void (^)(void))block
{
  [[self gameCenterAchievement] reportAchievementWithCompletionHandler:self.gameCenterResponseBlock];

  self.isUnlocked = YES;
  [self updateWriteCacheWithBlock:block];
}

-(void)relockWithBlock:(void (^)(void))block
{
  self.isUnlocked = NO;
  [self updateWriteCacheWithBlock:block];
}

#pragma mark - GreeWriteCacheable Protocol

-(NSString*)writeCacheCategory
{
  return self.identifier;
}

+(NSInteger)writeCacheMaxCategorySize
{
  return 1;
}

-(void)writeCacheCommitAndExecuteBlock:(void (^)(BOOL commitDidSucceed))block
{
  NSString* path = @"api/rest/sgpachievement/@me/@self/@app/";
  NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObject:self.identifier forKey:@"achievementDetailId"];

  void (^success)(GreeAFHTTPRequestOperation*, id) =^(GreeAFHTTPRequestOperation* op, id response) {
    if ([GreePlatform sharedInstance].benchmark) {
      NSString* method = self.isUnlocked ? kGreeBenchmarkHttpProtocolPost : kGreeBenchmarkHttpProtocolDelete;
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:method path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
    }
    if (block) {
      block(YES);
    }
  };

  void (^failure)(GreeAFHTTPRequestOperation*, NSError*) =^(GreeAFHTTPRequestOperation* op, NSError* error) {
    if ([GreePlatform sharedInstance].benchmark) {
      NSString* method = self.isUnlocked ? kGreeBenchmarkHttpProtocolPost : kGreeBenchmarkHttpProtocolDelete;
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:method path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
    }
    if (block) {
      block(NO);
    }
  };

  if ([GreePlatform sharedInstance].benchmark) {
    NSString* method = self.isUnlocked ? kGreeBenchmarkHttpProtocolPost : kGreeBenchmarkHttpProtocolDelete;
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:method path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  if (self.isUnlocked) {
    NSString* userId = [GreePlatform sharedInstance].localUserId;
    [parameters addEntriesFromDictionary:[self.identifier greeHashWithNonceAndKeyPrefix:userId]];
    [[GreePlatform sharedInstance].httpClient
       postPath:path
     parameters:parameters
        success:success
        failure:failure];
  } else {
    [[GreePlatform sharedInstance].httpClient
     encodedDeletePath:path
            parameters:parameters
               success:success
               failure:failure];
  }
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [self initWithIdentifier:[serializer objectForKey:@"id"]];
  if (self != nil) {
    self.name = [serializer objectForKey:@"name"];
    self.descriptionText = [serializer objectForKey:@"description"];
    self.iconUrl = [serializer urlForKey:@"thumbnail_url"];
    self.lockedIconUrl = [serializer urlForKey:@"lock_thumbnail_url"];
    self.isSecret = [serializer boolForKey:@"secret"];
    self.isUnlocked = ![serializer boolForKey:@"status"];
    self.score = [serializer integerForKey:@"score"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.identifier forKey:@"id"];
  [serializer serializeObject:self.name forKey:@"name"];
  [serializer serializeObject:self.descriptionText forKey:@"description"];
  [serializer serializeUrl:self.iconUrl forKey:@"thumbnail_url"];
  [serializer serializeUrl:self.lockedIconUrl forKey:@"lock_thumbnail_url"];
  [serializer serializeBool:self.isSecret forKey:@"secret"];
  [serializer serializeBool:!self.isUnlocked forKey:@"status"];
  [serializer serializeInteger:self.score forKey:@"score"];
}

#pragma mark - Internal Methods

-(GKAchievement*)gameCenterAchievement
{
  GKAchievement* achievement = nil;

  NSDictionary* gameCenterMapping = [[[GreePlatform sharedInstance] settings] objectValueForSetting:GreeSettingGameCenterAchievementMapping];
  NSString* gameCenterIdentifier = [gameCenterMapping objectForKey:self.identifier];
  if ([gameCenterIdentifier length] > 0) {
    achievement = [[[GKAchievement alloc] initWithIdentifier:gameCenterIdentifier] autorelease];
    achievement.percentComplete = 100.;
    if ([achievement respondsToSelector:@selector(setShowsCompletionBanner:)]) {
      [achievement setShowsCompletionBanner:NO];
    }
  }

  return achievement;
}

-(void)updateWriteCacheWithBlock:(void (^) (void))block
{
  GreeWriteCacheOperationHandle handleToObserve = [[[GreePlatform sharedInstance] writeCache] writeObject:self];
  if ([[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    handleToObserve = [[[GreePlatform sharedInstance] writeCache] commitAllObjectsOfClass:[self class] inCategory:self.identifier];
  }

  if (block) {
    [[[GreePlatform sharedInstance] writeCache] observeWriteCacheOperation:handleToObserve forCompletionWithBlock:block];
  }
}

#pragma mark - NSObject overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, identifer:%@, name:%@, description:%@, iconUrl:%@, lockedIconUrl:%@, isSecret:%@, isUnlocked:%@ score:%d>",
          NSStringFromClass([self class]),
          self,
          self.identifier,
          self.name,
          self.descriptionText,
          self.iconUrl,
          self.lockedIconUrl,
          self.isSecret ? @"YES": @"NO",
          self.isUnlocked ? @"YES": @"NO",
          self.score];
}

@end


@implementation GreeAchievementEnumerator

#pragma mark - GreeEnumerator Overrides

-(NSString*)httpRequestPath
{
  return @"api/rest/sgpachievement/@me/@self/@app";
}

-(NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeAchievement class]];
}

@end

