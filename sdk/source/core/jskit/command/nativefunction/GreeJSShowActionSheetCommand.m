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


#import "GreeJSShowActionSheetCommand.h"

#define kGreeJSAsyncCommandParamsCallbackKey @"callback"

@interface GreeJSShowActionSheetCommand ()
@property (nonatomic, retain) NSDictionary* parameters;
@end

@implementation GreeJSShowActionSheetCommand

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.parameters = nil;

  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"show_action_sheet";
}

-(void)execute:(NSDictionary*)params
{
  self.parameters = params;

  UIActionSheet* actionSheet = [[[UIActionSheet alloc]
                                          initWithTitle:[params objectForKey:@"title"]
                                               delegate:self
                                      cancelButtonTitle:nil
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:nil] autorelease];

  for (NSString* otherButtonTitle in [params objectForKey : @"buttons"]) {
    [actionSheet addButtonWithTitle:otherButtonTitle];
  }

  NSNumber* destructiveButtonIndex = [params objectForKey:@"destructive_index"];

  if (destructiveButtonIndex != nil) {
    actionSheet.destructiveButtonIndex = [destructiveButtonIndex integerValue];
  }

  NSNumber* cancelButtonIndex = [params objectForKey:@"cancel_index"];

  if (cancelButtonIndex != nil) {
    actionSheet.cancelButtonIndex = [cancelButtonIndex integerValue];
  }

  UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;

  [actionSheet showInView:viewController.view];
}

-(void)callback
{
  self.parameters = nil;

  [super callback];
}

-(void)actionSheet:(UIActionSheet*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:buttonIndex] forKey:@"result"];

  [[self.environment handler]
   callback:[self.parameters objectForKey:kGreeJSAsyncCommandParamsCallbackKey]
     params:callbackParameters];

  [self callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
