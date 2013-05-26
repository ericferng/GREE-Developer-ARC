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


#import <Foundation/Foundation.h>

@class GreeWebAppCacheItem;

@interface GreeWebAppCacheManifest : NSObject {
  NSString* name_;

  NSMutableDictionary* manifest_;
  NSMutableDictionary* files_;

  long long version_;
  NSURL* baseURL_;
  NSString* cacheRoot_;
  BOOL bundledAssetsCopied_;
}
@property (nonatomic, readonly, retain) NSString* cacheRoot;
@property (nonatomic, readonly, assign) long long version;
@property (nonatomic, readonly, retain) NSURL* baseURL;
@property (nonatomic, readonly, assign) BOOL bundledAssetsCopied;

-(id)initWithName:(NSString*)name withBaseURL:(NSURL*)baseURL;

-(NSString*)cachePathForURL:(NSURL*)u;

-(BOOL)isURLInManifest:(NSURL*)url;

-(void)markAsUpToDate:(GreeWebAppCacheItem*)item version:(NSUInteger)version;
-(void)markAsOutOfDate:(GreeWebAppCacheItem*)item;
-(void)markAllAsOutOfDate;
-(BOOL)hasUpToDateCacheForURL:(NSURL*)u;
-(void)flushToDisk;
-(long long)synchronizationCompletedWithVersion:(long long)version;
-(long long)versionOfCachedContentForURL:(NSURL*)u;

@end
