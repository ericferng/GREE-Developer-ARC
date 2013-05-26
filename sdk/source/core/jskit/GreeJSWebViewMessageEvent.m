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


#import "GreeJSWebViewMessageEvent.h"
#import "JSONKit.h"

NSString* const kGreeJSWebViewMessageEventNotificationName = @"GreeJSWebViewMessageEventNotification";
NSString* const kGreeJSWebViewMessageEventObjectKey = @"GreeJSWebViewMessageEventObjectKey";

@interface GreeJSWebViewMessageEvent ()
@property (nonatomic, readwrite, retain) NSString* messageEventName;
@property (nonatomic, readwrite, assign) NSNotification* notification;
@end

@implementation GreeJSWebViewMessageEvent

+(void)postMessageEventName:(NSString*)name object:(id)object userInfo:(NSDictionary*)userInfo
{
  NSMutableDictionary* d = [[userInfo mutableCopy] autorelease];
  GreeJSWebViewMessageEvent* event = [[[GreeJSWebViewMessageEvent alloc] init] autorelease];
  event.messageEventName = name;
  event.notification = [NSNotification notificationWithName:kGreeJSWebViewMessageEventNotificationName object:object userInfo:d];
  [d setObject:event forKey:kGreeJSWebViewMessageEventObjectKey];

  [[NSNotificationCenter defaultCenter] postNotification:event.notification];
}

-(void)dealloc
{
  [messageEventName_ release];
  [super dealloc];
}

-(void)fireMessageEventInWebView:(UIWebView*)webView
{
  NSMutableDictionary* userInfo = [[self.notification.userInfo mutableCopy] autorelease];
  [userInfo removeObjectForKey:kGreeJSWebViewMessageEventObjectKey];
  [[self class] fireMessageEventName:messageEventName_ userInfo:userInfo inWebView:webView];
}

+(void)fireMessageEventName:(NSString*)name userInfo:(NSDictionary*)userInfo inWebView:(UIWebView*)webView
{

  NSString* json = [userInfo greeJSONString];
  NSString* js = [NSString stringWithFormat:@"(function(e){e.initMessageEvent('%@',true,false,%@,window);return document.dispatchEvent(e)})(document.createEvent('MessageEvent'))", name, json];

  NSString* result = [webView stringByEvaluatingJavaScriptFromString:js];
  if (![result isEqualToString:@"true"]) {
    NSLog(@"fireMessageEventInWebView: failed. webView:%@ js:%@", webView, js);
  }
}

@end
