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
#import "GreeNoticeView.h"
#import "GreeGlobalization.h"
#import "NSObject+GreeAdditions.h"
#import "GreePlatform+Internal.h"

@interface GreeNoticeView ()
@property (nonatomic, retain) UIView* errorView;
@property (nonatomic, retain) UILabel* errorLabel;
@end

@implementation GreeNoticeView

-(void)dealloc
{
  self.errorView = nil;

  [super dealloc];
}

#pragma mark - UIView Overrides

-(void)layoutSubviews
{

  [self setNeedsDisplay];
}

#pragma mark - Public Interface

+(void)postWithParentView:(UIView*)parentView
                alignment:(GreeNoticeViewPosition)position
                  message:(NSString*)message
       positionAdjustment:(CGPoint)positionAdjustment
{
  GreeNoticeView* view = [[GreeNoticeView alloc]
                          initWithParentView:parentView
                                   alignment:position
                                     message:message
                          positionAdjustment:positionAdjustment];
  [UIView
   animateWithDuration:1.0f
            animations:^{
     view.errorView.alpha = 1.0f;
   } completion:^(BOOL finished) {
     [view.errorView performBlock:^{
        [UIView
         animateWithDuration:1.0f
                  animations:^{
           view.errorView.alpha = 0.0f;
         } completion:^(BOOL finished){
           [view.errorView removeFromSuperview];
         }];
      } afterDelay:2.5f];
   }];
}

-(id)initWithParentView:(UIView*)parentView
              alignment:(GreeNoticeViewPosition)position
                message:(NSString*)message
     positionAdjustment:(CGPoint)positionAdjustment
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    UILabel* errorLabel = [[[UILabel alloc]
                            initWithFrame:CGRectMake(0,
                                                     0,
                                                     parentView.frame.size.width,
                                                     30)] autorelease];
    errorLabel.text = message;

    // default value
    CGFloat rectHeight = errorLabel.bounds.size.height+10;
    CGFloat rectY = parentView.bounds.origin.y+positionAdjustment.y;
    if (position == GreeNoticeViewPositionTop) {
      // default value
    } else if(position == GreeNoticeViewPositionCenter) {
      rectY = CGRectGetMidY(parentView.bounds);
    } else if(position == GreeNoticeViewPositionButtom) {
      rectY = parentView.frame.size.height-rectHeight;
    }
    self.errorView = [[[UIView alloc]
                       initWithFrame:CGRectMake(parentView.bounds.origin.x+positionAdjustment.x,
                                                rectY,
                                                parentView.bounds.size.width,
                                                rectHeight)] autorelease];

    errorLabel.font = [UIFont systemFontOfSize:14];
    errorLabel.numberOfLines = 1;
    errorLabel.lineBreakMode = UILineBreakModeTailTruncation;
    errorLabel.textAlignment = UITextAlignmentCenter;
    errorLabel.textColor = [UIColor colorWithRed:0x33/255.0f
                                           green:0x44/255.0f
                                            blue:0x55/255.0f
                                           alpha:1.0];
    errorLabel.backgroundColor = [UIColor colorWithRed:0xFF/255.0f
                                                 green:0xFF/255.0f
                                                  blue:0xCC/255.0f
                                                 alpha:1.0];
    UIColor* borderColor = [UIColor colorWithRed:0xE1/255.0f
                                           green:0xE2/255.0f
                                            blue:0xE3/255.0f
                                           alpha:1.0];
    errorLabel.layer.borderColor =  [borderColor CGColor];
    errorLabel.layer.borderWidth = 1.0f;
    [self.errorView addSubview:errorLabel];
    self.errorView.clipsToBounds = YES;
    self.errorView.layer.cornerRadius = 8.0f;
    self.errorView.alpha = 0.0f;

    CALayer* subLayer = [CALayer layer];
    subLayer.frame = CGRectMake(self.errorView.frame.origin.x,
                                errorLabel.frame.size.height,
                                self.errorView.frame.size.width,
                                self.errorView.frame.size.height);
    [self.errorView.layer addSublayer:subLayer];
    subLayer.masksToBounds = YES;
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:
                          CGRectMake(-10.0, -10.0, subLayer.bounds.size.width+10.0, 7.5)];

    subLayer.shadowOffset = CGSizeMake(2.5, 2.5);
    subLayer.shadowColor = [borderColor CGColor];
    subLayer.shadowOpacity = 10.0;
    subLayer.shadowPath = [path CGPath];
    [parentView addSubview:self.errorView];
    [parentView bringSubviewToFront:self.errorView];
  }
  return self;
}


@end
