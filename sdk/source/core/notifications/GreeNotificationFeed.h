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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "GreeSerializer.h"
#import "GreeSerializable.h"

@interface GreeNotificationMessageData : NSObject<GreeSerializable, NSCoding>
@property (nonatomic, retain, readonly) NSString* text;
@property (nonatomic, assign, readonly) BOOL bold;
@property (nonatomic, retain, readonly) UIColor* color;
-(id)initWithText:(NSString*)text bold:(BOOL)bold color:(UIColor*)color;
@end

extern NSString *const GreeNotificationFeedFriendTypeLinkPending;
extern NSString* const GreeNotificationFeedFriendTypeRegistration;
extern NSString* const GreeNotificationFeedFriendTypeLinkApproved;

@interface GreeNotificationFeed : NSObject<GreeSerializable, NSCoding>

@property (nonatomic, retain, readonly) NSString* feedKey;
@property (nonatomic, retain, readonly) NSString* nameSpace;
@property (nonatomic, retain, readonly) NSString* thumbnailPath;
@property (nonatomic, retain, readonly) NSString* message;
@property (nonatomic, retain, readonly) NSString* url;
@property (nonatomic, retain, readonly) NSString* appName;
@property (nonatomic, retain, readonly) NSDate* date;
@property (nonatomic, retain, readonly) NSDictionary* messageDatas;
@property (nonatomic, assign) BOOL unread;
@property (nonatomic, assign, readonly) BOOL launchExternal;

-(id)initWithFeedKey:(NSString*)feedKey
           nameSpace:(NSString*)nameSpace
       thumbnailPath:(NSString*)thumbnailPath
             message:(NSString*)message
                 url:(NSString*)url
             appName:(NSString*)appName
                date:(NSDate*)date
        messegeDatas:(NSDictionary*)messageDatas
              unread:(BOOL)unread
      launchExternal:(BOOL)launchExternal;
-(void)loadThumbnailWithBlock:(void (^)(UIImage* icon, NSError* error))block;

@end
