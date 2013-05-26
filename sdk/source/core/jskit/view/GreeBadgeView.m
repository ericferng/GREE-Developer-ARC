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
#import "GreeBadgeView.h"

#define kDefaultTextColor       [UIColor whiteColor]
#define kDefaultBackgroundColor [UIColor redColor]
#define kDefaultOverlayColor    [UIColor colorWithWhite:1.0f alpha:0.3]
#define kDefaultTextFont        [UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
#define kDefaultShadowColor     [UIColor clearColor]
#define kDefaultStrokeColor     [UIColor whiteColor]
#define kStrokeWidth            2.0f
#define kMarginToDrawInside     (kStrokeWidth * 2)
#define kShadowOffset           CGSizeMake(1.0f, 1.0f)
#define kShadowOpacity          0.4f
#define kShadowColor            [UIColor colorWithWhite:0.0f alpha:kShadowOpacity]
#define kShadowRadius           1.0f
#define kBadgeHeight            14.0f
#define kBadgeTextSideMargin    6.0f
#define kBadgeCornerRadius      10.0f
#define kDefaultBadgeAlignment  GreeBadgeViewAlignmentTopRight

@interface GreeBadgeView ()
-(CGSize)sizeOfTextForCurrentSettings;
@end

@implementation GreeBadgeView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.badgeText = nil;
  self.textColor = nil;
  self.textShadowColor = nil;
  self.textFont = nil;
  self.badgeBackgroundColor = nil;
  self.strokeColor = nil;

  [super dealloc];
}

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.badgeAlignment = kDefaultBadgeAlignment;
    self.badgeBackgroundColor = kDefaultBackgroundColor;
    self.overlayColor = kDefaultOverlayColor;
    self.textColor = kDefaultTextColor;
    self.textShadowColor = kDefaultShadowColor;
    self.textFont = kDefaultTextFont;
    self.strokeColor = kDefaultStrokeColor;
    self.hideWhenZero = YES;
  }
  return self;
}

-(id)initWithParentView:(UIView*)parentView alignment:(GreeBadgeViewAlignment)alignment
{
  self = [self initWithFrame:CGRectZero];
  if (self) {
    self.userInteractionEnabled = NO;
    self.badgeAlignment = alignment;
    [parentView addSubview:self];
  }
  return self;
}

#pragma mark - UIView Overrides

-(void)layoutSubviews
{
  CGRect newFrame = self.frame;
  CGRect superviewFrame =
    CGRectIsEmpty(self.frameToPositionInRelationWith) ? self.superview.frame : self.frameToPositionInRelationWith;
  CGFloat textWidth = [self sizeOfTextForCurrentSettings].width;
  CGFloat viewWidth = textWidth + kBadgeTextSideMargin + (kMarginToDrawInside * 2);
  CGFloat viewHeight = kBadgeHeight + (kMarginToDrawInside * 2);
  CGFloat superviewWidth = superviewFrame.size.width;
  CGFloat superviewHeight = superviewFrame.size.height;
  newFrame.size.width = viewWidth;
  newFrame.size.height = viewHeight;

  switch (self.badgeAlignment) {
  case GreeBadgeViewAlignmentTopLeft:
    newFrame.origin.x = -viewWidth / 2.0f;
    newFrame.origin.y = -viewHeight / 2.0f;
    break;
  case GreeBadgeViewAlignmentTopRight:
    newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
    newFrame.origin.y = -viewHeight / 2.0f;
    break;
  case GreeBadgeViewAlignmentTopCenter:
    newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
    newFrame.origin.y = -viewHeight / 2.0f;
    break;
  case GreeBadgeViewAlignmentCenterLeft:
    newFrame.origin.x = -viewWidth / 2.0f;
    newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
    break;
  case GreeBadgeViewAlignmentCenterRight:
    newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
    newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
    break;
  case GreeBadgeViewAlignmentBottomLeft:
    newFrame.origin.x = -textWidth / 2.0f;
    newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
    break;
  case GreeBadgeViewAlignmentBottomRight:
    newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
    newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
    break;
  case GreeBadgeViewAlignmentBottomCenter:
    newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
    newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
    break;
  case GreeBadgeViewAlignmentCenter:
    newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
    newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
    break;
  default:
    break;
  }
  newFrame.origin.x += self.positionAdjustment.x;
  newFrame.origin.y += self.positionAdjustment.y;
  self.frame = CGRectIntegral(newFrame);
  [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
  BOOL anyTextToDraw = (self.badgeText.length > 0);
  if (!anyTextToDraw || (self.hideWhenZero && [self.badgeText isEqualToString:@"0"])) {
    return;
  }
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGRect rectToDraw = CGRectInset(rect, kMarginToDrawInside, kMarginToDrawInside);
  UIBezierPath* borderPath = [UIBezierPath
                              bezierPathWithRoundedRect:rectToDraw
                                      byRoundingCorners:(UIRectCorner)UIRectCornerAllCorners
                                            cornerRadii:CGSizeMake(kBadgeCornerRadius, kBadgeCornerRadius)];

  /* Background and shadow */
  CGContextSaveGState(ctx);

  CGContextAddPath(ctx, borderPath.CGPath);
  CGContextSetFillColorWithColor(ctx, self.badgeBackgroundColor.CGColor);
  CGContextSetShadowWithColor(ctx, kShadowOffset, kShadowRadius, kShadowColor.CGColor);
  CGContextDrawPath(ctx, kCGPathFill);

  CGContextRestoreGState(ctx);

  BOOL colorForOverlayPresent = self.overlayColor && ![self.overlayColor isEqual:[UIColor clearColor]];
  if (colorForOverlayPresent) {
    /* Gradient overlay */
    CGContextSaveGState(ctx);

    CGContextAddPath(ctx, borderPath.CGPath);
    CGContextClip(ctx);
    CGFloat height = rectToDraw.size.height;
    CGFloat width = rectToDraw.size.width;
    CGRect rectForOverlayCircle = CGRectMake(rectToDraw.origin.x,
                                             rectToDraw.origin.y - ceilf(height * 0.5),
                                             width,
                                             height);

    CGContextAddEllipseInRect(ctx, rectForOverlayCircle);
    CGContextSetFillColorWithColor(ctx, self.overlayColor.CGColor);
    CGContextDrawPath(ctx, kCGPathFill);

    CGContextRestoreGState(ctx);
  }

  /* Stroke */
  if (self.stroke) {
    CGContextSaveGState(ctx);

    CGContextAddPath(ctx, borderPath.CGPath);
    CGContextSetLineWidth(ctx, kStrokeWidth);
    CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);
    CGContextDrawPath(ctx, kCGPathStroke);

    CGContextRestoreGState(ctx);
  }

  /* Text */
  CGContextSaveGState(ctx);

  CGContextSetFillColorWithColor(ctx, self.textColor.CGColor);
  CGContextSetShadowWithColor(ctx, self.textShadowOffset, 1.0, self.textShadowColor.CGColor);
  CGRect textFrame = rectToDraw;
  CGSize textSize = [self sizeOfTextForCurrentSettings];
  textFrame.size.height = textSize.height;
  textFrame.origin.y = rectToDraw.origin.y + ceilf((rectToDraw.size.height - textFrame.size.height) / 2.0f);
  [self.badgeText
      drawInRect:textFrame
        withFont:self.textFont
   lineBreakMode:UILineBreakModeCharacterWrap
       alignment:UITextAlignmentCenter];

  CGContextRestoreGState(ctx);
}

