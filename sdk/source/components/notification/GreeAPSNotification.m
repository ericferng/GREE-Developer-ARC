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

#import "GreeAPSNotification.h"
#import "GreeSerializer.h"

@implementation GreeAPSNotification

#pragma mark -

-(void)dealloc
{
  self.actorId = nil;
  self.text = nil;
  self.iconToken = nil;
  self.iconURL = nil;
  self.contentId = nil;

  [super dealloc];
}

#pragma mark - GreeSerializable Protocol
-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if (self != nil) {
    //the actor is sent over as an int!
    self.actorId = [[serializer objectForKey:@"act"] description];
    self.text = [serializer objectForKey:@"text"];
    self.type = [serializer integerForKey:@"type"];
    self.iconFlag = [serializer integerForKey:@"iflag"];
    self.iconToken = [serializer objectForKey:@"itoken"];
    self.contentId = [serializer objectForKey:@"cid"];

    switch (self.iconFlag) {
    case GreeAPSNotificationIconGreeType:
      self.iconURL = nil;
      break;
    case GreeAPSNotificationIconApplicationType:
      self.iconURL = nil;
      break;
    case GreeAPSNotificationIconDownloadType:
      self.iconURL = [NSURL URLWithString:[serializer objectForKey:@"itoken"]];
      break;
    }
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.actorId forKey:@"act"];
  [serializer serializeObject:self.text forKey:@"text"];
  [serializer serializeInteger:self.type forKey:@"type"];
  [serializer serializeInteger:self.iconFlag forKey:@"iflag"];
  [serializer serializeObject:self.iconToken forKey:@"itoken"];
  [serializer serializeObject:self.contentId forKey:@"cid"];
}


-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, act:%@, text:%@, type:%@, iflag:%@, itoken:%@, cid:%@>",
          NSStringFromClass([self class]),
          self,
          self.actorId,
          self.text,
          NSStringFromGreeNotificationSource(self.type),
          NSStringFromGreeAPSNotificationIconType(self.iconFlag),
          self.iconToken,
          self.contentId];
}

@end
