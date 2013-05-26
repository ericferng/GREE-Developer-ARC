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

#import "GreeNotificationField.h"

NSString* const kGreeInviteNotificationField      = @"invite";
NSString* const kGreeTargetNotificationField      = @"target";
NSString* const kGreeOtherNotificationField       = @"other";
NSString* const kGreeActivityNotificationField    = @"activity";
NSString* const kGreeFriendNotificationField      = @"friend";

@interface GreeNotificationField ()

@property (nonatomic, retain, readwrite) NSString* fieldName;
@property (nonatomic, retain, readwrite) NSString* url;
@property (nonatomic, retain, readwrite) NSString* message;
@property (nonatomic, assign, readwrite) NSInteger offset;
@property (nonatomic, assign, readwrite) NSInteger limit;
@property (nonatomic, assign, readwrite) BOOL hasMore;

@end

@implementation GreeNotificationField

#pragma mark - Object lifecycle

-(void)dealloc
{
  self.fieldName = nil;
  self.feeds = nil;
  [super dealloc];
}

#pragma mark - Public Interface

-(id)initWithName:(NSString*)name
              url:(NSString*)url
          message:(NSString*)message
            feeds:(NSArray*)feeds
           offset:(NSInteger)offset
            limit:(NSInteger)limit
          hasMore:(BOOL)hasMore
{
  if (name == nil) {
    return nil;
  }

  self = [super init];
  if (self) {
    self.fieldName = name;
    self.url = url;
    self.message = message;
    self.feeds = [NSMutableArray arrayWithArray:feeds];
    self.offset = offset;
    self.limit = limit;
    self.hasMore = hasMore;
  }
  return self;
}

-(void)addFeed:(GreeNotificationFeed*)feed
{
  if (feed) {
    [(NSMutableArray*)self.feeds addObject:feed];
  }
}

-(void)addFeeds:(NSArray*)feeds
{
  if (feeds) {
    [(NSMutableArray*)self.feeds addObjectsFromArray:feeds];
  }
}

-(void)addFeedsFromField:(GreeNotificationField*)field
{
  if ([self.fieldName isEqualToString:field.fieldName]) {
    [(NSMutableArray*)self.feeds addObjectsFromArray:field.feeds];
    self.offset = field.offset;
    self.limit = field.limit;
    self.hasMore = field.hasMore;
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, name:%@, feeds:%@, offset:%@, limit:%@, hasMore:%@>",
          NSStringFromClass([self class]),
          self,
          self.fieldName,
          [self.feeds description],
          [NSString stringWithFormat:@"%d", self.offset],
          [NSString stringWithFormat:@"%d", self.limit],
          self.hasMore ? @"YES": @"NO"];

}

#pragma mark - NSCoding Protocol

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self.fieldName forKey:@"fieldName"];
  [aCoder encodeObject:self.url forKey:@"url"];
  [aCoder encodeObject:self.message forKey:@"message"];
  [aCoder encodeObject:self.feeds forKey:@"feeds"];
  [aCoder encodeInteger:self.offset forKey:@"offset"];
  [aCoder encodeInteger:self.limit forKey:@"limit"];
  [aCoder encodeBool:self.hasMore forKey:@"hasMore"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super init];
  if (self) {
    self.fieldName = [aDecoder decodeObjectForKey:@"fieldName"];
    self.url = [aDecoder decodeObjectForKey:@"url"];
    self.message = [aDecoder decodeObjectForKey:@"message"];
    self.feeds = [aDecoder decodeObjectForKey:@"feeds"];
    self.offset = [aDecoder decodeIntegerForKey:@"offset"];
    self.limit = [aDecoder decodeIntegerForKey:@"limit"];
    self.hasMore = [aDecoder decodeBoolForKey:@"hasMore"];
  }
  return self;
}

@end
