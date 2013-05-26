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


#import "GreeWebAppCache.h"
#import "GreeJSSyncCommand.h"
#import "GreeJSWebViewMessageEvent.h"

@interface GreeJSSyncCommand ()
@property (nonatomic, retain, readwrite) NSURL* baseURL;
@property (nonatomic, retain, readwrite) NSMutableArray* updatedFiles;
@property (nonatomic, retain, readwrite) NSMutableArray* failedFiles;
@property (nonatomic, readwrite) long long version;

-(void)cacheUpdatedNotification:(NSNotification*)notification;
-(void)allFilesUpdatedNotification:(NSNotification*)notification;
@end


@implementation GreeJSSyncCommand

-(id)init
{
  if ((self = [super init])) {
    self.updatedFiles = [NSMutableArray array];
    self.failedFiles = [NSMutableArray array];
  }
  return self;
}

-(void)dealloc
{
  self.baseURL = nil;
  self.updatedFiles = nil;
  self.failedFiles = nil;
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"sync";
}

-(void)execute:(NSDictionary*)params
{
  // create manifest object if does not exist
  NSString* appName = [params objectForKey:@"app"];
  NSString* versionString = [params objectForKey:@"version"];
  long long version = [versionString longLongValue];

  NSArray* files = [params objectForKey:@"files"];
  if ([appName length] <= 0) {
    NSLog(@"sync command requires app parameter");
    return;
  }

  NSString* href = [[self.environment webviewForCommand:self]
                    stringByEvaluatingJavaScriptFromString:@"document.location.href.replace(/[^/]+$/,'')"];
  self.baseURL = [NSURL URLWithString:href];
  GreeWebAppCache* cache = [GreeWebAppCache appCacheForName:appName];
  if (cache == nil) {
    if (self.baseURL == nil) {
      NSLog(@"invalid sync command issued in %@", href);
      return;
    }
    cache = [GreeWebAppCache registerAppCacheForName:appName withBaseURL:self.baseURL];
  } else {
    // baseURL cound be nil when command is issued from file:// pages.
    if (self.baseURL == nil) {
      self.baseURL = cache.baseURL;
    }
  }

  int enqueued = 0;
  for (NSDictionary* file in files) {
    if (![file isKindOfClass:[NSDictionary class]]) {
      NSLog(@"sync file description should be an object");
      continue;
    }
    GreeWebAppCacheItem* item = [[[GreeWebAppCacheItem alloc] initWithDictionary:file withBaseURL:self.baseURL] autorelease];
    // File is not newer than cached one. skip to update.
    // This situation can be occured in the case the client sent a request without version number.
    long long cachedVersion = [cache versionOfCachedContentForURL:item.url];
    if (item.version <= cachedVersion) {
      [self.failedFiles addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [item.url absoluteString], GreeWebAppCacheFileUpdatedNotificationUrlKey,
                                   [NSString stringWithFormat:@"Newer version %lld is already in cache", item.version], @"reason",
                                   nil]];
      continue;
    }

    if ([cache isItemAlreadyInQueue:item]) {
      continue;
    }

    if ([cache enqueueItem:item]) {
      ++enqueued;
    }
  }

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(cacheUpdatedNotification:)name:GreeWebAppCacheFileUpdatedNotification object:cache];
  [center addObserver:self selector:@selector(cacheFailedNotification:)name:GreeWebAppCacheFailedToUpdatNotification object:cache];
  [center addObserver:self selector:@selector(allFilesUpdatedNotification:)name:GreeWebAppCacheAllFilesUpdatedNotification object:cache];

  self.version = version;

  [cache startSync];
}


#pragma mark - Internal Methods

-(void)cacheUpdatedNotification:(NSNotification*)notification
{
  // values of userInfo should be JSON.stringifiable objects.
  NSMutableDictionary* userInfo = [[notification.userInfo mutableCopy] autorelease];
  [userInfo setObject:[[userInfo objectForKey:GreeWebAppCacheFileUpdatedNotificationUrlKey] absoluteString]
               forKey:GreeWebAppCacheFileUpdatedNotificationUrlKey];
  [GreeJSWebViewMessageEvent postMessageEventName:@"cacheUpdated" object:nil userInfo:userInfo];

  [self.updatedFiles addObject:userInfo];
}
-(void)cacheFailedNotification:(NSNotification*)notification
{
  NSMutableDictionary* userInfo = [[notification.userInfo mutableCopy] autorelease];
  [userInfo setObject:[[userInfo objectForKey:GreeWebAppCacheFileUpdatedNotificationUrlKey] absoluteString]
               forKey:GreeWebAppCacheFileUpdatedNotificationUrlKey];

  [self.failedFiles addObject:userInfo];
}

-(void)allFilesUpdatedNotification:(NSNotification*)notification
{
  GreeWebAppCache* cache = [notification object];
  NSDictionary* userInfo = notification.userInfo;
  BOOL success = [[userInfo objectForKey:GreeWebAppCacheAllFilesUpdatedNotificationSuccessKey] boolValue];
  if (success) {
    [cache allFilesUpdatedToVersion:self.version];
  }

  self.result = [NSDictionary dictionaryWithObjectsAndKeys:
                 cache.applicationName, @"app",
                 [self.baseURL absoluteString], @"baseURL",
                 self.updatedFiles, @"updated",
                 self.failedFiles, @"failed",
                 nil
                ];
  [self callback];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
