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


#import "GreeJSRecordAnalyticsDataCommand.h"
#import "GreeAnalyticsEvent.h"
#import "GreeSerializer.h"
#import "GreePlatform+Internal.h"

#define kGreeJSAddAnalyticsEventCallbackFunction @"callback"

@implementation GreeJSRecordAnalyticsDataCommand

#pragma mark - Public Interface

+(NSString*)name
{
  return @"record_analytics_data";
}

-(void)execute:(NSDictionary*)params
{
  GreeSerializer* deserializer = [GreeSerializer deserializerWithDictionary:params];
  GreeAnalyticsEvent* event = [[GreeAnalyticsEvent alloc] initWithGreeSerializer:deserializer];
  [[GreePlatform sharedInstance] addAnalyticsEvent:
   [GreeAnalyticsEvent eventWithType:event.type
                                name:event.name
                                from:event.from
                          parameters:event.parameters]];
  [event release];

  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  [[self.environment handler]
   callback:[params objectForKey:kGreeJSAddAnalyticsEventCallbackFunction]
     params:callbackParameters];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]),
          self];
}

@end
