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


#import "AFNetworking.h"
#import "GreeAnalyticsChunk.h"
#import "GreeAnalyticsEvent.h"
#import "GreeAnalyticsEventArray.h"
#import "GreeAnalyticsQueue.h"
#import "GreeError+Internal.h"
#import "GreeLogger.h"
#import "GreeNetworkReachability.h"
#import "GreeNSNotification+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "NSString+GreeAdditions.h"


static const NSTimeInterval GreeAnalyticsQueueMinimumFlushInterval = 10.0;

@interface GreeAnalyticsQueue ()
@property (nonatomic, assign) NSTimeInterval pollingInterval;
@property (nonatomic, assign) dispatch_source_t pollingTimer;
@property (nonatomic, assign) BOOL pollingTimerRunning;
@property (nonatomic, assign) NSTimeInterval maximumStorageTime;
@property (nonatomic, retain) id analyticsReachabilityHandle;
@property (nonatomic, retain) GreeAnalyticsEventArray* events;

+(NSURL*)cachesURL;

-(void)setup;
-(void)setupDefaultSettings;
-(void)startPollingTimer;  //resume the timer used to periodically add events
-(void)stopPollingTimer;   //suspends the timer
@end


@implementation GreeAnalyticsQueue

#pragma mark - Object Lifecycle

-(id)initWithSettings:(GreeSettings*)settings
{
  if ((self = [super init])) {
    [self setupDefaultSettings];

    if ([settings settingHasValue:GreeSettingAnalyticsMaximumStorageTime]) {
      self.maximumStorageTime = (NSTimeInterval)[settings integerValueForSetting : GreeSettingAnalyticsMaximumStorageTime] * 60;    // min -> sec
    }
    if ([settings settingHasValue:GreeSettingAnalyticsPollingInterval]) {
      _pollingInterval = (NSTimeInterval)[settings integerValueForSetting : GreeSettingAnalyticsPollingInterval] * 60;        // min -> sec
    }

    [self setup];
  }

  return self;
}

-(id)init
{
  if ((self = [super init])) {
    [self setupDefaultSettings];
    [self setup];
  }

  return self;
}

-(void)setup
{
  __block GreeAnalyticsQueue* queue = self;

  _pollingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                         0,
                                         0,
                                         dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                         );
  dispatch_source_set_event_handler(_pollingTimer, ^{
                                      GreeAnalyticsEvent* event1 = [GreeAnalyticsEvent pollingEvent];
                                      [queue addEvent:event1];
                                      [queue flushWithBlock:^(NSError* error){
                                         if (error) {
                                           GreeLog(@"GreeAnalyticsQueue: Could not flush analytics data: %@", [error localizedDescription]);
                                         }
                                       }];
                                    });

  NSURL* analyticsStorageURL = [[self class] cachesURL];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSError* error = nil;

  if ([fileManager fileExistsAtPath:[analyticsStorageURL path]]) {
    self.events = [[[GreeAnalyticsEventArray alloc] initFromFileURL:analyticsStorageURL] autorelease];
    if (![fileManager removeItemAtURL:analyticsStorageURL error:&error]) {
      GreeLog(@"GreeAnalyticsQueue: Unable to delete the event storage file: %@", [error localizedDescription]);
    }
  } else {
    [fileManager createDirectoryAtPath:[[analyticsStorageURL URLByDeletingLastPathComponent] path] withIntermediateDirectories:YES attributes:nil error:nil];
    self.events = [[[GreeAnalyticsEventArray alloc] init] autorelease];
  }
  self.events.maximumStorageTime = self.maximumStorageTime;

  self.analyticsReachabilityHandle = [[GreePlatform sharedInstance].analyticsReachability
                                      addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
                                        if (!GreeNetworkReachabilityStatusIsConnected(previous)&& GreeNetworkReachabilityStatusIsConnected(current)) {
                                          [queue flushWithBlock:^(NSError* error) {
                                             if (error) {
                                               GreeLog(@"Could not flush analytics data: %@", [error localizedDescription]);
                                             }
                                           }];
                                        }
                                      }];

  void (^storeBeforeExiting)(NSNotification*) =^(NSNotification* notification) {
    if ([queue.events storeToFileURL:analyticsStorageURL]) {
      [queue.events removeAllObjects];
    }
  };

  [[NSNotificationCenter defaultCenter]
   addObserverForName:UIApplicationDidFinishLaunchingNotification
               object:nil
                queue:nil
           usingBlock:^(NSNotification* notification) {
     [queue flushWithBlock:^(NSError* error) {
        if (error) {
          GreeLog(@"GreeAnalyticsQueue: Could not flush analytics data: %@", [error localizedDescription]);
        }
      }];
   }];

  [[NSNotificationCenter defaultCenter]
   addObserverForName:UIApplicationDidEnterBackgroundNotification
               object:nil
                queue:nil
           usingBlock:storeBeforeExiting];

  [[NSNotificationCenter defaultCenter]
   addObserverForName:UIApplicationWillTerminateNotification
               object:nil
                queue:nil
           usingBlock:storeBeforeExiting];

  [[NSNotificationCenter defaultCenter]
   addObserverForName:UIApplicationWillEnterForegroundNotification
               object:nil
                queue:nil
           usingBlock:^(NSNotification* notification) {
     NSError* error = nil;
     queue.events = [GreeAnalyticsEventArray eventsFromFileURL:analyticsStorageURL];
     queue.events.maximumStorageTime = queue.maximumStorageTime;
     if (![[NSFileManager defaultManager] removeItemAtURL:analyticsStorageURL error:&error]) {
       GreeLog(@"GreeAnalyticsQueue: Unable to delete the event storage file: %@", [error localizedDescription]);
     }
   }];

  [[NSNotificationCenter defaultCenter]
   addObserverForName:GreeNSNotificationUserLogin object:nil queue:nil usingBlock:^(NSNotification* note) {
     [self addEvent:[GreeAnalyticsEvent pollingEvent]];
     [queue flushWithBlock:^(NSError* error) {
        if (error) {
          GreeLog(@"GreeAnalyticsQueue: Could not flush analytics data: %@", [error localizedDescription]);
        }
      }];
     [self startPollingTimer];
   }];
  [[NSNotificationCenter defaultCenter]
   addObserverForName:GreeNSNotificationUserInvalidated object:nil queue:nil usingBlock:^(NSNotification* note) {
     [self stopPollingTimer];
   }];
  [[NSNotificationCenter defaultCenter]
   addObserverForName:GreeNSNotificationUserLogout object:nil queue:nil usingBlock:^(NSNotification* note) {
     [self stopPollingTimer];
   }];
}

