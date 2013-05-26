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

#import <ImageIO/ImageIO.h>
#import "GreeAvatarView.h"
#import "GreeLogger.h"

@interface GreeAvatarView ()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, retain) NSURLConnection* avatarFileDownloader;
@property (nonatomic, retain) NSMutableData* avatarData;
@property (nonatomic, copy) void (^completionBlock)(NSError*);

@end

@implementation GreeAvatarView

#pragma mark Private Methods

-(id)initWithFrame:(CGRect)frame user:(GreeUser*)user size:(GreeUserThumbnailSize)size completion:(void (^)(NSError*))completion
{
  self = [self initWithFrame:frame];
  if (self) {
    [self updateUser:user size:size completion:completion];
  }

  return self;
}

-(void)loadImagesFromData
{
  CGImageSourceRef avatarSource = CGImageSourceCreateWithData((CFDataRef)self.avatarData, NULL);
  if (!avatarSource) {
    GreeLogWarn(@"couldn't create the image source from the data");
    return;
  }

  size_t frameCount = CGImageSourceGetCount(avatarSource);
  GreeLog(@"the avatar has %d frames", frameCount);
  NSMutableArray* frames = [NSMutableArray array];

  self.animationDuration = 0.0f;
  for(size_t i1 = 0; i1 < frameCount; i1++) {
    CGImageRef anImage = CGImageSourceCreateImageAtIndex(avatarSource, i1, NULL);
    if (!anImage) {
      GreeLogWarn(@"couldn't load image #%d", i1);
      continue;
    }
    [frames addObject:[UIImage imageWithCGImage:anImage]];
    CGImageRelease(anImage);

    CFDictionaryRef avatarProperties = CGImageSourceCopyPropertiesAtIndex(avatarSource, i1, NULL);
    if (!avatarProperties) {
      GreeLogWarn(@"couldn't load properties #%d", i1);
      continue;
    }
    self.animationDuration += [[[(NSDictionary*) avatarProperties objectForKey:(NSString*)kCGImagePropertyGIFDictionary] objectForKey:(NSString*)kCGImagePropertyGIFDelayTime] doubleValue];
    CFRelease(avatarProperties);
  }

  CFRelease(avatarSource);

  GreeLog(@"loaded the frames from the data, duration: %lf", self.animationDuration);
  if (frames.count < 1) {
    GreeLogWarn(@"frame count is 0");
    return;
  }

  self.animationImages = frames;
  self.image = [frames objectAtIndex:0];
}

#pragma mark Public Methods

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
  }

  return self;
}

-(void)dealloc
{
  self.completionBlock = nil;
  self.avatarData = nil;
  self.avatarFileDownloader = nil;
  [super dealloc];
}

/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect
   {
   // Drawing code
   }
 */

-(void)updateUser:(GreeUser*)user size:(GreeUserThumbnailSize)size completion:(void (^)(NSError*))completion
{
  [self.avatarFileDownloader cancel];
  self.avatarData = nil;
  self.image = nil;
  self.animationImages = nil;

  self.completionBlock = completion;

  NSURL* avatarURL;
  switch (size) {
  case GreeUserThumbnailSizeSmall:
    avatarURL = user.thumbnailUrlSmall;
    break;
  case GreeUserThumbnailSizeLarge:
    avatarURL = user.thumbnailUrlLarge;
    break;
  case GreeUserThumbnailSizeHuge:
    avatarURL = user.thumbnailUrlHuge;
    break;
  case GreeUserThumbnailSizeStandard:
  default:
    avatarURL = user.thumbnailUrl;
    break;
  }

  GreeLog(@"started downloading %@'s avatar from %@", user.nickname, avatarURL.absoluteString);
  self.avatarFileDownloader = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:avatarURL] delegate:self];
}

+(id)avatarViewWithFrame:(CGRect)frame
{
  return [[[GreeAvatarView alloc] initWithFrame:frame] autorelease];
}

+(id)avatarViewWithFrame:(CGRect)frame user:(GreeUser*)user size:(GreeUserThumbnailSize)size completion:(void (^)(NSError*))completionBlock
{
  return [[[GreeAvatarView alloc] initWithFrame:frame user:user size:size completion:completionBlock] autorelease];
}

#pragma mark NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
  GreeLog(@"received a response from the server, file size: %d", [response expectedContentLength]);
  self.avatarData = [[[NSMutableData alloc] init] autorelease];
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
  [self.avatarData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
  GreeLog(@"download completed, file size: %d", self.avatarData.length);
  [self loadImagesFromData];
  self.avatarFileDownloader = nil;
  self.avatarData = nil;

  [self startAnimating];
  if(self.completionBlock)
    self.completionBlock(nil);
}

#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
  GreeLogWarn(@"an error occured during the download, %@", [error localizedDescription]);
  self.avatarFileDownloader = nil;
  self.avatarData = nil;

  if(self.completionBlock)
    self.completionBlock(error);
}

@end
