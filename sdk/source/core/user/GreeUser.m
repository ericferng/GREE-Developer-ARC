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

#import "GreeUser+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "AFNetworking.h"
#import "GreeSerializer.h"
#import "GreeEnumerator+Internal.h"
#import "GreeError+Internal.h"
#import "GreeBenchmark.h"
#import "GreeAuthorization.h"


static NSString* const kGreeUserDefaultsLocalUserKey = @"GreeUserDefaults.LocalUser";
static NSString* const kGreeUserDefaultsIsAppStartedKey = @"GreeUserDefaults.IsAppStarted";

NSString* const kGreeNSNotificationKeyUpdateNickname = @"GreeNSNotificationKeyUpdateNickname";

@interface GreeFriendEnumerator : GreeEnumeratorBase<GreeCountableEnumerator>
@end

@interface GreeIgnoredUserIdEnumerator : GreeEnumeratorBase
@end

@interface GreeUser ()
@property (nonatomic, readwrite, assign) BOOL hasThisApplication;
@property (nonatomic, readwrite, retain) id thumbnailHandle;
@property (nonatomic, readwrite, retain) NSString* nickname;
@property (nonatomic, readwrite, assign) GreeUserGrade userGrade;
@property (nonatomic, readwrite, retain) NSString* birthday;
@property (nonatomic, readwrite, retain) NSDate* creationDate;
@property (nonatomic, readwrite, copy) void (^thumbnailCompletionBlock)(UIImage* icon, NSError* error);
@property (nonatomic, readwrite, retain) NSURL* thumbnailUrl;
@property (nonatomic, readwrite, retain) NSURL* thumbnailUrlSmall;
@property (nonatomic, readwrite, retain) NSURL* thumbnailUrlLarge;
@property (nonatomic, readwrite, retain) NSURL* thumbnailUrlXlarge;
@property (nonatomic, readwrite, retain) NSURL* thumbnailUrlHuge;
@property (nonatomic, readwrite, retain) NSString* language;
@property (nonatomic, readwrite, retain) NSString* timeZone;
@property (nonatomic, readwrite, retain) NSString* displayName;
@property (nonatomic, readwrite, retain) NSURL* profileUrl;
@property (nonatomic, readwrite, retain) NSString* userHash;
@property (nonatomic, readwrite, retain) NSString* userType;
@property (nonatomic, readwrite, retain) NSString* userId;
@property (nonatomic, readwrite, retain) NSString* aboutMe;
@property (nonatomic, readwrite, retain) NSString* gender;
@property (nonatomic, readwrite, retain) NSString* age;
@property (nonatomic, readwrite, retain) NSString* bloodType;
@property (nonatomic, readwrite, retain) NSString* region;
@property (nonatomic, readwrite, retain) NSString* subRegion;
@property (nonatomic, readwrite, retain) NSArray* userSpecified;

-(NSURL*)thumbnailUrlWithSize:(GreeUserThumbnailSize)size;
@end

