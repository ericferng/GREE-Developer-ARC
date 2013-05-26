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

#import "GreePopoverContainerView.h"
#import "GreeTouchableView.h"

@class GreePopoverController;

@protocol GreePopoverControllerDelegate<NSObject>
@optional
-(void)popoverControllerDidDismissPopover:(GreePopoverController*)popoverController;
-(BOOL)popoverControllerShouldDismissPopover:(GreePopoverController*)popoverController;
@end

@protocol GreePopoverControllerDatasource
@optional
-(CGRect)displayRectForPopover;
@end

@interface GreePopoverController : NSObject<GreeTouchableViewDelegate>
@property (nonatomic, retain) UIViewController* contentViewController;
@property (nonatomic, retain, readonly) UIView* view;
@property (nonatomic, readonly, getter=isPopoverVisible) BOOL popoverVisible;
@property (nonatomic, readonly) UIPopoverArrowDirection popoverArrowDirection;
@property (nonatomic, assign) id<GreePopoverControllerDelegate> delegate;
@property (nonatomic, assign) CGSize popoverContentSize;
@property (nonatomic, retain) GreePopoverContainerViewProperties* containerViewProperties;
@property (nonatomic, retain) id<NSObject> context;
@property (nonatomic, copy) NSArray* passthroughViews;

-(id)initWithContentViewController:(UIViewController*)contentViewController;
-(void)dismissPopoverAnimated:(BOOL)animated;
-(void)presentPopoverFromBarButtonItem:(UIBarButtonItem*)item
              permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                              animated:(BOOL)animated;
-(void)presentPopoverFromRect:(CGRect)rect
                       inView:(UIView*)view
     permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                     animated:(BOOL)animated;
-(void)repositionPopoverFromRect:(CGRect)rect
                          inView:(UIView*)view
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections;
@end
