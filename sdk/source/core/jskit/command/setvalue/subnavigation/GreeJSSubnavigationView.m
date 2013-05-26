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

#import "GreeJSSubnavigationView.h"
#import "GreeJSSubnavigationMenuView.h"


@interface GreeJSSubnavigationView ()
@property (nonatomic, readwrite, retain) GreeJSSubnavigationMenuView* menuView;
@end

@implementation GreeJSSubnavigationView

#pragma mark -
#pragma mark Object Lifecycle

-(id)initWithDelegate:(NSObject<GreeJSSubnavigationMenuButtonDelegate>*)delegate
{
  if ((self = [super init])) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.autoresizesSubviews = YES;
    self.opaque = YES;
    self.menuView = [[[GreeJSSubnavigationMenuView alloc] init] autorelease];
    self.menuView.delegate = delegate;
    self.menuView.opaque = YES;
    [self addSubview:self.menuView];
  }
  return self;
}

-(void)dealloc
{
  self.menuView = nil;
  [_contentView release];
  _contentView = nil;
  [super dealloc];
}

-(BOOL)configureSubnavigationMenuWithParams:(NSDictionary*)params
{
  BOOL b = [self.menuView configureSubnavigationMenuWithParams:params];
  [self setNeedsLayout];
  return b;
}

#pragma mark - Public Interface

-(void)setContentView:(UIView*)view
{
  if (view != _contentView) {
    [_contentView release];
    _contentView = [view retain];
  }
  [self insertSubview:_contentView belowSubview:self.menuView];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
  [self setNeedsLayout];
}

-(void)setSelectedIconAtIndex:(NSInteger)index
{
  for (int i = 0; i < [self.menuView.icons count]; i++) {
    if (i == index) {
      [[self.menuView.icons objectAtIndex:i] setSelected:YES];
    } else {
      [[self.menuView.icons objectAtIndex:i] setSelected:NO];
    }
  }
}

#pragma mark -
#pragma mark UIView Overrides

-(void)layoutSubviews
{
  // Subnavi height is equal to size of navigation bar.
  
  CGRect parentFrame = self.bounds;

  float subnaviHeight;
  if ([self.menuView visible]) {
    subnaviHeight = (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 35.0f : 48.0f);
  } else {
    subnaviHeight = 0;
  }

  self.menuView.frame = CGRectMake(0, 0, parentFrame.size.width, subnaviHeight);
  self.contentView.frame = CGRectMake(0, subnaviHeight, parentFrame.size.width, parentFrame.size.height - subnaviHeight);

  [self.menuView setNeedsLayout];
  [self.contentView setNeedsLayout];
  [super layoutSubviews];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
