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

#import <QuartzCore/QuartzCore.h>
#import "GreeJSDownloadIndicatorView.h"
#import "UIImage+GreeAdditions.h"

@interface GreeJSDownloadIndicatorView ()
-(void)buttonTapped:(id)sender;
-(void)pauseLayer:(CALayer*)layer;
-(void)resumeLayer:(CALayer*)layer;
@property (nonatomic, assign, readwrite) BOOL isSpin;
@end

@implementation GreeJSDownloadIndicatorView

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.animationDuration = 0.8f;
    self.frame = CGRectMake(0, 0, 32.0f, 32.0f);
    self.userInteractionEnabled = YES;
    self.autoresizingMask =
      UIViewAutoresizingFlexibleLeftMargin |
      UIViewAutoresizingFlexibleRightMargin |
      UIViewAutoresizingFlexibleTopMargin |
      UIViewAutoresizingFlexibleBottomMargin;
    [self setBackgroundImage:[UIImage greeImageNamed:@"gree_loader.png"]
                    forState:UIControlStateNormal];
    [self addTarget:self action:@selector(buttonTapped:)forControlEvents:UIControlEventTouchUpInside];
  }
  return self;
}

#pragma mark - Internal Methods

-(void)buttonTapped:(id)sender
{
  if (self.block) {
    self.block(self);
  }
}

-(void)pauseLayer:(CALayer*)layer
{
  CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
  layer.speed = 0.0;
  layer.timeOffset = pausedTime;
  layer.beginTime = 0.0;
  self.isSpin = YES;
}

-(void)resumeLayer:(CALayer*)layer
{
  CFTimeInterval pausedTime = [layer timeOffset];
  layer.speed = 1.0;
  layer.timeOffset = 0.0;
  layer.beginTime = 0.0;
  CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
  layer.beginTime = timeSincePause;
  self.isSpin = NO;
}

#pragma mark - Public Interface

+(id)downloadIndicator
{
  return [[[self alloc] init] autorelease];
}

-(void)spin
{
  if ([self.layer animationForKey:@"transform.rotation"]) {
    [self resumeLayer:self.layer];
  } else {
    CABasicAnimation* spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spinAnimation.removedOnCompletion = NO;
    spinAnimation.byValue = [NSNumber numberWithFloat:2.0f*M_PI];
    spinAnimation.duration = self.animationDuration;
    spinAnimation.repeatCount = NSIntegerMax;
    [self.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
  }
  self.isSpin = YES;
}

-(void)pause
{
  [self resumeLayer:self.layer];
}

@end
