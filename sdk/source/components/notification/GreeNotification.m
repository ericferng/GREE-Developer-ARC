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

#import "GreeNotification+Internal.h"
#import "GreeSerializer.h"
#import "GreeAPSNotification.h"
#import "GreeLocalNotification.h"
#import "AFNetworking.h"
#import "GreeError+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeGlobalization.h"
#import "GreeSettings.h"
#import "UIImage+GreeAdditions.h"

#define NO_NOTIFICATION_DURATION -1.0f

@interface GreeNotification ()
@property (nonatomic, retain) NSDictionary* infoDictionary;

@property (nonatomic, assign) GreeAPSNotificationIconType iconFlag;
@property (nonatomic, retain) NSString* iconToken;
@property (nonatomic, retain) UIImage* iconImage;
@property (nonatomic, retain) NSString* badgeString;

@property (nonatomic, copy, readwrite) NSString* message;
@property (readwrite) GreeNotificationViewDisplayType displayType;
@property (readwrite) NSTimeInterval duration;

-(id)initWithAPSDictionary:(NSDictionary*)dictionary;
-(id)initWithLocalNotificationDictionary:(NSDictionary*)dictionary;
@end

const static NSTimeInterval localDefaultNotificationDuration = 3.0f;

@implementation GreeNotification

-(id)initWithMessage:(NSString*)message
         displayType:(GreeNotificationViewDisplayType)displayType
            duration:(NSTimeInterval)duration
{
  self = [super init];
  if (self != nil) {
    NSString* remoteDefaultNotificationDurationString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingDisplayTimeForInGameNotification];
    NSTimeInterval remoteDefaultNotificationDuration = remoteDefaultNotificationDurationString ? [remoteDefaultNotificationDurationString doubleValue] : NO_NOTIFICATION_DURATION;

    self.message = message;
    self.displayType = displayType;

    if (duration > 0.0f)
      self.duration = duration;
    else if (remoteDefaultNotificationDuration > 0.0f)
      self.duration = remoteDefaultNotificationDuration;
    else
      self.duration = localDefaultNotificationDuration;
  }

  return self;
}

-(id)initWithAPSDictionary:(NSDictionary*)dictionary
{
  NSDictionary* iam = [dictionary objectForKey:@"iam"];

  if (iam) {
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:[dictionary objectForKey:@"iam"]];
    GreeAPSNotification* apsNotification = [[[GreeAPSNotification alloc] initWithGreeSerializer:serializer] autorelease];
    NSString* inTimerNotificationDurationString = [serializer objectForKey:@"intimer"];
    NSTimeInterval inTimerNotificationDuration = inTimerNotificationDurationString ? [inTimerNotificationDurationString doubleValue] : NO_NOTIFICATION_DURATION;

    self = [self
            initWithMessage:apsNotification.text
                displayType:GreeNotificationViewDisplayDefaultType
                   duration:inTimerNotificationDuration];
    if (self != nil) {
      self.infoDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:@"dash", @"type",
                              [NSNumber numberWithInt:apsNotification.type], @"subtype",
                              apsNotification.actorId, @"actor_id",
                              apsNotification.contentId, @"cid",
                              nil] autorelease];
      self.iconFlag = apsNotification.iconFlag;
      self.iconToken = apsNotification.iconToken;
      self.badgeString = [[serializer objectForKey:@"badge"] description];
    }

  } else {
    NSDictionary* aps = [dictionary objectForKey:@"aps"];
    NSString* message_id = [aps objectForKey:@"message_id"];
    NSString* request_id = [aps objectForKey:@"request_id"];

    id alert = [aps objectForKey:@"alert"];
    NSString* text = [alert isKindOfClass:[NSDictionary class]] ? [alert objectForKey:@"body"] : alert;

    if (!alert) {
      [self release], self = nil;
    } else if (message_id) {
      self = [self initWithMessage:text displayType:GreeNotificationViewDisplayDefaultType duration:NO_NOTIFICATION_DURATION];
      self.infoDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:@"message", @"type", message_id, @"info-key", nil] autorelease];
    } else if (request_id) {
      self = [self initWithMessage:text displayType:GreeNotificationViewDisplayDefaultType duration:NO_NOTIFICATION_DURATION];
      self.infoDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:@"request", @"type", request_id, @"info-key", nil] autorelease];
    } else {
      [self release], self = nil;
    }
  }

  return self;
}

