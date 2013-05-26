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

#import "GreeUniversalMenuViewCellSubviewExpander.h"
#import "GreeUniversalMenuDefinitions.h"
#import "UIImage+GreeAdditions.h"
#import "UIView+GreeAdditions.h"

@interface GreeUniversalMenuViewCellSubviewExpander ()
@property (nonatomic, retain) UIButton* arrowButton;
@end

@implementation GreeUniversalMenuViewCellSubviewExpander

@synthesize isExpanded = _isExpanded;

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];

    self.arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.arrowButton addTarget:self action:@selector(arrowButtonTapped:)forControlEvents:UIControlEventTouchUpInside];

    UIImage* normalImage = [UIImage greeImageNamed:@"um-icon_arw_expand.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"um-icon_arw_expand_tap.png"];
    UIImage* normalBgImage = [UIImage greeImageNamed:@"um-icon_arw_expand_bg.png"];
    UIImage* highlightedBgImage = [UIImage greeImageNamed:@"um-icon_arw_expand_bg_tap.png"];

    self.arrowButton.frame = CGRectMake(0.f, 0.f, normalBgImage.size.width, normalBgImage.size.height);
    [self.arrowButton greeChangeFrameX:kGreeUniversalMenuMidX - CGRectGetMidX(self.arrowButton.bounds)];
    [self.arrowButton greeChangeFrameY:CGRectGetMidY(self.bounds) - CGRectGetMidY(self.arrowButton.bounds)];
    [self.arrowButton setImage:normalImage forState:UIControlStateNormal];
    [self.arrowButton setImage:highlightedImage forState:UIControlStateHighlighted];
    [self.arrowButton setBackgroundImage:normalBgImage forState:UIControlStateNormal];
    [self.arrowButton setBackgroundImage:highlightedBgImage forState:UIControlStateHighlighted];
    [self addSubview:self.arrowButton];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sectionWillExpand:)
                                                 name:@"GreeUniversalMenuSectionWillExpand"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sectionWillCollapse:)
                                                 name:@"GreeUniversalMenuSectionWillCollapse"
                                               object:nil];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.arrowButton = nil;
  self.block = nil;
  [super dealloc];
}

-(void)drawRect:(CGRect)rect
{
  [self drawNormalCellBorderWithRect:rect];
}

-(void)sectionWillExpand:(NSNotification*)notification
{
  if ([[[notification userInfo] objectForKey:@"section"] integerValue] == self.section) {
    [UIView animateWithDuration:0.2 animations:^{
       [self setIsExpanded:YES];
     }];
  }
}

-(void)sectionWillCollapse:(NSNotification*)notification
{
  if ([[[notification userInfo] objectForKey:@"section"] integerValue] == self.section) {
    [UIView animateWithDuration:0.2 animations:^{
       [self setIsExpanded:NO];
     }];
  }
}

-(void)setIsExpanded:(BOOL)isExpanded
{
  _isExpanded = isExpanded;
  if (isExpanded) {
    int degree = 180;
    self.arrowButton.imageView.transform = CGAffineTransformMakeRotation(degree * M_PI/180);
  } else {
    self.arrowButton.imageView.transform = CGAffineTransformIdentity;
  }
}

-(BOOL)isExpanded
{
  return _isExpanded;
}

-(void)arrowButtonTapped:(id)sender
{
  if (self.block) {
    self.block(self);
  }
}

@end
