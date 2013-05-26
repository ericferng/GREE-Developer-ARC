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

#import "GreeJSPhotoView.h"

#define kSpacingWidth    40
#define kSpacingHeight   0
#define kLimitOfScrollView                      3
#define kLengthFromCetner                       ((kLimitOfScrollView-1)/2)
#define kIndexOfCurrentScrollView       ((kLimitOfScrollView-1)/2)

@interface GreeJSPhotoView ()

@property (nonatomic, assign) NSInteger currentImageIndex;
@property (nonatomic, retain) UIScrollView* scrollView;
@property (nonatomic, assign) NSInteger contentOffsetIndex;
@property (nonatomic, retain) NSMutableArray* imageScrollViews;
@property (nonatomic, assign) CGSize viewSpacing;
@property (nonatomic, assign) CGSize previousScrollSize;
@property (nonatomic, assign) BOOL didSetup;
@property (nonatomic, assign) BOOL scrollingAnimation;

-(void)previousPageAnimated:(BOOL)animated;
-(void)nextPageAnimated:(BOOL)animated;
-(void)resetZoomScrollView:(GreeJSImageScrollView*)innerScrollView;
-(void)setPhotoImageAtIndex:(NSInteger)index toScrollView:(GreeJSImageScrollView*)innerScrollView;
-(CGSize)unitSize;
-(void)relayoutBaseScrollView;
-(void)relayoutImageScrollViews;
-(void)relayoutViewsAnimated:(BOOL)animated;
-(void)setupSubViews;
-(void)layoutSubviewsWithSizeChecking:(BOOL)checking animated:(BOOL)animated;
-(void)movePage:(BOOL)animated;
-(void)setupPreviousImage;
-(void)setupNextImage;
-(NSInteger)numberOfPhotoImages;

@end


@implementation GreeJSPhotoView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.scrollView = nil;
  self.imageScrollViews = nil;

  [super dealloc];
}

#pragma mark - UIView Overrides

-(void)layoutSubviews
{
  [self layoutSubviewsWithSizeChecking:YES animated:NO];
}

#pragma mark - Public Interface

-(void)setDelegate:(id<GreeJSPhotoViewDelegate>)delegate
{
  _delegate = delegate;
}

-(void)setCurrentPage:(NSInteger)page animated:(BOOL)animated
{
  if (page == self.currentImageIndex) {
    return;
  }

  NSInteger numberOfPhotoImages = [self numberOfPhotoImages];
  if (page < 0) {
    page = 0;
  } else if (page >= numberOfPhotoImages) {
    page = numberOfPhotoImages - 1;
  }

  self.currentImageIndex = page;
  self.contentOffsetIndex = page;

  for (int index=0; index < kLimitOfScrollView; index++) {
    [self setPhotoImageAtIndex:self.currentImageIndex+index-kLengthFromCetner
                  toScrollView:[self.imageScrollViews objectAtIndex:index]];
  }

  [self relayoutViewsAnimated:NO];
  [self layoutSubviewsWithSizeChecking:NO animated:animated];

}

-(void)setCurrentPage:(NSInteger)page
{
  [self setCurrentPage:page animated:YES];
}

-(NSInteger)currentPage
{
  return self.currentImageIndex;
}

-(void)previousPageAnimated:(BOOL)animated
{
  if (self.scrollingAnimation || self.currentPage <= 0) {
    return;
  }

  self.currentImageIndex--;
  self.contentOffsetIndex--;
  [self setupPreviousImage];
  [self movePage:animated];
}

-(void)nextPageAnimated:(BOOL)animated
{
  if(self.scrollingAnimation || self.currentPage >= [self numberOfPhotoImages]-1) {
    return;
  }

  self.currentImageIndex++;
  self.contentOffsetIndex++;
  [self setupNextImage];
  [self movePage:animated];
}

-(UIImageView*)currentPhotoImageView
{
  return ((GreeJSImageScrollView*)[self.imageScrollViews
                                   objectAtIndex:kIndexOfCurrentScrollView]).imageView;
}

#pragma mark - GreeJSImageScrollViewDelegate Methoads

-(void)didSingleTap:(GreeJSImageScrollView*)scrollView
{
  if ([self.delegate respondsToSelector:@selector(didSingleTap:)]) {
    [self.delegate didSingleTap:self];
  }
}

-(void)didDoubleTap:(GreeJSImageScrollView*)scrollView
{
  if ([self.delegate respondsToSelector:@selector(didDoubleTap:)]) {
    [self.delegate didDoubleTap:self];
  }
}

#pragma mark - UIScrollViewDelegate Methoads

