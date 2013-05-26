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

#import "GreeMenuNavController.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "UIViewController+GreeAdditions.h"
#import "UINavigationItem+GreeAdditions.h"

#import <CoreGraphics/CGColor.h>
#import <QuartzCore/CALayer.h>
#import <UIKit/UIPanGestureRecognizer.h>
#import <math.h>

#define OPEN_MENU_ANIMATION_DURATION 0.23
#define OPEN_MENU_SHADOW_OFFSET_X -3
#define OPEN_MENU_SHADOW_OFFSET_Y 0
#define OPEN_MENU_SHADOW_OPACITY 0.6f

NSString* const GreeDashboardWillShowUniversalMenuNotification = @"GreeDashboardWillShowUniversalMenuNotification";
NSString* const GreeDashboardDidShowUniversalMenuNotification = @"GreeDashboardDidShowUniversalMenuNotification";
NSString* const GreeDashboardWillHideUniversalMenuNotification = @"GreeDashboardWillHideUniversalMenuNotification";
NSString* const GreeDashboardDidHideUniversalMenuNotification = @"GreeDashboardDidHideUniversalMenuNotification";

@interface GreeMenuNavController ()
@property (nonatomic, retain) UIPanGestureRecognizer* rootPanGesture;
@property (nonatomic, retain) UIPanGestureRecognizer* menuPanGesture;
@property (nonatomic, retain) UITapGestureRecognizer* singleTapGesture;
-(void)updateMenuViewAnimated:(BOOL)animated notifyDelegate:(BOOL)notify;
-(void)revealButtonPushed;
-(CGFloat)panOffsetX:(UIPanGestureRecognizer*)gesture;
-(void)updateRootViewTransform:(UIPanGestureRecognizer*)gesture;
-(void)updateMenuViewOpenedState:(UIPanGestureRecognizer*)gesture;
-(BOOL)isNavigationBarAreaY:(CGFloat)y;
@end

@implementation GreeMenuNavController

#pragma mark - Object Lifecycle

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _isRevealed = NO;
    self.rootViewController = nil;
    self.menuViewController = nil;
    self.delegate = nil;
    self.rootPanGesture = nil;
    self.menuPanGesture = nil;
    _allowPanGesture = YES;
    _allowSingleTapGesture = YES;
  }

  return self;
}

-(id)initWithRootViewController:(UINavigationController*)rootViewController leftViewController:(UINavigationController*)leftViewController
{
  if ((self = [self initWithNibName:nil bundle:nil])) {
    self.rootViewController = rootViewController;
    self.menuViewController = leftViewController;
  }

  return self;
}

-(void)dealloc
{
  self.rootViewController = nil;
  self.menuViewController = nil;
  self.rootPanGesture = nil;
  self.menuPanGesture = nil;
  self.singleTapGesture = nil;
  self.delegate = nil;
  [super dealloc];
}

#pragma mark - Public Interface

#pragma mark - UIViewController Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

