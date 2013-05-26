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

/**
 * @file GreeIncentive.h
 * A class to represent an incentive and its enumerator.
 */
#import <Foundation/Foundation.h>
#import "GreeEnumerator.h"


typedef enum {
  GreeIncentiveNotDelivered,
  GreeIncentiveAlreadyDelivered,
} GreeIncentiveDelivered;

typedef enum {
  GreeIncentiveTypeRequest = 1,
  GreeIncentiveTypeInvite = 2
} GreeIncentiveType;

@interface GreeIncentive : NSObject

@property (nonatomic, readonly, retain) NSString* fromUserId;
@property (nonatomic, readonly, retain) NSString* toUserId;
@property (nonatomic, readonly, retain) NSDictionary* payloadDictionary;
@property (nonatomic, readonly) GreeIncentiveType incentiveType;
@property (nonatomic, readonly) GreeIncentiveDelivered delivered;


/** 
 @brief Initializes a new incentive.
 @note This is the designated initializer.
 @param incentiveType The type of incentive of type GreeIncentiveType.
 @param payloadDictionary The dictionary used to fill the gree incentive payload - the keys and value pairs are arbitrary.
*/
//- (id)initWithDictionary:(NSDictionary*)incentiveDictionary;
-(id)initWithType:(GreeIncentiveType)incentiveType payloadDictionary:(NSDictionary*)payloadDictionary;

/**
 @brief Send an incentive to an array of users.
 @param targetUserIds An array of user id strings to send the incentive to.
 @param block The response block.  numberOfTargets will contain a value indicating the number of users successfully targeted.  error will be nil if no error.
 */
-(void)postIncentiveToUsers:(NSArray*)targetUserIds block:(void (^)(NSString* numberOfTargets, NSError* error))block;

/**
 @brief Will retrieve all pending request incentives and call block for each page.
 @param payloadType An enum of type GreeIncentiveType that describes if the payload should be of the Request or Invite types.
 @param block The response block.  incentives is a page of GreeIncentives retreived for each iteration.  error will be nil if no error.
 @note After processing each incentive, -completeWithBlock must be called.  Otherwise the incentive will be returned upon subsequent calls to this method.
 @return An enumerator for the page of incentives.
 */
+(id<GreeEnumerator>)loadUnprocessedIncentivesOfType:(GreeIncentiveType)payloadType withBlock:(void (^)(NSArray* incentives, NSError* error))block;

/**
 @brief Changes the incentive from a pending to delivered state.
 @param block The response block.  error will be nil if no error.
 */
-(void)completeWithBlock:(void (^)(NSError* error))block;

@end
