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


#import "GreeJSCommandFactory.h"
#import "GreeJSLoadCachedPageCommand.h"
#import "GreeJSSyncCommand.h"
#import "GreeWebAppCache.h"
#import "GreeJSWebViewController.h"

@interface GreeJSLoadCachedPageCommand ()
@property (nonatomic, retain) NSString* failedCallbackFunctionName;
@end

@implementation GreeJSLoadCachedPageCommand

+(NSString*)name
{
  return @"loadCachedPage";
}

-(void)dealloc
{
  [_failedCallbackFunctionName autorelease];
  [super dealloc];
}

-(void)callback
{
  if ([self.result boolValue] == NO) {
    if ([self.failedCallbackFunctionName length] > 0) {
      [[self.environment webviewForCommand:self]
       stringByEvaluatingJavaScriptFromString:
       [NSString stringWithFormat:@"%@()", self.failedCallbackFunctionName]];
    }
  }
}


-(void)readyToLoadPath:(NSString*)path data:(NSData*)data
{
  NSString* suffix = [[self.environment webviewForCommand:self]
                      stringByEvaluatingJavaScriptFromString:@"document.location.search+document.location.hash"];

  NSURL* fileURL = [NSURL fileURLWithPath:path];
  NSURL* url = [NSURL URLWithString:suffix relativeToURL:fileURL];

  [[self.environment webviewForCommand:self] loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:url];
}

-(NSURL*)urlToLoadWithParams:(NSDictionary*)params
{
  NSURL* url = [NSURL URLWithString:[params objectForKey:@"url"]];
  if (url == nil) {
    url = [NSURL URLWithString:[[self.environment webviewForCommand:self]
                                stringByEvaluatingJavaScriptFromString:@"document.location.href"]];
  }
  return url;
}

-(void)execute:(NSDictionary*)params
{
  self.failedCallbackFunctionName = [params objectForKey:@"failed"];
  [super execute:params];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
