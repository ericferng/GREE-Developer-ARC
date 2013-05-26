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

#import "GreeJSImageScrollView.h"

#define kMinimumZoomScale   1.0
#define kMaximumZoomScale   5.0
#define kDoubleTapZoomScale 2.0

@interface GreeJSImageScrollView ()
-(void)didSingleTouch:(UITouch*)touch;
@property (nonatomic, retain, readwrite) UIImageView* imageView;
@end

@implementation GreeJSImageScrollView

#pragma mark - Object Lifecycle

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.delegate = self;
    self.minimumZoomScale = kMinimumZoomScale;
    self.maximumZoomScale = kMaximumZoomScale;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.backgroundColor = [UIColor greenColor];
    self.clipsToBounds = YES;
    self.canDoubleTapZooming = YES;

    self.imageView = [[[UIImageView alloc] initWithFrame:frame] autorelease];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth  |
      UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.imageView];
  }
  return self;
}

-(void)dealloc
{
  [super dealloc];
}

#pragma mark - UIView Overrides

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
  UITouch* touch = [touches anyObject];
  if ([touch tapCount] == 1) {
    [self performSelector:@selector(didSingleTouch:)withObject:touch afterDelay:0.25];
  }
  if ([touch tapCount] == 2) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([self.eventDelegate respondsToSelector:@selector(didDoubleTap:)]) {
      [self.eventDelegate didDoubleTap:self];
    }

    if (self.canDoubleTapZooming) {
      CGRect zoomRect = CGRectZero;
      if (self.zoomScale > 1.0f) {
        zoomRect = self.bounds;
      } else {
        zoomRect = [GreeJSImageScrollView zoomRectForScrollView:self
                                                      withScale:kDoubleTapZoomScale
                                                     withCenter:[touch locationInView:nil]];
      }
      [self zoomToRect:zoomRect animated:YES];
    }
  }
}

#pragma mark - Public Interface

+(CGRect)zoomRectForScrollView:(UIScrollView*)scrollView withScale:(float)scale withCenter:(CGPoint)center
{
  CGRect zoomRect = CGRectZero;
  zoomRect.size.height  = scrollView.frame.size.height/scale;
  zoomRect.size.width   = scrollView.frame.size.width/scale;
  zoomRect.origin.x     = center.x-(zoomRect.size.width/2.0);
  zoomRect.origin.y     = center.y-(zoomRect.size.height/2.0);
  return zoomRect;
}

#pragma mark - UIScrollViewDelegate

-(UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  return [self.subviews objectAtIndex:0];
}

#pragma mark - Internal Methods

-(void)didSingleTouch:(UITouch*)touch
{
  if ([self.eventDelegate respondsToSelector:@selector(didSingleTap:)]) {
    [self.eventDelegate didSingleTap:self];
  }
}

@end
