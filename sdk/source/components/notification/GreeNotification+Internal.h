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

#import "GreeNotification.h"

@interface GreeNotification (Internal)

// Holds the information necessary to build launch URLs
@property (nonatomic, retain, readonly) NSDictionary* infoDictionary;
@property (nonatomic, retain, readonly) UIImage* iconImage;
@property (nonatomic, retain, readonly) NSString* badgeString;

// Creates a notification from an Apple Push Notification payload dictionary.
+(id)notificationWithAPSDictionary:(NSDictionary*)dictionary;

// Creates a standard welcome notification for user login
+(id)notificationForLoginWithUsername:(NSString*)username;

// Creates a notification from a Local Notification payload dictionary.
+(id)notificationWithLocalNotificationDictionary:(NSDictionary*)dictionary;

-(void)loadIconWithBlock:(void (^)(NSError* error))block;

@end
