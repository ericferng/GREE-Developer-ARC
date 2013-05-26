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
#import "GreePopoverContainerView.h"
#import "UIImage+GreeAdditions.h"

@interface GreePopoverContainerView ()
@property (nonatomic, retain) UIImage* bgImage;
@property (nonatomic, retain) UIImage* arrowImage;
@property (nonatomic, retain) GreePopoverContainerViewProperties* properties;
@property (nonatomic, assign) CGRect arrowRect;
@property (nonatomic, assign) CGRect bgRect;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGPoint arrowOffset;
@property (nonatomic, assign) CGSize correctedSize;
@property (nonatomic, assign) UIPopoverArrowDirection arrowDirection;
-(void)determineGeometryForSize:(CGSize)theSize
                     anchorRect:(CGRect)anchorRect
                    displayArea:(CGRect)displayArea
       permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;
-(CGRect)contentRect;
-(CGSize)contentSize;
-(void)setProperties:(GreePopoverContainerViewProperties*)props;
-(void)initFrame;
@end

@implementation GreePopoverContainerView

#pragma mark - Object Lifecycle

-(id)         initWithSize:(CGSize)theSize
                anchorRect:(CGRect)anchorRect
               displayArea:(CGRect)displayArea
  permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
                properties:(GreePopoverContainerViewProperties*)theProperties
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self setProperties:theProperties];

    CGFloat correctedWidth = theSize.width + theProperties.leftBgMargin + theProperties.rightBgMargin + theProperties.leftContentMargin + theProperties.rightContentMargin;
    CGFloat correctedHeight = theSize.height + theProperties.topBgMargin + theProperties.bottomBgMargin + theProperties.topContentMargin + theProperties.bottomContentMargin;
    self.correctedSize = CGSizeMake(correctedWidth, correctedHeight);
    [self
     determineGeometryForSize:self.correctedSize
                   anchorRect:anchorRect
                  displayArea:displayArea
     permittedArrowDirections:permittedArrowDirections];
    [self initFrame];
    self.backgroundColor = [UIColor clearColor];
    UIImage* theImage = [UIImage greeImageNamed:self.properties.bgImageName];
    self.bgImage = [theImage
                    stretchableImageWithLeftCapWidth:self.properties.leftBgCapSize
                                        topCapHeight:self.properties.topBgCapSize];

    self.clipsToBounds = YES;
    self.userInteractionEnabled = YES;
  }
  return self;
}

-(void)dealloc
{
  self.properties = nil;
  [_contentView release];
  _contentView = nil;
  self.bgImage = nil;
  self.arrowImage = nil;
  [super dealloc];
}

#pragma mark - UIView Overrides

-(void)drawRect:(CGRect)rect
{
  [self.bgImage drawInRect:self.bgRect blendMode:kCGBlendModeNormal alpha:1.0];
  [self.arrowImage drawInRect:self.arrowRect blendMode:kCGBlendModeNormal alpha:1.0];
}

-(void)updatePositionWithAnchorRect:(CGRect)anchorRect
                        displayArea:(CGRect)displayArea
           permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
{
  [self
   determineGeometryForSize:self.correctedSize
                 anchorRect:anchorRect
                displayArea:displayArea
   permittedArrowDirections:permittedArrowDirections];
  [self initFrame];
  [self setNeedsDisplay];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
  return CGRectContainsPoint(self.contentRect, point);
}

#pragma mark - Public Interface

-(void)setContentView:(UIView*)view
{
  if (view != _contentView) {
    [_contentView release];
    _contentView = [view retain];
    _contentView.frame = self.contentRect;
    if (self.properties.roundCorner) {
      _contentView.layer.cornerRadius = 5.0f;
      _contentView.clipsToBounds = YES;
    }
    [self addSubview:_contentView];
  }
}

#pragma mark - Internal Methods

-(void)initFrame
{
  CGRect theFrame = CGRectOffset(CGRectUnion(self.bgRect, self.arrowRect), self.offset.x, self.offset.y);

  //If arrow rect origin is < 0 the frame above is extended to include it so we should offset the other rects
  self.arrowOffset = CGPointMake(MAX(0, -self.arrowRect.origin.x), MAX(0, -self.arrowRect.origin.y));
  self.bgRect = CGRectOffset(self.bgRect, self.arrowOffset.x, self.arrowOffset.y);
  self.arrowRect = CGRectOffset(self.arrowRect, self.arrowOffset.x, self.arrowOffset.y);

  self.frame = CGRectIntegral(theFrame);
}

-(CGSize)contentSize
{
  return self.contentRect.size;
}

-(CGRect)contentRect
{
  return CGRectMake(self.properties.leftBgMargin + self.properties.leftContentMargin + self.arrowOffset.x,
                    self.properties.topBgMargin + self.properties.topContentMargin + self.arrowOffset.y,
                    self.bgRect.size.width - self.properties.leftBgMargin - self.properties.rightBgMargin - self.properties.leftContentMargin - self.properties.rightContentMargin,
                    self.bgRect.size.height - self.properties.topBgMargin - self.properties.bottomBgMargin - self.properties.topContentMargin - self.properties.bottomContentMargin);
}

