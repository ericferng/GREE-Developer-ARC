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

#import <objc/runtime.h>
#import "GreeJSCommandFactory.h"
#import "GreeJSReadyCommand.h"
#import "GreeJSStartLoadingCommand.h"
#import "GreeJSContentsReadyCommand.h"
#import "GreeJSFailedWithErrorCommand.h"
#import "GreeJSInputSuccessCommand.h"
#import "GreeJSInputFailureCommand.h"
#import "GreeJSPushViewCommand.h"
#import "GreeJSPushViewWithUrlCommand.h"
#import "GreeJSPopViewCommand.h"
#import "GreeJSShowModalViewCommand.h"
#import "GreeJSShowInputViewCommand.h"
#import "GreeJSDismissModalViewCommand.h"
#import "GreeJSOpenExternalViewCommand.h"
#import "GreeJSSetViewTitleCommand.h"
#import "GreeJSSetPullToRefreshEnabledCommand.h"
#import "GreeJSSetSubnavigationMenuCommand.h"
#import "GreeJSShowPhotoCommand.h"
#import "GreeJSTakePhotoCommand.h"
#import "GreeJSGetContactListCommand.h"
#import "GreeJSOpenFromMenuCommand.h"
#import "GreeJSSetValueCommand.h"
#import "GreeJSGetValueCommand.h"
#import "GreeJSShowAlertViewCommand.h"
#import "GreeJSShowActionSheetCommand.h"
#import "GreeJSLaunchMailComposerCommand.h"
#import "GreeJSLaunchSMSComposerCommand.h"
#import "GreeJSLaunchNativeBrowserCommand.h"
#import "GreeJSLaunchNativeAppCommand.h"
#import "GreeJSSnsApiRequestCommand.h"
#import "GreeJSGetAppInfoCommand.h"
#import "GreeJSShowPhotoViewCommand.h"

@interface GreeJSCommandFactory ()
+(NSMutableDictionary*)parametersFromQueryString:(NSString*)query;
@end


@implementation GreeJSCommandFactory

static GreeJSCommandFactory* _instance = nil;

#pragma mark - Object Lifecycle (Singleton)

+(GreeJSCommandFactory*)instance
{
  @synchronized(self)
  {
    if (!_instance) {
      _instance = [[GreeJSCommandFactory alloc] init];
    }
  }
  return _instance;
}

-(id)init
{
  self = [super init];
  if (self) {
    self.commands = nil;
    [self importCommandMap];
  }
  return self;
}

-(void)dealloc
{
  self.commands = nil;

  [super dealloc];
}

+(id)allocWithZone:(NSZone*)zone
{
  @synchronized(self)
  {
    if (!_instance) {
      _instance = [super allocWithZone:zone];
      return _instance;
    }
  }
  return nil;
}

-(id)copyWithZone:(NSZone*)zone
{
  return self;
}

-(id)retain
{
  return self;
}

-(unsigned)retainCount
{
  return UINT_MAX;
}

-(oneway void)release
{
  // Do nothing.
}

-(id)autorelease
{
  return self;
}


#pragma mark - Public Interface

+(GreeJSCommand*)createCommand:(NSString*)name withCommandMap:(NSDictionary*)commands
{
  Class commandType = [commands objectForKey:name];
  if (commandType == nil) {
    NSString* firstChar = [name substringToIndex:1];
    NSString* body = [name substringFromIndex:1];
    NSString* className = [NSString stringWithFormat:@"GreeJS%@%@Command", [firstChar uppercaseString], body];
    commandType = NSClassFromString(className);
  }
  if (commandType) {
    return [[[commandType alloc] init] autorelease];
  }
  return nil;
}

-(id)createCommand:(NSURLRequest*)request
{
  NSURL* u = [request URL];
  NSString* name = [u host];
  GreeJSCommand* command = [[self class] createCommand:name withCommandMap:self.commands];
  NSDictionary* params = [[self class] parametersFromQueryString:[u query]];
  NSUInteger serial = [[params objectForKey:@"serial"] integerValue];
  command.serial = serial;
  return command;
}


#pragma mark - Internal Methods

+(NSMutableDictionary*)parametersFromQueryString:(NSString*)query
{
  NSMutableDictionary* params = [NSMutableDictionary dictionary];
  NSArray* components = [query componentsSeparatedByString:@"&"];
  for (NSString* pair in components) {
    NSArray* kv = [pair componentsSeparatedByString:@"="];
    if ([kv count] == 2) {
      NSString* k = [[kv objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      NSString* v = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [params setObject:v forKey:k];
    }
  }
  return params;
}

-(BOOL)isSubclassOfGreeJSCommand:(Class)aClass
{
  Class aSuperClass = aClass;

  while((aSuperClass = class_getSuperclass(aSuperClass))) {
    if (aSuperClass == [GreeJSCommand class])
      return YES;
  }

  return NO;
}

-(void)importCommandMap
{
  Class* classes = NULL;
  int numClasses = objc_getClassList(NULL, 0);
  if (0 < numClasses) {
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    NSMutableDictionary* commandMap = [NSMutableDictionary dictionary];

    for (int i1 = 0; i1 < numClasses; i1++) {
      if ([self isSubclassOfGreeJSCommand:classes[i1]]) {
        NSString* commandName = [classes[i1] name];

        if (commandName)
          [commandMap setObject:classes[i1] forKey:commandName];
      }
    }

    free(classes);

    self.commands = commandMap;
  }
}

#pragma mark - NSObject Overrides
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

@end
