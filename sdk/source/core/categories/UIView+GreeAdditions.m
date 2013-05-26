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

#import "UIView+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeRotator.h"

@interface UIView (GreeAdditionsPrivate)
-(UIWebView*)greeWebviewSuperviewOrNil;
@end

@implementation UIView (GreeAdditions)
-(CGRect)greeFirstResponderFrame
{
  if ([self isFirstResponder]) {
    UIWebView* webview = [self greeWebviewSuperviewOrNil];

    if (webview != nil) {
      return [webview greeActiveElementFrame];
    }

    return self.bounds;
  }

  for (UIView* view in self.subviews) {
    CGRect firstResponderFrame = [view greeFirstResponderFrame];

    if (!CGRectIsEmpty(firstResponderFrame)) {
      return [self convertRect:firstResponderFrame fromView:view];
    }
  }

  return CGRectZero;
}

-(UIWebView*)greeWebviewSuperviewOrNil
{
  UIWebView* webview = nil;
  UIView* currentView = self;

  while ([currentView superview] != nil) {
    if ([currentView isKindOfClass:[UIWebView class]]) {
      webview = (UIWebView*)currentView;
      break;
    } else {
      currentView = [currentView superview];
    }
  }

  return webview;
}

-(void)greeAddRotatingSubviewToViewController:(UIViewController*)viewController
{
  GreeRotator* rotator = [[GreePlatform sharedInstance] rotator];
  [rotator insertRotatingView:self toViewController:viewController];
}

-(void)greeRemoveRotatingSubviewFromSuperview
{
  GreeRotator* rotator = [[GreePlatform sharedInstance] rotator];
  [rotator removeRotatingSubview:self];
}

-(void)greeChangeFrameX:(CGFloat)x
{
  self.frame = CGRectMake(x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

-(void)greeChangeFrameY:(CGFloat)y
{
  self.frame = CGRectMake(self.frame.origin.x, y, self.frame.size.width, self.frame.size.height);
}

-(void)greeChangeFrameWidth:(CGFloat)width
{
  self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

-(void)greeChangeFrameHeight:(CGFloat)height
{
  self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

-(void)greeChangeFrameXRelatively:(CGFloat)x
{
  [self greeChangeFrameX:(self.frame.origin.x + x)];
}

-(void)greeChangeFrameYRelatively:(CGFloat)y
{
  [self greeChangeFrameY:(self.frame.origin.y + y)];
}

-(void)greeChangeFrameWidthRelatively:(CGFloat)width
{
  [self greeChangeFrameWidth:(self.frame.size.width + width)];
}

-(void)greeChangeFrameHeightRelatively:(CGFloat)height
{
  [self greeChangeFrameHeight:(self.frame.size.height + height)];
}


@end
