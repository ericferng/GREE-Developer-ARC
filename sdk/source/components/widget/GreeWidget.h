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

/**
 * @file GreeWidget.h
 * Contains all necessary interfaces, enumerations, and protocols to interact with GreeWidget.
 */

/**
 * Enumeration of all available GreeWidget positions.
 * @note All 6 positions are valid for widget if expandable is set to YES.
 * @note Only GreeWidgetPositionTopLeft and GreeWidgetPositionBottomLeft are allowed for Greewidget if expandable is set to NO.
 */
typedef enum {
/**
 * Positions the GreeWidget at the top of the screen vertically, all the way to the left.
 */
  GreeWidgetPositionTopLeft,
/**
 * Positions the GreeWidget at the bottom of the screen vertically, all the way to the left.
 */
  GreeWidgetPositionBottomLeft,
/**
 * Positions the GreeWidget in the middle of the screen vertically, all the way to the left.
 * @note NOT valid for non-expandable widget
 */
  GreeWidgetPositionMiddleLeft,

/**
 * Positions the GreeWidget at the bottom of the screen vertically, all the way to the right.
 * @note NOT valid for non-expandable widget
 */
  GreeWidgetPositionTopRight,
/**
 * Positions the GreeWidget at the bottom of the screen vertically, all the way to the right.
 * @note NOT valid for non-expandable widget
 */
  GreeWidgetPositionBottomRight,
/**
 * Positions the GreeWidget at the bottom of the screen vertically, all the way to the right.
 * @note NOT valid for non-expandable widget
 */
  GreeWidgetPositionMiddleRight,
} GreeWidgetPosition;

@class GreeWidget;

/**
 * The GreeWidgetDataSource protocol should be used to provide screenshot
 * data when the camera button on the widget is tapped.
 */
@protocol GreeWidgetDataSource<NSObject>
@required
/**
 * Capture an in-game screenshot and return it as a UIImage object.
 */
-(UIImage*)screenshotImageForWidget:(GreeWidget*)widget;

@optional
/**
 * Capture user text set for a screenshot description.
 */
-(NSString*)screenshotDescription;
@end

/**
 * The GreeWidget class provides a way to show in-game widget
 */
@interface GreeWidget : UIView

/**
 * This widget's position can be adjusted to any of the 6 valid positions when expandable is set to YES,
 * However, when expandable is set to NO, this widget only supports GreeWidgetPositionTopLeft and GreeWidgetPositionBottomLeft.
 * @note For non-expandable widget, it's position will be re-set to GreeWidgetPositionTopLeft if you pass in GreeWidgetPositionTopRight,
 * and re-set to GreeWidgetPositionBottomLeft if you pass in GreeWidgetPositionBottomRight, GreeWidgetPositionMiddleRight, or GreeWidgetPositionMiddleLeft.
 * @see GreeWidgetPosition
 */
@property (nonatomic, readwrite, assign) GreeWidgetPosition position;

/**
 * This widget's expandable feature can be turned on and off,
 * If YES, then widget has a control button so that it can be collapsed/expanded by clicking that button,
 * If NO, then widget will NOT have this feature.
 */
@property (nonatomic, readwrite, assign) BOOL expandable;

/**
 * Receiver's data source. Screenshot functionality on the widget is disabled unless
 * a data source is set.
 */
@property (nonatomic, readwrite, assign) id<GreeWidgetDataSource> dataSource;

@end