-(id)initWithLocalNotificationDictionary:(NSDictionary*)dictionary
{
  self = [self
          initWithMessage:[dictionary objectForKey:@"message"]
              displayType:GreeNotificationViewDisplayDefaultType
                 duration:NO_NOTIFICATION_DURATION];

  return self;
}

-(void)dealloc
{
  self.message = nil;
  self.iconToken = nil;
  self.iconImage = nil;
  self.badgeString = nil;

  self.infoDictionary = nil;

  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, message:%@, type:%@, duration:%f>",
          NSStringFromClass([self class]),
          self,
          self.message,
          NSStringFromGreeNotificationViewDisplayType(self.displayType),
          self.duration];
}

#pragma mark - Public Interface

+(id)notificationForLoginWithUsername:(NSString*)username
{
  if (username == nil) {
    // This should only happen in rare cases where there is a server-side problem
    // and the profile didn't contain any nickname.
    username = @"<No Nickname!>";
  }

  GreeNotification* notification = [[[GreeNotification alloc] initWithMessage:[NSString stringWithFormat:GreePlatformString(@"notificaton.welcomeback.message", @"Welcome, %@"),
                                                                               username]
                                                                  displayType:GreeNotificationViewDisplayDefaultType
                                                                     duration:NO_NOTIFICATION_DURATION] autorelease];

  notification.infoDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:@"dash", @"type", [NSNumber numberWithInt:GreeNotificationSourceMyLogin], @"subtype", nil] autorelease];

  NSInteger badgeCount = [GreePlatform sharedInstance].badgeValues.applicationBadgeCount;

  if (![[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingDisableSNSFeature])
    badgeCount += [GreePlatform sharedInstance].badgeValues.socialNetworkingServiceBadgeCount;
  if(badgeCount > 99)
    notification.badgeString = @"99+";
  else if(badgeCount > 0)
    notification.badgeString = [NSString stringWithFormat:@"%d", badgeCount];

  return notification;
}

+(id)notificationWithAPSDictionary:(NSDictionary*)dictionary
{
  return [[[GreeNotification alloc] initWithAPSDictionary:dictionary] autorelease];
}

+(id)notificationWithLocalNotificationDictionary:(NSDictionary*)dictionary
{
  return [[[GreeNotification alloc] initWithLocalNotificationDictionary:dictionary] autorelease];
}

-(void)loadIconWithBlock:(void (^)(NSError* error))block
{
  if(!block) return;  //we really need this to know when it is complete
  if(self.iconImage) return; //only do it once

  switch(self.iconFlag) {
  case GreeAPSNotificationIconApplicationType:
    self.iconImage = [UIImage greeAppIconNearestWidth:60];
    block(nil);
    break;
  case GreeAPSNotificationIconDownloadType:
  {
    NSURL* url = [NSURL URLWithString:self.iconToken];
    [[GreePlatform sharedInstance].httpClient downloadImageAtUrl:url withBlock:^(UIImage* image, NSError* error) {
       if(image) {   //avoid erasing an image already loaded properly
         self.iconImage = image;
       }
       if (error) {
         self.iconImage = [UIImage greeImageNamed:@"gree_notification_logo.png"];
       }
       block(error);
     }];
  }
  break;
  default:
  case GreeAPSNotificationIconGreeType:
    self.iconImage = [UIImage greeImageNamed:@"gree_notification_logo.png"];
    block(nil);
    break;
  }
}

@end
