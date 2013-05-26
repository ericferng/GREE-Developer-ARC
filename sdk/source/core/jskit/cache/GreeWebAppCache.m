//
// Copyright 2011 GREE, Inc.
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
#import "GreeWebAppCacheLog.h"
#import "GreeWebAppCacheManifest.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"

@interface GreeWebAppCache ()
-(id)initWithName:(NSString*)name withBaseURL:(NSURL*)baseURL;
-(BOOL)enqueueItem:(GreeWebAppCacheItem*)item withPriority:(NSOperationQueuePriority)priority;
-(void)synchronizedCoreFilesWithSuccess:(BOOL)success;
-(void)synchronizedAllFilesWithSuccess:(BOOL)success;
-(void)updateSyncStatus;
-(void)removeItemFromFileList:(GreeWebAppCacheItem*)item;
-(void)onUpdatedCacheForOperation:(GreeAFHTTPRequestOperation*)requestOperation cacheItem:(GreeWebAppCacheItem*)item;
-(long long)lastModified:(NSDictionary*)headers;
-(void)markAsFailedToDownload:(GreeWebAppCacheItem*)item;
-(void)operationForRequestEnded:(GreeAFHTTPRequestOperation*)requestOperation;
@end


@implementation GreeWebAppCache

static NSMutableDictionary* applications = nil;


#pragma mark -
#pragma mark Class Methods

+(GreeWebAppCache*)registerAppCacheForName:(NSString*)name withBaseURL:(NSURL*)baseURL
{
  if (applications == nil) {
    applications = [[NSMutableDictionary alloc] init];
  }
  GreeWebAppCache* appCache = [self appCacheForName:name];
  if (appCache == nil) {
    appCache = [[[GreeWebAppCache alloc] initWithName:name withBaseURL:baseURL] autorelease];
    [applications setObject:appCache forKey:name];
    appCache.baseURL = baseURL;
  }
  return appCache;
}

+(GreeWebAppCache*)appCacheForName:(NSString*)name
{
  return [applications objectForKey:name];
}


#pragma mark -
#pragma mark Object Lifecycle

-(void)dealloc
{
  [applicationName_ release];
  [httpClient_ release];
  [coreFiles_ release];
  [nonCoreFiles_ release];
  [failedCoreFileRequests_ release];
  [failedNonCoreFileRequests_ release];
  [super dealloc];
}


#pragma mark -
#pragma mark Public Interface

-(NSURL*)applicationURLToSynchronizeCache
{
  return [NSURL URLWithString:[NSString stringWithFormat:@"?app=%@&version=%lld", applicationName_, [self versionOfCachedContent]] relativeToURL:baseURL_];
}

-(NSURL*)applicationURL
{
  return [NSURL URLWithString:[NSString stringWithFormat:@"?app=%@", applicationName_] relativeToURL:baseURL_];
}

-(BOOL)isItemAlreadyInQueue:(GreeWebAppCacheItem*)item
{
  NSString* url = [item.url absoluteString];

  if (item.core) {
    return ([coreFiles_ objectForKey:url] != nil);
  } else {
    return ([nonCoreFiles_ objectForKey:url] != nil);
  }
}

-(BOOL)enqueueItem:(GreeWebAppCacheItem*)item
{
  return [self enqueueItem:item withPriority:NSOperationQueuePriorityNormal];
}

-(BOOL)fetchURLWithPriority:(NSURL*)url
{
  NSString* key = [url absoluteString];
  NSOperation* op = nil;
  if (( op = [coreFiles_ objectForKey:key]) == nil) {
    op = [nonCoreFiles_ objectForKey:key];
  }
  if (op) {
    op.queuePriority = NSOperationQueuePriorityHigh;
  } else {
    if ([manifest_ hasUpToDateCacheForURL:url]) {
      // already download completed
    } else {
      GreeWebAppCacheItem* item = [[[GreeWebAppCacheItem alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    [url absoluteString], @"path",
                                                                                    nil]
                                                                       withBaseURL:baseURL_] autorelease];
      [self enqueueItem:item withPriority:NSOperationQueuePriorityHigh];
    }
  }
  return YES;
}

-(BOOL)hasUpToDateCacheForURL:(NSURL*)u
{
  return [manifest_ hasUpToDateCacheForURL:u];
}

-(void)allFilesUpdatedToVersion:(long long)version
{
  long long newVersion = [manifest_ synchronizationCompletedWithVersion:version];
  [GreeWebAppCacheLog log:@"synchronization completed new version is:%lld specified version by sync command: %lld", newVersion, version];
}

-(long long)versionOfCachedContent
{
  return manifest_.version;
}

