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


#import <UIKit/UIKit.h>

#define HEXCOLOR(n) (((float)n)/ 255.0f)
static float const kGreeJSRefreshHeaderHeight = 60.0f;
static float const kGreeJSRefreshHeaderMargin = 10.0f;

static float const kGreeJSRefreshLabelOffset = 15.0f;
static float const kGreeJSRefreshLabelHeight = 20.0f;

@class GreeJSLoadingIndicatorView;

@interface GreeJSPullToRefreshHeaderView : UIView

@property (nonatomic, retain) UILabel* refreshLabel;
@property (nonatomic, retain) UILabel* refreshUpdateLabel;
@property (nonatomic, retain) UIImageView* refreshArrow;
@property (nonatomic, retain) GreeJSLoadingIndicatorView* refreshSpinner;
@property (nonatomic, copy) NSString* textPullToRefresh;
@property (nonatomic, copy) NSString* textReleaseToRefresh;
@property (nonatomic, copy) NSString* textNowLoading;
@property (nonatomic, copy) NSString* textFormatUpdateTime;

-(void)updateTimeOfRefreshed;
-(void)nowLoading:(BOOL)nowLoading;

@end
