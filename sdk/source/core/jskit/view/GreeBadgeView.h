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

typedef enum {
  GreeBadgeViewAlignmentTopLeft,
  GreeBadgeViewAlignmentTopRight,
  GreeBadgeViewAlignmentTopCenter,
  GreeBadgeViewAlignmentCenterLeft,
  GreeBadgeViewAlignmentCenterRight,
  GreeBadgeViewAlignmentBottomLeft,
  GreeBadgeViewAlignmentBottomRight,
  GreeBadgeViewAlignmentBottomCenter,
  GreeBadgeViewAlignmentCenter
} GreeBadgeViewAlignment;

@interface GreeBadgeView : UIView
@property (nonatomic, copy) NSString* badgeText;
@property (nonatomic, assign) GreeBadgeViewAlignment badgeAlignment;
@property (nonatomic, retain) UIColor* textColor;
@property (nonatomic, assign) CGSize textShadowOffset;
@property (nonatomic, retain) UIColor* textShadowColor;
@property (nonatomic, retain) UIFont* textFont;
@property (nonatomic, retain) UIColor* badgeBackgroundColor;
@property (nonatomic, retain) UIColor* overlayColor;
@property (nonatomic, assign) CGPoint positionAdjustment;
@property (nonatomic, assign) CGRect frameToPositionInRelationWith;
@property (nonatomic, assign) BOOL stroke;
@property (nonatomic, retain) UIColor* strokeColor;
@property (nonatomic, assign) BOOL hideWhenZero;
-(id)initWithParentView:(UIView*)parentView alignment:(GreeBadgeViewAlignment)alignment;
@end
