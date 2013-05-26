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

#import "GreeNotificationFeed.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"

@interface GreeNotificationMessageData ()
+(double)validColorValue:(double)value;
@property (nonatomic, retain, readwrite) NSString* text;
@property (nonatomic, assign, readwrite) BOOL bold;
@property (nonatomic, retain, readwrite) UIColor* color;
@end


@implementation GreeNotificationMessageData

#pragma mark - Object Lifecyle

-(void)dealloc
{
  self.text = nil;
  self.color = nil;
  [super dealloc];
}

#pragma mark - Public Interface

-(id)initWithText:(NSString*)text bold:(BOOL)bold color:(UIColor*)color
{
  self = [super init];
  if (self) {
    self.text = text;
    self.bold = bold;
    self.color = color;
  }
  return self;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, text:%@, bold:%@ color:%@>",
          NSStringFromClass([self class]),
          self,
          self.text,
          self.bold ? @"Yes": @"No",
          self.color];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  double r = [[[[serializer objectForKey:@"font"] objectForKey:@"color"] objectForKey:@"r"] doubleValue];
  double g = [[[[serializer objectForKey:@"font"] objectForKey:@"color"] objectForKey:@"g"] doubleValue];
  double b = [[[[serializer objectForKey:@"font"] objectForKey:@"color"] objectForKey:@"b"] doubleValue];

  r = [GreeNotificationMessageData validColorValue:r];
  g = [GreeNotificationMessageData validColorValue:g];
  b = [GreeNotificationMessageData validColorValue:b];

  UIColor* color = [[[UIColor alloc] initWithRed:(CGFloat)r/255.0
                                           green:(CGFloat)g/255.0
                                            blue:(CGFloat)b/255.0
                                           alpha:1.0] autorelease];

  BOOL bold = [[[serializer objectForKey:@"font"] objectForKey:@"bold"] boolValue];

  return [self initWithText:[serializer objectForKey:@"text"]
                       bold:bold
                      color:color];
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - NSCoding Protocol

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self.text forKey:@"text"];
  [aCoder encodeBool:self.bold forKey:@"bold"];
  [aCoder encodeObject:self.color forKey:@"color"];

}

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super init];
  if (self) {
    self.text = [aDecoder decodeObjectForKey:@"text"];
    self.bold = [aDecoder decodeBoolForKey:@"bold"];
    self.color = [aDecoder decodeObjectForKey:@"color"];
  }
  return self;
}


#pragma mark - Internal Methods

+(double)validColorValue:(double)value
{
  if(value < 0) {
    value = 0;
  } else if(value > 255) {
    value = 255;
  }
  return value;
}
@end

NSString *const GreeNotificationFeedFriendTypeLinkPending   = @"friends_link_pending";
NSString* const GreeNotificationFeedFriendTypeRegistration  = @"friends_registration";
NSString* const GreeNotificationFeedFriendTypeLinkApproved  = @"friends_link_approved";

@interface GreeNotificationFeed ()

@property (nonatomic, retain, readwrite) NSString* feedKey;
@property (nonatomic, retain, readwrite) NSString* nameSpace;
@property (nonatomic, retain, readwrite) NSString* thumbnailPath;
@property (nonatomic, retain, readwrite) NSString* message;
@property (nonatomic, retain, readwrite) NSString* url;
@property (nonatomic, retain, readwrite) NSString* appName;
@property (nonatomic, retain, readwrite) NSDate* date;
@property (nonatomic, retain, readwrite) NSDictionary* messageDatas;
@property (nonatomic, assign, readwrite) BOOL launchExternal;

@end

@implementation GreeNotificationFeed

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.feedKey = nil;
  self.nameSpace = nil;
  self.thumbnailPath = nil;
  self.message = nil;
  self.url = nil;
  self.appName = nil;
  self.messageDatas = nil;
  self.date = nil;

  [super dealloc];
}

#pragma mark - Public interface

