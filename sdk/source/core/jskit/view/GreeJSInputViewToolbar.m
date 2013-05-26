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

#import "GreeJSInputViewToolbar.h"
#import "GreeJSInputViewController.h"
#import "UIView+GreeAdditions.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat kRightMargin = 8.0f;

@implementation GreeJSInputViewToolbar

-(id)initWithWidth:(CGFloat)width
{
  CGRect frame = CGRectMake(0, 0, width, kGreeJSTextToolbarHeight);
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.layer.shadowOffset = CGSizeMake(0, -4);
    self.layer.shadowColor = [[UIColor colorWithRed:0xe1 / 255.0f
                                              green:0xe2 / 255.0f
                                               blue:0xe3 / 255.0f
                                              alpha:1.0] CGColor];
    self.layer.shadowOpacity = 1.0;
  }
  return self;
}

-(void)dealloc
{
  self.textCounterLabel = nil;
  self.textLimitLabel = nil;
  [super dealloc];
}

-(void)buildTextCounterViewsWithLimit:(NSUInteger)limit
{
  CGRect bounds = self.bounds;
  self.textCounterLabel = [[[UILabel alloc] init] autorelease];
  self.textCounterLabel.font = [UIFont systemFontOfSize:14.0f];
  self.textCounterLabel.backgroundColor = [UIColor clearColor];
  [self setTextCounterColorNormal];

  self.textLimitLabel = [[[UILabel alloc] init] autorelease];
  self.textLimitLabel.font = [UIFont systemFontOfSize:14.0f];
  self.textLimitLabel.backgroundColor = [UIColor clearColor];
  self.textLimitLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                                  green:0x88 / 255.0f
                                                   blue:0x88 / 255.0f
                                                  alpha:1.0];

  NSString* limitString = [[NSNumber numberWithUnsignedInteger:limit] stringValue];
  self.textLimitLabel.text = [NSString stringWithFormat:@"/%@", limitString];
  [self.textLimitLabel sizeToFit];
  CGFloat topMargin = (self.frame.size.height - self.textLimitLabel.frame.size.height) / 2;

  [self.textLimitLabel greeChangeFrameX:(bounds.size.width - self.textLimitLabel.frame.size.width - kRightMargin)];
  [self.textLimitLabel greeChangeFrameY:topMargin];
  self.textLimitLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self.textCounterLabel greeChangeFrameX:(self.textLimitLabel.frame.origin.x - self.textCounterLabel.bounds.size.width)];
  [self.textCounterLabel greeChangeFrameY:topMargin];
  self.textCounterLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

  [self addSubview:self.textCounterLabel];
  [self addSubview:self.textLimitLabel];
}

-(void)setTextCounterColorNormal
{
  self.textCounterLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                                    green:0x88 / 255.0f
                                                     blue:0x88 / 255.0f
                                                    alpha:1.0f];
}

-(void)setTextCounterColorOverLimit
{
  self.textCounterLabel.textColor = [UIColor colorWithRed:0xFF / 255.0f
                                                    green:0x44 / 255.0f
                                                     blue:0x44 / 255.0f
                                                    alpha:1.0f];
}

-(void)updateTextCounterWidthWithTextLength:(int)length
{
  UILabel* label = self.textCounterLabel;
  label.text = [[NSNumber numberWithUnsignedInteger:length] stringValue];
  CGFloat widthDifference = label.frame.size.width;
  [label sizeToFit];
  widthDifference -= label.frame.size.width;
  [self.textCounterLabel greeChangeFrameXRelatively:widthDifference];
}

-(void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();

  // border top
  CGContextMoveToPoint(context, 0, 0);
  CGContextAddLineToPoint(context, rect.size.width, 0);
  CGContextSetRGBStrokeColor(context,
                             0xd1/ 255.0f,
                             0xd2 / 255.0f,
                             0xd3 / 255.0f,
                             1.0f);
  CGContextSetLineWidth(context, 2.0f); // I dont't know why 2.0f to draw 1px line.
  CGContextStrokePath(context);

  // gradient
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = {
    0xf1 / 255.0f, // top color
    0xf2 / 255.0f,
    0xf3 / 255.0f,
    1.0f,
    0xe7 / 255.0f, // bottom color
    0xe8 / 255.0f,
    0xe9 / 255.0f,
    1.0f
  };
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, num_locations);
  CGPoint startPoint = CGPointMake(rect.size.width / 2, 1);
  CGPoint endPoint   = CGPointMake(rect.size.width / 2, rect.size.height);
  CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);

  // border bottom
  CGContextMoveToPoint(context, 0, rect.size.height);
  CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
  CGContextSetRGBStrokeColor(context,
                             0xd7 / 255.0f,
                             0xd8 / 255.0f,
                             0xd9 / 255.0f,
                             1.0f);
  CGContextStrokePath(context);
}

@end
