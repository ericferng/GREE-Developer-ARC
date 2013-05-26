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


#import <UIKit/UIKit.h>

extern NSString* const kGreeJSWebViewMessageEventNotificationName;
extern NSString* const kGreeJSWebViewMessageEventObjectKey;

@interface GreeJSWebViewMessageEvent : NSObject {
  NSString* messageEventName_;
  NSNotification* notification_;
}
@property (nonatomic, readonly, retain) NSString* messageEventName;
@property (nonatomic, readonly, assign) NSNotification* notification;

+(void)postMessageEventName:(NSString*)name object:(id)object userInfo:(NSDictionary*)userInfo;
-(void)fireMessageEventInWebView:(UIWebView*)webView;
+(void)fireMessageEventName:(NSString*)name userInfo:(NSDictionary*)userInfo inWebView:(UIWebView*)webView;
@end
