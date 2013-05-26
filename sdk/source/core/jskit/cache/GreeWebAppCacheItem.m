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

@interface GreeWebAppCacheItem ()
@property (nonatomic, readwrite, retain) NSURL* url;
@property (nonatomic, readwrite, assign) BOOL core;
@property (nonatomic, readwrite, retain) NSString* path;
@end

@implementation GreeWebAppCacheItem

-(id)initWithDictionary:(NSDictionary*)def withBaseURL:(NSURL*)baseURL
{
  // baseURL is always the page URL which issued "cachePage" and "sync" command
  if (self = [super init]) {
    NSString* path = [def objectForKey:@"path"];
    self.url = [NSURL URLWithString:path relativeToURL:baseURL];
    self.core = ([[def objectForKey:@"core"] intValue] > 0);

    NSString* version = [def objectForKey:@"version"];
    self.version = (long long)[version longLongValue];
  }
  return self;
}

-(void)dealloc
{
  [url_ release];
  [super dealloc];
}

@end
