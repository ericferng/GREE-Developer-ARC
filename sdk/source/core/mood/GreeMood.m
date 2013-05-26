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

#import "GreeMood.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import "GreeSerializer.h"
#import "GreeError+Internal.h"
#import "GreeSettings.h"

NSString* const GreeContentTypeMood = @"mood";
static NSString* const GreeMoodEntryIdKey = @"id";
static NSString* const GreeMoodEntryTextKey = @"text";
static NSString* const GreeMoodEntryAttachImageListKey = @"attach_image_list";
static NSString* const GreeMoodEntryCommentNumKey = @"comment_num";
static NSString* const GreeMoodEntryLikeNumKey = @"like_num";
static NSString* const GreeMoodEntryIsLikeUserKey = @"is_like_user";
static NSString* const GreeMoodEntryAttachImageLargeSizeKey = @"640";

@interface GreeMood ()

@property (nonatomic, assign, readwrite) NSInteger userId;
@property (nonatomic, assign, readwrite) NSInteger identifier;

@end

@implementation GreeMood

@synthesize userId = _userId;

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.text = nil;
  self.attachImageList = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(void)loadMoodId:(NSInteger)moodId
           userId:(NSInteger)userId
            block:(void (^)(GreeMood* mood, NSError* error))block
{
  if (!block) {
    return;
  }
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  NSString* connectUrl = [settings objectValueForSetting:GreeSettingServerUrlConnect];
  NSString* developmentMode = [settings stringValueForSetting:GreeSettingDevelopmentMode];
  if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] ||
      [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
    connectUrl = [connectUrl stringByReplacingOccurrencesOfString:@"gree-dev.net" withString:@"gree.jp"];
  }

  NSString* endpoint = @"/api/rest/mood/entries";
  NSString* urlString = [NSString stringWithFormat:@"%@%@/%d/%d", connectUrl, endpoint, userId, moodId];
  [[GreePlatform sharedInstance].httpClient getPath:urlString
                                         parameters:nil
                                            success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     GreeMood* returnMood = nil;
     NSError* returnError = nil;
     if(![responseObject isKindOfClass:[NSDictionary class]]) {
       returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
     } else {
       NSDictionary* returnDictionary = [responseObject objectForKey:@"entry"];
       if(![returnDictionary isKindOfClass:[NSDictionary class]]) {
         returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
       } else {
         GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:returnDictionary];
         returnMood = [[[GreeMood alloc] initWithGreeSerializer:serializer] autorelease];
       }
     }
     block(returnMood, returnError);
   }
                                            failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     block(nil, [GreeError convertToGreeError:error]);
   }];
}

-(id)initWithMoodId:(NSInteger)moodId userId:(NSInteger)userId
{
  self = [super init];
  if (self) {
    self.identifier = moodId;
    self.userId = userId;
  }
  return self;
}

#pragma mark - GreeSerializable Methods

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [self initWithMoodId:[serializer integerForKey:@"id"]
                       userId:[[[serializer objectForKey:@"user"] valueForKey:@"id"] intValue]];
  if (self) {
    self.text  = [serializer objectForKey:GreeMoodEntryTextKey];
    self.attachImageList = [NSMutableDictionary dictionary];
    NSArray* value640 =  [[serializer objectForKey:GreeMoodEntryAttachImageListKey]
                          valueForKey:GreeMoodEntryAttachImageLargeSizeKey];
    if (value640 && value640.count > 0) {
      [(NSMutableDictionary*)self.attachImageList setValue:[value640 objectAtIndex:0
       ]
                                                    forKey:GreeMoodEntryAttachImageLargeSizeKey];
    }
    self.commentNum = [serializer integerForKey:GreeMoodEntryCommentNumKey];
    self.likeNum = [serializer integerForKey:GreeMoodEntryLikeNumKey];
    self.isLikeUser = [serializer boolForKey:GreeMoodEntryIsLikeUserKey];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - GreeContent Datasource Methods

-(NSInteger)userId
{
  return _userId;
}

-(NSInteger)contentId
{
  return self.identifier;
}

-(NSString*)contentType
{
  return GreeContentTypeMood;
}

-(NSString*)imageUrlString
{
  return [self.attachImageList valueForKey:GreeMoodEntryAttachImageLargeSizeKey];
}

-(NSInteger)likeNum
{
  return _likeNum;
}

-(NSInteger)commentNum
{
  return _commentNum;
}

-(NSString*)title
{
  return nil;
}

-(NSString*)messega
{
  return _text;
}

-(BOOL)isLikeUser
{
  return _isLikeUser;
}

-(void)setIsLike:(BOOL)isLike
{
  _isLikeUser = isLike;
}

@end