-(void)loadView
{
  [super loadView];
  [self.rootViewController loadView];
  [self.menuViewController loadView];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  [self.rootViewController viewDidLoad];
  [self.menuViewController viewDidLoad];

  assert(self.rootViewController && self.menuViewController);
  [self.view addSubview:self.rootViewController.view];
  [self.view insertSubview:self.menuViewController.view belowSubview:self.rootViewController.view];

  if ([GreePlatform shouldPersistUniversalMenuForIPad]) {
    self.rootViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width - OPEN_MENU_OFFSET, self.view.bounds.size.height);
  } else {
    self.rootViewController.view.frame = self.view.bounds;
  }
  self.menuViewController.view.frame = CGRectMake(0, 0, OPEN_MENU_OFFSET + OPEN_MENU_OFFSET_RIGHT_MARGIN, self.view.bounds.size.height);

  self.view.autoresizesSubviews = YES;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.menuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;

  CALayer* rootLayer = self.rootViewController.view.layer;
  rootLayer.shadowOffset = CGSizeMake(OPEN_MENU_SHADOW_OFFSET_X, OPEN_MENU_SHADOW_OFFSET_Y);
  rootLayer.shadowOpacity = OPEN_MENU_SHADOW_OPACITY;
  rootLayer.shadowPath = [UIBezierPath bezierPathWithRect:self.rootViewController.view.bounds].CGPath;

  if (![GreePlatform shouldPersistUniversalMenuForIPad]) {
    self.rootPanGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)] autorelease];
    self.rootPanGesture.delegate = self;
    self.rootPanGesture.enabled = self.allowPanGesture;
    [self.rootViewController.view addGestureRecognizer:self.rootPanGesture];

    self.menuPanGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)] autorelease];
    self.menuPanGesture.delegate = self;
    self.menuPanGesture.enabled = self.allowPanGesture;
  }

  self.singleTapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTapGesture:)] autorelease];
  self.singleTapGesture.delegate = self;
  self.singleTapGesture.enabled = self.allowSingleTapGesture;
  self.singleTapGesture.numberOfTapsRequired = 1;
  self.singleTapGesture.numberOfTouchesRequired = 1;

  //For iPad, we need to disable pan gesture, since rootViewController and menuViewController should always open
  if (![GreePlatform shouldPersistUniversalMenuForIPad]) {
    [self.rootViewController.view addGestureRecognizer:_rootPanGesture];
    [self.rootViewController.topViewController.view addGestureRecognizer:_singleTapGesture];
    [self.menuViewController.view addGestureRecognizer:_menuPanGesture];
  }

  self.view.backgroundColor = [UIColor colorWithRed:62.0/255.0
                                              green:71.0/255.0
                                               blue:80.0/255.0
                                              alpha:1.0];
  [self.view setNeedsLayout];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.rootViewController viewWillAppear:animated];
  [self.menuViewController viewWillAppear:animated];

  //For iPad, we need to always show the menuviewcontroller
  if ([GreePlatform shouldPersistUniversalMenuForIPad]) {
    [self setIsRevealed:YES];
  }
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.rootViewController viewDidAppear:animated];
  [self.menuViewController viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.rootViewController viewWillDisappear:animated];
  [self.menuViewController viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self.rootViewController viewDidDisappear:animated];
  [self.menuViewController viewDidDisappear:animated];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.rootViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.menuViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Internal Methods

-(void)updateMenuViewAnimated:(BOOL)animated notifyDelegate:(BOOL)notify
{
  __block UIView* slidingView = self.rootViewController.view;
  __block BOOL notifyDelegate = notify;
  __block CGAffineTransform slidingViewTransform;
  __block SEL delegateSelector;
  __block NSString* notificationName;

  void (^transformationBlock)(void) =^{
    slidingView.transform = slidingViewTransform;
  };

  void (^eventBlock)(void) =^{
    if (notifyDelegate) {
      if (self.delegate && [self.delegate respondsToSelector:delegateSelector]) {
        [self.delegate performSelector:delegateSelector withObject:self withObject:self.menuViewController];
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self.rootViewController];
    }
  };

  if (self.isRevealed) {
    delegateSelector = @selector(menuController:willShowViewController:);
    notificationName = GreeDashboardWillShowUniversalMenuNotification;
    eventBlock();

    [self.menuViewController.view setHidden:NO];
    slidingViewTransform = CGAffineTransformMakeTranslation(OPEN_MENU_OFFSET, 0);
    delegateSelector = @selector(menuController:didShowViewController:);
    notificationName = GreeDashboardDidShowUniversalMenuNotification;
  } else {
    delegateSelector = @selector(menuController:willHideViewController:);
    notificationName = GreeDashboardWillHideUniversalMenuNotification;
    eventBlock();

    slidingViewTransform = CGAffineTransformIdentity;
    delegateSelector = @selector(menuController:didHideViewController:);
    notificationName = GreeDashboardDidHideUniversalMenuNotification;
  }

  if (animated) {
    [UIView animateWithDuration:OPEN_MENU_ANIMATION_DURATION
                     animations:transformationBlock
                     completion:^(BOOL finished){ eventBlock(); }];
  } else {
    transformationBlock();
    eventBlock();
  }
}

