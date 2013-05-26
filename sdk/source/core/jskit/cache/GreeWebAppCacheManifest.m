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


#import "GreeWebAppCacheManifest.h"
#import "GreeWebAppCacheItem.h"
#import "JSONKit.h"
#import "NSBundle+GreeAdditions.h"
#import <UIKit/UIKit.h>

@interface GreeWebAppCacheManifest ()
@property (nonatomic, readwrite, retain) NSString* cacheRoot;
@property (nonatomic, readwrite, retain) NSURL* baseURL;

-(void)initializeAppCacheContent;
-(NSString*)bundledAssetRoot;
-(NSString*)cachedManifestPath;
-(long long)latestVersionOfCachedContent;
-(void)onManifestUpdated;
-(NSMutableDictionary*)cacheEntryForURL:(NSURL*)u;
-(NSString*)normalizeURLForHashKey:(NSURL*)url;
-(void)markItem:(GreeWebAppCacheItem*)item asUpToDate:(BOOL)upToDate version:(NSUInteger)version;
-(BOOL)copyDefaultManifest;
-(NSString*)localVersionCatalog;
-(BOOL)hasFreshManifest;
-(void)removeCachedFileForItem:(GreeWebAppCacheItem*)item;
-(void)debugDumpManifestAsJSON;
@end

@implementation GreeWebAppCacheManifest

#define MANIFEST_FILENAME @"manifest.plist"


#pragma mark - Object Lifecycle

-(id)initWithName:(NSString*)name withBaseURL:(NSURL*)baseURL
{
  if ((self = [super init])) {
    name_ = [name retain];

    NSArray* pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cacheRoot = [NSString stringWithFormat:@"%@/assets-%@.bundle", [pathList lastObject], name_];
    self.baseURL = baseURL;

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification* note) {
       [self flushToDisk];
     }];

    [self initializeAppCacheContent];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [manifest_ release];
  [files_ release];
  [baseURL_ release];
  [super dealloc];
}


#pragma mark - Public Interface

// Returns local file path for URL
-(NSString*)cachePathForURL:(NSURL*)u
{
  NSString* path = [u path];
  if ([path isEqualToString:@"/"]) {
    path = @"/index.html";
  }
  NSString* filePath = [NSString stringWithFormat:@"%@/%@%@", self.cacheRoot, [u host], path];
  return filePath;
}

-(BOOL)isURLInManifest:(NSURL*)url
{
  NSString* key = [self normalizeURLForHashKey:url];
  return ([files_ objectForKey:key] != nil);
}

-(void)markAsUpToDate:(GreeWebAppCacheItem*)item version:(NSUInteger)version
{
  [self markItem:item asUpToDate:YES version:version];
}

-(void)markAsOutOfDate:(GreeWebAppCacheItem*)item
{
  [self markItem:item asUpToDate:NO version:0];
}

-(void)markAllAsOutOfDate
{
  for (NSString* key in files_) {
    NSMutableDictionary* entry = [files_ objectForKey:key];
    [entry setObject:[NSNumber numberWithBool:NO] forKey:@"upToDate"];
  }
}

-(BOOL)hasUpToDateCacheForURL:(NSURL*)u
{
  NSDictionary* entry = [self cacheEntryForURL:u];
  NSString* upToDate = [entry objectForKey:@"upToDate"];
  return upToDate ? [upToDate boolValue] : YES;
}

-(void)flushToDisk
{
  NSString* manifestPath = [self cachedManifestPath];
  [manifest_ setObject:[NSNumber numberWithUnsignedInteger:version_] forKey:@"version"];
  [manifest_ writeToFile:manifestPath atomically:YES];
}

-(long long)synchronizationCompletedWithVersion:(long long)version
{
  long long actuallyCachedContentVersion = [self latestVersionOfCachedContent];
  // verion information inconsistency between assets server and application server can occur
  // due to the case that synchronization happened during deployment
  long long newVersion = (actuallyCachedContentVersion > version) ? version : actuallyCachedContentVersion;
  if (newVersion <= version_) {
    return 0;
  }

  version_ = newVersion;
  [self flushToDisk];

  return newVersion;
}

-(long long)versionOfCachedContentForURL:(NSURL*)u
{
  NSDictionary* entry = [self cacheEntryForURL:u];
  NSNumber* version = [entry objectForKey:@"version"];
  return [version longLongValue];
}


#pragma mark - Internal Methods

-(void)initializeAppCacheContent
{
  if ([self hasFreshManifest] == NO) {
    bundledAssetsCopied_ = YES;
    [self copyDefaultManifest];
  }

  manifest_ = [[NSMutableDictionary alloc] initWithContentsOfFile:[self cachedManifestPath]];

  // resolve relative pathes
  NSDictionary* files = [manifest_ objectForKey:@"files"];
  files_ = [[NSMutableDictionary alloc] init];
  for (NSString* path in files) {
    NSURL* u = [NSURL URLWithString:path relativeToURL:baseURL_];
    NSDictionary* file = [files objectForKey:path];
    path = [u absoluteString];
    [files_ setObject:file forKey:path];
  }
  [manifest_ setObject:files_ forKey:@"files"];

  NSString* version = [manifest_ objectForKey:@"version"];
  version_ = [version longLongValue];
}

