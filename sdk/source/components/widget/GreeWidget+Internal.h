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
#import "GreeWidget.h"
#import "GreeSettings.h"

#define GreeWidgetBarDimentionHeight (30)
#define RGBA(r, g, b, a) ((r)/255.0f), ((g)/255.0f), ((b)/255.0f), (a)

static const CGFloat GreeWidgetBubbleTopEdge = 4.;
static const CGFloat GreeWidgetBubbleBottomEdge = 6.; //this value is acquired by experimenting

@interface UIFont (GreeWidget)
+(UIFont*)fontForGreeWidgetBadgeLabel;
@end

typedef void (^GreeWidgetItemCallbackBlock)();

@protocol GreeWidgetItemDelegate<NSObject>
@required
-(BOOL)hasNotifications;
-(NSString*)titleForTotalBadge;
-(void)collapse;
-(void)expand;
@end

@protocol GreeWidgetDataSourceOfItem<NSObject>
@required
-(CGFloat)widthNeeded;
@end

@class GreeWidgetItem;
@class GreeWidgetControlItem;
@class GreeBadgeValues;

#define GreeWidgetPositionIsOnLeft(position) ((position) == GreeWidgetPositionTopLeft || (position) == GreeWidgetPositionBottomLeft || (position) == GreeWidgetPositionMiddleLeft)
#define GreeWidgetPositionIsOnRight(position) ((position) == GreeWidgetPositionTopRight || (position) == GreeWidgetPositionBottomRight || (position) == GreeWidgetPositionMiddleRight)

#define GreeWidgetPositionIsOnTop(position) ((position) == GreeWidgetPositionTopLeft || (position) == GreeWidgetPositionTopRight)
#define GreeWidgetPositionIsOnMiddle(position) ((position) == GreeWidgetPositionMiddleLeft || (position) == GreeWidgetPositionMiddleRight)
#define GreeWidgetPositionIsOnBottom(position) ((position) == GreeWidgetPositionBottomLeft || (position) == GreeWidgetPositionBottomRight)

@interface GreeWidget ()<GreeWidgetItemDelegate>

@property (nonatomic, readwrite, retain) GreeWidgetItem* dashboardItem;
@property (nonatomic, readwrite, retain) GreeWidgetItem* gameMessageItem;
@property (nonatomic, readwrite, retain) GreeWidgetItem* screenshotItem;
@property (nonatomic, readwrite, retain) GreeWidgetControlItem* controlItem;
@property (nonatomic, readwrite, assign) NSTimeInterval collapseDuration;

@property (nonatomic, readwrite, assign) UIViewController* hostViewController;
@property (nonatomic, assign) BOOL isCollapsed;

-(id)initWithSettings:(GreeSettings*)settings;
-(id)refreshBadgeCount;
-(void)updateBadgesWithValue:(GreeBadgeValues*)badgeValues;
-(void)relocateBar;

-(void)collapse;
-(void)expand;

-(BOOL)hasNotifications;
-(NSString*)titleForTotalBadge;

@end

