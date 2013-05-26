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

#import "GreeInviteNotificationField.h"

@interface GreeInviteNotificationField ()

@property (nonatomic, assign, readwrite) NSInteger unreadInvite;

@end

@implementation GreeInviteNotificationField

#pragma mark - Object Lifecyle

-(id)initWithName:(NSString*)name
              url:(NSString*)url
          message:(NSString*)message
            feeds:(NSArray*)feeds
           offset:(NSInteger)offset
            limit:(NSInteger)limit
          hasMore:(BOOL)hasMore
     unreadInvite:(NSInteger)unreadInvite
{
  self = [super
          initWithName:name
                   url:url
               message:message
                 feeds:feeds
                offset:offset
                 limit:limit
               hasMore:hasMore];
  if (self) {
    self.unreadInvite = unreadInvite;
  }
  return self;
}


#pragma mark - NSCoding Protocol

-(void)encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeInteger:self.unreadInvite forKey:@"unreadInvite"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.unreadInvite = [aDecoder decodeIntegerForKey:@"unreadInvite"];
  }
  return self;
}

@end
