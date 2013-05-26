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
#import "GreeAnalyticsEventArray.h"
#import "GreeLogger.h"
#import "GreeSerializer.h"


@interface GreeAnalyticsEventArray ()
@property (nonatomic, retain) NSMutableArray* objects;
@property (nonatomic, assign, readwrite) NSRange rangeOfMarkedEvents;
@end


@implementation GreeAnalyticsEventArray

#pragma mark - Object Lifecycle

+(id)events
{
  return [[[self alloc] init] autorelease];
}

-(id)init
{
  self = [super init];
  if (self) {
    self.objects = [NSMutableArray array];
    [self unmarkEvents];
    self.maximumStorageTime = 0.f;
  }
  return self;
}

+(id)eventsFromFileURL:(NSURL*)fileURL
{
  return [[[self alloc] initFromFileURL:fileURL] autorelease];
}

-(id)initFromFileURL:(NSURL*)fileURL
{
  if (![fileURL isFileURL]) {
    GreeLog(@"GreeAnalyticsEventArray: URL of storage file is not a file URL:%@", [fileURL description]);
    return nil;
  }

  NSDictionary* storedEvents = [NSDictionary dictionaryWithContentsOfURL:fileURL];
  if (storedEvents == nil) {
    GreeLog(@"GreeAnalyticsEventArray: Could not read data from the file:%@", fileURL);
    return nil;
  }

  GreeSerializer* serializer = [[GreeSerializer alloc] initWithSerializedDictionary:storedEvents];
  NSArray* eventsArray = [serializer arrayOfSerializableObjectsWithClass:[GreeAnalyticsEvent class] forKey:@"events"];

  self = [super init];
  if (self) {
    self.objects = [NSMutableArray arrayWithArray:eventsArray];
    [self unmarkEvents];
    self.maximumStorageTime = 0.f;
  }

  [serializer release];

  return self;
}

-(void)dealloc
{
  self.objects = nil;
  [super dealloc];
}


#pragma mark - Public Methods

-(void)addObject:(id)anObject
{
  @synchronized(self) {
    [self.objects addObject:anObject];
  }
}

-(void)dropOutOfStorageTimeEvents
{
  @synchronized(self) {
    for (GreeAnalyticsEvent* ev in [self.objects reverseObjectEnumerator]) {
      float issuedTime = fabs([ev.issuedTime timeIntervalSinceNow]);
      if (self.maximumStorageTime <= issuedTime) {
        [self.objects removeObject:ev];
      }
    }
    self.rangeOfMarkedEvents = NSMakeRange(0, [self count]);
  }
}

-(void)removeAllObjects
{
  @synchronized(self) {
    [self.objects removeAllObjects];
    [self unmarkEvents];
  }
}

-(void)removeMarkedEvents
{
  @synchronized(self) {
    [self.objects removeObjectsInRange:self.rangeOfMarkedEvents];
    [self unmarkEvents];
  }
}

-(BOOL)storeToFileURL:(NSURL*)fileURL
{
  if (![fileURL isFileURL]) {
    GreeLog(@"GreeAnalyticsEventArray: URL of storage file is not a file URL:%@", [fileURL description]);
    return NO;
  }

  GreeSerializer* serializer = [GreeSerializer serializer];
  @synchronized(self) {
    [serializer serializeArrayOfSerializableObjects:self.objects ofClass:[GreeAnalyticsEvent class] forKey:@"events"];
  }
  if (![serializer.rootDictionary writeToURL:fileURL atomically:YES]) {
    GreeLog(@"GreeAnalyticsEventArray: Error writing the events to the URL:%@", fileURL);
    return NO;
  }

  return YES;
}

-(BOOL)haveMarkedEvents
{
  return (0 < NSMaxRange(self.rangeOfMarkedEvents));
}

-(NSArray*)eventsInMarked
{
  NSMutableArray* events = [NSMutableArray array];

  @synchronized(self) {
    for (NSUInteger i = self.rangeOfMarkedEvents.location; i < self.rangeOfMarkedEvents.length; i++) {
      [events addObject:[self objectAtIndex:i]];
    }
  }

  if ([events count] == 0)
    events = nil;

  return events;
}

-(void)unmarkEvents
{
  self.rangeOfMarkedEvents = NSMakeRange(0, 0);
}

#pragma mark - NSArray Primitive Methods

-(NSUInteger)count
{
  return [self.objects count];
}

-(id)objectAtIndex:(NSUInteger)index
{
  return [self.objects objectAtIndex:index];
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, rangeOfMarkedEvents:[%d,%d], maximumStorageTime:%f,\n%@>",
          NSStringFromClass([self class]), self,
          self.rangeOfMarkedEvents.location, self.rangeOfMarkedEvents.length,
          self.maximumStorageTime,
          self.objects];
}

@end
