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

#import "GreeIncentive.h"
#import "JSONKit.h"
#import "GreeLogger.h"
#import "GreeEnumerator+Internal.h"
#import "AFNetworking.h"
#import "GreeSerializer.h"
#import "GreeError+Internal.h"

#import "GreePlatform.h"
#import "GreeSettings.h"
#import "GreeIncentive+Internal.h"


const NSInteger maxKeyLength = 16;


@interface GreeIncentive ()
@property (nonatomic, readwrite, retain) NSDictionary* payloadDictionary;
@property (nonatomic, readwrite, retain) NSString* appId;
@property (nonatomic, readwrite, retain) NSString* incentiveEventId;
@property (nonatomic, readwrite, retain) NSString* incentiveEventPayloadId;
@property (nonatomic, readwrite, assign) GreeIncentiveType incentiveType;
@property (nonatomic, readwrite, retain) NSString* fromUserId;
@property (nonatomic, readwrite, retain) NSString* toUserId;
@property (nonatomic, readwrite) GreeIncentiveDelivered delivered;

@end

@interface GreeIncentiveEnumerator : GreeEnumeratorBase

@property       (nonatomic, assign) GreeIncentiveDelivered delivered;
@property       (nonatomic, assign) GreeIncentiveType incentiveType;
@property       (nonatomic, assign) NSUInteger timestamp;

-(id)initWithStartIndex:(NSInteger)startIndex
               pageSize:(NSInteger)pageSize
              delivered:(GreeIncentiveDelivered)delivered
            payloadType:(GreeIncentiveType)incentiveType
              timestamp:(NSUInteger)timestamp;

@end


@implementation GreeIncentive

#pragma mark - Object Lifecycle

// Designated initializer
-(id)initWithType:(GreeIncentiveType)incentiveType payloadDictionary:(NSDictionary*)payloadDictionary
{
  self = [super init];
  if (self != nil) {
    self.payloadDictionary = payloadDictionary;
    self.incentiveType = incentiveType;
    self.appId = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId];
  }
  return self;
}

-(void)dealloc
{
  self.payloadDictionary = nil;
  [super dealloc];
}


#pragma mark - Public Interface

-(void)postIncentiveToUsers:(NSArray*)targetUserIds block:(void (^)(NSString* numberOfTargets, NSError* error))block
{


  NSString* userIdList = [targetUserIds componentsJoinedByString:@","];
  NSString* postPath = [NSString stringWithFormat:@"/api/rest/incentiverequest/%@/%d/", userIdList, (int)self.incentiveType];

  [[GreePlatform sharedInstance].httpClient postPath:postPath parameters:self.payloadDictionary success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if(block) {
       NSString* targetCount = [responseObject objectForKey:@"entry"];
       NSError* err = nil;
       if(!targetCount) {
         err = [GreeError localizedGreeErrorWithCode:GreeIncentiveSubmitFailed];
       }
       block(targetCount, err);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(block) {
       block(nil, [GreeError convertToGreeError:error]);
     }
   }];
}


+(id<GreeEnumerator>)loadUnprocessedIncentivesOfType:(GreeIncentiveType)payloadType
                                           withBlock:(void (^)(NSArray* incentives, NSError* error))block
{

  id<GreeEnumerator> enumerator = [[GreeIncentiveEnumerator alloc] initWithStartIndex:0
                                                                             pageSize:0
                                                                            delivered:GreeIncentiveNotDelivered
                                                                          payloadType:payloadType
                                                                            timestamp:0];

  [enumerator loadNext:block];
  return [enumerator autorelease];
}

-(void)completeWithBlock:(void (^)(NSError* error))block
{
  NSString* putPath = [NSString stringWithFormat:@"/api/rest/incentiverequest/%@", self.incentiveEventId];

  [[GreePlatform sharedInstance].httpClient putPath:putPath parameters:nil success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if(block) {
       NSError* err = nil;
       block(err);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(block) {
       block([GreeError convertToGreeError:error]);
     }
   }];

}

-(NSString*)serialize
{
  NSString* returnString = [self.payloadDictionary greeJSONString];
  return returnString;
}


#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if (self != nil) {
    self.incentiveEventId = [serializer objectForKey:@"incentive_event_id"];
    self.appId = [serializer objectForKey:@"app_id"];
    self.fromUserId = [serializer objectForKey:@"from_user_id"];
    self.toUserId = [serializer objectForKey:@"to_user_id"];
    self.incentiveEventPayloadId = [serializer objectForKey:@"incentive_event_payload_id"];
    self.incentiveType = [[serializer objectForKey:@"payload_type"] intValue];
    self.delivered = [[serializer objectForKey:@"delivered"] intValue];

    NSString* payload = [serializer objectForKey:@"payload"];
    if (payload) {
      self.payloadDictionary = [payload greeObjectFromJSONString];
    }
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.incentiveEventId forKey:@"incentive_event_id"];
  [serializer serializeObject:self.appId forKey:@"app_id"];
  [serializer serializeObject:self.fromUserId forKey:@"from_user_id"];
  [serializer serializeObject:self.toUserId forKey:@"to_user_id"];
  [serializer serializeObject:self.incentiveEventPayloadId forKey:@"incentive_event_payload_id"];
  [serializer serializeObject:[NSNumber numberWithInt:self.incentiveType] forKey:@"payload_type"];
  [serializer serializeObject:[NSNumber numberWithInt:self.delivered] forKey:@"delivered"];

  [serializer serializeObject:self.payloadDictionary forKey:@"payload"];
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, incentiveEventId: %@, appId: %@, fromUserId: %@, toUserId: %@, incentiveEventPayloadId: %@, payloadType: %d, delivered: %d,  incentivePayload: %@>",
          NSStringFromClass([self class]), self, self.incentiveEventId, self.appId, self.fromUserId, self.toUserId, self.incentiveEventPayloadId, self.incentiveType, self.delivered, self.payloadDictionary];
}


-(BOOL)isEqual:(id)anObject
{
  if ([anObject isKindOfClass:[GreeIncentive class]] &&
      [self.incentiveEventId isEqualToString:((GreeIncentive*)anObject).incentiveEventId]) {
    return YES;
  }
  return NO;
}


@end


#pragma mark - GreeIncentiveEnumerator

@implementation GreeIncentiveEnumerator

-(id)initWithStartIndex:(NSInteger)startIndex
               pageSize:(NSInteger)pageSize
              delivered:(GreeIncentiveDelivered)delivered
            payloadType:(GreeIncentiveType)incentiveType
              timestamp:(NSUInteger)timestamp
{
  self = [super initWithStartIndex:startIndex pageSize:pageSize];
  if (self != nil) {
    self.delivered = delivered;
    self.incentiveType = incentiveType;
    self.timestamp = timestamp;
  }
  return self;
}

-(void)dealloc
{
  [super dealloc];
}


#pragma mark - GreeEnumerator overrides

-(NSString*)httpRequestPath
{
  return @"/api/rest/incentiverequest";
}

-(NSArray*)convertData:(NSArray*)input
{
  NSArray* deserialized = [GreeSerializer deserializeArray:input withClass:[GreeIncentive class]];

  return deserialized;
}

-(void)updateParams:(NSMutableDictionary*)params
{
  [params setObject:[NSNumber numberWithInt:(int)self.delivered] forKey:@"delivered"];
  [params setObject:[NSNumber numberWithInt:(int)self.incentiveType] forKey:@"payload_type"];
  if (self.timestamp > 0) {
    [params setObject:[NSNumber numberWithUnsignedInteger:self.timestamp] forKey:@"timestamp"];
  }
}

@end
