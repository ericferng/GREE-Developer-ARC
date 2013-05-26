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

#import "GreeDispatchTimer.h"

@interface GreeDispatchTimer ()
@property (nonatomic, retain) GreeDispatchTimer* mySelf;
@property (nonatomic, assign) dispatch_source_t timerDispatchSource;
-(id)initWithStartTime:(dispatch_time_t)startTime interval:(uint64_t)interval leeway:(uint64_t)leeway
         dispatchQueue:(dispatch_queue_t)dispatchQueue block:(dispatch_block_t)block;
-(void)releaseDispatchSource;
@end

@implementation GreeDispatchTimer

#pragma mark - Object Lifecycle

-(void)dealloc
{
  [self cancel];
  [self releaseDispatchSource];
  [super dealloc];
}

-(id)initWithStartTime:(dispatch_time_t)startTime interval:(uint64_t)interval leeway:(uint64_t)leeway
         dispatchQueue:(dispatch_queue_t)dispatchQueue block:(dispatch_block_t)block
{
  if ((self = [super init])) {
    self.timerDispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatchQueue);

    dispatch_source_set_timer(self.timerDispatchSource, startTime, interval, leeway);
    dispatch_source_set_event_handler(self.timerDispatchSource, block);
  }
  return self;
}

#pragma mark - public

+(id)timerWithStartTime:(dispatch_time_t)startTime interval:(uint64_t)interval leeway:(uint64_t)leeway
          dispatchQueue:(dispatch_queue_t)dispatchQueue block:(dispatch_block_t)block
{
  GreeDispatchTimer* timer = [[[GreeDispatchTimer alloc] initWithStartTime:startTime interval:interval leeway:leeway
                                                             dispatchQueue:dispatchQueue block:block] autorelease];
  return timer.mySelf = timer;
}

+(id)startWithStartTime:(dispatch_time_t)startTime interval:(uint64_t)interval leeway:(uint64_t)leeway
          dispatchQueue:(dispatch_queue_t)dispatchQueue block:(dispatch_block_t)block
{
  GreeDispatchTimer* timer = [GreeDispatchTimer timerWithStartTime:startTime interval:interval leeway:leeway
                                                     dispatchQueue:dispatchQueue block:block];
  [timer resume];
  return timer;
}

+(id)startWithIntervalSecond:(uint64_t)second dispatchQueue:(dispatch_queue_t)dispatchQueue block:(dispatch_block_t)block
{
  uint64_t interval = (uint64_t)second * NSEC_PER_SEC;
  uint64_t leeway = 0;
  dispatch_time_t startTime = dispatch_walltime(NULL, interval);

  if (!dispatchQueue) {
    dispatchQueue = dispatch_get_main_queue();
  }

  return [GreeDispatchTimer startWithStartTime:startTime interval:interval leeway:leeway
                                 dispatchQueue:dispatchQueue block:block];
}

-(void)resume
{
  if (self.timerDispatchSource) {
    dispatch_resume(self.timerDispatchSource);
  }
}

-(void)invalidate
{
  [self cancel];
  [self releaseDispatchSource];
  self.mySelf = nil;
}

-(void)cancel
{
  if (self.timerDispatchSource) {
    dispatch_source_cancel(self.timerDispatchSource);
  }
}

#pragma mark - private

-(void)releaseDispatchSource
{
  if (_timerDispatchSource) {
    dispatch_release(self.timerDispatchSource);
    self.timerDispatchSource = nil;
  }
}

@end
