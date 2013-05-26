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

#import "GreeJSIconLoader.h"
#import "GreeJSIconPersistentCache.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@interface GreeJSIconLoader ()
@property (nonatomic, retain) NSMutableDictionary* iconImages;
@property (nonatomic, retain) NSOperationQueue* queue;
@end

@implementation GreeJSIconLoader

# pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.iconImages = [NSMutableDictionary dictionary];
    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    self.queue.maxConcurrentOperationCount = 2;
    [self.queue setSuspended:NO];
  }
  return self;
}

-(void)dealloc
{
  self.iconImages = nil;
  self.queue = nil;
  [super dealloc];
}

# pragma mark - Public Methods

+(id)sharedIconLoader
{
  static id _sharedIconLoader = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
                  _sharedIconLoader = [[self alloc] init];
                });
  return _sharedIconLoader;
}

-(void)requestIconForKey:(NSURL*)key
{
  [self requestIconForKey:key options:[NSDictionary dictionary]];
}

-(void)requestIconForKey:(NSURL*)key options:(NSDictionary*)options
{
  UIImage* icon = [self.iconImages objectForKey:key];
  if (icon) {
    [self postNotificationWithIcon:icon forKey:key];
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                   if ([[options objectForKey:@"cache"] boolValue]) {
                     UIImage* icon = [[GreeJSIconPersistentCache sharedImageCache] cachedImageForURL:key];
                     if (icon) {
                       [self rawImageDidLoadWith:icon forKey:key options:options];
                       return;
                     }
                   }

                   NSURLRequest* request = [NSURLRequest requestWithURL:key];
                   [self.queue addOperation:[GreeAFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage* image) {
                                               [self rawImageDidLoadWith:image forKey:key options:options];
                                             }]];
                 });
}

#pragma mark - Internal Methods

-(void)rawImageDidLoadWith:(UIImage*)image forKey:(NSURL*)key options:(NSDictionary*)options
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                   UIImage* icon = [self processImage:image withOptions:options];
                   dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.iconImages setObject:icon forKey:key];
                                    [self postNotificationWithIcon:icon forKey:key];
                                  });
                 });
}

-(void)postNotificationWithIcon:(UIImage*)icon forKey:(NSURL*)key
{
  [[NSNotificationCenter defaultCenter] postNotificationName:(NSString*)kGreeIconDidLoadNotification
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObject:icon forKey:[key absoluteString]]];
}

-(UIImage*)processImage:(UIImage*)rawImage withOptions:(NSDictionary*)options
{
  CGSize size;
  NSValue* sizeValue = [options objectForKey:@"size"];
  if (sizeValue) {
    size = [sizeValue CGSizeValue];
  } else {
    size = rawImage.size;
  }
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  CGFloat cornerRadius = [[options objectForKey:@"cornerRadius"] floatValue];

  CALayer* imageLayer = [CALayer layer];
  imageLayer.frame = rect;
  imageLayer.contents = (id)rawImage.CGImage;
  if (cornerRadius) {
    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = cornerRadius;
  }

  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end
