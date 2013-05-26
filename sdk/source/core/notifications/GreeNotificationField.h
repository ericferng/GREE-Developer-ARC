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

extern NSString* const kGreeInviteNotificationField;
extern NSString* const kGreeTargetNotificationField;
extern NSString* const kGreeOtherNotificationField;
extern NSString* const kGreeActivityNotificationField;
extern NSString* const kGreeFriendNotificationField;

@class GreeNotificationFeed;

@interface GreeNotificationField : NSObject<NSCoding>
@property (nonatomic, retain, readonly) NSString* fieldName;
@property (nonatomic, retain, readonly) NSString* url;
@property (nonatomic, retain, readonly) NSString* message;
@property (nonatomic, retain) NSArray* feeds;
@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign, readonly) NSInteger limit;
@property (nonatomic, assign, readonly) BOOL hasMore;
-(id)initWithName:(NSString*)name
              url:(NSString*)url
          message:(NSString*)message
            feeds:(NSArray*)feeds
           offset:(NSInteger)offset
            limit:(NSInteger)limit
          hasMore:(BOOL)hasMore;
-(void)addFeed:(GreeNotificationFeed*)feed;
-(void)addFeeds:(NSArray*)feeds;
-(void)addFeedsFromField:(GreeNotificationField*)field;
@end
