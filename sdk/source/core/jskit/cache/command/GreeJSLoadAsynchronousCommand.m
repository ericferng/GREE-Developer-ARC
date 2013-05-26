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

#import "GreeJSLoadAsynchronousCommand.h"
#import "GreeWebAppCache.h"

@interface GreeJSLoadAsynchronousCommand ()

@property (nonatomic, retain) NSURL* urlToLoad;

-(void)_readyToLoad;
@end

@implementation GreeJSLoadAsynchronousCommand

static NSMutableSet* loadingURLs = nil;

+(NSMutableSet*)sharedLoadingURLs
{
  if (loadingURLs == nil) {
    loadingURLs = [[NSMutableSet alloc] init];
  }
  return loadingURLs;
}

-(void)dealloc
{
  self.appName = nil;
  self.urlToLoad = nil;
  [super dealloc];
}

-(void)callback
{
  [super callback];
}
-(GreeWebAppCache*)appCache
{
  return [GreeWebAppCache appCacheForName:self.appName];
}

-(void)windup
{
  [[[self class] sharedLoadingURLs] removeObject:self.urlToLoad];
  [self callback];
}

-(void)waitForURL
{
  if ([[self appCache] hasUpToDateCacheForURL:self.urlToLoad]) {
    [self _readyToLoad];
  } else {
    // change priority if not updated yet
    [[self appCache] fetchURLWithPriority:self.urlToLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUpdatedNotification:)name:GreeWebAppCacheFileUpdatedNotification object:[self appCache]];
  }
}

-(void)onCoreFilesSyncComplete
{
  if ([[self appCache] isReadyToBoot]) {
    [self waitForURL];
  } else {
    // had error while syncing core files
    self.result = [NSNumber numberWithBool:NO];
    [self windup];
  }
}

-(void)waitForCoreFiles
{
  if ([[self appCache] isSyncingCoreFiles]) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreFilesUpdatedNotification:)name:GreeWebAppCacheCoreFilesUpdatedNotification object:[self appCache]];
  } else {
    [self onCoreFilesSyncComplete];
  }
}

-(void)fileUpdatedNotification:(NSNotification*)notification
{
  NSDictionary* userInfo = [notification userInfo];
  NSString* updatedURLString = [[userInfo objectForKey:GreeWebAppCacheFileUpdatedNotificationUrlKey] absoluteString];
  if ([updatedURLString isEqualToString:[self.urlToLoad absoluteString]]) {
    [self _readyToLoad];
  }
}

-(void)failedToUpdate:(NSNotification*)notification
{
  NSDictionary* userInfo = notification.userInfo;
  // Need to check whether the notification is for this command.
  // Therefore fail notificaitons are devlivered to all async load commands.
  NSString* urlString = [[userInfo objectForKey:@"url"] absoluteString];
  if ([urlString isEqualToString:[self.urlToLoad absoluteString]]) {
    self.result = [NSNumber numberWithBool:NO];
    [self windup];
  }
}

-(void)coreFilesUpdatedNotification:(NSNotification*)notification
{
  [self onCoreFilesSyncComplete];
}

-(NSURL*)urlToLoadWithParams:(NSDictionary*)params
{
  // override this method to specify url to load
  return nil;
}

-(void)readyToLoadPath:(NSString*)path data:(NSData*)data
{
  // Override this method to do something.
}

-(void)_readyToLoad
{
  // wait for the file itself
  NSString* filePath = [[self appCache] cachePathForURL:self.urlToLoad];
  NSData* data = [NSData dataWithContentsOfFile:filePath];
  if (data) {
    [self readyToLoadPath:filePath data:data];
  } else {
    NSLog(@"cache not found for %@", filePath);
  }

  self.result = [NSNumber numberWithBool:YES];
  [self windup];
}

-(void)execute:(NSDictionary*)params
{
  NSString* appName = [params objectForKey:@"app"];
  if ([appName length] <= 0) {
    NSLog(@"sync command requires app parameter");
    self.result = [NSNumber numberWithBool:NO];
    [self callback];
    return;
  }
  self.appName = appName;

  NSURL* u = [self urlToLoadWithParams:params];
  if ([[self appCache] isURLInManifest:u] == NO) {
    NSLog(@"url is not in manifest %@", u);
    self.result = [NSNumber numberWithBool:NO];
    [self callback];
    return;
  }

  self.urlToLoad = u;

  NSMutableSet* loadingURLs = [[self class] sharedLoadingURLs];
  [loadingURLs addObject:u];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToUpdate:)name:GreeWebAppCacheFailedToUpdatNotification object:nil];
  [self waitForCoreFiles];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