-(void)revealButtonPushed
{
  [self setIsRevealed:!self.isRevealed];
}

-(void)setIsRevealed:(BOOL)isRevealed
{
  if (_isRevealed == isRevealed) return;

  _isRevealed = isRevealed;

  BOOL animated = YES;
  //For iPad, remove the animation
  if ([GreePlatform shouldPersistUniversalMenuForIPad]) {
    animated = NO;
  }
  [self updateMenuViewAnimated:animated notifyDelegate:YES];
}

-(CGFloat)panOffsetX:(UIPanGestureRecognizer*)gesture
{
  CGPoint translation = [gesture translationInView:self.view];

  CGFloat offset = translation.x + (self.isRevealed ? OPEN_MENU_OFFSET : 0);

  // If we go to the edge only translate by a fraction of the amount past the edge
  if (offset > OPEN_MENU_OFFSET) {
    // Max OPEN_MENU_OFFSET_RIGHT_MARGIN px
    CGFloat rightOffset = log2(offset - OPEN_MENU_OFFSET) / log2(1.3);

    offset = OPEN_MENU_OFFSET + rightOffset;
  }

  // Should not translate past the origin
  if (offset < 0) {
    offset = 0;
  }

  return offset;
}

-(void)updateRootViewTransform:(UIPanGestureRecognizer*)gesture
{
  CGFloat offsetX = [self panOffsetX:gesture];
  self.rootViewController.view.transform = CGAffineTransformMakeTranslation(offsetX, 0);
}

-(void)updateMenuViewOpenedState:(UIPanGestureRecognizer*)gesture
{
  CGFloat offsetX = [self panOffsetX:gesture];
  CGPoint velocity = [gesture velocityInView:self.view];
  BOOL shouldBeRevealed = ((offsetX + velocity.x) > (OPEN_MENU_OFFSET / 2)) ? YES : NO;
  if (shouldBeRevealed != self.isRevealed) {
    [self setIsRevealed:shouldBeRevealed];
  } else {
    [self updateMenuViewAnimated:YES notifyDelegate:NO];
  }
}

#pragma mark - UINavigationBar Delegate Methods

-(BOOL)navigationBar:(UINavigationBar*)navigationBar shouldPushItem:(UINavigationItem*)item
{
  return YES;
}

#pragma mark - UINavigationController Delegate Methods

-(void)navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
}

-(BOOL)isNavigationBarAreaY:(CGFloat)y
{
  return (y <= self.rootViewController.navigationBar.frame.size.height);
}

#pragma mark - UIGestureRecognizer methods

-(void)setAllowPanGesture:(BOOL)allowPanGesture
{
  _allowPanGesture = allowPanGesture;
  self.rootPanGesture.enabled = self.allowPanGesture;
  self.menuPanGesture.enabled = self.allowPanGesture;
}

-(void)setAllowSingleTapGesture:(BOOL)allowSingleTapGesture
{
  _allowSingleTapGesture = allowSingleTapGesture;
  self.singleTapGesture.enabled = self.allowSingleTapGesture;
}

-(void)onPanGesture:(UIPanGestureRecognizer*)gesture
{
  switch (gesture.state) {
  case UIGestureRecognizerStateBegan:
  case UIGestureRecognizerStateChanged:
    [self updateRootViewTransform:gesture];
    break;

  case UIGestureRecognizerStateCancelled:
  case UIGestureRecognizerStateFailed:
  case UIGestureRecognizerStateEnded:
    [self updateMenuViewOpenedState:gesture];
    break;

  case UIGestureRecognizerStatePossible:
  default:
    break;
  }
}

-(void)onSingleTapGesture:(UITapGestureRecognizer*)gesture
{
  if (self.isRevealed) {
    [self setIsRevealed:NO];
  }
}

#pragma mark - UIGestureRecognizer Delegate Methods

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  CGPoint p = [gestureRecognizer locationInView:self.rootViewController.view];
  return self.isRevealed || ([self isNavigationBarAreaY:p.y]);
}

@end
