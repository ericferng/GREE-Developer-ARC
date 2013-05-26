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
#import "GreeUniversalMenuViewCellSubviewNormal.h"
#import "GreeUniversalMenuDefinitions.h"
#import "GreeJSIconLoader.h"
#import "UIImage+GreeAdditions.h"
#import "UIView+GreeAdditions.h"

@interface GreeUniversalMenuViewCellSubviewNormal ()
@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UIImageView* badgeImageL;
@property (nonatomic, retain) UIImageView* badgeImageC;
@property (nonatomic, retain) UIImageView* badgeImageR;
@property (nonatomic, retain) UILabel* badgeLabel;
@property (nonatomic, retain) NSURL* iconURL;
@end

@implementation GreeUniversalMenuViewCellSubviewNormal

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    static const CGFloat BorderTopHeight = 1;
    static const CGFloat BorderBottomHeight = 1;

    static const CGFloat TitleLabelY = BorderTopHeight;
    static const CGFloat TitleLabelHeight = (kGreeUniversalMenuNormalCellHeight
                                             - BorderTopHeight
                                             - BorderBottomHeight);
    static const CGFloat BadgeImageHeight = 24;
    static const CGFloat BadgeImageY = (kGreeUniversalMenuNormalCellHeight / 2
                                        - BadgeImageHeight / 2);

    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];

    self.title = [[[UILabel alloc] initWithFrame:CGRectMake(0,
                                                            TitleLabelY,
                                                            0,
                                                            TitleLabelHeight)] autorelease];
    self.title.font = [UIFont fontWithName:@"Helvetica-Bold" size:kGreeUniversalMenuBaseFontSize];
    self.title.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];
    self.title.textColor = [UIColor greeColorWithHex:kGreeUniversalMenuListText];
    self.title.shadowColor = [UIColor greeColorWithHex:kGreeUniversalMenuListTextShadow];
    self.title.shadowOffset = CGSizeMake(0, -1);

    self.icon = [[[UIImageView alloc] initWithFrame:CGRectMake(kGreeUniversalMenuBasePadding,
                                                               kGreeUniversalMenuBasePadding,
                                                               kGreeUniversalMenuBaseIconSize,
                                                               kGreeUniversalMenuBaseIconSize)] autorelease];

    self.badgeImageL = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"um-icon_badge_l.png"]] autorelease];
    [self.badgeImageL greeChangeFrameY:BadgeImageY];
    self.badgeImageC = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"um-icon_badge_c.png"]] autorelease];
    [self.badgeImageC greeChangeFrameY:BadgeImageY];
    self.badgeImageR = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"um-icon_badge_r.png"]] autorelease];
    [self.badgeImageR greeChangeFrameY:BadgeImageY];

    self.badgeLabel = [[[UILabel alloc] init] autorelease];
    [self.badgeLabel greeChangeFrameY:BadgeImageY];
    [self.badgeLabel greeChangeFrameHeight:BadgeImageHeight];
    self.badgeLabel.backgroundColor = [UIColor clearColor];
    self.badgeLabel.textColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBadgeText];
    self.badgeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:kGreeUniversalMenuSubTextFontSize];
    self.badgeValue = 0;

    [self addSubview:self.title];
    [self addSubview:self.icon];
    [self addSubview:self.badgeLabel];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.title = nil;
  self.icon = nil;
  self.badgeImageL = nil;
  self.badgeImageC = nil;
  self.badgeImageR = nil;
  self.badgeLabel = nil;
  self.iconURL = nil;
  [super dealloc];
}

-(void)drawRect:(CGRect)rect
{
  if ([self layoutBadge]) {
    [self.badgeImageL.image drawAtPoint:self.badgeImageL.frame.origin];
    [self.badgeImageR.image drawAtPoint:self.badgeImageR.frame.origin];
    for (CGFloat i = self.badgeImageL.frame.origin.x + self.badgeImageL.frame.size.width;
         i < self.badgeImageR.frame.origin.x;
         i += 1.0f) {
      [self.badgeImageC.image drawAtPoint:CGPointMake(i, self.badgeImageC.frame.origin.y)];
    }
  }

  [self drawNormalCellBorderWithRect:rect];
}

