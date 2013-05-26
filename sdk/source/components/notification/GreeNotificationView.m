//
// Copyright 2011 GREE, Inc.
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

#import "GreeNotificationView.h"
#import "UIImage+GreeAdditions.h"

#define CGColorFromRGB(rgbValue) [[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0] CGColor]
#define IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

const static CGFloat messageLabelOriginX = 40.0f;
const static CGFloat messageLabelRightMargin = 5.0f;
const static CGFloat messageLabelFontSize_iPhone = 12.0f;
const static CGFloat messageLabelFontSize_iPad = 18.0f;
const static NSInteger messageLabelFontColor_iPhone = 0x808080;
const static NSInteger messageLabelFontColor_iPad = 0xC6C6C6;

const static CGFloat iconOriginX = 10.0f;
const static CGFloat iconOriginY = 10.0f;
const static CGFloat iconWidth = 24.0f;
const static CGFloat iconHeight = 24.0f;
const static CGFloat iconCornerRadius = 4.0f;

const static CGFloat arrowWidth = 10.0f;
const static CGFloat arrowRightMargin = 10.0f;

const static CGFloat badgeRightMargin = 5.0f;
const static CGFloat badgeExtraWidth = 16.0f;
const static CGFloat badgeExtraHeight = 8.0f;
const static CGFloat badgeCornerRadius = 12.0f;
const static NSInteger badgeBackgroundColorTop = 0xFF3333;
const static NSInteger badgeBackgroundColorBottom = 0xDD0000;
const static CGFloat badgeFontSize_iPhone = 14.0f;
const static CGFloat badgeFontSize_iPad = 16.0f;

const static CGFloat closeButtonWidth = 20.0f;
const static CGFloat closeButtonHeight = 44.0f;
const static CGFloat closeButtonBuffer = 20.0f;

@implementation GreeNotificationView

-(id)initWithMessage:(NSString*)aMessage icon:(UIImage*)anImage frame:(CGRect)aFrame
{
  return [self initWithMessage:aMessage icon:anImage badgeString:nil frame:aFrame];
}

