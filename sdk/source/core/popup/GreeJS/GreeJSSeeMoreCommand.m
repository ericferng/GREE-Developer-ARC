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


#import "GreeLogger.h"
#import "GreeJSSeeMoreCommand.h"


@implementation GreeJSSeeMoreCommand

#pragma mark - Public Interface

-(void)dealloc
{
  self.nextData = nil;
  [super dealloc];
}


#pragma mark - NSObject Overrides


#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"see_more";
}

-(void)execute:(NSDictionary*)params
{
  GreeLog(@"params:%@ nextData:%@", params, self.nextData);

  UIWebView* aWebView = [self.environment webviewForCommand:self];
  NSArray* items = [self.nextData objectForKey:@"items"];
  for (id anItem in items) {
    NSString* aJsString = [NSString stringWithFormat:@"appendItem(%@)", anItem];
    [aWebView stringByEvaluatingJavaScriptFromString:aJsString];
  }

  NSNumber* offset = (NSNumber*)[self.nextData objectForKey:@"offset"];
  NSNumber* limit = (NSNumber*)[self.nextData objectForKey:@"limit"];
  NSString* hasNext = [self.nextData objectForKey:@"hasNext"];
  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                      offset, @"offset",
                                      limit, @"limit",
                                      hasNext, @"hasNext",
                                      nil];
  NSString* callback = [params objectForKey:@"callback"];
  [[self.environment handler] callback:callback params:callbackParameters];
  [self callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}
@end
