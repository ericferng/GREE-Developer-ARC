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

#import "GreeUniversalMenuViewCellSubviewNotSelectable.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeUniversalMenuDefinitions.h"
#import "UIView+GreeAdditions.h"

@implementation GreeUniversalMenuViewCellSubviewNotSelectable

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    static const CGFloat BorderTopHeight = 1;
    static const CGFloat TitleLabelWidth = (kGreeUniversalMenuWidth
                                            - kGreeUniversalMenuBasePadding
                                            - kGreeUniversalMenuBasePadding);
    static const CGFloat TitleLabelY = BorderTopHeight;
    static const CGFloat TitleLabelHeight = kGreeUniversalMenuNormalCellHeight - BorderTopHeight * 2;

    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];

    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(kGreeUniversalMenuBasePadding,
                                                            TitleLabelY,
                                                            TitleLabelWidth,
                                                            TitleLabelHeight)] autorelease];
    self.title.font = [UIFont fontWithName:@"Helvetica" size:kGreeUniversalMenuSubTextFontSize];
    self.title.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];
    self.title.textColor = [UIColor greeColorWithHex:kGreeUniversalMenuListText];
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
  CGContextSetFillColorWithColor(context, [UIColor greeColorWithHex:kGreeUniversalMenuListBorderTop].CGColor);
  CGContextFillRect(context, CGRectMake(0.0f, 0.0f, self.frame.size.width, borderSize));
}

@end
