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

#import "GreePhoto.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import "GreeSerializer.h"
#import "GreeError+Internal.h"
#import "GreeSettings.h"

NSString* const GreeContentTypePhoto = @"photo";
static NSString* const GreePhotoEntryIdKey = @"id";
static NSString* const GreePhotoEntryAlbumIdKey = @"album_id";
static NSString* const GreePhotoEntryTitleKey = @"title";
static NSString* const GreePhotoEntryTextKey = @"text";
static NSString* const GreePhotoEntryCommentNumKey = @"comment_num";
static NSString* const GreePhotoEntryLikeNumKey = @"like_num";
static NSString* const GreePhotoEntryIsLikeUserKey = @"is_like_user";
static NSString* const GreePhotoEntryPhotoUrlKey = @"photo_url";
static NSString* const GreePhotoEntryPhotoLargeSizeKey = @"640";

@interface GreePhoto ()
@property (nonatomic, assign, readwrite) NSInteger userId;
@property (nonatomic, assign, readwrite) NSInteger identifier;
@end

@implementation GreePhoto

@synthesize userId = _userId;

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.title = nil;
  self.text = nil;
  self.photoUrlLists = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(void)loadPhotosWithAlbumId:(NSInteger)albumId
                      userId:(NSInteger)userId
                      offset:(NSInteger)offset
                       limit:(NSInteger)limit
                       block:(void (^)(NSArray* photos, NSError* error))block
{
  if (limit <= 0) {
    limit = 20;
  }

  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  NSString* connectUrl = [settings objectValueForSetting:GreeSettingServerUrlConnect];
  NSString* developmentMode = [settings stringValueForSetting:GreeSettingDevelopmentMode];
  if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] ||
      [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
    connectUrl = [connectUrl stringByReplacingOccurrencesOfString:@"gree-dev.net" withString:@"gree.jp"];
  }
  NSString* endpoint = @"/api/rest/photo/entries";
  NSString* urlString = [NSString stringWithFormat:@"%@%@/%d",
                         connectUrl,
                         endpoint,
                         userId];
  NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%d", albumId], GreePhotoEntryAlbumIdKey
                              , [NSString stringWithFormat:@"%d", offset], @"offset"
                              , [NSString stringWithFormat:@"%d", limit], @"limit"
                              , nil];
  [[GreePlatform sharedInstance].httpClient getPath:urlString
                                         parameters:parameters
                                            success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSArray* returnArray = nil;
     NSError* returnError = nil;
     if(![responseObject isKindOfClass:[NSDictionary class]]) {
       returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
     } else {
       returnArray = [responseObject objectForKey:@"entry"];
       if(![returnArray isKindOfClass:[NSArray class]]) {
         returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
       } else {
         returnArray = [GreeSerializer deserializeArray:returnArray
                                              withClass:[GreePhoto class]];
         if (returnArray.count == 0) {
           returnArray = nil;
         }
       }
     }
     block(returnArray, returnError);
   }
                                            failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     block(nil, [GreeError convertToGreeError:error]);
   }];
}

-(id)initWithPhotoId:(NSInteger)photoId albumId:(NSInteger)albumId userId:(NSInteger)userId
{
  self = [super init];
  if (self) {
    self.identifier = photoId;
    self.albumId = albumId;
    self.userId = userId;
    self.photoUrlLists = [NSMutableDictionary dictionary];
  }
  return self;
}

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  GreePhoto* photo = [self initWithPhotoId:[serializer integerForKey:GreePhotoEntryIdKey]
                                   albumId:[serializer integerForKey:GreePhotoEntryAlbumIdKey]
                                    userId:[[[serializer objectForKey:@"user"] valueForKey:@"id"] intValue]];
  if (photo) {
    photo.title = [serializer objectForKey:GreePhotoEntryTitleKey];
    photo.text = [serializer objectForKey:GreePhotoEntryTextKey];
    photo.commentNum = [serializer integerForKey:GreePhotoEntryCommentNumKey];
    photo.likeNum = [serializer integerForKey:GreePhotoEntryLikeNumKey];
    photo.isLikeUser = [serializer boolForKey:GreePhotoEntryIsLikeUserKey];

    NSString* url640string = [[serializer objectForKey:GreePhotoEntryPhotoUrlKey] valueForKey:GreePhotoEntryPhotoLargeSizeKey];
    if (url640string) {
      [(NSMutableDictionary*)self.photoUrlLists setValue:url640string forKey:GreePhotoEntryPhotoLargeSizeKey];
    }
  }
  return photo;
}

#pragma mark - GreeSerializable Methods

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - GreeContent Datasource Methods

-(NSInteger)userId
{
  return _userId;
}

-(NSString*)contentType
{
  return GreeContentTypePhoto;
}

-(NSInteger)contentId
{
  return self.identifier;
}

-(NSString*)imageUrlString
{
  return [self.photoUrlLists objectForKey:GreePhotoEntryPhotoLargeSizeKey];
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
  return _title;
}

-(NSString*)messega
{
  return _text;
}

-(BOOL)isLikeUser
{
  return _isLikeUser;
}

@end
