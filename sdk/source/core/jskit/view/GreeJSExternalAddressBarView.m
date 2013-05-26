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


#import "GreeJSExternalAddressBarView.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"

static float const kButtonPadding = 5.0f;
static float const kButtonWidth   = 32.0f;
static float const kButtonHeight  = 28.0f;

@interface GreeJSExternalAddressBarView ()

@property (nonatomic, retain) UIButton* backButton;
@property (nonatomic, retain) UIButton* forwardButton;
@property (nonatomic, retain) UIButton* addressBarButton;
@property (nonatomic, retain) UILabel* addressBarLabel;
@property (nonatomic, retain) UIActivityIndicatorView* addressLoadingIndicator;

-(void)setupButtons;
-(void)setupTextField;

@end

@implementation GreeJSExternalAddressBarView

@synthesize backButtonEnabled = _backButtonEnabled;
@synthesize forwardButtonEnabled = _forwardButtonEnabled;
@synthesize addressBarText = _addressBarText;
@synthesize isLoading = _isLoading;

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    UIImage* image = [UIImage greeImageNamed:@"gree_URL_panel.png"];
    UIImage* stretchableImage = [image stretchableImageWithLeftCapWidth:100.0f topCapHeight:12.0f];
    UIImageView* viewView= [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
    viewView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth |
      UIViewAutoresizingFlexibleHeight;
    viewView.image = stretchableImage;
    [self addSubview:viewView];
    [self setupButtons];
    [self setupTextField];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  }
  return self;
}

-(void)dealloc
{
  self.delegate = nil;
  self.addressBarText = nil;
  self.addressBarLabel = nil;
  self.backButton = nil;
  self.forwardButton = nil;
  self.addressBarButton = nil;
  self.addressLoadingIndicator = nil;
  [super dealloc];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

#pragma mark - Internal Methods

-(void)setupButtons
{
  UIImage* backImage = [UIImage greeImageNamed:@"gree_btn_eb_back_default.png"];
  UIImage* backImageHighlight = [UIImage greeImageNamed:@"gree_btn_eb_back_highlight.png"];
  UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [backButton setImage:backImage forState:UIControlStateNormal];
  [backButton setImage:backImageHighlight forState:UIControlStateHighlighted];
  backButton.frame = CGRectMake(kButtonPadding,
                                (self.frame.size.height - backImage.size.height)/2,
                                backImage.size.width,
                                backImage.size.height);
  backButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [backButton addTarget:self.delegate
                 action:@selector(onAddressBarViewBackButtonTap:)
       forControlEvents:UIControlEventTouchUpInside];
  backButton.enabled = NO;
  self.backButton = backButton;

  UIImage* forwardImage = [UIImage greeImageNamed:@"gree_btn_eb_forward_default.png"];
  UIImage* forwardImageHighlight = [UIImage greeImageNamed:@"gree_btn_eb_forward_highlight.png"];
  UIButton* forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [forwardButton setImage:forwardImage forState:UIControlStateNormal];
  [forwardButton setImage:forwardImageHighlight forState:UIControlStateHighlighted];
  forwardButton.frame = CGRectMake(backButton.frame.size.width + kButtonPadding,
                                   backButton.frame.origin.y,
                                   forwardImage.size.width,
                                   forwardImage.size.height);
  forwardButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [forwardButton addTarget:self.delegate
                    action:@selector(onAddressBarViewForwardButtonTap:)
          forControlEvents:UIControlEventTouchUpInside];
  forwardButton.enabled = NO;
  self.forwardButton = forwardButton;

  [self addSubview:self.backButton];
  [self addSubview:self.forwardButton];
}

-(void)setupTextField
{
  
  CGRect rect = CGRectZero;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    rect = CGRectMake(90, 9, 640, 24);
  } else {
    rect = CGRectMake(90, 9, 190, 24);
  }
  UILabel* addressBarLabel = [[[UILabel alloc] initWithFrame:rect] autorelease];
  addressBarLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                     UIViewAutoresizingFlexibleBottomMargin |
                                     UIViewAutoresizingFlexibleRightMargin |
                                     UIViewAutoresizingFlexibleWidth;
  addressBarLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0f];
  addressBarLabel.backgroundColor = [UIColor clearColor];
  addressBarLabel.textColor = [UIColor grayColor];
  addressBarLabel.lineBreakMode = UILineBreakModeTailTruncation;
  self.addressBarLabel = addressBarLabel;
  [self addSubview:addressBarLabel];

  CGFloat adjust = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? (kButtonWidth / 2) : 0;

  CGRect aFrame = self.addressBarLabel.frame;
  UIButton* addressBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
  addressBarButton.frame = CGRectMake(aFrame.origin.x + aFrame.size.width - adjust,
                                      aFrame.origin.y,
                                      kButtonWidth,
                                      kButtonHeight);
  addressBarButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                      UIViewAutoresizingFlexibleBottomMargin |
                                      UIViewAutoresizingFlexibleLeftMargin;

  self.addressBarButton = addressBarButton;
  [self addSubview:addressBarButton];

  CGRect indicatorFrame = CGRectMake(addressBarButton.frame.origin.x,
                                     addressBarButton.frame.origin.y,
                                     20,
                                     20);
  UIActivityIndicatorView* addressLoadingIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame] autorelease];
  addressLoadingIndicator.center = addressBarButton.center;
  addressLoadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  addressLoadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                             UIViewAutoresizingFlexibleBottomMargin |
                                             UIViewAutoresizingFlexibleLeftMargin;

  self.addressLoadingIndicator = addressLoadingIndicator;
  [self addSubview:addressLoadingIndicator];
}

#pragma mark - Public Interface

-(void)setIsLoading:(BOOL)isLoading
{
  _isLoading = isLoading;

  if (self.isLoading) {
    [self.addressBarButton setImage:nil forState:UIControlStateNormal];
    [self.addressLoadingIndicator startAnimating];
  } else {
    [self.addressLoadingIndicator stopAnimating];
    UIImage* reloadImage = [UIImage greeImageNamed:@"gree_btn_URL_refresh_default.png"];
    [self.addressBarButton setImage:reloadImage forState:UIControlStateNormal];
    [self.addressBarButton addTarget:self.delegate
                              action:@selector(onAddressBarViewReloadButtonTap:)
                    forControlEvents:UIControlEventTouchUpInside];
  }
}

-(BOOL)isLoading
{
  return _isLoading;
}

-(void)setBackButtonEnabled:(BOOL)backButtonEnabled
{
  _backButtonEnabled = backButtonEnabled;
  self.backButton.enabled = backButtonEnabled;
}

-(BOOL)backButtonEnabled
{
  return _backButtonEnabled;
}

-(void)setForwardButtonEnabled:(BOOL)forwardButtonEnabled
{
  _forwardButtonEnabled = forwardButtonEnabled;
  self.forwardButton.enabled = forwardButtonEnabled;
}

-(BOOL)forwardButtonEnabled
{
  return _forwardButtonEnabled;
}

-(void)setAddressBarText:(NSString*)addressBarText
{
  if (_addressBarText == addressBarText) {
    return;
  }
  NSString* oldValue = _addressBarText;
  _addressBarText = [addressBarText copy];
  self.addressBarLabel.text = _addressBarText;

  [oldValue release];
}

-(NSString*)addressBarText
{
  return _addressBarText;
}

@end
