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
#import "GreeModelessAlertView.h"
#import "UIImage+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "UIView+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"

typedef void (^setPositionBlock)(CGPoint newCenter, CGFloat rotateAngle);

static const NSTimeInterval kAnimateDuration = 0.15;
static const NSTimeInterval kShowDuration    = 1.0;

@interface GreeModelessAlertView ()

@property (nonatomic, retain) NSTimer* fadeOutTimer;
@property (nonatomic, retain) UIView* alertView;
@property (nonatomic, retain) UILabel* label;
@property (nonatomic, retain) UIImageView* imageView;

-(void)showStatus:(NSString*)string;
-(void)show;
-(void)dismiss;
-(void)setStatus:(NSString*)string;
-(void)layoutSubviews;
-(CGFloat)visibleKeyboardHeight;

@end

@implementation GreeModelessAlertView

# pragma mark - Public methods

-(void)showNoConnectionAlert
{
  [self showStatus:GreePlatformString(@"GreeModelessAlertView.noNetworkConnection.message", @"No network connection")];
}


# pragma mark - Object lifecycle

-(id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.alpha = 0;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.alertView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.alertView.layer.cornerRadius = 7;
    self.alertView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    self.alertView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleLeftMargin);
    [self addSubview:self.alertView];

    self.imageView = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"alert_icon.png"]] autorelease];
    [self.alertView addSubview:self.imageView];

    self.label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.label.textColor = [UIColor whiteColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.adjustsFontSizeToFitWidth = YES;
    self.label.textAlignment = UITextAlignmentCenter;
    self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.label.font = [UIFont boldSystemFontOfSize:16];
    self.label.shadowColor = [UIColor blackColor];
    self.label.shadowOffset = CGSizeMake(0, -1);
    self.label.numberOfLines = 0;
    self.label.font = [UIFont fontWithName:@"Helvetica" size:16];
    [self.alertView addSubview:self.label];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (self.fadeOutTimer) {
    [self.fadeOutTimer invalidate];
  }
  self.fadeOutTimer = nil;
  self.alertView = nil;
  self.label = nil;
  self.imageView = nil;

  [super dealloc];
}


# pragma mark - Internal methods

-(void)showStatus:(NSString*)string
{
  if (self.alpha != 1) {
    [self show];
  }

  if (self.fadeOutTimer) {
    [self.fadeOutTimer invalidate];
  }
  self.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:kShowDuration target:self selector:@selector(dismiss)userInfo:nil repeats:NO];

  [self setStatus:string];
}

-(void)show
{
  if (!self.superview) {
    UIViewController* viewController = [UIViewController greeLastPresentedViewController];
    self.frame = viewController.view.bounds;
    [self greeAddRotatingSubviewToViewController:viewController];
  }
  [self layoutSubviews];
  self.alertView.transform = CGAffineTransformScale(self.alertView.transform, 1.3, 1.3);

  void (^animations)(void) =^{
    [self layoutSubviews];
    self.alertView.transform = CGAffineTransformIdentity;
    self.alpha = 1;
  };

  UIViewAnimationOptions option = (self.alpha == 0) ? UIViewAnimationOptionLayoutSubviews
                                  : UIViewAnimationOptionBeginFromCurrentState;
  [UIView animateWithDuration:kAnimateDuration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | option
                   animations:animations
                   completion:nil];

  [self setNeedsDisplay];
}

-(void)dismiss
{
  void (^animations)(void) =^{
    self.alertView.transform = CGAffineTransformScale(self.alertView.transform, 0.8, 0.8);
    self.alpha = 0;
  };
  void (^completion)(BOOL) =^(BOOL finished){
    if (!finished) {
      return;
    }

    [self layoutSubviews];
    [self greeRemoveRotatingSubviewFromSuperview];
    self.alertView.transform = CGAffineTransformIdentity;
  };

  [UIView animateWithDuration:kAnimateDuration
                        delay:0
                      options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                   animations:animations
                   completion:completion];
}

-(void)layoutSubviews
{
  const float alertPositionFromTopRelative = 0.45;

  CGFloat activeHeight = self.bounds.size.height - [self visibleKeyboardHeight];
  CGFloat posY = floor(activeHeight * alertPositionFromTopRelative);
  CGFloat posX = self.bounds.size.width / 2;

  self.alertView.center = CGPointMake(posX, posY);
}

-(void)setStatus:(NSString*)string
{
  const CGFloat alertHeight = 40;
  const CGFloat alertWidthPadding = 45;

  CGSize labelSize = [string sizeWithFont:self.label.font];
  CGFloat labelWidthMax = self.bounds.size.width - alertWidthPadding;
  CGFloat labelWidth = (labelSize.width < labelWidthMax) ? labelSize.width : labelWidthMax;
  CGFloat alertWidth = labelWidth + alertWidthPadding;

  self.alertView.bounds = CGRectMake(0, 0, alertWidth, alertHeight);
  self.imageView.frame = CGRectMake(12, 11.5, self.imageView.frame.size.width, self.imageView.frame.size.height);
  self.label.text = string;
  self.label.frame = CGRectMake(35, 9.5, labelWidth, labelSize.height);
}

-(CGFloat)visibleKeyboardHeight
{
  UIWindow* keyboardWindow = nil;
  for (id window in [[UIApplication sharedApplication] windows]) {
    if (![[window class] isEqual:[UIWindow class]]) {
      keyboardWindow = window;
    }
  }

  UIView* foundKeyboard = nil;
  for (UIView* possibleKeyboard in [keyboardWindow subviews]) {
    if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
      possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
    }
    if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
      foundKeyboard = possibleKeyboard;
      break;
    }
  }

  return foundKeyboard.bounds.size.height;
}

@end
