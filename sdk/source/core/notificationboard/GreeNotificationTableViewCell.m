//
// Copyright 2012 GREE International, Inc.
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

#import <QuartzCore/QuartzCore.h>
#import "GreeNotificationTableViewCell.h"
#import "GreePlatform+Internal.h"
#import "UIView+GreeAdditions.h"

static CGFloat const kIconWidth = 36.0;
static CGFloat const kIconHeight = 36.0;
static CGFloat const kIconCornerRadius = 6.5;
static CGFloat const kCellPaddingLeft = 10.0;
static CGFloat const kCellPaddingTop = 10.0;
static CGFloat const kCellPaddingBottom = 10.0;
static CGFloat const kMainMessageWidth = 188.0;
static CGFloat const kIconImageMarginRight = 10.0;
static CGFloat const kMainMessageFontSize = 14.0;
static CGFloat const kSubMassageWidth = 188.0;
static CGFloat const kSubMessageFontSize = 14.0;
static CGFloat const kSubMessageMarginRight = 10.0;
static CGFloat const kTimeMessageFontSize = 14.0;
static CGFloat const kTimeMessageWidth = 188.0;
static CGFloat const kIconColumnWidth = kCellPaddingLeft + kIconWidth + kIconImageMarginRight;
static CGFloat const kAccessoryColumnAddWidth = 20;
static CGFloat const kMinMessageColumnWidth = 56;
static CGFloat const kMinAccessoryColumnWidth = 10.0;
static CGFloat const kMinCellWidth = kIconColumnWidth + kMinMessageColumnWidth + kMinAccessoryColumnWidth;


@interface GreeNotificationTableViewCell ()
{
  GreeNotificationTableViewCellLabel* testLabel;
  CGFloat currentMessageColumnWidth;
}
@property (retain, nonatomic) UIView* backgroundView;
@end

@implementation GreeNotificationTableViewCell

#pragma mark - Object Lifecycle

-(id)initWidthReuseIdentifier:(NSString*)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self) {
    self.iconImageView = [[[UIImageView alloc] init] autorelease];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;

    self.mainMessageLabel = [[[GreeNotificationTableViewCellLabel alloc] initWithFrame:CGRectZero] autorelease];
    self.mainMessageLabel.font = [UIFont systemFontOfSize:kMainMessageFontSize];
    self.mainMessageLabel.textColor = [UIColor
                                       colorWithRed:0x33 / 255.0f
                                              green:0x44 / 255.0f
                                               blue:0x55 / 255.0f
                                              alpha:1.0];
    [self.mainMessageLabel setNumberOfLines:0];
    [self.mainMessageLabel setBackgroundColor:[UIColor clearColor]];
    self.mainMessageLabel.lineBreakMode = UILineBreakModeCharacterWrap;

    self.subMessageLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.subMessageLabel.font = [UIFont systemFontOfSize:kSubMessageFontSize];
    self.subMessageLabel.textColor = [UIColor
                                      colorWithRed:0x77 / 255.0f
                                             green:0x88 / 255.0f
                                              blue:0x99 / 255.0f
                                             alpha:1.0];
    self.subMessageLabel.backgroundColor = [UIColor clearColor];
    [self.subMessageLabel setNumberOfLines:0];
    self.subMessageLabel.lineBreakMode = UILineBreakModeCharacterWrap;

    self.timeMessageLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.timeMessageLabel.font = [UIFont systemFontOfSize:kTimeMessageFontSize];
    self.timeMessageLabel.backgroundColor = [UIColor clearColor];
    self.timeMessageLabel.textColor = [UIColor
                                       colorWithRed:0x77 / 255.0f
                                              green:0x88 / 255.0f
                                               blue:0x99 / 255.0f
                                              alpha:1.0];
    self.timeMessageLabel.highlightedTextColor = [UIColor whiteColor];
    [self.timeMessageLabel setNumberOfLines:0];
    self.timeMessageLabel.lineBreakMode = UILineBreakModeCharacterWrap;

    [self.contentView addSubview:self.iconImageView];
    [self.contentView addSubview:self.mainMessageLabel];
    [self.contentView addSubview:self.subMessageLabel];
    [self.contentView addSubview:self.timeMessageLabel];
  }
  return self;
}

