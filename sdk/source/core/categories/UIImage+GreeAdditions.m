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


#import "NSData+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"

@interface UIImage (GreeAdditionsPrivate)
+(UIImage*)greeChooseImageClosestToWidth:(NSInteger)targetWidth current:(UIImage*)current challenger:(UIImage*)challenger;
@end


@implementation UIImage (GreeAdditions)

+(id)greeResizeImage:(UIImage*)anOriginalImage maxPixel:(int)maxPixel
{
  return [self greeResizeImage:anOriginalImage maxPixel:maxPixel rotation:0];
}

+(id)greeResizeImage:(UIImage*)anOriginalImage maxPixel:(int)maxPixel rotation:(int)rotation
{
  int x = anOriginalImage.size.width;
  int y = anOriginalImage.size.height;

  if (y == 0 || x == 0)
    return nil;

  double ratio = (float)x / y;
  bool resized = NO;

  if (1 < ratio) {
    if (maxPixel < x) {
      x = maxPixel;
      y = (int)(x / ratio);
      resized = YES;
    }
  } else {
    if (maxPixel < y) {
      y = maxPixel;
      x = (int)(y * ratio);
      resized = YES;
    }
  }
  if (resized == NO && rotation == 0) {
    return anOriginalImage;
  }

  if (rotation < 0 || 3 < rotation) {
    rotation = 0;
  }

  CGContextRef context;
  switch (rotation) {
  case 0:
    UIGraphicsBeginImageContext(CGSizeMake(x, y));
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, 0);
    CGContextRotateCTM(context, 0);
    break;
  case 1:
    UIGraphicsBeginImageContext(CGSizeMake(y, x));
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, y, 0);
    CGContextRotateCTM(context, M_PI_2);
    break;
  case 2:
    UIGraphicsBeginImageContext(CGSizeMake(x, y));
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, x, y);
    CGContextRotateCTM(context, M_PI_2*2);
    break;
  case 3:
    UIGraphicsBeginImageContext(CGSizeMake(y, x));
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, x);
    CGContextRotateCTM(context, M_PI_2* -1);
    break;
  }

  CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
  [anOriginalImage drawInRect:CGRectMake(0, 0, x, y)];
  UIImage* aResultImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return aResultImage;
}

-(NSString*)greeBase64EncodedString
{
  NSData* anImageData = UIImageJPEGRepresentation(self, 0.65f);
  return [anImageData greeBase64EncodedString];
}

#define kGreeIconName       @"Icon.png"
#define kGreeRetinaIconName @"Icon@2x.png"
+(id)greeIconImageFromBundle
{
  NSString* anIconFileName = nil;
  NSArray* iconFileNames = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
  if (iconFileNames) {
    if ([iconFileNames containsObject:kGreeRetinaIconName]) {
      anIconFileName = kGreeRetinaIconName;
    } else {
      anIconFileName = kGreeIconName;
    }
  } else {
    anIconFileName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFile"];
  }
  if (!anIconFileName) {
    return nil;
  }

  NSString* anIconFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle greePlatformCoreBundle] bundlePath], anIconFileName];
  UIImage* anIconImage = [UIImage imageWithContentsOfFile:anIconFilePath];

  return anIconImage;
}

+(id)greeImageNamed:(NSString*)imageName
{
  NSString* extension = [imageName pathExtension];
  NSString* baseName = [imageName stringByDeletingPathExtension];
  NSString* basePath = [[NSBundle greePlatformCoreBundle] pathForResource:baseName
                                                                   ofType:extension];
  NSString* retinaPath = [[NSBundle greePlatformCoreBundle] pathForResource:[baseName stringByAppendingString:@"@2x"]
                                                                     ofType:extension];

  BOOL isRetinaDisplay = NO;
  if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale > 1.0) {
      isRetinaDisplay = YES;
    }
  }

  UIImage* image = nil;

  if (isRetinaDisplay) {
    if (retinaPath) {
      image = [UIImage imageWithContentsOfFile:retinaPath];
    } else {
      image = [UIImage imageWithContentsOfFile:basePath];
    }
  } else {
    if (basePath) {
      image = [UIImage imageWithContentsOfFile:basePath];
    } else {
      image = [UIImage imageWithContentsOfFile:retinaPath];
    }
  }

  return image;
}


+(UIImage*)greeChooseImageClosestToWidth:(NSInteger)targetWidth current:(UIImage*)current challenger:(UIImage*)challenger
{
  UIImage* returnValue = current;
  if(challenger) {
    if((!current) ||
       ((current.size.width > targetWidth) && (current.size.width > challenger.size.width)) ||
       ((current.size.width <= targetWidth) && (current.size.width < challenger.size.width))
       ) {
      returnValue = challenger;
    }
  }
  return returnValue;
}

+(UIImage*)greeAppIconNearestWidth:(NSInteger)targetWidth
{
  __block UIImage* currentImage = nil;

  NSArray* ios5Icons = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"];
  [ios5Icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
     currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:obj]];
   }];
  NSArray* ios3Icons = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
  [ios3Icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
     currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:obj]];
   }];
  NSString* iconFile = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFile"];
  currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:iconFile]];
  currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:@"Icon"]];
  currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:@"Icon-Small"]];
  currentImage = [UIImage greeChooseImageClosestToWidth:targetWidth current:currentImage challenger:[UIImage imageNamed:@"Icon-Small-50"]];
  return currentImage;
}
@end
