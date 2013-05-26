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

#import "GreeRotator.h"
#import "GreePlatform+Internal.h"

@interface GreeRotatorContainerView : UIView
@end

@implementation GreeRotatorContainerView
-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
  UIView* view = [super hitTest:point withEvent:event];

  if (view == self) {
    return nil;
  }

  return view;
}
@end

@interface GreeRotator ()
@property (nonatomic, retain) NSMutableDictionary* rotatingViewsDictionary;

-(void)rotateView:(UIView*)view toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

+(CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)interfaceOrientation;
+(CGRect)boundsForOrientation:(UIInterfaceOrientation)interfaceOrientation rect:(CGRect)rect;
+(CGPoint)centerForOrientation:(UIInterfaceOrientation)interfaceOrientation bounds:(CGRect)bounds;
@end

@implementation GreeRotator

#pragma mark - Object Lifecycle

-(id)init
{
  if ((self = [super init])) {
    self.rotatingViewsDictionary = [NSMutableDictionary dictionaryWithCapacity:8];
  }

  return self;
}

-(void)dealloc
{
  self.rotatingViewsDictionary = nil;
  [super dealloc];
}

#pragma mark - Internal Methods

-(void)insertRotatingView:(UIView*)subview toViewController:(UIViewController*)viewController
{
  UIView* superview = viewController.view;
  GreeRotatorContainerView* rotatingContainerView = [[GreeRotatorContainerView alloc] initWithFrame:superview.bounds];

  UIInterfaceOrientation normalizedOrientation = [GreePlatform sharedInstance].interfaceOrientation;
  rotatingContainerView.autoresizesSubviews = YES;
  rotatingContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  CGRect localFrame = [superview convertRect:superview.frame fromView:superview.superview];
  CGRect screenFrame = [superview convertRect:[UIScreen mainScreen].bounds fromView:nil];
  CGRect applicationFrame = [superview convertRect:[UIScreen mainScreen].applicationFrame fromView:nil];
  if (CGRectEqualToRect(localFrame, screenFrame) &&
      ![UIApplication sharedApplication].statusBarHidden &&
      viewController.wantsFullScreenLayout &&
      (viewController == [UIApplication sharedApplication].keyWindow.rootViewController)) {
    rotatingContainerView.frame = applicationFrame;
  } else {
    rotatingContainerView.frame = localFrame;
  }

  [superview addSubview:rotatingContainerView];
  [rotatingContainerView addSubview:subview];
  [self rotateView:rotatingContainerView toInterfaceOrientation:normalizedOrientation];
  [self.rotatingViewsDictionary setObject:rotatingContainerView forKey:[NSValue valueWithNonretainedObject:subview]];
  [rotatingContainerView release];
}

-(void)removeRotatingSubview:(UIView*)subview
{
  [subview removeFromSuperview];
  [[self.rotatingViewsDictionary objectForKey:[NSValue valueWithNonretainedObject:subview]] removeFromSuperview];
  [self.rotatingViewsDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:subview]];
}

-(void)rotateViewsToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated duration:(NSTimeInterval)duration
{
  void (^animations)(void) =^(void){
    for (id key in self.rotatingViewsDictionary) {
      UIView* rotatingView = (UIView*)[self.rotatingViewsDictionary objectForKey:key];
      [self rotateView:rotatingView toInterfaceOrientation:interfaceOrientation];
    }
  };

  if (animated) {
    [UIView animateWithDuration:duration animations:animations];
  } else {
    animations();
  }
}

-(void)rotateView:(UIView*)view toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // If the manually rotate flag is not set return here and let UIKit handle interface orientation
  if (![GreePlatform sharedInstance].manuallyRotate)
    return;

  CGAffineTransform orientationTransform = [[self class] transformForOrientation:interfaceOrientation];
  CGAffineTransform normalizeTransformation = CGAffineTransformIdentity;
  CGAffineTransform intermediateTransformation;
  UIView* superView = view.superview;
  while (superView) {
    intermediateTransformation = superView.transform;
    normalizeTransformation = CGAffineTransformConcat(normalizeTransformation, intermediateTransformation);
    superView = superView.superview;
  }

  CGRect globalRect = [view.superview convertRect:view.frame toView:nil];
  CGRect boundsRect = CGRectApplyAffineTransform(globalRect, orientationTransform);

  if (CGAffineTransformEqualToTransform(normalizeTransformation, orientationTransform)) {
    view.transform = CGAffineTransformIdentity;
  } else {
    view.transform = orientationTransform;
  }

  view.bounds = CGRectMake(0, 0, CGRectGetWidth(boundsRect), CGRectGetHeight(boundsRect));
}

+(CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  CGAffineTransform transform = CGAffineTransformIdentity;

  switch (interfaceOrientation) {
  case UIInterfaceOrientationLandscapeLeft:
    transform = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
    break;
  case UIInterfaceOrientationLandscapeRight:
    transform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
    transform = CGAffineTransformMake(-1, 0, -0, -1, 0, 0);
  case UIInterfaceOrientationPortrait:
  default:
    break;
  }

  return transform;
}

+(CGRect)boundsForOrientation:(UIInterfaceOrientation)interfaceOrientation rect:(CGRect)rect
{
  CGRect bounds;

  switch (interfaceOrientation) {
  case UIInterfaceOrientationLandscapeLeft:
  case UIInterfaceOrientationLandscapeRight:
    bounds = CGRectMake(0.0f, 0.0f, rect.size.height, rect.size.width);
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
  case UIInterfaceOrientationPortrait:
  default:
    bounds = CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height);
    break;
  }

  return bounds;
}

+(CGPoint)centerForOrientation:(UIInterfaceOrientation)interfaceOrientation bounds:(CGRect)bounds
{
  CGPoint center;

  switch (interfaceOrientation) {
  case UIInterfaceOrientationLandscapeLeft:
  case UIInterfaceOrientationLandscapeRight:
    center = CGPointMake(CGRectGetMidY(bounds), CGRectGetMidX(bounds));
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
  case UIInterfaceOrientationPortrait:
  default:
    center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    break;
  }

  return center;
}

@end
