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
#import "GreeUniversalMenuViewSectionHeader.h"
#import "GreeUniversalMenuDefinitions.h"

@implementation GreeUniversalMenuViewSectionHeader

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    static const CGFloat TitleLabelWidth = (kGreeUniversalMenuWidth - kGreeUniversalMenuBasePadding * 2);

    CAGradientLayer* gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 1, self.bounds.size.width, 30);
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor greeColorWithHex:kGreeUniversalMenuSectionHeaderBackgroundGradientTop] CGColor],
                       (id)[[UIColor greeColorWithHex:kGreeUniversalMenuSectionHeaderBackgroundGradientBottom] CGColor],
                       nil];
    [self.layer insertSublayer:gradient atIndex:0];

    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(kGreeUniversalMenuBasePadding, 0, TitleLabelWidth, self.frame.size.height)] autorelease];
    self.title.font = [UIFont fontWithName:@"Helvetica-Bold" size:kGreeUniversalMenuBaseFontSize];
    self.title.textColor = [UIColor whiteColor];
    self.title.backgroundColor = [UIColor clearColor];
    self.title.shadowColor = [UIColor greeColorWithHex:kGreeUniversalMenuListTextShadow];
    self.title.shadowOffset = CGSizeMake(0, -1);

    [self addSubview:self.title];
  }
  return self;
}

-(void)dealloc
{
  self.title = nil;
  [super dealloc];
}

-(void)drawRect:(CGRect)rect
{
  CGFloat borderSize = 1.0f;
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, [UIColor greeColorWithHex:kGreeUniversalMenuSectionHeaderBorderTop].CGColor);
  CGContextFillRect(context, CGRectMake(0.0f, 0.0f, self.frame.size.width, borderSize));

  CGContextSetFillColorWithColor(context, [UIColor greeColorWithHex:kGreeUniversalMenuSectionHeaderBorderBottom].CGColor);
  CGContextFillRect(context, CGRectMake(0.0f, self.frame.size.height - borderSize, self.frame.size.width, borderSize));
}

@end
