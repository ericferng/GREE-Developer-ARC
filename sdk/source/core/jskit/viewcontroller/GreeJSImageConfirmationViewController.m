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


#import "GreeJSImageConfirmationViewController.h"
#import "GreeGlobalization.h"

@interface GreeJSImageConfirmationViewController ()
-(UIImage*)resizeImageToFitToView;
-(void)imageDidSelected:(id)sender;
@end

@implementation GreeJSImageConfirmationViewController

-(void)dealloc
{
  [image_ release];
  [imageView_ release];

  image_ = nil;
  imageView_ = nil;
  delegate_ = nil;

  [super dealloc];
}

-(id)init
{
  self = [super init];
  if (self) {
    self.navigationItem.rightBarButtonItem =
      [[[UIBarButtonItem alloc] initWithTitle:GreePlatformString(@"GreeJS.ImageConfirmationController.Title", @"Use")
                                        style:UIBarButtonItemStyleDone
                                       target:self
                                       action:@selector(imageDidSelected:)] autorelease];

    // If not set explicitly, UIImagePickerController's default style (UIStatusBarStyleBlackTranslucent) is used.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
  }
  return self;
}

-(UIImage*)resizeImageToFitToView
{
  CGSize size = self.view.bounds.size;

  double x = self.image.size.width;
  double y = self.image.size.height;
  if (x > size.width) {
    double scale = size.width / x;
    x *= scale;
    y *= scale;
  }
  if (y > size.height) {
    double scale = size.height / y;
    x *= scale;
    y *= scale;
  }

  UIGraphicsBeginImageContext(CGSizeMake(x, y));
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
  [self.image drawInRect:CGRectMake(0, 0, x, y)];
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

-(void)loadView
{
  [super loadView];
  UIView* v = self.view;

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [v setBounds:CGRectMake(0, 0, 320, 480)];
    self.contentSizeForViewInPopover = CGSizeMake(320, 480);
  }

  v.backgroundColor = [UIColor blackColor];
  self.imageView = [[[UIImageView alloc] initWithFrame:v.bounds] autorelease];
  self.imageView.image = [self resizeImageToFitToView];
  self.imageView.contentMode = UIViewContentModeCenter;

  [v addSubview:self.imageView];
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated
{
  self.delegate = nil;
  [super dismissModalViewControllerAnimated:animated];
}

-(void)imageDidSelected:(id)sender
{
  [self.delegate imageDidSelected:self];
}

@end
