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
#import "GreeJSPullToRefreshHeaderView.h"
#import "UIImage+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreeJSLoadingIndicatorView.h"

@interface GreeJSPullToRefreshHeaderView ()
-(void)setupSubViews;
@end

@implementation GreeJSPullToRefreshHeaderView


#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.textPullToRefresh = GreePlatformString(@"GreeJS.PullToRefreshHeaderView.PullToRefresh", @"Pull To Refresh");
    self.textReleaseToRefresh = GreePlatformString(@"GreeJS.PullToRefreshHeaderView.ReleaseToRefresh", @"Release To Refresh");
    self.textNowLoading = GreePlatformString(@"GreeJS.PullToRefreshHeaderView.NowLoading", @"Now Loading...");
    self.textFormatUpdateTime = GreePlatformString(@"GreeJS.PullToRefreshHeaderView.LastUpdated", @"Last Updated: %@");

    [self setupSubViews];
    self.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
  }
  return self;
}

-(void)dealloc
{
  self.refreshLabel = nil;
  self.refreshUpdateLabel = nil;
  self.refreshArrow = nil;
  self.refreshSpinner = nil;

  self.textPullToRefresh = nil;
  self.textReleaseToRefresh = nil;
  self.textNowLoading = nil;
  self.textFormatUpdateTime = nil;

  [super dealloc];
}


#pragma mark - Public Interface

-(void)updateTimeOfRefreshed
{
  NSDate* now= [NSDate date];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setLocale:[NSLocale currentLocale]];
  [formatter setDateStyle:kCFDateFormatterMediumStyle];
  [formatter setTimeStyle:NSDateFormatterShortStyle];
  NSString* result = [formatter stringFromDate:now];
  self.refreshUpdateLabel.text = [NSString stringWithFormat:self.textFormatUpdateTime, result];
  [formatter release];
}
-(void)nowLoading:(BOOL)nowLoading
{
  if (nowLoading) {
    self.refreshLabel.text = self.textNowLoading;
    self.refreshArrow.hidden = YES;
    self.refreshSpinner.hidden = NO;
  } else {
    self.refreshLabel.text = self.textPullToRefresh;
    self.refreshArrow.hidden = NO;
    self.refreshSpinner.hidden = YES;
  }
}


#pragma mark - Internal Methods

-(void)setupSubViews
{
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;

  self.frame = CGRectMake(0, 0 - kGreeJSRefreshHeaderHeight, screenWidth, kGreeJSRefreshHeaderHeight);
  self.backgroundColor = [UIColor colorWithRed:HEXCOLOR(0xF7)
                                         green:HEXCOLOR(0xF7)
                                          blue:HEXCOLOR(0xF7)
                                         alpha:1.0f];

  self.refreshLabel = [[[UILabel alloc] init] autorelease];
  self.refreshLabel.backgroundColor = [UIColor clearColor];
  self.refreshLabel.font = [UIFont boldSystemFontOfSize:14.0f];
  self.refreshLabel.textColor = [UIColor colorWithRed:HEXCOLOR(0x33)
                                                green:HEXCOLOR(0x44)
                                                 blue:HEXCOLOR(0x55)
                                                alpha:1.0f];
  self.refreshLabel.shadowColor = [UIColor colorWithRed:HEXCOLOR(0xf7)
                                                  green:HEXCOLOR(0xf8)
                                                   blue:HEXCOLOR(0xf9)
                                                  alpha:1.0f];
  self.refreshLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
  self.refreshLabel.layer.shadowRadius = 0.0;

  self.refreshLabel.textAlignment = UITextAlignmentCenter;
  self.refreshLabel.text = self.textPullToRefresh;

  self.refreshUpdateLabel = [[[UILabel alloc] init] autorelease];
  self.refreshUpdateLabel.backgroundColor = [UIColor clearColor];
  self.refreshUpdateLabel.font = [UIFont systemFontOfSize:13.0f];
  self.refreshUpdateLabel.textColor = [UIColor colorWithRed:HEXCOLOR(0x77)
                                                      green:HEXCOLOR(0x88)
                                                       blue:HEXCOLOR(0x99)
                                                      alpha:1.0f];
  self.refreshUpdateLabel.shadowColor = [UIColor colorWithRed:HEXCOLOR(0xf7)
                                                        green:HEXCOLOR(0xf8)
                                                         blue:HEXCOLOR(0xf9)
                                                        alpha:1.0f];
  self.refreshUpdateLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
  self.refreshUpdateLabel.layer.shadowRadius = 0.0;

  self.refreshUpdateLabel.textAlignment = UITextAlignmentCenter;
  [self updateTimeOfRefreshed];

  self.refreshArrow = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"gree_pull_to_refresh_arrow.png"]] autorelease];
  self.refreshArrow.frame = CGRectMake((kGreeJSRefreshHeaderHeight - 27) / 2,
                                       (kGreeJSRefreshHeaderHeight - 44) / 2,
                                       27, 44);
  self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.refreshSpinner = [[[GreeJSLoadingIndicatorView alloc] initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypePullToRefresh] autorelease];
  self.refreshSpinner.frame = CGRectMake((kGreeJSRefreshHeaderHeight - 24) / 2, (kGreeJSRefreshHeaderHeight - 24) / 2, 24, 24);
  self.refreshSpinner.hidden = YES;
  self.autoresizingMask = self.refreshArrow.autoresizingMask;

  [self addSubview:self.refreshLabel];
  [self addSubview:self.refreshUpdateLabel];
  [self addSubview:self.refreshArrow];
  [self addSubview:self.refreshSpinner];
}

#pragma mark - UIView overrides
-(void)layoutSubviews
{
  CGRect bounds = self.superview.bounds;
  self.refreshLabel.frame = CGRectMake(0, kGreeJSRefreshLabelOffset, bounds.size.width, kGreeJSRefreshLabelHeight);
  self.refreshUpdateLabel.frame = CGRectMake(0,
                                             self.refreshLabel.frame.size.height + kGreeJSRefreshLabelOffset,
                                             bounds.size.width,
                                             kGreeJSRefreshLabelHeight);
  self.refreshSpinner.frame = CGRectMake((kGreeJSRefreshHeaderHeight - 24) / 2, (kGreeJSRefreshHeaderHeight - 24) / 2, 24, 24);
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

@end
