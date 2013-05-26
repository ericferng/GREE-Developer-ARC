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


#import "GreeJSHandler.h"
#import "GreeJSCommandFactory.h"
#import "GreeJSAsyncCommand.h"
#import "JSONKit.h"
#import "GreeJSCommandEnvironment.h"

static NSString* const kGreeJSCommandScheme        = @"proton";
static NSString* const kGreeJSInterfaceInitializer = @"about:blank";
static NSString* const kGreeJSScriptGetParams      = @"document.querySelector('iframe#proton').contentWindow.document.body.textContent";

static NSString* const kGreeJSScriptIsProtonPage   = @"document.body.getAttribute('data-proton')";
static NSString* const kGreeJSScriptIsReady        = @"use('proton').isReady();";
static NSString* const kGreeJSScriptOpen           = @"use('proton').open('%@', %@, %@);";
static NSString* const kGreeJSScriptOpenURL        = @"use('proton').openURL('%@', %@);";
static NSString* const kGreeJSScriptReload         = @"use('proton').reload(null, %@);";
static NSString* const kGreeJSScriptReset          = @"use('proton').reset('%@', %@);";
static NSString* const kGreeJSScriptGetDefaultView = @"use('proton').defaultView().name();";
static NSString* const kGreeJSScriptCallback       = @"use('proton.app').callback('%@', %@);";
static NSString* const kGreeJSScriptAddCallback    = @"use('proton.app').addCallback('%@', use('%@')['%@']);";

static NSString* const kGreeJSScriptOnCommandInvoked   = @"use('proton.app').onCommandInvoked('%@');";
static NSString* const kGreeJSScriptOnCommandCompleted = @"use('proton.app').onCommandCompleted('%@', %d, %@);";

@interface GreeJSHandler ()
-(NSDictionary*)dictionaryWithJson:(NSString*)json;
-(NSString*)jsonWithDictionary:(NSDictionary*)dictionary;
-(NSString*)evaluateJavaScript:(NSString*)js;
@end

@implementation GreeJSHandler

#pragma mark - Object Lifecycle

-(id)init
{
  if (self = [super init]) {
    self.executingAsyncCommands = [NSMutableArray array];
  }
  return self;
}

-(void)dealloc
{
  self.currentCommand = nil;
  self.webView = nil;

  for (GreeJSAsyncCommand* command in self.executingAsyncCommands) {
    [command abort];
    command.environment = nil;
  }

  self.executingAsyncCommands = nil;
  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

#pragma mark GreeJSCommand Handlers

+(BOOL)executeCommandFromRequest:(NSURLRequest*)request
                         handler:(GreeJSHandler*)handler
                     environment:(id<GreeJSCommandEnvironment>)environment
{
  if ([GreeJSHandler isInterfaceInitializer:request]) {
    return YES;
  }

  if ([GreeJSHandler isJavascriptBridgeCommand:request]) {
    id command = [[GreeJSCommandFactory instance] createCommand:request];

    if (command) {
      return [self executeCommand:command parameters:[handler parameters] handler:handler environment:environment];
    } else {
      [handler onCommandInvoked:command];
      return YES;
    }
  }

  return NO;
}

+(BOOL)executeCommand:(GreeJSCommand*)command
           parameters:(NSDictionary*)parameters
              handler:(GreeJSHandler*)handler
          environment:(id<GreeJSCommandEnvironment>)environment
{
  if (![environment isJavascriptBridgeEnabled]) {
    return NO;
  }

  if ([environment shouldExecuteCommand:command withParameters:parameters]) {
    if ([environment respondsToSelector:@selector(commandWillExecute:withParameters:)]) {
      [environment commandWillExecute:command withParameters:parameters];
    }

    [handler onCommandInvoked:command];

    command.environment = environment;

    [command execute:parameters];

    if (![command isAsynchronousCommand]) {
      [handler onCommandCompleted:command];
    }

    environment = command.environment;  // The environment may have been nullified at this point
    if ([environment respondsToSelector:@selector(commandDidExecute:withParameters:)]) {
      [environment commandDidExecute:command withParameters:parameters];
    }

    return YES;
  }

  return NO;
}

+(BOOL)isJavascriptBridgeCommand:(NSURLRequest*)request
{
  if ([[[request URL] scheme] isEqualToString:kGreeJSCommandScheme]) {
    return YES;
  }
  return NO;
}

+(BOOL)isInterfaceInitializer:(NSURLRequest*)request
{
  if ([[[request URL] absoluteString] isEqualToString:kGreeJSInterfaceInitializer]) {
    return YES;
  }
  return NO;
}

-(NSDictionary*)parameters
{
  NSString* json = [self evaluateJavaScript:kGreeJSScriptGetParams];
  if (!json) {
    return nil;
  }
  NSDictionary* params = [self dictionaryWithJson:json];
  return params;
}

-(void)clearCommandEnvironment:(id<GreeJSCommandEnvironment>)environment
{
  for (GreeJSAsyncCommand* command in self.executingAsyncCommands) {
    if (command.environment == environment) {
      command.environment = nil;
    }
  }
  if (self.currentCommand.environment == environment) {
    self.currentCommand.environment = nil;
  }
}

#pragma mark Proton JS Function Calls

-(BOOL)isProtonPage
{
  NSString* isProtonPage = [self evaluateJavaScript:kGreeJSScriptIsProtonPage];
  return [isProtonPage isEqualToString:@"true"] ? YES : NO;
}

-(BOOL)isReady
{
  NSString* isReady = [self evaluateJavaScript:kGreeJSScriptIsReady];
  return [isReady isEqualToString:@"true"] ? YES : NO;
}

-(void)open:(NSString*)viewName
{
  [self open:viewName params:nil options:nil];
}

-(void)open:(NSString*)viewName params:(NSDictionary*)params
{
  [self open:viewName params:params options:nil];
}

-(void)open:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options
{
  NSString* jsonParams = [self jsonWithDictionary:params];
  NSString* jsonOptions = [self jsonWithDictionary:options];

  NSString* script = [NSString stringWithFormat:kGreeJSScriptOpen, viewName, jsonParams, jsonOptions];
  [self evaluateJavaScript:script];
}

-(void)openURL:(NSURL*)url
{
  [self openURL:url options:nil];
}

-(void)openURL:(NSURL*)url options:(NSDictionary*)options
{
  NSString* jsonOptions = [self jsonWithDictionary:options];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptOpenURL, [url absoluteURL], jsonOptions];
  [self evaluateJavaScript:script];
}

