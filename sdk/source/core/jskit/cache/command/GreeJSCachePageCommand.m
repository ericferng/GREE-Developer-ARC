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

@interface GreeJSCachePageCommand : GreeJSCommand
@end


@implementation GreeJSCachePageCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"cachePage";
}

-(void)execute:(NSDictionary*)params
{
  NSString* appName = [params objectForKey:@"app"];
  if ([appName length] <= 0) {
    NSLog(@"%@ command requires app parameter", [[self class] name]);
    return;
  }

  NSUInteger version = [[params objectForKey:@"version"] unsignedIntegerValue];
  if (version <= 0) {
    NSLog(@"%@ invalid cache version", [[self class] name]);
    return;
  }

  NSString* href = [[self.environment webviewForCommand:self ]
                    stringByEvaluatingJavaScriptFromString:@"document.location.href"];
  NSURL* u = [NSURL URLWithString:href];

  GreeWebAppCache* appCache = [GreeWebAppCache appCacheForName:appName];
  NSString* content = [[self.environment webviewForCommand:self]
                       stringByEvaluatingJavaScriptFromString:@"try{window.__bootstrap.rawHtml()}catch(e){document.documentElement.outerHTML}"];
  NSData* data = [content dataUsingEncoding:NSUTF8StringEncoding];

  NSArray* components = [[u path] componentsSeparatedByString:@"/"];
  NSString* lastPathComponent = [components lastObject];
  GreeWebAppCacheItem* item = [[[GreeWebAppCacheItem alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                lastPathComponent, @"path",
                                                                                nil] withBaseURL:u] autorelease];
  [appCache updateCacheItem:item withContent:data version:version];

  self.result = [NSNumber numberWithBool:YES];
}


-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
