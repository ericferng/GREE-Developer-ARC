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


#import "GreeJSLaunchNativeBrowserCommand.h"
#import <MessageUI/MessageUI.h>

#define kGreeJSLaunchNativeBrowserCommand @"callback"

@interface GreeJSLaunchNativeBrowserCommand ()
-(NSDictionary*)callbackDictionaryWithResult:(NSString*)result error:(NSString*)error;
@end

@implementation GreeJSLaunchNativeBrowserCommand

#pragma mark - GreeJSCommand Overrides
+(NSString*)name
{
  return @"launch_native_browser";
}

-(void)execute:(NSDictionary*)params
{
  NSString* urlString = [params objectForKey:@"URL"];

  if (urlString == nil) {
    [[self.environment handler]
     callback:kGreeJSLaunchNativeBrowserCommand
       params:[self callbackDictionaryWithResult:@"-1" error:@"No URL Provided"]];
    return;
  }

  NSURL* URL = [NSURL URLWithString:urlString];

  if (URL == nil) {
    [[self.environment handler]
     callback:kGreeJSLaunchNativeBrowserCommand
       params:[self callbackDictionaryWithResult:@"-1" error:@"Invalid URL Provided"]];
    return;
  }

  if (![[UIApplication sharedApplication] canOpenURL:URL]) {
    [[self.environment handler]
     callback:kGreeJSLaunchNativeBrowserCommand
       params:[self callbackDictionaryWithResult:@"-1" error:@"UIApplication could not open the URL"]];
    return;
  }

  [[UIApplication sharedApplication] openURL:URL];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

#pragma mark - Internal Methods
-(NSDictionary*)callbackDictionaryWithResult:(NSString*)result error:(NSString*)error
{
  return [NSDictionary dictionaryWithObjectsAndKeys:result, @"result", error, @"error", nil];
}

@end