-(long long)versionOfCachedContentForURL:(NSURL*)u
{
  return [manifest_ versionOfCachedContentForURL:u];
}

-(BOOL)updateCacheItem:(GreeWebAppCacheItem*)item withContent:(NSData*)content version:(NSUInteger)version
{
  NSString* filePath = [self cachePathForURL:item.url];
  NSArray* components = [filePath componentsSeparatedByString:@"/"];
  NSString* containerDirectoryPath = [[components subarrayWithRange:NSMakeRange(0, [components count] - 1)] componentsJoinedByString:@"/"];
  [[NSFileManager defaultManager] createDirectoryAtPath:containerDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];

  [manifest_ markAsUpToDate:item version:version];

  return [content writeToFile:filePath atomically:YES];
}

-(BOOL)isSyncingCoreFiles
{
  return ([coreFiles_ count] > 0);
}

-(BOOL)isReadyToBoot
{
  return ([self isSyncingCoreFiles] == NO) && ([failedCoreFileRequests_ count] <= 0);
}

-(BOOL)isURLInManifest:(NSURL*)url
{
  return [manifest_ isURLInManifest:url];
}

-(void)startSync
{
  synchronized_ = NO;
  [self updateSyncStatus];
  //[queue_ setSuspended:NO];
}

-(NSString*)cachePathForURL:(NSURL*)u
{
  return [manifest_ cachePathForURL:u];
}


#pragma mark -
#pragma mark Internal Methods

-(id)initWithName:(NSString*)name withBaseURL:(NSURL*)baseURL
{
  if ((self = [super init])) {
    coreFiles_ = [[NSMutableDictionary alloc] init];
    nonCoreFiles_ = [[NSMutableDictionary alloc] init];
    failedCoreFileRequests_ = [[NSMutableArray alloc] init];
    failedNonCoreFileRequests_ = [[NSMutableArray alloc] init];

    applicationName_ = [name retain];
    
    httpClient_ = [[GreeAFHTTPClient clientWithBaseURL:baseURL] retain];
    manifest_ = [[GreeWebAppCacheManifest alloc] initWithName:name withBaseURL:baseURL];

    if (manifest_.bundledAssetsCopied) {
      [GreeWebAppCacheLog log:@"copied assets from bundle"];
    }
    [GreeWebAppCacheLog log:@"appcache initialized version:%lld", manifest_.version];

    synchronized_ = NO;
    coreFilesReady_ = NO;
  }
  return self;
}

-(BOOL)enqueueItem:(GreeWebAppCacheItem*)item withPriority:(NSOperationQueuePriority)priority
{
  NSString* url = [item.url absoluteString];

  [manifest_ markAsOutOfDate:item];

  NSURL* u = item.url;
  
  NSURLRequest* request = [NSURLRequest requestWithURL:u];
  __block GreeWebAppCacheItem* blockItem = [item retain];

  GreeAFHTTPRequestOperation* requestOperation = [httpClient_ HTTPRequestOperationWithRequest:request
                                                                                      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
                                                    NSData* data = [operation responseData];

                                                    long long lastModified = [self lastModified:operation.response.allHeaderFields];
                                                    [GreeWebAppCacheLog log:@"requestDidFinish %@ item.version:%lld lastModified:%lld remains(core,noncore):(%d,%d)", [blockItem.url absoluteString], blockItem.version, lastModified, [coreFiles_ count], [nonCoreFiles_ count]];

                                                    if (blockItem.version < lastModified) {
                                                      
                                                      NSLog(@"version changed while syncing");
                                                    }

                                                    [self updateCacheItem:blockItem withContent:data version:lastModified];
                                                    [self onUpdatedCacheForOperation:operation cacheItem:blockItem];
                                                    [self removeItemFromFileList:blockItem];

                                                    [self operationForRequestEnded:operation];
                                                    [blockItem release];
                                                  }
                                                                                      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
                                                    [GreeWebAppCacheLog log:@"requestDidFail %@ item.version:%lld remains:(%d,%d)", [blockItem.url absoluteString], blockItem.version, [coreFiles_ count], [nonCoreFiles_ count]];

                                                    [self markAsFailedToDownload:blockItem];
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebAppCacheFailedToUpdatNotification object:self
                                                                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                               blockItem.url, GreeWebAppCacheFileUpdatedNotificationUrlKey,
                                                               [error localizedDescription], GreeWebAppCacheFileUpdatedNotificationReasonKey,
                                                               nil]];
                                                    [self operationForRequestEnded:operation];

                                                    [blockItem release];
                                                  }
                                                 ];
  [requestOperation setQueuePriority:priority];
  [httpClient_ enqueueHTTPRequestOperation:requestOperation];

  synchronized_ = NO;
  if (item.core) {
    [coreFiles_ setObject:requestOperation forKey:url];
    coreFilesReady_ = NO;
  } else {
    [nonCoreFiles_ setObject:requestOperation forKey:url];
  }

  [GreeWebAppCacheLog log:@"enqueueItem %@ version:%lld core:%d", [u absoluteString], item.version, item.core];

  return YES;
}

