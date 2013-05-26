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

#import "GreeJSSubnavigationIconView.h"

static float const kLabelTopPadding           = 1.0f;
static float const kLabelLandscapeLeftPadding = 2.0f;
static float const kLabelHeight               = 14.0f; // kSubnavigationIconLabelFontSize + 2.0f
static float const kImageHeight               = 30.0f;
static float const kImageWidth                = 30.0f;
static float const kImagePortraitTopPadding   = 2.0f;
static NSString* const kLabelKey    = @"label";
static NSString* const kCallbackKey = @"callback";
static NSString* const kIconKey     = @"icon";
static NSString* const kSelectedKey = @"selected";
static int const kSelectedTrueValue = 1;

@interface GreeJSSubnavigationIconView ()

@property (nonatomic, assign) UIImageView* iconImageView;
@property (nonatomic, assign) UILabel* label;
@property (nonatomic, copy) NSString* iconName;

@end


@implementation GreeJSSubnavigationIconView


#pragma mark -
#pragma mark Object Lifecycle

-(id)initWithNormalImage:(UIImage*)normalImage
           selectedImage:(UIImage*)selectedImage
                  params:(NSDictionary*)params
                delegate:(NSObject<GreeJSSubnavigationMenuButtonDelegate>*)delegate
{
  self = [super init];
  if (self) {
    self.delegate = delegate;
    self.autoresizingMask =
      UIViewAutoresizingFlexibleHeight |
      UIViewAutoresizingFlexibleWidth;
    self.normalImage = normalImage;
    self.selectedImage = selectedImage;
    self.iconImageView = [[[UIImageView alloc] initWithImage:self.normalImage] autorelease];
    [self addSubview:self.iconImageView];

    // Instantiate label, add as subview.
    self.label = [[[UILabel alloc] init] autorelease];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.text = [params objectForKey:kLabelKey];
    float hex = 255.0f;
    [self.label setShadowColor:[UIColor colorWithRed:0x0c/hex
                                               green:0x1e/hex
                                                blue:0x1f/hex
                                               alpha:1.0f]];
    self.label.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.label.font = [UIFont fontWithName:kSubnavigationIconLabelFont size:kSubnavigationIconLabelFontSize];
    [self addSubview:self.label];

    self.callback = [params objectForKey:kCallbackKey];
    [self   addTarget:self.delegate
               action:@selector(onSubnavigationMenuButtonIconTap:)
     forControlEvents:UIControlEventTouchUpInside];

    self.selected = [[params objectForKey:kSelectedKey] intValue] == kSelectedTrueValue ? YES : NO;
  }
  return self;
}

-(void)dealloc
{
  self.iconName = nil;
  self.labelString = nil;
  self.callback = nil;
  self.callbackParams = nil;
  self.normalImage = nil;
  self.selectedImage = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
  self.iconImageView.backgroundColor = [UIColor clearColor];
  self.label.backgroundColor = [UIColor clearColor];

  CGSize imageSize = CGSizeMake(kSubnavigationIconImageWidth, kSubnavigationIconImageHeight);
  CGRect imageViewRect = CGRectMake(0, 0, imageSize.width, imageSize.height);

  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    imageViewRect.origin.x = (self.frame.size.width - imageSize.width)/2;

    self.iconImageView.frame = CGRectMake((self.frame.size.width - kImageWidth)/2,
                                          kImagePortraitTopPadding,
                                          kImageWidth,
                                          kImageHeight);

    self.label.frame = CGRectMake(0,
                                  imageViewRect.origin.y + kImagePortraitTopPadding + \
                                  self.iconImageView.bounds.size.height + kLabelTopPadding,
                                  self.bounds.size.width,
                                  kLabelHeight);

    self.label.textAlignment = UITextAlignmentCenter;
  } else {
    CGSize labelSize = CGSizeMake(self.frame.size.width - kImageWidth - kLabelLandscapeLeftPadding, kLabelHeight);
    CGSize textSize = [self.label.text sizeWithFont:[UIFont fontWithName:kSubnavigationIconLabelFont size:kSubnavigationIconLabelFontSize]
                                  constrainedToSize:labelSize
                                      lineBreakMode:UILineBreakModeTailTruncation];
    imageViewRect.origin.x = (self.frame.size.width - kImageWidth - kLabelLandscapeLeftPadding - textSize.width)/2;

    self.iconImageView.frame = CGRectMake(imageViewRect.origin.x,
                                          (self.frame.size.height - kImageHeight)/2,
                                          kImageWidth,
                                          kImageHeight);

    self.label.frame = CGRectMake(imageViewRect.origin.x + kImageWidth + kLabelLandscapeLeftPadding,
                                  roundf((self.frame.size.height - kLabelHeight)/2),
                                  labelSize.width,
                                  labelSize.height);
    self.label.textAlignment = UITextAlignmentLeft;
  }
}


#pragma mark - UIButton Overrides

-(void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  float hex = 255.0f;
  if (selected) {
    self.iconImageView.image = self.selectedImage;
    self.label.textColor = [UIColor colorWithRed:0xff/hex
                                           green:0xff/hex
                                            blue:0xff/hex
                                           alpha:1.0f];
    self.backgroundColor = [UIColor colorWithRed:0x22/hex
                                           green:0x22/hex
                                            blue:0x22/hex
                                           alpha:1.0f];
  } else {
    self.iconImageView.image = self.normalImage;
    self.label.textColor = [UIColor colorWithRed:0x8c/hex
                                           green:0x91/hex
                                            blue:0x94/hex
                                           alpha:1.0f];
    self.backgroundColor = [UIColor clearColor];
  }
}

-(void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  float hex = 255.0f;
  if (highlighted || self.selected) {
    self.backgroundColor = [UIColor colorWithRed:0x22/hex
                                           green:0x22/hex
                                            blue:0x22/hex
                                           alpha:1.0f];
    self.iconImageView.image = self.selectedImage;
    self.label.textColor = [UIColor colorWithRed:0xff/hex
                                           green:0xff/hex
                                            blue:0xff/hex
                                           alpha:1.0f];
  } else {
    self.backgroundColor = [UIColor clearColor];
    self.iconImageView.image = self.normalImage;
    self.label.textColor = [UIColor colorWithRed:0x8c/hex
                                           green:0x91/hex
                                            blue:0x94/hex
                                           alpha:1.0f];
  }
}

#pragma mark -
#pragma mark - Public Interface

-(void)setSelectedImage:(UIImage*)image
{
  if (self.selected == YES) {
    self.iconImageView.image = image;
  }
  if (_selectedImage != image) {
    [_selectedImage release];
    _selectedImage = [image retain];
  }
}

-(void)setNormalImage:(UIImage*)image
{
  if (self.selected == NO) {
    self.iconImageView.image = image;
  }
  if (_normalImage != image) {
    [_normalImage release];
    _normalImage = [image retain];
  }
}

@end
