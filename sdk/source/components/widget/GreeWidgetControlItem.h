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
#import "GreeWidget+Internal.h"

@interface GreeWidgetControlItem : UIButton<GreeWidgetDataSourceOfItem>
@property (nonatomic, assign) id<GreeWidgetItemDelegate> delegate;
//control item is clicked to collapse widget bar, or set by widget when its expandable is reset
@property (nonatomic, readwrite, assign) BOOL collapsed;

+(id)  itemWithLeftImage:(UIImage*)imagePointToLeft
              rightImage:(UIImage*)imagePointToRight
   leftNotificationImage:(UIImage*)leftNotificationImage
  rightNotificationImage:(UIImage*)rightNotificationImage
                delegate:(id<GreeWidgetItemDelegate>)delegate;

-(CGFloat)widthNeeded;
-(void)updatePosition:(GreeWidgetPosition)position;
-(void)updateNotificationLabel;

@end