-(void)setIconURL:(NSURL*)url cache:(BOOL)cache
{
  self.icon.image = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.iconURL = url;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(iconDidLoad:)
                                               name:(NSString*)kGreeIconDidLoadNotification
                                             object:nil];
  NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSValue valueWithCGSize:CGSizeMake(kGreeUniversalMenuBaseIconSize, kGreeUniversalMenuBaseIconSize)], @"size",
                           [NSNumber numberWithFloat:5], @"cornerRadius",
                           [NSNumber numberWithBool:cache], @"cache", nil];
  [[GreeJSIconLoader sharedIconLoader] requestIconForKey:url options:options];
}

-(void)setBadgeValue:(NSUInteger)badgeValue
{
  _badgeValue = badgeValue;

  if (badgeValue == 0) {
    self.badgeLabel.enabled = NO;
    self.badgeLabel.hidden = YES;
  } else {
    self.badgeLabel.enabled = YES;
    self.badgeLabel.hidden = NO;
    self.badgeLabel.text = [[NSNumber numberWithUnsignedInteger:badgeValue] stringValue];
  }
}

-(void)setIconEnabled:(BOOL)iconEnabled
{
  _iconEnabled = iconEnabled;
  [self layoutIcon];
  [self layoutTitle];
}

-(void)iconDidLoad:(NSNotification*)notification
{
  UIImage* image = [[notification userInfo] objectForKey:[self.iconURL absoluteString]];
  if (image) {
    self.icon.image = image;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

-(void)layoutIcon
{
  self.icon.hidden = !self.iconEnabled;
}

-(void)layoutTitle
{
  CGFloat titleLabelX = kGreeUniversalMenuBasePadding;

  if (self.iconEnabled) {
    titleLabelX += kGreeUniversalMenuBaseIconSize + kGreeUniversalMenuBasePadding;
  }

  CGFloat titleLabelWidth = (kGreeUniversalMenuWidth
                             - titleLabelX
                             - kGreeUniversalMenuBasePadding);

  [self.title greeChangeFrameX:titleLabelX];
  [self.title greeChangeFrameWidth:titleLabelWidth];
}

-(BOOL)layoutBadge
{
  if (self.badgeValue == 0) {
    CGFloat xFromRight = kGreeUniversalMenuWidth;
    xFromRight -= kGreeUniversalMenuBasePadding;
    CGFloat xFromLeft = self.title.frame.origin.x;
    CGFloat titleWidth = xFromRight - xFromLeft;

    [self.title greeChangeFrameWidth:titleWidth];
    return NO;
  }

  static const CGFloat BadgePaddingRight = 6;
  static const CGFloat BadgePaddingLeft = 6;
  CGFloat textWidthMin = BadgePaddingRight + 1.0f + BadgePaddingLeft;
  CGFloat textWidth = [self.badgeLabel.text sizeWithFont:self.badgeLabel.font].width;
  CGFloat textMarginLeft = 0;
  if (textWidth < textWidthMin) {
    textMarginLeft = (textWidthMin - textWidth) / 2;
    textWidth = textWidthMin;
  }

  CGFloat xFromRight = kGreeUniversalMenuWidth;

  xFromRight -= kGreeUniversalMenuBasePadding;

  CGFloat badgeLabelRX = xFromRight - self.badgeImageR.bounds.size.width;
  xFromRight -= BadgePaddingRight;

  CGFloat badgeLabelX = xFromRight - textWidth + textMarginLeft;
  xFromRight -= textWidth;

  xFromRight -= BadgePaddingLeft;
  CGFloat badgeImageLX = xFromRight;

  xFromRight -= kGreeUniversalMenuBasePadding;
  CGFloat xFromLeft = self.title.frame.origin.x;
  CGFloat titleWidth = xFromRight - xFromLeft;

  [self.badgeImageL greeChangeFrameX:badgeImageLX];
  [self.badgeImageR greeChangeFrameX:badgeLabelRX];
  [self.badgeLabel greeChangeFrameX:badgeLabelX];
  [self.badgeLabel greeChangeFrameWidth:textWidth];
  [self.title greeChangeFrameWidth:titleWidth];

  return YES;
}

@end
