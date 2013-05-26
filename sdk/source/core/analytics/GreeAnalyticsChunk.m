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

#import "GreeAnalyticsChunk.h"

@interface GreeAnalyticsChunk ()
@end

@implementation GreeAnalyticsChunk

#pragma mark - Object Lifecycle

-(id)initWithHeader:(GreeAnalyticsHeader*)header body:(NSArray*)body
{
  if ((self = [super init])) {
    self.header = header;
    self.body = body;
  }

  return self;
}

-(void)dealloc
{
  self.header = nil;
  self.body = nil;

  [super dealloc];
}

#pragma mark - GreeSerializable

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  if((self = [super init])) {
    self.header = [serializer objectOfClass:[GreeAnalyticsHeader class] forKey:@"h"];
    self.body = [serializer arrayOfSerializableObjectsWithClass:[GreeAnalyticsEvent class] forKey:@"b"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:self.header forKey:@"h"];
  [serializer serializeArrayOfSerializableObjects:self.body ofClass:[GreeAnalyticsEvent class] forKey:@"b"];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, header:{ %@ }, bodyItemsCount:%d>",
          NSStringFromClass([self class]),
          self,
          [self.header description],
          [self.body count]];
}



@end
