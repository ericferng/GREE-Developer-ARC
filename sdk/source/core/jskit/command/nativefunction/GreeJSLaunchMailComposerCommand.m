//
// Copyright 2012 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use thisfile except in compliance with the License.
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


#import "GreeJSLaunchMailComposerCommand.h"
#import "GreePlatform+Internal.h"
#import "GreePlatform.h"
#import "UIViewController+GreeAdditions.h"

#define kGreeJSSendMailParamsCallbackKey @"callback"

@interface GreeJSLaunchMailComposerCommand ()
-(void)callbackWithResult:(NSDictionary*)callbackParameters;
@property (nonatomic, retain) NSDictionary* parameters;
@end

@implementation GreeJSLaunchMailComposerCommand
#pragma mark - Object lifecycle

-(void)dealloc
{
  self.parameters = nil;
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"launch_mail_composer";
}

-(void)execute:(NSDictionary*)params
{
  self.parameters = params;

  if (![MFMailComposeViewController canSendMail]) {
    NSDictionary* callbackParameters = [NSDictionary dictionaryWithObject:@"fail" forKey:@"result"];
    [self callbackWithResult:callbackParameters];
    return;
  }

  MFMailComposeViewController* mailViewController = [[MFMailComposeViewController alloc] init];
  mailViewController.mailComposeDelegate = self;
  [mailViewController setSubject:[params objectForKey:@"subject"]];
  [mailViewController setToRecipients:[params objectForKey:@"to"]];
  [mailViewController setCcRecipients:[params objectForKey:@"cc"]];
  [mailViewController setBccRecipients:[params objectForKey:@"bcc"]];
  [mailViewController setMessageBody:[params objectForKey:@"body"] isHTML:NO];
  [[UIViewController greeLastPresentedViewController] greePresentViewController:mailViewController animated:YES completion:nil];
  [mailViewController release];
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
   callback:[self.parameters objectForKey:kGreeJSSendMailParamsCallbackKey]
     params:callbackParameters];

  [self callback];
}

#pragma mark - MFMailComposeViewController delegate method
-(void)mailComposeController:(MFMailComposeViewController*)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError*)error
{
  NSDictionary* callbackParameters = nil;

  switch (result) {
  case MFMailComposeResultSent:
  case MFMailComposeResultSaved:
  case MFMailComposeResultFailed:
  case MFMailComposeResultCancelled:
  default:
    callbackParameters = [NSDictionary dictionaryWithObject:@"success" forKey:@"result"];
    break;
  }


  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  [self callbackWithResult:callbackParameters];
}

@end