-(void)scrollViewDidScroll:(UIScrollView*)scrollView
{
  if (!scrollView.dragging) {
    return;
  }
  CGFloat position = scrollView.contentOffset.x / scrollView.bounds.size.width;
  CGFloat delta = position - (CGFloat)self.currentImageIndex;

  if (fabs(delta) >= 1.0f) {
    GreeJSImageScrollView* currentScrollView =
      [self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
    [self resetZoomScrollView:currentScrollView];

    if (delta > 0.0f) {
      self.currentImageIndex = self.currentImageIndex+1;
      self.contentOffsetIndex = self.contentOffsetIndex+1;
      [self setupNextImage];
      if ([self.delegate respondsToSelector:@selector(photoScrollViewDidChangeNextPage:photoView:)]) {
        [self.delegate photoScrollViewDidChangeNextPage:scrollView photoView:self];
      }
    } else {
      self.currentImageIndex = self.currentImageIndex-1;
      self.contentOffsetIndex = self.contentOffsetIndex-1;
      [self setupPreviousImage];
      if ([self.delegate respondsToSelector:@selector(photoScrollViewDidChangePreviousPage:photoView:)]) {
        [self.delegate photoScrollViewDidChangePreviousPage:scrollView photoView:self];
      }
    }
  }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
  if ([self.delegate respondsToSelector:@selector(photoScrollViewDidEndDecelerating:photoView:)]) {
    [self.delegate photoScrollViewDidEndDecelerating:scrollView photoView:self];
  }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
  self.scrollingAnimation = NO;
}

#pragma mark - Internal Methods

-(NSInteger)numberOfPhotoImages
{
  NSInteger numberOfPhotos = [self.delegate numberOfPhotoImages:self];
  if (numberOfPhotos < 0) {
    numberOfPhotos = 0;
  }
  return numberOfPhotos;
}

-(void)resetZoomScrollView:(GreeJSImageScrollView*)innerScrollView
{
  innerScrollView.zoomScale = 1.0;
  innerScrollView.contentOffset = CGPointZero;
}

-(void)setPhotoImageAtIndex:(NSInteger)index toScrollView:(GreeJSImageScrollView*)innerScrollView
{
  if (index < 0 || [self numberOfPhotoImages] <= index) {
    innerScrollView.imageView.image = nil;
    return;
  }
  innerScrollView.imageView.image = [self.delegate
                                       photoImage:self
                                        imageView:innerScrollView.imageView
                                     imageAtIndex:index];
  [self resetZoomScrollView:innerScrollView];
}

-(void)reloadPhotos
{
  NSInteger numberOfViews = [self numberOfPhotoImages];
  if (self.currentImageIndex >= numberOfViews) {
    if (numberOfViews == 0) {
      self.currentImageIndex = 0;
    } else {
      self.currentImageIndex = numberOfViews-1;
    }
    self.contentOffsetIndex = self.currentImageIndex;
  }

  for (int index=0; index < kLimitOfScrollView; index++) {
    [self setPhotoImageAtIndex:self.currentImageIndex+index-kLengthFromCetner
                  toScrollView:[self.imageScrollViews objectAtIndex:index]];
  }
}

-(CGSize)unitSize
{
  CGSize size;
  size = self.bounds.size;
  size.width += self.viewSpacing.width;
  return size;
}

-(void)relayoutBaseScrollView
{
  CGRect scrollViewFrame = self.bounds;
  scrollViewFrame.origin.x -= self.viewSpacing.width/2.0;
  scrollViewFrame.size.width += self.viewSpacing.width;
  self.scrollView.frame = scrollViewFrame;
}

-(void)relayoutImageScrollViews
{
  CGRect imageScrollViewFrame = CGRectZero;
  imageScrollViewFrame.size = self.bounds.size;
  imageScrollViewFrame.origin.x = (self.contentOffsetIndex-kLengthFromCetner) * imageScrollViewFrame.size.width;

  for(int i = 0; i < kLimitOfScrollView; i++) {
    GreeJSImageScrollView* innerScrollView = [self.imageScrollViews objectAtIndex:i];
    imageScrollViewFrame.origin.x += self.viewSpacing.width/2.0;
    innerScrollView.frame = imageScrollViewFrame;
    imageScrollViewFrame.origin.x += imageScrollViewFrame.size.width;
    imageScrollViewFrame.origin.x += self.viewSpacing.width/2.0;
  }
}

-(void)relayoutViewsAnimated:(BOOL)animated
{
  if (animated) {
    [UIView beginAnimations:nil context:nil];
  }
  [self relayoutBaseScrollView];
  [self relayoutImageScrollViews];
  if (animated) {
    [UIView commitAnimations];
  }
}

-(void)setupSubViews
{
  self.viewSpacing = CGSizeMake(kSpacingWidth, kSpacingHeight);
  self.scrollView.clipsToBounds = NO;

  self.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin  |
    UIViewAutoresizingFlexibleWidth       |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin   |
    UIViewAutoresizingFlexibleHeight      |
    UIViewAutoresizingFlexibleBottomMargin;
  self.clipsToBounds = YES;
  self.backgroundColor = [UIColor blackColor];

  self.scrollView = [[[UIScrollView alloc] initWithFrame:self.frame] autorelease];
  self.scrollView.delegate = self;
  self.scrollView.pagingEnabled = YES;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.scrollsToTop = NO;
  self.scrollView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
  [self relayoutBaseScrollView];

  [self addSubview:self.scrollView];

  CGRect imageScrollViewFrame = CGRectZero;
  self.imageScrollViews = [NSMutableArray array];

  for(int i = 0; i < kLimitOfScrollView; i++) {
    GreeJSImageScrollView* imageScrollView = [[GreeJSImageScrollView alloc] initWithFrame:imageScrollViewFrame];
    imageScrollView.clipsToBounds = YES;
    imageScrollView.backgroundColor = self.backgroundColor;
    imageScrollView.eventDelegate = self;
    [self.scrollView addSubview:imageScrollView];
    [self.imageScrollViews addObject:imageScrollView];
    [imageScrollView release];
  }
  [self relayoutImageScrollViews];
}

-(void)layoutSubviewsWithSizeChecking:(BOOL)checking animated:(BOOL)animated
{
  if (!self.didSetup) {
    [self setupSubViews];
    [self reloadPhotos];
    self.didSetup = YES;
  }

  CGSize newSize;
  newSize = self.bounds.size;
  CGSize oldSize = self.previousScrollSize;

  if (checking && CGSizeEqualToSize(newSize, oldSize)) {
    return;
  }

  self.scrollView.clipsToBounds = NO;

  self.previousScrollSize = newSize;
  CGSize newSizeWithSpace = newSize;
  newSizeWithSpace.width += self.viewSpacing.width;

  GreeJSImageScrollView* currentScrollView =
    [self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
  CGSize oldContentSize = currentScrollView.contentSize;
  CGPoint oldContentOffset = currentScrollView.contentOffset;

  CGFloat zoomScale = currentScrollView.zoomScale;

  CGPoint oldCenter;
  oldCenter.x = oldContentOffset.x + oldSize.width/2.0;
  oldCenter.y = oldContentOffset.y + oldSize.height/2.0;

  CGFloat ratioW = oldCenter.x / oldContentSize.width;
  CGFloat ratioH = oldCenter.y / oldContentSize.height;

  CGFloat x = (self.contentOffsetIndex-kLengthFromCetner) * newSizeWithSpace.width;
  for (GreeJSImageScrollView* scrollView in self.imageScrollViews) {

    x += self.viewSpacing.width/2.0;                    // left space

    scrollView.frame = CGRectMake(x, 0, newSize.width, newSize.height);
    CGSize contentSize;
    if (scrollView == currentScrollView) {
      contentSize.width  = newSize.width  * scrollView.zoomScale;
      contentSize.height = newSize.height * scrollView.zoomScale;
    } else {
      contentSize = newSize;
    }
    scrollView.contentSize = contentSize;
    x += newSize.width;
    x += self.viewSpacing.width/2.0;                    // right space
  }

  if (zoomScale > 1.0) {
    CGSize newContentSize = currentScrollView.contentSize;
    CGPoint newCenter;
    newCenter.x = ratioW * newContentSize.width;
    newCenter.y = ratioH * newContentSize.height;

    CGPoint newContentOffset;
    newContentOffset.x = newCenter.x - newSize.width /2.0;
    newContentOffset.y = newCenter.y - newSize.height/2.0;
    currentScrollView.contentOffset = newContentOffset;
  }
  self.scrollView.contentSize = CGSizeMake([self numberOfPhotoImages]*newSizeWithSpace.width, newSize.height);
  [self.scrollView setContentOffset:CGPointMake(self.contentOffsetIndex*newSizeWithSpace.width, 0)
                           animated:animated];
}

-(void)movePage:(BOOL)animated
{
  self.scrollingAnimation = YES;
  [self.scrollView setContentOffset:CGPointMake(self.contentOffsetIndex*[self unitSize].width, 0)
                           animated:animated];
}

-(void)setupPreviousImage
{
  GreeJSImageScrollView* rightView = [self.imageScrollViews objectAtIndex:kLimitOfScrollView-1];
  GreeJSImageScrollView* leftView = [self.imageScrollViews objectAtIndex:0];

  CGRect frame = leftView.frame;
  frame.origin.x -= frame.size.width + self.viewSpacing.width;
  rightView.frame = frame;

  [self.imageScrollViews removeObjectAtIndex:kLimitOfScrollView-1];
  [self.imageScrollViews insertObject:rightView atIndex:0];
  [self setPhotoImageAtIndex:self.currentImageIndex-kLengthFromCetner toScrollView:rightView];
}

-(void)setupNextImage
{
  GreeJSImageScrollView* rightView = [self.imageScrollViews objectAtIndex:kLimitOfScrollView-1];
  GreeJSImageScrollView* leftView = [self.imageScrollViews objectAtIndex:0];

  CGRect frame = rightView.frame;
  frame.origin.x += frame.size.width + self.viewSpacing.width;
  leftView.frame = frame;

  [self.imageScrollViews removeObjectAtIndex:0];
  [self.imageScrollViews addObject:leftView];
  [self setPhotoImageAtIndex:self.currentImageIndex+kLengthFromCetner toScrollView:leftView];
}

@end
