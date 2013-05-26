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

#import "GreeModeratedText.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeHTTPClient.h"
#import "GreeSerializer.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "GreeModerationList.h"
#import "GreeError+Internal.h"
#import "GreeBenchmark.h"

NSString* const GreeModeratedTextUpdatedNotification = @"GreeModeratedTextUpdatedNotification";

@interface GreeModeratedText ()
@property (nonatomic, retain, readwrite) NSString* content;
@property (nonatomic, retain, readwrite) NSString* ownerId;
@property (nonatomic, assign, readwrite) GreeModerationStatus status;
@property (nonatomic, retain, readwrite) NSDate* lastCheckedTimestamp;
@property (nonatomic, retain, readwrite) NSString* textId;
@property (nonatomic, retain, readwrite) NSString* appId;
@property (nonatomic, retain, readwrite) NSString* authorId;
@end

@implementation GreeModeratedText

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.textId = nil;
  self.appId = nil;
  self.authorId = nil;
  self.ownerId = nil;

  self.content = nil;

  self.lastCheckedTimestamp = nil;

  [super dealloc];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  if ((self = [super init])) {
    self.textId = [serializer objectForKey:@"textId"];
    self.appId = [serializer objectForKey:@"appId"];
    self.authorId = [serializer objectForKey:@"authorId"];
    self.ownerId = [serializer objectForKey:@"ownerId"];

    self.content = [serializer objectForKey:@"data"];
    NSString* statusString = [serializer objectForKey:@"status"];
    self.status = [statusString integerValue];

    self.lastCheckedTimestamp = [serializer dateForKey:@"lastCheckedTimestamp"];
  }

  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.textId forKey:@"textId"];
  [serializer serializeObject:self.appId forKey:@"appId"];
  [serializer serializeObject:self.authorId forKey:@"authorId"];
  [serializer serializeObject:self.ownerId forKey:@"ownerId"];

  [serializer serializeObject:self.content forKey:@"data"];

  NSString* statusString = [NSString stringWithFormat:@"%d", self.status];
  [serializer serializeObject:statusString forKey:@"status"];

  [serializer serializeDate:self.lastCheckedTimestamp forKey:@"lastCheckTimestamp"];
}


#pragma mark - Public Interface

+(void)createWithString:(NSString*)aString block:(void (^)(GreeModeratedText* createdUserText, NSError* error))block
{
  NSString* path = @"/api/rest/moderation/@app";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  NSDictionary* parameters = [NSDictionary dictionaryWithObject:aString forKey:@"data"];

  [[GreePlatform sharedInstance].httpClient
     postPath:path
   parameters:parameters
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSArray* entryItems = [responseObject objectForKey:@"entry"];
     NSArray* userTexts = [GreeSerializer deserializeArray:entryItems withClass:[GreeModeratedText class]];

     NSAssert([userTexts count] == 1, @"Creating a user did not return exactly one moderated text");

     if (block) {
       GreeModeratedText* firstText = [userTexts objectAtIndex:0];
       firstText.lastCheckedTimestamp = [NSDate date];
       block(firstText, nil);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }

      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if (block) {
       block(nil, error);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

+(void)loadFromIds:(NSArray*)textIds block:(void (^)(NSArray* userTexts, NSError* error))block
{
  if (!block) {
    return;
  }

  NSString* joinedTextIds = [textIds componentsJoinedByString:@","];
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", joinedTextIds];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  [[GreePlatform sharedInstance].httpClient
      getPath:path
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
     NSArray* entryItems = [responseObject objectForKey:@"entry"];
     NSArray* userTexts = [GreeSerializer deserializeArray:entryItems withClass:[GreeModeratedText class]];
     block(userTexts, nil);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }

      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     block(nil, error);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

-(void)updateWithString:(NSString*)updatedString block:(void (^)(NSError* error))block
{
  self.lastCheckedTimestamp = nil;
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", self.textId];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPut path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  NSDictionary* parameters = [NSDictionary dictionaryWithObject:updatedString forKey:@"data"];

  [[GreePlatform sharedInstance].httpClient
      putPath:path
   parameters:parameters
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     self.content = updatedString;
     [[NSNotificationCenter defaultCenter] postNotificationName:GreeModeratedTextUpdatedNotification object:self];
     if (block) {
       block(nil);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPut path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }

      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     if (block) {
       block([GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPut path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

-(void)deleteWithBlock:(void (^)(NSError* error))block
{
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", self.textId];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  [[GreePlatform sharedInstance].httpClient
   deletePath:path
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if (block) {
       block(nil);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   }

      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
     if (block) {
       block([GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

-(void)beginNotification
{
  GreeModerationList* modList = [[GreePlatform sharedInstance] moderationList];
  [modList addText:self];
}

-(void)endNotification
{
  GreeModerationList* modList = [[GreePlatform sharedInstance] moderationList];
  [modList removeText:self];
}

+(NSArray*)currentList
{
  GreeModerationList* modList = [GreePlatform sharedInstance].moderationList;
  return [modList currentList];
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, textId:%@, appId:%@, content:%@, status:%d lastUpdated:%@>",
          NSStringFromClass([self class]),
          self,
          self.textId,
          self.appId,
          self.content,
          self.status,
          self.lastCheckedTimestamp];
}

-(BOOL)isEqual:(id)object
{
  if (![object isMemberOfClass:[GreeModeratedText class]]) {
    return NO;
  }

  GreeModeratedText* userText = (GreeModeratedText*)object;

  return [self.textId isEqualToString:userText.textId];
}

-(NSUInteger)hash
{
  return [self.textId hash];
}

@end
