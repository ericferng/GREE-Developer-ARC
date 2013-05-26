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

#import <MessageUI/MessageUI.h>
#import "GreeJSLaunchSMSComposerCommand.h"
#import "UIViewController+GreeAdditions.h"

#define kGreeJSSendSMSParamsCallbackKey @"callback"

@interface GreeJSLaunchSMSComposerCommand ()
-(void)callbackWithResult:(NSDictionary*)callbackParameters;
@property (nonatomic, retain) NSDictionary* parameters;
@end

@implementation GreeJSLaunchSMSComposerCommand

#pragma mark - Object lifecycle

-(void)dealloc
{
  self.parameters = nil;
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"launch_sms_composer";
}

-(void)execute:(NSDictionary*)params
{
  NSMutableArray* recipientArray = [NSMutableArray array];
  NSString* bodyString = [NSString string];

  id to = [params objectForKey:@"to"];
  if (to) {
    if ([to isKindOfClass:[NSArray class]]) {
      [recipientArray setArray:to];
    } else if ([to isKindOfClass:[NSString class]]) {
      [recipientArray addObject:to];
    }
  }

  id body = [params objectForKey:@"body"];
  if (body) {
    bodyString = [NSString stringWithFormat:@"%@", body];
  }

  self.parameters = params;

  if (![MFMessageComposeViewController canSendText]) {
    NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:@"fail" forKey:@"result"];
    [self callbackWithResult:callbackParameters];
    return;
  }

  MFMessageComposeViewController* messageViewController = [[MFMessageComposeViewController alloc] init];
  messageViewController.messageComposeDelegate = self;
  messageViewController.recipients = recipientArray;
  messageViewController.body = bodyString;
  [[UIViewController greeLastPresentedViewController] greePresentViewController:messageViewController animated:YES completion:nil];
  [messageViewController release];

}

-(void)callback
{
  self.parameters = nil;

  [super callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

#pragma mark - Internal Methods
-(void)callbackWithResult:(NSDictionary*)callbackParameters
{
  [[self.environment handler]
   callback:[self.parameters objectForKey:kGreeJSSendSMSParamsCallbackKey]
     params:callbackParameters];

  [self callback];
}

#pragma mark - MFMailComposeViewController delegate method
-(void)messageComposeViewController:(MFMessageComposeViewController*)controller
                didFinishWithResult:(MessageComposeResult)result
{
  NSDictionary* callbackParameters = nil;

  switch (result) {
  case MessageComposeResultSent:
  case MessageComposeResultFailed:
  case MessageComposeResultCancelled:
  default:
    callbackParameters = [NSDictionary dictionaryWithObject:@"success" forKey:@"result"];
    break;
  }

  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  [self callbackWithResult:callbackParameters];
}

@end