@implementation GreeUser

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.userId = nil;
  self.nickname = nil;
  self.aboutMe = nil;
  self.birthday = nil;
  self.gender = nil;
  self.age = nil;
  self.bloodType = nil;
  self.region = nil;
  self.subRegion = nil;
  self.language = nil;
  self.timeZone = nil;
  self.creationDate = nil;
  self.thumbnailCompletionBlock = nil;
  self.userSpecified = nil;

  self.displayName = nil;
  self.userHash = nil;
  self.userType = nil;
  self.profileUrl = nil;
  self.thumbnailUrl = nil;
  self.thumbnailUrlSmall = nil;
  self.thumbnailUrlLarge = nil;
  self.thumbnailUrlXlarge = nil;
  self.thumbnailUrlHuge = nil;
  self.thumbnailHandle = nil;

  [super dealloc];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if (self != nil) {
    self.userId = [serializer objectForKey:@"id"];
    self.nickname = [serializer objectForKey:@"nickname"];
    self.aboutMe = [serializer objectForKey:@"aboutMe"];
    self.birthday = [serializer objectForKey:@"birthday"];
    self.gender = [serializer objectForKey:@"gender"];
    self.age = [serializer objectForKey:@"age"];
    self.bloodType = [serializer objectForKey:@"bloodType"];
    self.userGrade = [serializer integerForKey:@"userGrade"];
    self.region = [serializer objectForKey:@"region"];
    self.subRegion = [serializer objectForKey:@"subregion"];
    self.language = [serializer objectForKey:@"language"];
    self.timeZone = [serializer objectForKey:@"timezone"];
    self.userSpecified = (NSArray*)[serializer objectForKey:@"userSpecified"];

    self.displayName = [serializer objectForKey:@"displayName"];
    self.hasThisApplication = [serializer boolForKey:@"hasApp"];

    self.userHash = [serializer objectForKey:@"userHash"];
    self.userType = [serializer objectForKey:@"userType"];
    self.profileUrl = [serializer urlForKey:@"profileUrl"];
    self.thumbnailUrl = [serializer urlForKey:@"thumbnailUrl"];
    self.thumbnailUrlSmall = [serializer urlForKey:@"thumbnailUrlSmall"];
    self.thumbnailUrlLarge = [serializer urlForKey:@"thumbnailUrlLarge"];
    self.thumbnailUrlXlarge = [serializer urlForKey:@"thumbnailUrlXlarge"];
    self.thumbnailUrlHuge = [serializer urlForKey:@"thumbnailUrlHuge"];

    self.creationDate = [serializer dateForKey:@"creationDate"];
    if(!self.creationDate) {
      self.creationDate = [NSDate date];
    }
  }

  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.userId forKey:@"id"];
  [serializer serializeObject:self.nickname forKey:@"nickname"];
  [serializer serializeObject:self.aboutMe forKey:@"aboutMe"];
  [serializer serializeObject:self.birthday forKey:@"birthday"];
  [serializer serializeObject:self.gender forKey:@"gender"];
  [serializer serializeObject:self.age forKey:@"age"];
  [serializer serializeObject:self.bloodType forKey:@"bloodType"];
  [serializer serializeInteger:self.userGrade forKey:@"userGrade"];
  [serializer serializeObject:self.region forKey:@"region"];
  [serializer serializeObject:self.subRegion forKey:@"subregion"];
  [serializer serializeObject:self.language forKey:@"language"];
  [serializer serializeObject:self.timeZone forKey:@"timezone"];
  [serializer serializeObject:self.userSpecified forKey:@"userSpecified"];

  [serializer serializeObject:self.displayName forKey:@"displayName"];
  [serializer serializeBool:self.hasThisApplication forKey:@"hasApp"];
  [serializer serializeObject:self.userHash forKey:@"userHash"];
  [serializer serializeObject:self.userType forKey:@"userType"];
  [serializer serializeUrl:self.profileUrl forKey:@"profileUrl"];
  [serializer serializeUrl:self.thumbnailUrl forKey:@"thumbnailUrl"];
  [serializer serializeUrl:self.thumbnailUrlSmall forKey:@"thumbnailUrlSmall"];
  [serializer serializeUrl:self.thumbnailUrlLarge forKey:@"thumbnailUrlLarge"];
  [serializer serializeUrl:self.thumbnailUrlXlarge forKey:@"thumbnailUrlXlarge"];
  [serializer serializeUrl:self.thumbnailUrlHuge forKey:@"thumbnailUrlHuge"];

  [serializer serializeDate:self.creationDate forKey:@"creationDate"];

}

#pragma mark - Public Interface

-(BOOL)isNicknameRegistered
{
  return [self.userSpecified containsObject:@"nickname"];
}

+(void)registerNickName:(NSString*)nickname block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"nickname", nil],
    nickname
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = [NSDictionary dictionaryWithObject:nickname
                                                     forKey:@"nickname"];


  NSString* path = @"/api/rest/register";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  [[GreePlatform sharedInstance].httpClient
     postPath:path
   parameters:params
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     GreeUser* cachedUser = [GreeUser localUserFromCache];
     cachedUser.nickname = nickname;

     NSMutableArray* newSpecified = [NSMutableArray arrayWithArray:cachedUser.userSpecified];
     [newSpecified addObject:@"nickname"];
     cachedUser.userSpecified = newSpecified;

     [[NSNotificationCenter defaultCenter] postNotificationName:kGreeNSNotificationKeyUpdateNickname object:cachedUser];
     block(nil);

     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* aError) {
     block(MakeGreeError(operation, aError));
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }
  ];
}

+(void)loadUserWithId:(NSString*)userId block:(void (^)(GreeUser* user, NSError* error))block
{
  [GreeUser loadUserWithId:userId isLimitedInfo:NO block:block];
}

