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


#import "GreeAPI+Internal.h"
#import "GreeMyApplication.h"
#import "GreePlatform+Internal.h"
#import "GreeSerializer.h"


NSString* const GreeMyApplicationParameterDeviceKey     = @"type";
NSString* const GreeMyApplicationParameterDeviceAll     = @"all";
NSString* const GreeMyApplicationParameterDeviceFP      = @"fp";
NSString* const GreeMyApplicationParameterDeviceSP      = @"sp";
NSString* const GreeMyApplicationParameterDeviceIOS     = @"ios";
NSString* const GreeMyApplicationParameterDeviceAndroid = @"andriod";


@interface GreeMyApplicationEnumerator : GreeAPIEnumeratorBase
@end

@implementation GreeMyApplicationEnumerator

#pragma mark - GreeAPIEnumeratorBase Overrides

-(NSString*)httpRequestResourceSpecifier
{
  return @"profile/myapp";
}

-(NSArray*)convertData:(NSArray*)input
{
  NSArray* deserialized = [GreeSerializer deserializeArray:input withClass:[GreeMyApplication class]];

  return deserialized;
}

@end


@interface GreeMyApplication ()

@property (nonatomic, retain) NSString* identifier;           // app_id
@property (nonatomic, retain) NSString* name;                 // name
@property (nonatomic, retain) NSString* shortenName;          // shorten_name
@property (nonatomic, retain) NSURL* thumbnailUrlSmall;       // app_thumbnail_url / small
@property (nonatomic, retain) NSURL* thumbnailUrlMiddle;      // app_thumbnail_url / middle
@property (nonatomic, retain) NSURL* thumbnailUrlLarge;       // app_thumbnail_url / large
@property (nonatomic, retain) NSDate* lastAccess;             // last_access

@end


@implementation GreeMyApplication

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.identifier = nil;
  self.name = nil;
  self.shortenName = nil;
  self.thumbnailUrlSmall = nil;
  self.thumbnailUrlMiddle = nil;
  self.thumbnailUrlLarge = nil;
  self.lastAccess = nil;
  [super dealloc];
}

#pragma mark - GreeAPI Overrides

+(id<GreeAPIEnumerator>)getWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block
{
  GreeMyApplicationEnumerator* enumerator = [[GreeMyApplicationEnumerator alloc] init];
  [enumerator setParameters:parameters];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

#pragma mark - GreeSerializable Overrides

-(id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [self init];
  if (self) {
    self.identifier = [serializer objectForKey:@"app_id"];
    NSDictionary* thumbnailUrls = [serializer objectForKey:@"app_thumbnail_url"];
    self.thumbnailUrlSmall = [NSURL URLWithString:[thumbnailUrls objectForKey:@"small"]];
    self.thumbnailUrlMiddle = [NSURL URLWithString:[thumbnailUrls objectForKey:@"middle"]];
    self.thumbnailUrlLarge = [NSURL URLWithString:[thumbnailUrls objectForKey:@"large"]];
    self.lastAccess = [serializer dateForKey:@"last_access"];
    self.name = [serializer objectForKey:@"name"];
    self.shortenName = [serializer objectForKey:@"shorten_name"];
  }
  return self;
}

-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, appId:%@, thumbnail_small:%@, thumbnail_middle:%@, thumbnail_large:%@, last_access:%@, name:%@, shorten_name:%@>",
          NSStringFromClass([self class]), self,
          self.identifier,
          self.thumbnailUrlSmall,
          self.thumbnailUrlMiddle,
          self.thumbnailUrlLarge,
          self.lastAccess,
          self.name,
          self.shortenName];
}

@end
