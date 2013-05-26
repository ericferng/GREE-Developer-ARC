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

#import "GreeModerationList.h"
#import "GreeModeratedText+Internal.h"
#import "GreeSerializer.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"

@interface GreeModeratedText (Private)
@property (nonatomic, retain) NSDate* lastCheckedTimestamp;
@end

@interface GreeModerationList ()
-(void)deserialize;
-(void)serialize;
-(void)process;

-(void)setTimerWithInterval:(int64_t)interval;
-(void)removeTimer;

@property (nonatomic, assign) dispatch_source_t timer;
@property (nonatomic, retain) NSMutableDictionary* textList;
@end

@implementation GreeModerationList

#pragma mark - Object Lifecycle

GREEPLATFORM_AUTOREGISTER_COMPONENT

-(id)init
{
  self = [super init];
  if(self) {
    self.textList = [NSMutableDictionary dictionary];
  }
  return self;
}

-(id)initWithSerialization
{
  self = [self init]; //which calls to super
  if(self) {
    [self deserialize];
    [self setTimerWithInterval:60 * 60];
  }
  return self;
}


-(void)dealloc
{
  [self removeTimer];
  self.textList  = nil;
  [super dealloc];
}


#pragma mark - GreeComponent Protocol

+(id)componentWithSettings:(GreeSettings*)settings
{
  id<GreePlatformComponent> obj = [[[[self class] alloc] initWithSerialization] autorelease];

  return obj;
}


-(void)willRemoveComponentFromPlatform
{
  [self finish];
}

#pragma mark - Public Interface
-(void)addText:(GreeModeratedText*)text
{
  [self.textList setObject:text forKey:text.textId];
  [self serialize];
}
-(void)removeText:(GreeModeratedText*)text
{
  [self.textList removeObjectForKey:text.textId];
  [self serialize];
}


-(void)finish
{
  [self removeTimer];
}

-(NSArray*)currentList
{
  NSMutableArray* returnList = [NSMutableArray array];
  [self.textList enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     [returnList addObject:obj];
   }];
  return returnList;
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p textList:%@>", NSStringFromClass([self class]), self, self.textList];
}

#pragma mark - Internal Methods
-(void)deserialize
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* jsonData = [defaults objectForKey:@"GreeModerationList"];
  GreeSerializer* serializer = [[[GreeSerializer alloc] initWithSerializedDictionary:jsonData] autorelease];
  serializer.deserialzeIntoMutableContainers = YES;
  self.textList = (NSMutableDictionary*)[serializer dictionaryOfSerializableObjectsWithClass:[GreeModeratedText class] forKey:@"GreeModeratedTexts"];
}

-(void)serialize
{
  GreeSerializer* serializer = [GreeSerializer serializer];
  [serializer serializeDictionaryOfSerializableObjects:self.textList ofClass:[GreeModeratedText class] forKey:@"GreeModeratedTexts"];
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:serializer.rootDictionary forKey:@"GreeModerationList"];
}

//generally called by the timer
-(void)process
{
  NSMutableSet* updatedIds = [NSMutableSet set];
  NSTimeInterval fromNow = [[NSDate date] timeIntervalSinceReferenceDate];
  [self.textList enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     GreeModeratedText* text = obj;
     //based on status and last updated time, add to updatedIds
     NSInteger timeInterval = 0;
     switch(text.status) {
     case GreeModerationStatusBeingChecked:
       timeInterval = 3 * 60 * 60;
       break;
     case GreeModerationStatusDeleted:
       break;
     case GreeModerationStatusResultApproved:
       timeInterval = 24 * 60 * 60;
     case GreeModerationStatusResultRejected:
       break;
     };

     if(timeInterval) {
       NSTimeInterval fromText = [text.lastCheckedTimestamp timeIntervalSinceReferenceDate]; //this way, null dates are handled properly
       if(fromText + timeInterval < fromNow) {
         [updatedIds addObject:text.textId];
       }
     }
   }];

  if(updatedIds.count > 0) {
    [GreeModeratedText loadFromIds:updatedIds.allObjects block:^(NSArray* userTexts, NSError* error) {
       NSDate* date = [NSDate date];
       for(GreeModeratedText* receivedText in userTexts) {
         GreeModeratedText* watchedText = [self.textList objectForKey:receivedText.textId];
         if(watchedText && watchedText.status != receivedText.status) {
           watchedText.status = receivedText.status;
           watchedText.lastCheckedTimestamp = date;
           [[NSNotificationCenter defaultCenter] postNotificationName:GreeModeratedTextUpdatedNotification object:watchedText];
         }
       }
     }];
  }

}

-(void)setTimerWithInterval:(int64_t)interval
{
  if(self.timer) {
    return; //this really should not happen
  }
  self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

  if (self.timer) {
    NSTimeInterval nsTime = interval * NSEC_PER_SEC;
    dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, nsTime), nsTime, 1.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
                                        [self process];
                                      });
    dispatch_source_set_cancel_handler(self.timer, ^{
                                         dispatch_release(self.timer);
                                         self.timer = NULL;
                                       });
    dispatch_resume(self.timer);
  }

}
-(void)removeTimer
{
  if(self.timer) {
    dispatch_source_cancel(self.timer);
  }
}




@end