+(void)loadUserWithId:(NSString*)userId isLimitedInfo:(BOOL)isLimitedInfo block:(void (^)(GreeUser* user, NSError* error))block
{
  if (!block) {
    return;
  }

  NSString* path = [NSString stringWithFormat:@"/api/rest/people/%@/@self", userId];

  void (^successBlock)(GreeAFHTTPRequestOperation*, id) =^(GreeAFHTTPRequestOperation* operation, id responseObject){
    NSDictionary* entry = [responseObject objectForKey:@"entry"];
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:entry];
    GreeUser* user = [[GreeUser alloc] initWithGreeSerializer:serializer];
    block(user, nil);
    [user release];
    if ([GreePlatform sharedInstance].benchmark) {
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
    }
  };

  void (^failureBlock)(GreeAFHTTPRequestOperation*, NSError*) =^(GreeAFHTTPRequestOperation* operation, NSError* error){
    block(nil, [GreeError convertToGreeError:error]);
    if ([GreePlatform sharedInstance].benchmark) {
      [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
    }
  };

  NSDictionary* queryParameters = nil;
  if (isLimitedInfo) {
    queryParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"id,nickname,displayName,thumbnailUrl,thumbnailUrlSmall,thumbnailUrlLarge,thumbnailUrlXlarge,thumbnailUrlHuge", @"fields",
                       nil];

  } else {
    queryParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"id,nickname,displayName,userGrade,region,subregion,language,timezone,aboutMe,birthday,profileUrl,thumbnailUrl,thumbnailUrlSmall,thumbnailUrlLarge,thumbnailUrlXlarge,thumbnailUrlHuge,gender,age,bloodType,hasApp,userHash,userType,userSpecified",
                       @"fields",
                       nil];
  }

  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:queryParameters
      success:successBlock
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     failureBlock(operation, error);
   }];
}

-(id<GreeCountableEnumerator>)loadFriendsWithBlock:(void (^)(NSArray* friends, NSError* error))block
{
  id<GreeCountableEnumerator> enumerator = [[GreeFriendEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator setGuid:self.userId];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

-(id<GreeEnumerator>)loadIgnoredUserIdsWithBlock:(void (^)(NSArray* ignoredUserIds, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeIgnoredUserIdEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator setGuid:self.userId];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

-(void)loadThumbnailWithSize:(GreeUserThumbnailSize)size block:(void (^)(UIImage* icon, NSError* error))block
{
  [self cancelThumbnailLoad];
  if(!block) {
    return;
  }

  NSURL* url = [self thumbnailUrlWithSize:size];

  self.thumbnailCompletionBlock = block;
  self.thumbnailHandle = [[[GreePlatform sharedInstance] httpClient] downloadImageAtUrl:url withBlock:^(UIImage* image, NSError* error) {
                            if(self.thumbnailCompletionBlock) { //it wasn't canceled
                              if(image.size.width > 0) { //make sure it's a real image, 404 errors send a blank image....
                                self.thumbnailCompletionBlock(image, error);
                                self.thumbnailCompletionBlock = nil;
                              } else {
                                [GreeUser loadUserWithId:self.userId block:^(GreeUser* user, NSError* error) {
                                   if(user) {
                                     self.thumbnailUrl = user.thumbnailUrl;
                                     self.thumbnailUrlSmall = user.thumbnailUrlSmall;
                                     self.thumbnailUrlLarge = user.thumbnailUrlLarge;
                                     self.thumbnailUrlXlarge = user.thumbnailUrlXlarge;
                                     self.thumbnailUrlHuge = user.thumbnailUrlHuge;
                                     self.creationDate = [NSDate date];
                                     //need to store it if this is the local user
                                     if([[GreePlatform sharedInstance].localUserId isEqualToString:self.userId]) {
                                       [GreeUser storeLocalUser:self];
                                     }
                                   }
                                   if(self.thumbnailCompletionBlock) {
                                     self.thumbnailHandle = [[[GreePlatform sharedInstance] httpClient] downloadImageAtUrl:[self thumbnailUrlWithSize:size] withBlock:^(UIImage* image, NSError* error) {
                                                               if(self.thumbnailCompletionBlock) {
                                                                 self.thumbnailCompletionBlock(image, error);
                                                                 self.thumbnailCompletionBlock = nil;
                                                               }
                                                             }];
                                   }
                                 }];
                              }
                            }
                          }];
}

-(void)cancelThumbnailLoad
{
  [[[GreePlatform sharedInstance] httpClient] cancelWithHandle:self.thumbnailHandle];
  self.thumbnailHandle = nil;
  self.thumbnailCompletionBlock = nil;
}

-(void)isIgnoringUserWithId:(NSString*)ignoredUserId block:(void (^)(BOOL isIgnored, NSError* error))block
{
  if (!block) {
    return;
  }

  NSString* path = [NSString stringWithFormat:@"/api/rest/ignorelist/%@/@all/%@", self.userId, ignoredUserId];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
     id responseEntry = [responseObject objectForKey:@"entry"];
     if ([responseEntry isKindOfClass:[NSString class]]) {
       block(NO, nil);
     } else if([responseEntry isKindOfClass:[NSArray class]] || [responseEntry isKindOfClass:[NSDictionary class]]) {
       block(YES, nil);
     } else {
       block(NO, [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     block(NO, [GreeError convertToGreeError:error]);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, id:%@, nickname:%@, hasThisApplication:%@, userGrade:%d, region:%@, subRegion:%@, language:%@, timeZone:%@>",
          NSStringFromClass([self class]),
          self,
          self.userId,
          self.nickname,
          self.hasThisApplication ? @"YES": @"NO",
          self.userGrade,
          self.region,
          self.subRegion,
          self.language,
          self.timeZone];
}

-(BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[GreeUser class]]) {
    return [self.userId isEqualToString:[object userId]];
  }

  return NO;
}

-(NSUInteger)hash
{
  return [self.userId hash];
}

#pragma mark - Internal Methods

-(NSURL*)thumbnailUrlWithSize:(GreeUserThumbnailSize)size
{
  NSURL* url = nil;
  switch (size) {
  case GreeUserThumbnailSizeSmall :
    url = self.thumbnailUrlSmall;
    break;
  default:
  case GreeUserThumbnailSizeStandard:
    url = self.thumbnailUrl;
    break;
  case GreeUserThumbnailSizeLarge:
    url = self.thumbnailUrlLarge;
    break;
  case GreeUserThumbnailSizeXlarge:
    url = self.thumbnailUrlXlarge;
    break;
  case GreeUserThumbnailSizeHuge:
    url = self.thumbnailUrlHuge;
    break;
  }
  return url;
}


#pragma mark - LocalUser Methods

+(GreeUser*)localUserFromCache
{
  GreeUser* anUser = nil;
  NSDictionary* serializedObject = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kGreeUserDefaultsLocalUserKey];
  if (serializedObject) {
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:[serializedObject objectForKey:@"user"]];
    anUser = [[[GreeUser alloc] initWithGreeSerializer:serializer] autorelease];
  }
  return anUser;
}

+(void)storeLocalUser:(GreeUser*)aUser
{
  GreeSerializer* serializer = [GreeSerializer serializer];
  [serializer serializeObject:aUser forKey:@"user"];
  [[NSUserDefaults standardUserDefaults] setObject:serializer.rootDictionary forKey:kGreeUserDefaultsLocalUserKey];
}

+(void)removeLocalUserInCache
{
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGreeUserDefaultsLocalUserKey];
}

