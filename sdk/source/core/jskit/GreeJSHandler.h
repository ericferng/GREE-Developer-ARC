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

@protocol GreeJSCommandEnvironment;
@class GreeJSCommand;

@interface GreeJSHandler : NSObject
@property (nonatomic, assign) UIWebView* webView;
@property (nonatomic, retain) GreeJSCommand* currentCommand;
@property (nonatomic, retain) NSMutableArray* executingAsyncCommands;

#pragma mark - GreeJSCommand Handlers
+(BOOL)executeCommandFromRequest:(NSURLRequest*)request
                         handler:(GreeJSHandler*)handler
                     environment:(id<GreeJSCommandEnvironment>)environment;
+(BOOL)executeCommand:(GreeJSCommand*)command
           parameters:(NSDictionary*)parameters
              handler:(GreeJSHandler*)handler
          environment:(id<GreeJSCommandEnvironment>)environment;
+(BOOL)isJavascriptBridgeCommand:(NSURLRequest*)request;
+(BOOL)isInterfaceInitializer:(NSURLRequest*)request;
-(NSDictionary*)parameters;
-(void)clearCommandEnvironment:(id<GreeJSCommandEnvironment>)environment;

# pragma mark - Proton JS Function Calls

-(BOOL)isProtonPage;
-(BOOL)isReady;
-(void)open:(NSString*)viewName;
-(void)open:(NSString*)viewName params:(NSDictionary*)params;
-(void)open:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options;
-(void)openURL:(NSURL*)url;
-(void)openURL:(NSURL*)url options:(NSDictionary*)options;
-(void)resetToView:(NSString*)view toParams:(NSDictionary*)params;
-(void)reload;
-(void)reloadWithOptions:(NSDictionary*)options;
-(void)forceLoadView:(NSString*)viewName params:(NSDictionary*)params;
-(void)forceLoadView:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options;
-(void)forcePushView:(NSString*)viewName params:(NSDictionary*)params;
-(NSString*)defaultView;
-(void)callback:(NSString*)callback params:(NSDictionary*)params;
-(void)callback:(NSString*)callback arguments:(NSArray*)args;
-(void)addCallback:(NSString*)ns method:(NSString*)method;

#pragma mark - Native Callback Events
-(void)onCommandInvoked:(GreeJSCommand*)command;
-(void)onCommandCompleted:(GreeJSCommand*)command;

@end