-(void)synchronizedCoreFilesWithSuccess:(BOOL)success
{
  [GreeWebAppCacheLog log:@"Core files synchronized success: %d", success];
  coreFilesReady_ = success;
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebAppCacheCoreFilesUpdatedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                               [NSNumber numberWithBool:success], GreeWebAppCacheCoreFilesUpdatedNotificationSuccessKey,
                                                                                                                               nil]
  ];
}

-(void)synchronizedAllFilesWithSuccess:(BOOL)success
{
  [GreeWebAppCacheLog log:@"All files synchronized success: %d", success];
  synchronized_ = success;
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebAppCacheAllFilesUpdatedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                              [NSNumber numberWithBool:success], GreeWebAppCacheAllFilesUpdatedNotificationSuccessKey,
                                                                                                                              nil]
  ];
  [failedCoreFileRequests_ removeAllObjects];
  [failedNonCoreFileRequests_ removeAllObjects];
}

-(void)updateSyncStatus
{
  if (coreFilesReady_ == NO && [coreFiles_ count] <= 0) {
    BOOL success = ([failedCoreFileRequests_ count] <= 0);
    [self synchronizedCoreFilesWithSuccess:success];
  }
  if (synchronized_ == NO && [coreFiles_ count] <= 0 && [nonCoreFiles_ count] <= 0) {
    BOOL success = ([failedCoreFileRequests_ count] <= 0) && ([failedNonCoreFileRequests_ count] <= 0);
    [self synchronizedAllFilesWithSuccess:success];
  }
}

-(void)removeItemFromFileList:(GreeWebAppCacheItem*)item
{
  NSString* url = [item.url absoluteString];
  if (item.core) {
    [coreFiles_ removeObjectForKey:url];
  } else {
    [nonCoreFiles_ removeObjectForKey:url];
  }
}

-(void)onUpdatedCacheForOperation:(GreeAFHTTPRequestOperation*)requestOperation cacheItem:(GreeWebAppCacheItem*)item
{
  // NSHTTPURLResponses return case-sensitive dictionaries of headers.
  NSString* contentType = nil;
  for (NSString* headerKey in requestOperation.request.allHTTPHeaderFields.allKeys) {
    if ([@"content-type" caseInsensitiveCompare:headerKey] == NSOrderedSame) {
      contentType = [requestOperation.request.allHTTPHeaderFields objectForKey:headerKey];
    }
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebAppCacheFileUpdatedNotification object:self
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithBool:item.core], GreeWebAppCacheFileUpdatedNotificationCoreKey,
             [NSNumber numberWithLongLong:item.version], GreeWebAppCacheFileUpdatedNotificationVersionKey,
             item.url, GreeWebAppCacheFileUpdatedNotificationUrlKey,
             contentType,  GreeWebAppCacheFileUpdatedNotificationContentTypeKey,
             nil]];
}

-(long long)lastModified:(NSDictionary*)headers
{
  // NSHTTPURLResponses return case-sensitive dictionaries of headers.
  NSString* lastModified = nil;
  for (NSString* headerKey in headers.allKeys) {
    if ([@"last-modified" caseInsensitiveCompare:headerKey] == NSOrderedSame) {
      lastModified = [headers objectForKey:headerKey];
    }
  }

  NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
  NSDate* date = [dateFormatter dateFromString:lastModified];
  return (long long)[date timeIntervalSince1970];
}


-(void)markAsFailedToDownload:(GreeWebAppCacheItem*)item
{
  NSString* url = [item.url absoluteString];

  if (item.core) {
    [coreFiles_ removeObjectForKey:url];
    [failedCoreFileRequests_ addObject:item];
  } else {
    [failedNonCoreFileRequests_ addObject:item];
    [nonCoreFiles_ removeObjectForKey:url];
  }
}

-(void)operationForRequestEnded:(GreeAFHTTPRequestOperation*)requestOperation
{
  [self updateSyncStatus];
}

#pragma mark -
#pragma mark Unused Methods

//- (int)countOfFailedRequests:(NSDictionary*)files
//{
//  int n = 0;
//  for (NSString *url in files) {
//    NSNumber *b = [coreFiles_ objectForKey:url];
//    if ([b boolValue]) {
//      ++n;
//    }
//  }
//  return n;
//}

@end