+(void)upgradeLocalUser:(GreeUserGrade)grade
{
  [GreePlatform sharedInstance].localUser.userGrade = grade;
}

+(void)setLocalUserNickname:(NSString*)nickname
{
  [GreePlatform sharedInstance].localUser.nickname = nickname;
}

+(void)setLocalUserBirthday:(NSDate*)birthday
{
  NSDateFormatter* df = [[NSDateFormatter alloc] init];
  df.dateFormat = @"yyyy-MM-dd";
  NSString* birthdayAsString = [df stringFromDate:birthday];
  [df release];

  [GreePlatform sharedInstance].localUser.birthday = birthdayAsString;
}

+(void)setIsAppStarted:(BOOL)started
{
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:started] forKey:kGreeUserDefaultsIsAppStartedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+(BOOL)isAppStarted
{
  return [[[NSUserDefaults standardUserDefaults] objectForKey:kGreeUserDefaultsIsAppStartedKey] intValue] == 1;
}


@end

#pragma mark - GreeFriendEnumerator
@implementation GreeFriendEnumerator

#pragma mark - GreeEnumeratorBase Overrides

-(NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/people/%@/@friends", self.guid];
}

-(NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeUser class]];
}

@end

#pragma mark - GreeIgnoredUserIdEnumerator

@implementation GreeIgnoredUserIdEnumerator

#pragma mark - GreeEnumeratorBase Overrides

-(NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/ignorelist/%@/@all", self.guid];
}

-(NSArray*)convertData:(NSArray*)input
{
  NSMutableArray* ignoredIds = [[NSMutableArray alloc] initWithCapacity:[input count]];
  for (NSDictionary* entry in input) {
    if ([entry isKindOfClass:[NSDictionary class]]) {
      [ignoredIds addObject:[NSString stringWithFormat:@"%@", [entry objectForKey:@"ignorelistId"]]];
    }
  }

  NSArray* immutableResponse = [NSArray arrayWithArray:ignoredIds];
  [ignoredIds release];
  return immutableResponse;
}

@end
