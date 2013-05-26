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
#import "GreeWebAppCache.h"
#import "GreeJSWebViewController.h"

@interface GreeJSIsInManifestCommand : GreeJSCommand
@end

@implementation GreeJSIsInManifestCommand

+(NSString*)name
{
  return @"isInManifest";
}

-(void)execute:(NSDictionary*)params
{
  NSString* appName = [params objectForKey:@"app"];
  if ([appName length] <= 0) {
    NSLog(@"%@ command requires app parameter", [[self class] name]);
    return;
  }

  NSString* url = [params objectForKey:@"url"];
  GreeWebAppCache* appCache = [GreeWebAppCache appCacheForName:appName];

  NSURL* u = [NSURL URLWithString:url relativeToURL:appCache.baseURL];
  BOOL inManifest = [appCache isURLInManifest:u];
  self.result = [NSArray arrayWithObjects:
                 [NSNumber numberWithBool:inManifest],
                 [u absoluteString],
                 nil];

}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}
@end
