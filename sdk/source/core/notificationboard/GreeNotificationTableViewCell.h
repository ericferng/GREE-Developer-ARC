//
// Copyright 2012 GREE International, Inc.
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

#import <UIKit/UIKit.h>
#import "GreeNotificationTableViewCellLabel.h"

@interface GreeNotificationTableViewCell : UITableViewCell
@property (retain, nonatomic) UIImageView* iconImageView;
@property (retain, nonatomic) GreeNotificationTableViewCellLabel* mainMessageLabel;
@property (retain, nonatomic) UILabel* subMessageLabel;
@property (retain, nonatomic) UILabel* timeMessageLabel;
-(id)initWidthReuseIdentifier:(NSString*)reuseIdentifier;
-(CGFloat)cellHeight:(CGFloat)cellWidth;
@end