#pragma mark - Public Interface

-(void)setBadgeAlignment:(GreeBadgeViewAlignment)badgeAlignment
{
  if (badgeAlignment != _badgeAlignment) {
    _badgeAlignment = badgeAlignment;
    switch (badgeAlignment) {
    case GreeBadgeViewAlignmentTopLeft:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleRightMargin;
      break;
    case GreeBadgeViewAlignmentTopRight:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleLeftMargin;
      break;
    case GreeBadgeViewAlignmentTopCenter:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin;
      break;
    case GreeBadgeViewAlignmentCenterLeft:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleRightMargin;
      break;
    case GreeBadgeViewAlignmentCenterRight:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleLeftMargin;
      break;
    case GreeBadgeViewAlignmentBottomLeft:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleRightMargin;
      break;
    case GreeBadgeViewAlignmentBottomRight:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin;
      break;
    case GreeBadgeViewAlignmentBottomCenter:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin;
      break;
    case GreeBadgeViewAlignmentCenter:
      self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleBottomMargin;
      break;
    default:
      break;
    }
    [self setNeedsLayout];
  }
}

-(void)setBadgePositionAdjustment:(CGPoint)badgePositionAdjustment
{
  self.positionAdjustment = badgePositionAdjustment;
  [self setNeedsLayout];
}

-(void)setBadgeText:(NSString*)badgeText
{
  if (badgeText != _badgeText) {
    _badgeText = [badgeText copy];
    [self setNeedsLayout];
    [self setNeedsDisplay];
  }
}

-(void)setBadgeTextColor:(UIColor*)badgeTextColor
{
  if (badgeTextColor != _textColor) {
    _textColor = badgeTextColor;
    [self setNeedsDisplay];
  }
}

-(void)setBadgeTextShadowColor:(UIColor*)badgeTextShadowColor
{
  if (badgeTextShadowColor != _textShadowColor) {
    _textShadowColor = badgeTextShadowColor;
    [self setNeedsDisplay];
  }
}

-(void)setBadgeTextShadowOffset:(CGSize)badgeTextShadowOffset
{
  _textShadowOffset = badgeTextShadowOffset;
  [self setNeedsDisplay];
}

-(void)setBadgeTextFont:(UIFont*)badgeTextFont
{
  if (badgeTextFont != _textFont) {
    _textFont = badgeTextFont;
    [self setNeedsDisplay];
  }
}

-(void)setBadgeBackgroundColor:(UIColor*)badgeBackgroundColor
{
  if (badgeBackgroundColor != _badgeBackgroundColor) {
    _badgeBackgroundColor = badgeBackgroundColor;
    [self setNeedsDisplay];
  }
}

#pragma mark - Internal Methods

-(CGSize)sizeOfTextForCurrentSettings
{
  return [self.badgeText sizeWithFont:self.textFont];
}

@end
