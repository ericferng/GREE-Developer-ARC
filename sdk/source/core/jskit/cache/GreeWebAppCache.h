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


#import "GreeWebAppCacheItem.h"

@class GreeWebAppCache;
@class GreeWebAppCacheManifest;
@class GreeAFHTTPClient;


#define GreeWebAppCacheFileUpdatedNotification @"GreeWebAppCacheFileUpdatedNotification"
#define GreeWebAppCacheFailedToUpdatNotification @"GreeWebAppCacheFailedToUpdatNotification"
#define GreeWebAppCacheCoreFilesUpdatedNotification @"GreeWebAppCacheCoreFilesUpdatedNotification"
#define GreeWebAppCacheAllFilesUpdatedNotification @"GreeWebAppCacheAllFilesUpdatedNotification"
#define GreeWebAppCacheSynchronizationCompletedNotification @"GreeWebAppCacheSynchronizationCompletedNotification"

#define GreeWebAppCacheFileUpdatedNotificationCoreKey  @"core"
#define GreeWebAppCacheFileUpdatedNotificationUrlKey  @"url"
#define GreeWebAppCacheFileUpdatedNotificationReasonKey  @"reason"
#define GreeWebAppCacheFileUpdatedNotificationContentTypeKey  @"contentType"
#define GreeWebAppCacheFileUpdatedNotificationVersionKey  @"version"

#define GreeWebAppCacheCoreFilesUpdatedNotificationSuccessKey @"GreeWebAppCacheCoreFilesUpdatedNotificationSuccessKey"
#define GreeWebAppCacheAllFilesUpdatedNotificationSuccessKey  @"GreeWebAppCacheAllFilesUpdatedNotificationSuccessKey"

@interface GreeWebAppCache : NSObject {
  NSString* applicationName_;
  NSURL* baseURL_;

  GreeAFHTTPClient* httpClient_;
  BOOL synchronized_;
  BOOL coreFilesReady_;

  // List of files to download. Set No to the value if failed to download.
  NSMutableDictionary* coreFiles_;
  NSMutableDictionary* nonCoreFiles_;

  NSMutableArray* failedCoreFileRequests_;
  NSMutableArray* failedNonCoreFileRequests_;

  GreeWebAppCacheManifest* manifest_;
}

@property (nonatomic, readonly, assign) BOOL synchronized;
@property (nonatomic, readonly, retain) NSString* applicationName;
@property (nonatomic, readwrite, retain) NSURL* baseURL;

+(GreeWebAppCache*)registerAppCacheForName:(NSString*)name withBaseURL:(NSURL*)baseURL;
+(GreeWebAppCache*)appCacheForName:(NSString*)name;

-(NSURL*)applicationURLToSynchronizeCache;
-(NSURL*)applicationURL;
-(BOOL)isItemAlreadyInQueue:(GreeWebAppCacheItem*)item;
-(BOOL)enqueueItem:(GreeWebAppCacheItem*)item;
-(BOOL)fetchURLWithPriority:(NSURL*)url;
-(BOOL)hasUpToDateCacheForURL:(NSURL*)u;
-(void)allFilesUpdatedToVersion:(long long)version;
-(long long)versionOfCachedContent;
-(long long)versionOfCachedContentForURL:(NSURL*)u;
-(BOOL)updateCacheItem:(GreeWebAppCacheItem*)item withContent:(NSData*)content version:(NSUInteger)version;
-(BOOL)isSyncingCoreFiles;
-(BOOL)isReadyToBoot;
-(BOOL)isURLInManifest:(NSURL*)url;
-(void)startSync;
-(NSString*)cachePathForURL:(NSURL*)u;


@end