-(NSString*)bundledAssetRoot
{
  NSString* bundlePath = [[NSBundle greePlatformCoreBundle] bundlePath];
  return [NSString stringWithFormat:@"%@/assets-%@.bundle", bundlePath, name_];
}

-(NSString*)cachedManifestPath
{
  return [NSString stringWithFormat:@"%@/"MANIFEST_FILENAME, self.cacheRoot];
}

// returns minimum version of cached assets
-(long long)latestVersionOfCachedContent
{
  long long version = 0;
  for (NSString* key in files_)
  {
    NSDictionary* file = [files_ objectForKey:key];
    NSNumber* versionNumber = [file objectForKey:@"version"];
    if (versionNumber) {
      long long v = [versionNumber longLongValue];
      if (version < v) {
        version = v;
      }
    }
  }
  return version;
}

-(void)applicationWillResignActiveNotification:(NSNotification*)notification
{
}

-(void)onManifestUpdated
{
}

-(NSMutableDictionary*)cacheEntryForURL:(NSURL*)u
{
  NSString* key = [self normalizeURLForHashKey:u];
  return [files_ objectForKey:key];
}

-(NSString*)normalizeURLForHashKey:(NSURL*)url
{
  NSString* u = [url absoluteString];
  NSRange range = [u rangeOfString:@"?"];
  if (range.location != NSNotFound) {
    u = [u substringToIndex:range.location];
  }
  range = [u rangeOfString:@"#"];
  if (range.location != NSNotFound) {
    u = [u substringToIndex:range.location];
  }
  return u;
}

-(void)markItem:(GreeWebAppCacheItem*)item asUpToDate:(BOOL)upToDate version:(NSUInteger)version
{
  NSString* key = [self normalizeURLForHashKey:item.url];

  NSMutableDictionary* entry = [files_ objectForKey:key];
  if (entry) {
    [entry setObject:[NSNumber numberWithBool:upToDate] forKey:@"upToDate"];
    if (version > 0) {
      [entry setObject:[NSNumber numberWithUnsignedInteger:version] forKey:@"version"];
    }
  } else {
    entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
             [item.url absoluteString], @"path",
             [NSNumber numberWithBool:item.core], @"core",
             [NSNumber numberWithLongLong:version], @"version",
             [NSNumber numberWithBool:upToDate], @"upToDate",
             nil];
    [files_ setObject:entry forKey:key];
  }

  if (upToDate == NO) {
    [self removeCachedFileForItem:item];
  }
  [self onManifestUpdated];
}

-(BOOL)copyDefaultManifest
{
  NSString* bundlePath = [self bundledAssetRoot];
  NSDirectoryEnumerator* dir = [[NSFileManager defaultManager] enumeratorAtPath:bundlePath];
  NSString* file;
  while((file = [dir nextObject])) {
    NSString* destination = [[self.cacheRoot stringByAppendingPathComponent:[baseURL_ host]] stringByAppendingPathComponent:file];
    if([[dir fileAttributes] fileType] == NSFileTypeDirectory) {
      [[NSFileManager defaultManager] createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];
    } else if([[dir fileAttributes] fileType] == NSFileTypeRegular) {
      // copy manifest at last therefore manifest.plist file is used as a flag indicates that all files are copied from asset or not.
      if ([file isEqualToString:MANIFEST_FILENAME]) {
        continue;
      }
      NSString* source = [bundlePath stringByAppendingPathComponent:file];
      [[NSData dataWithContentsOfFile:source] writeToFile:destination atomically:NO];
    }
  }

  NSString* jsonfile = [NSString stringWithFormat:@"%@/%@.json", bundlePath, MANIFEST_FILENAME];
  NSData* data = [NSData dataWithContentsOfFile:jsonfile];
  NSString* json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
  NSDictionary* manifest = [json greeMutableObjectFromJSONString];
  [manifest writeToFile:[self cachedManifestPath] atomically:YES];

  return YES;
}

-(NSString*)localVersionCatalog
{
  return @"";
}

-(BOOL)hasFreshManifest
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSString* cachedManifestPath = [self cachedManifestPath];
  if ([fm fileExistsAtPath:cachedManifestPath] == NO) {
    NSLog(@"%s -- Could not find manifest file at path[%@]", __FUNCTION__, cachedManifestPath);
  }

  NSString* bundlePath = [self bundledAssetRoot];
  NSString* bundledManifestPath = [bundlePath stringByAppendingPathComponent:MANIFEST_FILENAME];

  NSError* error = nil;
  [fm attributesOfItemAtPath:bundledManifestPath error:&error];
  if (error) {
    NSLog(@"bundled manifest not found at %@", bundledManifestPath);
    return NO;
  }
  [fm attributesOfItemAtPath:cachedManifestPath error:&error];
  if (error) {
    return NO;
  }

  return YES;
}

-(void)removeCachedFileForItem:(GreeWebAppCacheItem*)item
{
  NSString* filepath = [self cachePathForURL:item.url];

  NSError* error;
  [[NSFileManager defaultManager] removeItemAtPath:filepath error:&error];
}

#pragma mark Debug Methods

-(void)debugDumpManifestAsJSON
{
  static int counter = 0;
  NSString* json = [manifest_ greeJSONString];
  NSString* path = [NSString stringWithFormat:@"/Users/kentaro.kumagai/manifest-%d.json", ++counter];
  [[json dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
}

@end
