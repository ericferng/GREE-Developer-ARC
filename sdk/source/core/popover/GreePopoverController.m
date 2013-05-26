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

#import "GreePopoverController.h"
#import "UIImage+GreeAdditions.h"

#define FADE_DURATION 0.25

@interface GreePopoverController ()
-(UIView*)keyView;
-(void)updateBackgroundPassthroughViews;
-(CGRect)displayAreaForView:(UIView*)theView;
-(GreePopoverContainerViewProperties*)defaultContainerViewProperties;
-(void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated;
-(void)animationDidStop:(NSString*)animationID
               finished:(NSNumber*)finished
                context:(void*)theContext;
-(CGRect)barButtonItem:(UIBarButtonItem*)item frameInView:(UIView*)view;

@property (nonatomic, retain) GreeTouchableView* backgroundView;
@property (nonatomic, readwrite) UIPopoverArrowDirection popoverArrowDirection;
@property (nonatomic, readwrite, getter=isPopoverVisible) BOOL popoverVisible;
@property (nonatomic, retain, readwrite) UIView* view;
@end

@implementation GreePopoverController

#pragma mark - Object Lifecycle

-(id)initWithContentViewController:(UIViewController*)viewController
{
  if ((self = [self init])) {
    self.contentViewController = viewController;
  }
  return self;
}

-(void)dealloc
{
  [self dismissPopoverAnimated:NO];
  self.contentViewController = nil;
  self.containerViewProperties = nil;
  self.passthroughViews = nil;
  self.context = nil;
  [super dealloc];
}

#pragma mark - Public Interface

-(void)setContentViewController:(UIViewController*)viewController
{
  if (viewController != _contentViewController) {
    [_contentViewController release];
    _contentViewController = [viewController retain];
    self.popoverContentSize = CGSizeZero;
  }
}

-(void)setPassthroughViews:(NSArray*)array
{
  [_passthroughViews release];
  _passthroughViews = nil;
  if (array) {
    _passthroughViews = [[NSArray alloc] initWithArray:array];
  }
  [self updateBackgroundPassthroughViews];
}

-(void)dismissPopoverAnimated:(BOOL)animated
{
  [self dismissPopoverAnimated:animated userInitiated:NO];
}

-(void)presentPopoverFromBarButtonItem:(UIBarButtonItem*)item
              permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                              animated:(BOOL)animated
{
  UIView* view = [self keyView];
  CGRect rect = [self barButtonItem:item frameInView:view];
  return [self
            presentPopoverFromRect:rect
                            inView:view
          permittedArrowDirections:arrowDirections
                          animated:animated];
}

-(void)presentPopoverFromRect:(CGRect)rect
                       inView:(UIView*)theView
     permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                     animated:(BOOL)animated
{
  [self dismissPopoverAnimated:NO];

  //First force a load view for the contentViewController so the popoverContentSize is properly initialized
  [self.contentViewController performSelector:@selector(view)];

  if (CGSizeEqualToSize(self.popoverContentSize, CGSizeZero)) {
    self.popoverContentSize = self.contentViewController.contentSizeForViewInPopover;
  }

  CGRect displayArea = [self displayAreaForView:theView];
  GreePopoverContainerViewProperties* props =
    self.containerViewProperties ? self.containerViewProperties : [self defaultContainerViewProperties];
  GreePopoverContainerView* containerView = [[[GreePopoverContainerView alloc]
                                                          initWithSize:self.popoverContentSize
                                                            anchorRect:rect displayArea:displayArea
                                              permittedArrowDirections:arrowDirections
                                                            properties:props] autorelease];
  self.popoverArrowDirection = containerView.arrowDirection;

  UIView* keyView = self.keyView;
  self.backgroundView = [[[GreeTouchableView alloc] initWithFrame:keyView.bounds] autorelease];
  self.backgroundView.contentMode = UIViewContentModeScaleToFill;
  self.backgroundView.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleBottomMargin;
  self.backgroundView.backgroundColor = [UIColor clearColor];
  self.backgroundView.delegate = self;
  [keyView addSubview:self.backgroundView];
  [keyView bringSubviewToFront:self.backgroundView];

  containerView.frame = [theView convertRect:containerView.frame toView:self.backgroundView];
  [self.backgroundView addSubview:containerView];

  containerView.contentView = self.contentViewController.view;
  containerView.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin;

  self.view = containerView;
  [self updateBackgroundPassthroughViews];

  [self.contentViewController viewWillAppear:animated];
  [self.view becomeFirstResponder];

  if (animated) {
    self.view.alpha = 0.0;
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:FADE_DURATION];
    self.view.alpha = 1.0;
    [UIView commitAnimations];
  } else {
    self.popoverVisible = YES;
    [self.contentViewController viewDidAppear:animated];
  }
}