-(id)initWithMessage:(NSString*)aMessage icon:(UIImage*)anImage badgeString:(NSString*)aBadgeString frame:(CGRect)aFrame
{
  self = [super initWithFrame:aFrame];
  if (self) {
    UIImage* backImage = [UIImage greeImageNamed:@"notifications_panel.png"];
    UIImageView* background = [[UIImageView alloc] initWithImage:backImage];
    CGRect backFrame = CGRectMake(0, 0, aFrame.size.width, aFrame.size.height);
    background.frame = backFrame;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:background];
    [background release];

    UIImageView* arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(
                                aFrame.size.width - arrowRightMargin - arrowWidth,
                                0.0,
                                arrowWidth,
                                aFrame.size.height
                                )];
    arrowView.image = [UIImage greeImageNamed:@"gree_caret_white.png"];
    arrowView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    arrowView.contentMode = UIViewContentModeCenter;
    [self addSubview:arrowView];
    [arrowView release];

    if(aBadgeString) {
      UIFont* badgeFont = [UIFont fontWithName:@"Helvetica-Bold" size:IPAD ? badgeFontSize_iPad : badgeFontSize_iPhone];
      CGSize badgeSize = [aBadgeString sizeWithFont:badgeFont];
      badgeSize.width += badgeExtraWidth;
      badgeSize.height += badgeExtraHeight;

      UIView* badgeView = [[UIView alloc] initWithFrame:CGRectMake(
                             aFrame.size.width - arrowRightMargin - arrowWidth - badgeRightMargin - badgeSize.width,
                             (aFrame.size.height - badgeSize.height) / 2.0f,
                             badgeSize.width,
                             badgeSize.height
                             )];
      badgeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

      CAGradientLayer* gradient = [CAGradientLayer layer];
      [gradient setFrame:[badgeView bounds]];
      [gradient setColors:[NSArray arrayWithObjects:(id)CGColorFromRGB(badgeBackgroundColorTop), (id)CGColorFromRGB(badgeBackgroundColorBottom), nil]];
      gradient.cornerRadius = badgeCornerRadius;
      [badgeView.layer addSublayer:gradient];

      UILabel* badgeLabel = [[UILabel alloc] initWithFrame:[badgeView bounds]];
      badgeLabel.backgroundColor = [UIColor clearColor];
      badgeLabel.textColor = [UIColor whiteColor];
      badgeLabel.font = badgeFont;
      badgeLabel.text = aBadgeString;
      badgeLabel.textAlignment = UITextAlignmentCenter;
      badgeLabel.layer.shadowColor = CGColorFromRGB(badgeBackgroundColorBottom);
      badgeLabel.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
      badgeLabel.layer.shadowRadius = 0.0f;
      badgeLabel.layer.shadowOpacity = 1.0f;
      [badgeView addSubview:badgeLabel];
      [badgeLabel release];

      [self addSubview:badgeView];
      [badgeView release];

      self.messageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                              messageLabelOriginX,
                              0.0f,
                              badgeView.frame.origin.x - messageLabelOriginX - messageLabelRightMargin,
                              aFrame.size.height
                              )] autorelease];
    } else {
      self.messageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                              messageLabelOriginX,
                              0.0f,
                              arrowView.frame.origin.x - messageLabelOriginX - messageLabelRightMargin,
                              aFrame.size.height
                              )] autorelease];
    }

    self.messageLabel.text = aMessage;
    self.messageLabel.textColor = (id)CGColorFromRGB(IPAD ? messageLabelFontColor_iPad : messageLabelFontColor_iPhone);
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.baselineAdjustment = UIBaselineAdjustmentNone;
    self.messageLabel.font = [UIFont fontWithName:IPAD ? @"Helvetica-Bold": @"Helvetica" size:IPAD ? messageLabelFontSize_iPad : messageLabelFontSize_iPhone];

    self.messageLabel.numberOfLines = 2;
    self.messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.messageLabel];

    self.iconView = [[[UIImageView alloc] initWithImage:anImage] autorelease];
    self.iconView.frame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
    self.iconView.layer.cornerRadius = iconCornerRadius;
    self.iconView.layer.masksToBounds = YES;
    [self addSubview:self.iconView];

    _showsCloseButton = NO;
    self.messageLabel.textColor = [UIColor whiteColor];

    [self setAccessibilityLabel:aMessage];
  }
  return self;
}

-(void)dealloc
{
  self.iconView = nil;
  self.messageLabel = nil;
  self.closeButton = nil;
  self.notification = nil;
  [super dealloc];
}

-(void)setShowsCloseButton:(BOOL)showsCloseButton
{
  if (showsCloseButton && !self.closeButton) {
    self.closeButton = [[[UIButton alloc] initWithFrame:CGRectMake(
                           self.bounds.size.width - closeButtonBuffer,
                           (self.bounds.size.height / 2.0f) - (closeButtonHeight / 2.0f),
                           closeButtonWidth,
                           closeButtonHeight
                           )] autorelease];

    [self.closeButton setImage:[UIImage greeImageNamed:@"gree_notification_close_white.png"] forState:UIControlStateNormal];
    self.closeButton.accessibilityLabel = @"Close";

    [self addSubview:self.closeButton];

  } else if (!showsCloseButton) {
    [self.closeButton removeFromSuperview];
    self.closeButton = nil;

  }
  _showsCloseButton = showsCloseButton;
}

#pragma mark - NSObject overrides
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, message:%@, frame:%@, showsCloseButton:%@>",
          NSStringFromClass([self class]),
          self,
          self.messageLabel.text,
          NSStringFromCGRect(self.frame),
          self.showsCloseButton ? @"YES": @"NO"];
}

@end
