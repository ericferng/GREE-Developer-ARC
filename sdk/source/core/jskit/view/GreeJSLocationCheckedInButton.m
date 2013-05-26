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

#import "GreeJSLocationCheckedInButton.h"
#import "UIImage+GreeAdditions.h"

@implementation GreeJSLocationCheckedInButton

-(void)dealloc
{
  self.spotNameLabel = nil;
  self.locationIcon = nil;
  [super dealloc];
}

+(GreeJSLocationCheckedInButton*)buttonWithFrame:(CGRect)frame
{
  GreeJSLocationCheckedInButton* button = [[self class] buttonWithType:UIButtonTypeCustom];
  button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  button.frame = frame;

  button.spotNameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(30, 7, frame.size.width - 33, 20)] autorelease];
  button.spotNameLabel.textColor = [UIColor colorWithRed:0x00 / 255.0f
                                                   green:0x77 / 255.0f
                                                    blue:0xaa / 255.0f
                                                   alpha:1.0f];
  button.spotNameLabel.backgroundColor = [UIColor clearColor];
  button.spotNameLabel.adjustsFontSizeToFitWidth = NO;
  [button addSubview:button.spotNameLabel];

  button.locationIcon = [[[UIImageView alloc]
                          initWithImage:[UIImage greeImageNamed:@"gree_location_header_icon.png"]] autorelease];
  button.locationIcon.frame = CGRectMake(10, 10, 13, 14);
  [button addSubview:button.locationIcon];

  button.enabled = NO;
  button.alpha = 0.0f;

  return button;
}

-(void)showWithText:(NSString*)text
{
  self.spotNameLabel.text = text;
  self.enabled = YES;
  self.alpha = 1.0f;
}

-(void)hide
{
  [self setTitle:nil forState:UIControlStateNormal];
  self.enabled = NO;
  self.alpha = 0.0f;
}

-(void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();

  // border top
  CGContextMoveToPoint(context, 0, 0);
  CGContextAddLineToPoint(context, self.frame.size.width, 0);
  CGContextSetRGBStrokeColor(context,
                             0xe1 / 255.0f,
                             0xe2 / 255.0f,
                             0xe3 / 255.0f,
                             1.0f);
  CGContextStrokePath(context);

  // gradient
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = {
    0xf0 / 255.0f, // top color
    0xf1 / 255.0f,
    0xf2 / 255.0f,
    1.0f,
    0xe7 / 255.0f, // bottom color
    0xe8 / 255.0f,
    0xe9 / 255.0f,
    1.0f
  };
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, num_locations);
  CGPoint startPoint = CGPointMake(self.frame.size.width / 2, 1);
  CGPoint endPoint   = CGPointMake(self.frame.size.width / 2, self.frame.size.height - 1);
  CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);

  // border bottom
  CGContextMoveToPoint(context, 0, self.frame.size.height);
  CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height);
  CGContextSetRGBStrokeColor(context,
                             0xd7 / 255.0f,
                             0xd8 / 255.0f,
                             0xd9 / 255.0f,
                             1.0f);
  CGContextStrokePath(context);
}

@end
