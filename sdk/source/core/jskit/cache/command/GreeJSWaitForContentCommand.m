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


#import "GreeJSCommandFactory.h"
#import "GreeJSWaitForContentCommand.h"
#import "GreeWebAppCache.h"

// invoke "callback" on "url" is updated. "callback" is invoked immediately if "url" is already up-to-date.
@implementation GreeJSWaitForContentCommand

+(NSString*)name
{
  return @"waitForContent";
}

-(NSURL*)urlToLoadWithParams:(NSDictionary*)params
{
  NSString* url = [params objectForKey:@"url"];

  GreeWebAppCache* appCache = [GreeWebAppCache appCacheForName:self.appName];
  return [NSURL URLWithString:url relativeToURL:appCache.baseURL];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
