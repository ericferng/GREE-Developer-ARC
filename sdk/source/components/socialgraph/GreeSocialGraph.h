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


#import <Foundation/Foundation.h>
#import "GreeEnumerator.h"


@interface GreeSocialGraph : NSObject

@property (nonatomic, retain, readonly) NSString* userId;
@property (nonatomic, retain, readonly) NSString* graphId;
@property (nonatomic, retain, readonly) NSString* relationId;


// parameters:
// - GreeSocialGraphParameterKeyStartIndex:
//   default: 0
//   using paging for starting index
// - GreeSocialGraphParameterKeyPageSize:
//   default: 10
//   using paging for page size
// - GreeSocialGraphParameterKeyOrderBy:
//   using sorting algorithm
//   specify 0..N values through NSArray
// - GreeSocialGraphParameterKeyUserId:
//   default: GreeSocialGraphParameterUserIdMe(@me)
//   using whether retrieve who graph object
//   can specify user id of a game friend
// - GreeSocialGraphParameterKeySelector:
//   default: GreeSocialGraphParameterSelectorApp(@app)
//   can retrieve game friends of current application in current version of api
+(id<GreeEnumerator>)loadFriendListWithParameters:(NSDictionary*)parameters block:(GreeEnumeratorResponseBlock)block;

// parameters:
// - GreeSocialGraphParameterKeyUserId:
//   default: GreeSocialGraphParameterUserIdMe(@me)
//   using whether retrieve who graph object
//   can specify user id of a game friend
// - GreeSocialGraphParameterKeySelector:
//   default: GreeSocialGraphParameterSelectorApp(@app)
//   can retrieve game friends of current application in current version of api
+(void)requestNumberOfFriendsWithParameters:(NSDictionary*)parameters block:(void (^)(NSInteger count, NSError* error))block;

// - userId:
//   using whether retrieve who graph object
//   can specify user id or @me
// - friendIds:
//   can specify just one game friend id in current version of api
//   specify the value of this parameter in NSArray
+(void)requestRelationshipWithUserId:(NSString*)userId friendId:(NSArray*)friendIds block:(void (^)(BOOL hasRelationship, NSError* error))block;

@end

extern NSString* const GreeSocialGraphParameterKeyStartIndex;
extern NSString* const GreeSocialGraphParameterKeyPageSize;
extern NSString* const GreeSocialGraphParameterKeyOrderBy;
extern NSString* const GreeSocialGraphParameterKeyUserId;
extern NSString* const GreeSocialGraphParameterKeySelector;

extern NSString* const GreeSocialGraphParameterUserIdMe;
extern NSString* const GreeSocialGraphParameterSelectorApp;
extern NSString* const GreeSocialGraphParameterOrderByWeight;
extern NSString* const GreeSocialGraphParameterOrderByCTime;
extern NSString* const GreeSocialGraphParameterOrderByMTime;