-(void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat frameWidth = self.frame.size.width;
  if (frameWidth < kMinCellWidth) {
    currentMessageColumnWidth = kMinMessageColumnWidth;
  } else {
    if (self.accessoryView.frame.size.width > 0) {
      currentMessageColumnWidth = frameWidth - (kIconColumnWidth + self.accessoryView.frame.size.width+kAccessoryColumnAddWidth);
    } else {
      currentMessageColumnWidth = frameWidth - kIconColumnWidth - kMinAccessoryColumnWidth;
    }
  }
  CGRect bounds = self.contentView.bounds;
  self.iconImageView.frame = CGRectMake(bounds.origin.x + kCellPaddingLeft,
                                        kCellPaddingTop,
                                        kIconWidth,
                                        kIconHeight);
  [self.mainMessageLabel greeChangeFrameX:self.iconImageView.frame.origin.x+self.iconImageView.frame.size.width + kIconImageMarginRight];
  [self.mainMessageLabel greeChangeFrameY:self.iconImageView.frame.origin.y];
  [self.mainMessageLabel greeChangeFrameWidth:currentMessageColumnWidth];
  [self.mainMessageLabel greeChangeFrameHeight:[self.mainMessageLabel multiFontHeight:currentMessageColumnWidth]];

  CGSize subMessageSize = [self.subMessageLabel.text
                                sizeWithFont:self.subMessageLabel.font
                           constrainedToSize:CGSizeMake(currentMessageColumnWidth, 1000)
                               lineBreakMode:UILineBreakModeCharacterWrap];

  [self.subMessageLabel greeChangeFrameX:self.iconImageView.frame.origin.x+self.iconImageView.frame.size.width + kIconImageMarginRight];
  [self.subMessageLabel greeChangeFrameY:self.mainMessageLabel.frame.origin.y + [self.mainMessageLabel multiFontHeight:currentMessageColumnWidth]];
  [self.subMessageLabel greeChangeFrameWidth:subMessageSize.width];
  [self.subMessageLabel greeChangeFrameHeight:subMessageSize.height];

  CGSize timeMessageSize = [self.timeMessageLabel.text
                                 sizeWithFont:self.timeMessageLabel.font
                            constrainedToSize:CGSizeMake(currentMessageColumnWidth, 1000)
                                lineBreakMode:UILineBreakModeCharacterWrap];

  if (subMessageSize.width + timeMessageSize.width + kSubMessageMarginRight < currentMessageColumnWidth) {
    if ([self.subMessageLabel.text isEqualToString:@""] || self.subMessageLabel.text.length == 0) {
      [self.timeMessageLabel greeChangeFrameX:self.subMessageLabel.frame.origin.x];
      [self.timeMessageLabel greeChangeFrameY:self.subMessageLabel.frame.origin.y + self.subMessageLabel.frame.size.height];
    } else {
      [self.timeMessageLabel greeChangeFrameX:self.subMessageLabel.frame.origin.x + self.subMessageLabel.frame.size.width + kSubMessageMarginRight];
      [self.timeMessageLabel greeChangeFrameY:self.subMessageLabel.frame.origin.y];
    }
  } else {
    [self.timeMessageLabel greeChangeFrameX:self.subMessageLabel.frame.origin.x];
    [self.timeMessageLabel greeChangeFrameY:self.subMessageLabel.frame.origin.y + self.subMessageLabel.frame.size.height];
  }
  [self.timeMessageLabel greeChangeFrameWidth:timeMessageSize.width];
  [self.timeMessageLabel greeChangeFrameHeight:timeMessageSize.height];
}

-(void)dealloc
{
  self.iconImageView = nil;
  self.mainMessageLabel = nil;
  self.subMessageLabel = nil;
  self.timeMessageLabel = nil;

  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

#pragma mark - Public Interface

-(CGFloat)cellHeight:(CGFloat)cellWidth
{
  if(cellWidth < kMinCellWidth) {
    cellWidth = kMinCellWidth;
  }

  CGFloat messageWidth;
  if (self.accessoryView.frame.size.width > 0) {
    messageWidth = cellWidth - (kIconColumnWidth + self.accessoryView.frame.size.width + kAccessoryColumnAddWidth);
  } else {
    messageWidth = cellWidth - (kIconColumnWidth -kMinAccessoryColumnWidth);
  }
  CGFloat cellHeight = kCellPaddingTop;
  cellHeight += [self.mainMessageLabel multiFontHeight:messageWidth];

  CGSize subMessageSize = [self.subMessageLabel.text
                                sizeWithFont:self.subMessageLabel.font
                           constrainedToSize:CGSizeMake(messageWidth, 1000)
                               lineBreakMode:UILineBreakModeCharacterWrap];

  CGSize timeMessageSize = [self.timeMessageLabel.text
                                 sizeWithFont:self.timeMessageLabel.font
                            constrainedToSize:CGSizeMake(messageWidth, 1000)
                                lineBreakMode:UILineBreakModeCharacterWrap];

  if ([self.subMessageLabel.text isEqualToString:@""] || self.subMessageLabel.text.length == 0) {
    cellHeight += timeMessageSize.height;
  } else {
    cellHeight += subMessageSize.height;
    if (subMessageSize.width + timeMessageSize.width + kSubMessageMarginRight < messageWidth) {
    } else {
      cellHeight += timeMessageSize.height;
    }
  }
  cellHeight += kCellPaddingBottom;

  CGFloat minHeight = kCellPaddingTop + kIconHeight + kCellPaddingBottom;
  if (cellHeight < minHeight) {
    cellHeight = minHeight;
  }
  return cellHeight;
}

@end