-(void)setProperties:(GreePopoverContainerViewProperties*)props
{
  if (_properties != props) {
    [_properties release];
    _properties = [props retain];
  }
}

-(void)determineGeometryForSize:(CGSize)theSize
                     anchorRect:(CGRect)anchorRect
                    displayArea:(CGRect)displayArea
       permittedArrowDirections:(UIPopoverArrowDirection)supportedArrowDirections
{
  UIPopoverArrowDirection theArrowDirection = UIPopoverArrowDirectionUp;
  self.offset =  CGPointZero;
  self.bgRect = CGRectZero;
  self.arrowRect = CGRectZero;
  self.arrowDirection = UIPopoverArrowDirectionUnknown;

  CGFloat biggestSurface = 0.0f;
  CGFloat currentMinMargin = 0.0f;

  UIImage* upArrowImage = [UIImage greeImageNamed:self.properties.upArrowImageName];
  if ((supportedArrowDirections & theArrowDirection)) {
    CGRect theBgRect = CGRectZero;
    CGRect theArrowRect = CGRectZero;
    CGPoint theOffset = CGPointZero;
    CGFloat xArrowOffset = 0.0;
    CGFloat yArrowOffset = 0.0;
    CGPoint anchorPoint = CGPointZero;
    anchorPoint = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMaxY(anchorRect));
    xArrowOffset = theSize.width / 2 - upArrowImage.size.width / 2;
    yArrowOffset = self.properties.topBgMargin - upArrowImage.size.height;
    theOffset = CGPointMake(anchorPoint.x - xArrowOffset - upArrowImage.size.width / 2,
                            anchorPoint.y  - yArrowOffset);
    theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
    if (theOffset.x < 0) {
      xArrowOffset += theOffset.x;
      theOffset.x = 0;
    } else if (theOffset.x + theSize.width > displayArea.size.width) {
      xArrowOffset += (theOffset.x + theSize.width - displayArea.size.width);
      theOffset.x = displayArea.size.width - theSize.width;
    }

    //Cap the arrow offset
    xArrowOffset = MAX(xArrowOffset, self.properties.leftBgMargin + self.properties.arrowMargin);
    xArrowOffset = MIN(xArrowOffset, theSize.width - self.properties.rightBgMargin - self.properties.arrowMargin - upArrowImage.size.width);
    theArrowRect = CGRectMake(xArrowOffset,
                              yArrowOffset,
                              upArrowImage.size.width,
                              upArrowImage.size.height);
    CGRect bgFrame = CGRectOffset(theBgRect, theOffset.x, theOffset.y);
    CGFloat minMarginLeft = CGRectGetMinX(bgFrame) - CGRectGetMinX(displayArea);
    CGFloat minMarginRight = CGRectGetMaxX(displayArea) - CGRectGetMaxX(bgFrame);
    CGFloat minMarginTop = CGRectGetMinY(bgFrame) - CGRectGetMinY(displayArea);
    CGFloat minMarginBottom = CGRectGetMaxY(displayArea) - CGRectGetMaxY(bgFrame);

    if (minMarginLeft < 0) {
      // Popover is too wide and clipped on the left; decrease width
      // and move it to the right
      theOffset.x -= minMarginLeft;
      theBgRect.size.width += minMarginLeft;
      minMarginLeft = 0;
      if (theArrowDirection == UIPopoverArrowDirectionRight) {
        theArrowRect.origin.x = CGRectGetMaxX(theBgRect) - self.properties.rightBgMargin;
      }
    }
    if (minMarginTop < 0) {
      // Popover is too high and clipped at the top; decrease height
      // and move it down
      theOffset.y -= minMarginTop;
      theBgRect.size.height += minMarginTop;
      minMarginTop = 0;
      if (theArrowDirection == UIPopoverArrowDirectionDown) {
        theArrowRect.origin.y = CGRectGetMaxY(theBgRect) - self.properties.bottomBgMargin;
      }
    }
    if (minMarginBottom < 0) {
      // Popover is too high and clipped at the bottom; decrease height.
      theBgRect.size.height += minMarginBottom;
      minMarginBottom = 0;
      if (theArrowDirection == UIPopoverArrowDirectionUp) {
        theArrowRect.origin.y = CGRectGetMinY(theBgRect) - upArrowImage.size.height + self.properties.topBgMargin;
      }
    }
    bgFrame = CGRectOffset(theBgRect, theOffset.x, theOffset.y);
    CGFloat minMargin = MIN(minMarginLeft, minMarginRight);
    minMargin = MIN(minMargin, minMarginTop);
    minMargin = MIN(minMargin, minMarginBottom);

    // Calculate intersection and surface
    CGRect intersection = CGRectIntersection(displayArea, bgFrame);
    CGFloat surface = intersection.size.width * intersection.size.height;
    if (surface >= biggestSurface && minMargin >= currentMinMargin) {
      self.offset = theOffset;
      self.arrowRect = theArrowRect;
      self.bgRect = theBgRect;
      self.arrowDirection = theArrowDirection;
    }
  }
  self.arrowImage = upArrowImage;
}

@end
