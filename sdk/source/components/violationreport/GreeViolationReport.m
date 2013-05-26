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
#import "GreeError+Internal.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "GreeSerializable.h"
#import "GreeSerializer.h"
#import "GreeViolationReport.h"


const NSString* const GreeViolationReportParameterCategoryIdKey         = @"categoryId";
const NSString* const GreeViolationReportParameterCommentKey            = @"comment";
const NSString* const GreeViolationReportParameterTargetUserIdKey       = @"targetUserId";
const NSString* const GreeViolationReportParameterTextIdKey             = @"textId";
static const NSString* const GreeViolationReportParameterContentTypeKey = @"contentType";

static const int GreeViolationReportContentTypeValue = 9999;


@interface GreeViolationReport ()<GreeSerializable>
@property (nonatomic, retain) NSString* reportId;
@property (nonatomic, retain) NSString* appId;
@property (nonatomic, retain) NSString* userId;
@property (nonatomic, retain) NSString* comment;
@property (nonatomic, retain) NSString* targetUserId;
@property (nonatomic, retain) NSString* textId;
@property (nonatomic, retain) NSDate* reportedTime;
@end


@implementation GreeViolationReport

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.reportId = nil;
  self.appId = nil;
  self.userId = nil;
  self.comment = nil;
  self.targetUserId = nil;
  self.textId = nil;
  self.reportedTime = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(void)reportWithParameters:(NSDictionary*)parameters block:(void (^)(GreeViolationReport* report, NSError* error))block
{
  NSMutableDictionary* postParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [postParameters
   setObject:[NSNumber numberWithInt:GreeViolationReportContentTypeValue]
      forKey:GreeViolationReportParameterContentTypeKey];

  [[GreePlatform sharedInstance].httpClient
     postPath:@"api/rest/violationreport/@me/@app"
   parameters:postParameters
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if (block) {
       NSDictionary* entry = [responseObject objectForKey:@"entry"];
       GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:entry];
       GreeViolationReport* report = [[GreeViolationReport alloc] initWithGreeSerializer:serializer];
       block(report, nil);
       [report release];
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if (block) {
       block(nil, [GreeError convertToGreeError:error]);
     }
   }];
}

#pragma mark - GreeSerializable Overrides

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if(self) {
    self.reportId = [serializer objectForKey:@"reportedId"];
    self.appId = [serializer objectForKey:@"appId"];
    self.userId = [serializer objectForKey:@"userId"];
    self.comment = [serializer objectForKey:@"comment"];
    self.targetUserId = [serializer objectForKey:@"targetUserId"];
    self.textId = [serializer objectForKey:@"textId"];
    self.reportedTime = [serializer dateForKey:@"reportedTime"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, reportId:%@, appId:%@, userId:%@, comment:%@, targetUserId:%@, textId:%@, reportedTime:%@>",
          NSStringFromClass([self class]), self,
          self.reportId,
          self.appId,
          self.userId,
          self.comment,
          self.targetUserId,
          self.textId,
          self.reportedTime];
}

#pragma mark - Internal Methods

@end
