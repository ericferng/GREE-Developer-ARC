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
#import "GreePhoneNumberBasedParts.h"
#import "GreePhoneNumberBasedPage.h"
#import "GreePlatform+Internal.h"

@implementation GreeTouchEventScrollView

#pragma mark - UIScrollView Overrides

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self.nextResponder touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
  if (!self.dragging) {
    [self.nextResponder touchesEnded:touches withEvent:event];
  }
}

@end


@implementation GreeNoInteractionUIView

#pragma mark - UIView Overrides

-(id)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
  id hitView = [super hitTest:point withEvent:event];
  if (hitView == self) {
    return nil;
  }
  return hitView;
}

-(void)drawRect:(CGRect)rect
{
  [super drawRect:rect];
  self.clipsToBounds = true;
}

@end


@implementation GreeTableCellLikeView

#pragma mark - UIView Overrides

-(void)drawRect:(CGRect)rect
{
  [super drawRect:rect];
  self.clipsToBounds = true;
  self.layer.cornerRadius = 10;
  self.layer.borderWidth  = 1;
  self.layer.borderColor  = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorTableOutline].CGColor;
}

@end


@interface GreeUITextField ()<UITextFieldDelegate>
-(void)initialWork;
@end

@implementation GreeUITextField


#pragma mark - Object Lifecycle

-(void)dealloc
{
  if ([self.myPlaceholder superview]) {
    [self.myPlaceholder removeFromSuperview];
  }
  self.myPlaceholder = nil;

  [super dealloc];
}

-(id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self initialWork];
  }
  return self;
}

-(id)initWithCoder:(NSCoder*)decoder
{
  if ((self = [super initWithCoder:decoder])) {
    [self initialWork];
  }
  return self;
}

-(void)initialWork
{
  self.myPlaceholder = [[[UILabel alloc] init] autorelease];
  self.myPlaceholder.frame     = CGRectMake(0, 2, self.frame.size.width, 0);
  self.myPlaceholder.font      = [GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontTextFieldPlaceholder];
  self.myPlaceholder.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormPlaceholder];
  self.myPlaceholder.backgroundColor = [UIColor clearColor];

  [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidBeginEditingNotification object:nil queue:nil
                                                usingBlock:^(NSNotification* note){
     [self.myPlaceholder setAlpha:0];
   }];
  [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidEndEditingNotification object:nil queue:nil
                                                usingBlock:^(NSNotification* note){
     [self showPlaceholder];
   }];
}

#pragma mark - UIView Overrides

-(void)drawRect:(CGRect)rect
{
  [self.myPlaceholder sizeToFit];
  [self addSubview:self.myPlaceholder];
  [self showPlaceholder];

  [super drawRect:rect];
}

#pragma mark - Internal Methods

-(void)showPlaceholder
{
  [self.myPlaceholder setAlpha:(self.text.length > 0 ? 0: 1)];
}

@end
