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

@interface GreePopoverContainerViewProperties : NSObject
@property (nonatomic, retain) NSString* bgImageName;
@property (nonatomic, retain) NSString* upArrowImageName;
@property (nonatomic, retain) NSString* downArrowImageName;
@property (nonatomic, retain) NSString* leftArrowImageName;
@property (nonatomic, retain) NSString* rightArrowImageName;
@property (nonatomic, assign) CGFloat leftBgMargin;
@property (nonatomic, assign) CGFloat rightBgMargin;
@property (nonatomic, assign) CGFloat topBgMargin;
@property (nonatomic, assign) CGFloat bottomBgMargin;
@property (nonatomic, assign) CGFloat leftContentMargin;
@property (nonatomic, assign) CGFloat rightContentMargin;
@property (nonatomic, assign) CGFloat topContentMargin;
@property (nonatomic, assign) CGFloat bottomContentMargin;
@property (nonatomic, assign) NSInteger topBgCapSize;
@property (nonatomic, assign) NSInteger leftBgCapSize;
@property (nonatomic, assign) CGFloat arrowMargin;
@property (nonatomic, assign) BOOL roundCorner;
@end
