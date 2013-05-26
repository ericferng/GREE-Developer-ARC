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


#import "GreeJSShowAlertViewCommand.h"
#import "JSONKit.h"

@interface GreeJSShowAlertViewCommand ()
@property (nonatomic, retain) NSDictionary* parameters;
@end

@implementation GreeJSShowAlertViewCommand

#pragma mark - Object Lifecycle
-(void)dealloc
{
  self.parameters = nil;

  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_alert_view";
}

-(void)execute:(NSDictionary*)params
{
  self.parameters = params;

  id titleObject = [params objectForKey:@"title"];
  id messageObject = [params objectForKey:@"message"];
  NSString* title =   ([titleObject isKindOfClass:[NSString class]]) ? titleObject : [titleObject description];
  NSString* message = ([messageObject isKindOfClass:[NSString class]]) ? messageObject : [messageObject description];

  UIAlertView* alertView = [[[UIAlertView alloc]
                                 initWithTitle:title
                                       message:message
                                      delegate:self
                             cancelButtonTitle:nil
                             otherButtonTitles:nil] autorelease];

  for (NSString* otherButtonTitle in [params objectForKey : @"buttons"]) {
    [alertView addButtonWithTitle:otherButtonTitle];
  }

  NSNumber* cancelButtonIndex = [params objectForKey:@"cancel_index"];

  if (cancelButtonIndex != nil) {
    alertView.cancelButtonIndex = [cancelButtonIndex integerValue];
  }

  [alertView show];
  [self retain];
}

-(void)callback
{
  self.parameters = nil;

  [super callback];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:buttonIndex] forKey:@"result"];

  [[self.environment handler]
   callback:[self.parameters objectForKey:@"callback"]
     params:callbackParameters];

  [self callback];
  [self release];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