-(id)initWithFeedKey:(NSString*)feedKey
           nameSpace:(NSString*)nameSpace
       thumbnailPath:(NSString*)thumbnailPath
             message:(NSString*)message
                 url:(NSString*)url
             appName:(NSString*)appName
                date:(NSDate*)date
        messegeDatas:(NSDictionary*)messageDatas
              unread:(BOOL)unread
      launchExternal:(BOOL)launchExternal
{
  self = [super init];
  if (self) {
    self.feedKey = feedKey;
    self.nameSpace = nameSpace;
    self.thumbnailPath = thumbnailPath;
    self.message = message;
    self.url = url;
    self.appName = appName;
    self.date = date;
    self.messageDatas = messageDatas;
    self.unread = unread;
    self.launchExternal = launchExternal;
  }
  return self;
}

-(void)loadThumbnailWithBlock:(void (^)(UIImage* icon, NSError* error))block
{
  if (!block) {
    return;
  }
  NSURL* url = [NSURL URLWithString:self.thumbnailPath];
  if (!url) {
    return;
  }
  [[[GreePlatform sharedInstance] httpClient]
   downloadImageAtUrl:url
            withBlock:^(UIImage* image, NSError* error) {
     block(image, error);
   }];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, feedkey:%@, nameSpace:%@, thumbnailPath:%@, message:%@, url:%@, appName:%@, date:%@, messageDatas:%@, unread:%@, launchExternal:%@>",
          NSStringFromClass([self class]),
          self,
          self.feedKey,
          self.nameSpace,
          self.thumbnailPath,
          self.message,
          self.url,
          self.appName,
          [self.date description],
          [self.messageDatas description],
          self.unread ? @"Yes": @"No",
          self.launchExternal ? @"Yes": @"No"];
}

#pragma mark - GreeSerializable Protocol

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  return [self
          initWithFeedKey:[serializer objectForKey:@"feed_key"]
                nameSpace:[serializer objectForKey:@"namespace"]
            thumbnailPath:[serializer objectForKey:@"image"]
                  message:[serializer objectForKey:@"message"]
                      url:[serializer objectForKey:@"url"]
                  appName:[serializer objectForKey:@"app_name"]
                     date:[serializer UTCDateForKey:@"date"]
             messegeDatas:[serializer dictionaryOfSerializableObjectsWithClass:[GreeNotificationMessageData class] forKey:@"data"]
                   unread:[serializer boolForKey:@"unread"]
           launchExternal:[serializer boolForKey:@"launch_external"]];
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - NSCoding Protocol

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self.feedKey forKey:@"feedKey"];
  [aCoder encodeObject:self.nameSpace forKey:@"nameSpace"];
  [aCoder encodeObject:self.thumbnailPath forKey:@"thumbnailPath"];
  [aCoder encodeObject:self.message forKey:@"message"];
  [aCoder encodeObject:self.url forKey:@"url"];
  [aCoder encodeObject:self.appName forKey:@"appName"];
  [aCoder encodeObject:self.date forKey:@"date"];
  [aCoder encodeObject:self.messageDatas forKey:@"messageDatas"];
  [aCoder encodeBool:self.unread forKey:@"unread"];
  [aCoder encodeBool:self.launchExternal forKey:@"launchExternal"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super init];
  if (self) {
    self.feedKey = [aDecoder decodeObjectForKey:@"feedKey"];
    self.nameSpace = [aDecoder decodeObjectForKey:@"nameSpace"];
    self.thumbnailPath = [aDecoder decodeObjectForKey:@"thumbnailPath"];
    self.message = [aDecoder decodeObjectForKey:@"message"];
    self.url = [aDecoder decodeObjectForKey:@"url"];
    self.appName = [aDecoder decodeObjectForKey:@"appName"];
    self.date = [aDecoder decodeObjectForKey:@"date"];
    self.messageDatas = [aDecoder decodeObjectForKey:@"messageDatas"];
    self.unread = [aDecoder decodeBoolForKey:@"unread"];
    self.launchExternal = [aDecoder decodeBoolForKey:@"launchExternal"];
  }
  return self;
}

@end
