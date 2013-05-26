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

#import "GreeAnalyticsEvent.h"
#import "NSDateFormatter+GreeAdditions.h"

@interface GreeAnalyticsEvent ()
-(id)initWithType:(NSString*)type name:(NSString*)name from:(NSString*)from issuedTime:(NSDate*)issuedTime parameters:(NSDictionary*)parameters;
@end

@implementation GreeAnalyticsEvent

#pragma mark - Object Lifecycle
+(id)pollingEvent
{
  return [self eventWithType:@"act" name:@"active" from:@"" parameters:nil];
}

+(id)eventWithType:(NSString*)type name:(NSString*)name from:(NSString*)from parameters:(NSDictionary*)parameters
{
  return [[[GreeAnalyticsEvent alloc] initWithType:type
                                              name:name
                                              from:from
                                        parameters:parameters] autorelease];
}

-(id)initWithType:(NSString*)type name:(NSString*)name from:(NSString*)from parameters:(NSDictionary*)parameters
{
  return [self initWithType:type name:name from:from issuedTime:[NSDate date] parameters:parameters];
}

-(id)initWithType:(NSString*)type name:(NSString*)name from:(NSString*)from issuedTime:(NSDate*)issuedTime parameters:(NSDictionary*)parameters
{
  if ((self = [super init])) {
    self.type = type;
    self.name = name;
    self.from = from;
    self.issuedTime = issuedTime;
    self.parameters = parameters;
  }

  return self;
}

-(void)dealloc
{
  self.type = nil;
  self.name = nil;
  self.from = nil;
  self.issuedTime = nil;
  self.parameters = nil;

  [super dealloc];
}

#pragma mark - GreeSerializable
-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  return [self initWithType:[serializer objectForKey:@"tp"]
                       name:[serializer objectForKey:@"nm"]
                       from:[serializer objectForKey:@"fr"]
                 issuedTime:[serializer UTCDateForKey:@"tm"]
                 parameters:[serializer objectForKey:@"pr"]];
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.type forKey:@"tp"];
  [serializer serializeObject:self.name forKey:@"nm"];
  [serializer serializeObject:self.from forKey:@"fr"];
  [serializer serializeUTCDate:self.issuedTime forKey:@"tm"];
  [serializer serializeObject:self.parameters forKey:@"pr"];
}

#pragma mark - NSObject Overrides
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, type:%@, name:%@, from:%@, issuedTime:%@, parameters:%@>",
          NSStringFromClass([self class]),
          self,
          self.type,
          self.name,
          self.from,
          [[NSDateFormatter greeUTCDateFormatter] stringFromDate:self.issuedTime],
          [self.parameters description]];
}
@end