-(void)repositionPopoverFromRect:(CGRect)rect
                          inView:(UIView*)theView
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
{
  CGRect displayArea = [self displayAreaForView:theView];
  GreePopoverContainerView* containerView = (GreePopoverContainerView*)self.view;
  [containerView
   updatePositionWithAnchorRect:rect
                    displayArea:displayArea
       permittedArrowDirections:arrowDirections];

  self.popoverArrowDirection = containerView.arrowDirection;
  containerView.frame = [theView convertRect:containerView.frame toView:self.backgroundView];
}

#pragma mark - Internal Methods

-(void)animationDidStop:(NSString*)animationID
               finished:(NSNumber*)finished
                context:(void*)theContext
{
  if ([animationID isEqual:@"FadeIn"]) {
    self.view.userInteractionEnabled = YES;
    self.popoverVisible = YES;
    [self.contentViewController viewDidAppear:YES];
  } else {
    self.popoverVisible = NO;
    [self.contentViewController viewDidDisappear:YES];
    [self.view removeFromSuperview];
    self.view = nil;
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;

    BOOL userInitiatedDismissal = [(NSNumber*) theContext boolValue];
    if (userInitiatedDismissal) {
      //Only send message to delegate in case the user initiated this event, which is if he touched outside the view
      [self.delegate popoverControllerDidDismissPopover:self];
    }
  }
}

-(CGRect)barButtonItem:(UIBarButtonItem*)item frameInView:(UIView*)view
{
  BOOL hasCustomView = (item.customView != nil);
  if (!hasCustomView) {
    UIView* tempView = [[UIView alloc] initWithFrame:CGRectZero];
    item.customView = tempView;
    [tempView release];
  }

  UIView* parentView = item.customView.superview;
  NSUInteger indexOfView = [parentView.subviews indexOfObject:item.customView];
  if (!hasCustomView) {
    item.customView = nil;
  }
  UIView* button = [parentView.subviews objectAtIndex:indexOfView];
  return [parentView convertRect:button.frame toView:view];
}

-(UIView*)keyView
{
  UIWindow* window = [[UIApplication sharedApplication] keyWindow];
  if (window.subviews.count > 0) {
    return [window.subviews lastObject];
  } else {
    return window;
  }
}

-(void)updateBackgroundPassthroughViews
{
  self.backgroundView.passthroughViews = self.passthroughViews;
}

-(void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated
{
  if (self.view) {
    [self.contentViewController viewWillDisappear:animated];
    self.popoverVisible = NO;
    [self.view resignFirstResponder];
    if (animated) {
      self.view.userInteractionEnabled = NO;
      [UIView beginAnimations:@"FadeOut" context:[NSNumber numberWithBool:userInitiated]];
      [UIView setAnimationDelegate:self];
      [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
      [UIView setAnimationDuration:FADE_DURATION];
      self.view.alpha = 0.0;
      [UIView commitAnimations];
    } else {
      [self.contentViewController viewDidDisappear:animated];
      [self.view removeFromSuperview];
      self.view = nil;
      [self.backgroundView removeFromSuperview];
      self.backgroundView = nil;
      [self.delegate popoverControllerDidDismissPopover:self];
    }
  }
}

-(CGRect)displayAreaForView:(UIView*)theView
{
  CGRect displayArea = CGRectZero;
  if ([theView conformsToProtocol:@protocol(GreePopoverControllerDatasource)] &&
      [theView respondsToSelector:@selector(displayRectForPopover)]) {
    displayArea = [(id <GreePopoverControllerDatasource>) theView displayRectForPopover];
  } else {
    displayArea = [[[UIApplication sharedApplication] keyWindow]
                   convertRect:[[UIScreen mainScreen]
                                applicationFrame]
                        toView:theView];
  }
  return displayArea;
}

-(GreePopoverContainerViewProperties*)defaultContainerViewProperties
{
  GreePopoverContainerViewProperties* ret = [[GreePopoverContainerViewProperties new] autorelease];
  CGSize imageSize = CGSizeMake(30.0f, 30.0f);
  CGFloat bgMargin = 10.0;
  CGFloat contentMargin = 2.0;
  ret.leftBgMargin = bgMargin;
  ret.rightBgMargin = bgMargin;
  ret.topBgMargin = bgMargin;
  ret.bottomBgMargin = bgMargin;
  ret.leftBgCapSize = imageSize.width/2;
  ret.topBgCapSize = imageSize.height/2;
  ret.leftContentMargin = contentMargin;
  ret.rightContentMargin = contentMargin;
  ret.topContentMargin = contentMargin;
  ret.bottomContentMargin = contentMargin;
  ret.arrowMargin = 1.0;
  ret.roundCorner = YES;
  ret.bgImageName = @"nb-window-base.png";
  ret.upArrowImageName = @"nb-window-arw.png";
  ret.downArrowImageName = nil;
  ret.leftArrowImageName = nil;
  ret.rightArrowImageName = nil;
  return ret;
}

#pragma mark - GreeTouchableView Delegate

-(void)viewDidTouched:(GreeTouchableView*)view
{
  if (self.popoverVisible) {
    if (!self.delegate || [self.delegate popoverControllerShouldDismissPopover:self]) {
      [self dismissPopoverAnimated:NO userInitiated:YES];
    }
  }
}

@end
