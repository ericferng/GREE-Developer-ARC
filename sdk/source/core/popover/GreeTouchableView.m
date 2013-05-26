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

#import "GreeTouchableView.h"

@interface GreeTouchableView ()
@property (nonatomic, assign) BOOL testHits;
-(BOOL)isPassthroughView:(UIView*)view;
@end

@implementation GreeTouchableView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.passthroughViews = nil;
  [super dealloc];
}

#pragma mark - UIView Overrides

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
  if (self.testHits) {
    return nil;
  } else if (self.touchForwardingDisabled) {
    return self;
  } else {
    UIView* hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
      self.testHits = YES;
      UIView* superHitView = [self.superview hitTest:point withEvent:event];
      self.testHits = NO;
      if ([self isPassthroughView:superHitView]) {
        hitView = superHitView;
      }
    }
    return hitView;
  }
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self.delegate viewDidTouched:self];
}

#pragma mark - Internal Methods

-(BOOL)isPassthroughView:(UIView*)view
{
  if (view == nil) {
    return NO;
  }
  if ([self.passthroughViews containsObject:view]) {
    return YES;
  }
  return [self isPassthroughView:view.superview];
}

@end
