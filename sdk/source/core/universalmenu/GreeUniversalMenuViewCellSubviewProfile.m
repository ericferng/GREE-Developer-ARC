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

#import "GreeUniversalMenuViewCellSubviewProfile.h"
#import "GreeUniversalMenuDefinitions.h"
#import "GreeJSIconLoader.h"
#import <QuartzCore/QuartzCore.h>

@interface GreeUniversalMenuViewCellSubviewProfile ()
@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) NSURL* privateIconURL;
@end

@implementation GreeUniversalMenuViewCellSubviewProfile

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    static const CGFloat IconSize = 68;
    static const CGFloat IconBorderWidth = 3;
    static const CGFloat LabelX = (kGreeUniversalMenuBasePadding
                                   + IconBorderWidth
                                   + IconSize
                                   + IconBorderWidth
                                   + kGreeUniversalMenuBasePadding);
    static const CGFloat LabelWidth = (kGreeUniversalMenuWidth
                                       - LabelX
                                       - kGreeUniversalMenuBasePadding);
    static const CGFloat NicknameFontSize = 18;
    static const CGFloat NameFontSize = kGreeUniversalMenuSubTextFontSize;
    static const CGFloat LabelPaddingFromMidY = 2.5f;
    static const CGFloat NicknameLabelY = (kGreeUniversalMenuProfileHeight / 2
                                           - LabelPaddingFromMidY * 2
                                           - NicknameFontSize);
    static const CGFloat NicknameLabelHeight = (NicknameFontSize + LabelPaddingFromMidY * 2);
    static const CGFloat NameLabelY = (kGreeUniversalMenuProfileHeight / 2);
    static const CGFloat NameLabelHeight = (NameFontSize + LabelPaddingFromMidY * 2);

    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuTitleBackground];

    self.icon = [[[UIImageView alloc] initWithFrame:CGRectMake(kGreeUniversalMenuBasePadding,
                                                               kGreeUniversalMenuBasePadding,
                                                               IconSize,
                                                               IconSize)] autorelease];
    self.icon.layer.borderWidth = IconBorderWidth;
    self.icon.layer.borderColor = [[UIColor whiteColor] CGColor];

    self.nickname = [[[UILabel alloc] initWithFrame:CGRectMake(LabelX, NicknameLabelY, LabelWidth, NicknameLabelHeight)] autorelease];
    self.nickname.font = [UIFont fontWithName:@"Helvetica-Bold" size:NicknameFontSize];
    self.nickname.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuTitleBackground];
    self.nickname.textColor = [UIColor greeColorWithHex:kGreeUniversalMenuListText];

    self.name = [[[UILabel alloc] initWithFrame:CGRectMake(LabelX, NameLabelY, LabelWidth, NameLabelHeight)] autorelease];
    self.name.font = [UIFont fontWithName:@"Helvetica" size:NameFontSize];
    self.name.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuTitleBackground];
    self.name.textColor = [UIColor greeColorWithHex:kGreeUniversalMenuListText];

    [self addSubview:self.nickname];
    [self addSubview:self.name];
    [self addSubview:self.icon];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.icon = nil;
  self.privateIconURL = nil;
  [super dealloc];
}

-(void)drawRect:(CGRect)rect
{
  CGFloat borderSize = 1.0f;
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, [UIColor greeColorWithHex:kGreeUniversalMenuTitleBorderBottom].CGColor);
  CGContextFillRect(context, CGRectMake(0.0f, self.frame.size.height - borderSize, self.frame.size.width, borderSize));
}

-(void)setIconURL:(NSURL*)url
{
  self.privateIconURL = url;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(iconDidLoad:)
                                               name:(NSString*)kGreeIconDidLoadNotification
                                             object:nil];
  [[GreeJSIconLoader sharedIconLoader] requestIconForKey:url];
}

-(void)iconDidLoad:(NSNotification*)notification
{
  UIImage* image = [[notification userInfo] objectForKey:[self.privateIconURL absoluteString]];
  if (image) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.icon.image = image;
  }
}

@end