-(void)setupDefaultSettings
{
  self.maximumStorageTime = 30 * 24 * 60 * 60;    // 30 day
  // Do not use property to set polling interval for here to avoid polling timer from starting
  _pollingInterval = 5 * 60;                      //  5 min
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (_pollingTimer) {
    [self stopPollingTimer];
    dispatch_release(_pollingTimer);
  }

  [[GreePlatform sharedInstance].analyticsReachability removeObserverBlock:self.analyticsReachabilityHandle];
  self.analyticsReachabilityHandle = nil;

  self.events = nil;

  [super dealloc];
}

#pragma mark - Public interface

-(void)flushWithBlock:(void (^)(NSError* error))block
{
  if(self.events.count == 0 || [self.events haveMarkedEvents]) {
    if (block) {
      block(nil); //we may want to delay this to the next selector
    }
  } else {
    [self.events dropOutOfStorageTimeEvents];
    NSArray* markedEvents = [self.events eventsInMarked];
    if(markedEvents.count == 0) {
      if(block) {
        block(nil);
      }
      return;
    }

    GreeSerializer* serializer = [GreeSerializer serializer];
    GreeAnalyticsChunk* chunk = [[GreeAnalyticsChunk alloc] init];

    chunk.header = [GreeAnalyticsHeader header];
    chunk.body = markedEvents;
    [chunk serializeWithGreeSerializer:serializer];

    [[GreePlatform sharedInstance].httpClient
       postPath:@"api/rest/analytics"
     parameters:serializer.rootDictionary
        success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
       [self.events removeMarkedEvents];
       if (block) {
         block(nil);
       }
     }
        failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
       [self.events unmarkEvents];
       if (block) {
         block([GreeError convertToGreeError:error]);
       }
     }];

    [chunk release];
  }
}

-(void)addEvent:(GreeAnalyticsEvent*)event
{
  [self.events addObject:event];
}

-(void)setPollingInterval:(NSTimeInterval)pollingInterval
{
  _pollingInterval = pollingInterval;
  [self startPollingTimer];
}


#pragma mark - Internal Methods
-(void)startPollingTimer
{
  [self stopPollingTimer];
  if(self.pollingInterval > 0) {
    uint64_t interval = self.pollingInterval * NSEC_PER_SEC;
    dispatch_source_set_timer(_pollingTimer, dispatch_walltime(NULL, interval), interval, 1.0 * NSEC_PER_SEC);
    dispatch_resume(_pollingTimer);
    self.pollingTimerRunning = YES;
  }
}

-(void)stopPollingTimer
{
  if (self.pollingTimerRunning) {
    dispatch_suspend(_pollingTimer);
    self.pollingTimerRunning = NO;
  }
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, eventCount:%d, pollingInterval:%f>",
          NSStringFromClass([self class]),
          self,
          [self.events count],
          self.pollingInterval];
}


#pragma mark - Internal methods

+(NSURL*)cachesURL
{
  return [NSURL fileURLWithPath:[NSString greeCachePathForRelativePath:@"analyticsEvents.plist"]];
}

@end