-(void)reload
{
  [self reloadWithOptions:nil];
}

-(void)reloadWithOptions:(NSDictionary*)options
{
  NSString* json = [self jsonWithDictionary:options];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptReload, json];
  [self evaluateJavaScript:script];
}

-(void)resetToView:(NSString*)view toParams:(NSDictionary*)params
{
  NSString* json = [self jsonWithDictionary:params];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptReset, view, json];
  [self evaluateJavaScript:script];
}

-(void)forceLoadView:(NSString*)viewName params:(NSDictionary*)params
{
  NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"force_load_view"];
  [self open:viewName params:params options:options];
}

-(void)forceLoadView:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options
{
  NSMutableDictionary* opts = [[options mutableCopy] autorelease];
  [opts setValue:[NSNumber numberWithBool:YES] forKey:@"force_load_view"];
  [self open:viewName params:params options:opts];
}

-(void)forcePushView:(NSString*)viewName params:(NSDictionary*)params
{
  NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"force_push_view"];
  [self open:viewName params:params options:options];
}

-(NSString*)defaultView
{
  return [self evaluateJavaScript:kGreeJSScriptGetDefaultView];
}

-(void)callback:(NSString*)callback params:(NSDictionary*)params
{
  NSString* json = [self jsonWithDictionary:params];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptCallback, callback, json];
  [self evaluateJavaScript:script];
}

-(void)callback:(NSString*)callback arguments:(NSArray*)args
{
  NSMutableString* arguments = [NSMutableString string];
  BOOL appendComma = NO;
  for (id arg in args) {
    if (appendComma) {
      [arguments appendString:@","];
    }

    if ([arg isKindOfClass:[NSNumber class]]) {
      if ('c' == *[arg objCType]) {
        [arguments appendString:[arg boolValue] ? @"true": @"false"];
      } else {
        [arguments appendString:[arg stringValue]];
      }
    } else {
      if ([arg isKindOfClass:[NSDictionary class]]) {
        [arguments appendString:[self jsonWithDictionary:arg]];
      } else {
        [arguments appendString:[arg greeJSONString]];
      }
    }
    appendComma = YES;
  }
  NSString* script = [NSString stringWithFormat:kGreeJSScriptCallback, callback, arguments];
  [self evaluateJavaScript:script];
}

-(void)addCallback:(NSString*)ns method:(NSString*)method
{
  NSString* callbackId = [NSString stringWithFormat:@"%@.%@", ns, method];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptAddCallback, callbackId, ns, method];
  [self evaluateJavaScript:script];
}

#pragma mark Native Callback Events

-(void)onCommandInvoked:(GreeJSCommand*)command
{
  self.currentCommand = command;
  if ([command isAsynchronousCommand]) {
    [self.executingAsyncCommands addObject:command];
  }

  NSString* name = [[command class] name];
  NSString* script = [NSString stringWithFormat:kGreeJSScriptOnCommandInvoked, name];
  [self evaluateJavaScript:script];
}

-(void)onCommandCompleted:(GreeJSCommand*)command
{
  
  NSString* result = nil;
  if ([command.result isKindOfClass:[NSNumber class]]) {
    if ('c' == *[command.result objCType]) {
      result = [command.result boolValue] ? @"true" : @"false";
    } else {
      result = [command.result stringValue];
    }
  } else {
    result = command.result ? [command.result greeJSONString] : @"null";
  }
  NSString* script = [NSString stringWithFormat:kGreeJSScriptOnCommandCompleted, [[command class] name], command.serial, result];
  NSString* r = [self evaluateJavaScript:script];
  if (![r isEqualToString:@"ok"]) {
    NSLog(@"onCommandCompleted failed: %@", script);
  }

  self.currentCommand = nil;
  if ([command isAsynchronousCommand]) {
    [self.executingAsyncCommands removeObject:command];
  }
}


#pragma mark - Internal Methods

-(NSDictionary*)dictionaryWithJson:(NSString*)json
{
  NSDictionary* dictionary = [json greeMutableObjectFromJSONString];
  return dictionary;
}

-(NSString*)jsonWithDictionary:(NSDictionary*)dictionary
{
  NSString* json = [dictionary greeJSONString];
  if (!json) {
    json = @"{}";
  }
  return json;
}

-(NSString*)evaluateJavaScript:(NSString*)js
{
  NSString* wrapped = [NSString stringWithFormat:@"try{%@}catch(e){}", js];
  return [self.webView stringByEvaluatingJavaScriptFromString:wrapped];
}
@end
