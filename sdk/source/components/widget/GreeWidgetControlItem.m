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

#import "GreeWidgetControlItem.h"
#import "GreeWidget+Internal.h"

@interface GreeWidgetControlItem ()
//indicating if this control item is on the left of the widget bar or not, default is NO
@property (nonatomic, readwrite, assign) BOOL onLeft;
//imagePointToLeft is the arrow image pointing to left
@property (nonatomic, readwrite, retain) UIImage* imagePointToLeft;
//imagePointToLeft is the arrow image pointing to right
@property (nonatomic, readwrite, retain) UIImage* imagePointToRight;
//when this control item is on the left of the widget bar, and there is notification
@property (nonatomic, readwrite, retain) UIImage* leftNotificationImage;
//when this control item is on the right of the widget bar, and there is notification
@property (nonatomic, readwrite, retain) UIImage* rightNotificationImage;
//current background image used
@property (nonatomic, readwrite, retain) UIImage* image;

@end

@implementation GreeWidgetControlItem

#pragma mark - Object Lifecycle
+(id)  itemWithLeftImage:(UIImage*)imagePointToLeft
              rightImage:(UIImage*)imagePointToRight
   leftNotificationImage:(UIImage*)leftNotificationImage
  rightNotificationImage:(UIImage*)rightNotificationImage
                delegate:(id<GreeWidgetItemDelegate>)delegate
{
  GreeWidgetControlItem* item = [self buttonWithType:UIButtonTypeCustom];
  item.delegate = delegate;
  item.onLeft = NO;
  item.collapsed = NO;

  item.imagePointToLeft = imagePointToLeft;
  item.imagePointToRight = imagePointToRight;
  item.leftNotificationImage = leftNotificationImage;
  item.rightNotificationImage = rightNotificationImage;
  item.image = item.imagePointToLeft; //default background image is left image

  [item addTarget:item action:@selector(buttonTouched:)forControlEvents:UIControlEventTouchUpInside];
  [item.titleLabel setFont:[UIFont fontForGreeWidgetBadgeLabel]];
  [item.titleLabel setTextColor:[UIColor colorWithRed:0xf7/255.0f green:0xf8/255.0f blue:0xf9/255.0f alpha:1]];
  [item.titleLabel setBackgroundColor:[UIColor clearColor]];
  [item.titleLabel setTextAlignment:UITextAlignmentCenter];
  [item.titleLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1-0xaa/255.0f]];
  [item.titleLabel setShadowOffset:CGSizeMake(0, -1)];
  [item setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, GreeWidgetBubbleBottomEdge, 0)];
  return item;
}

-(void)dealloc
{
  self.delegate = nil;
  self.image = nil;
  self.imagePointToLeft = nil;
  self.imagePointToRight = nil;
  self.leftNotificationImage = nil;
  self.rightNotificationImage = nil;
  [super dealloc];
}

#pragma mark - Internal Methods
-(void)buttonTouched:(id)sender
{
  if (self.collapsed) {
    self.collapsed = NO;
  } else {
    self.collapsed = YES;
  }
}

-(BOOL)notificationON
{
  return self.collapsed && [self.delegate hasNotifications];
}

-(void)setCollapsed:(BOOL)collapsed
{
  //collapse status is not changed
  if ((collapsed && _collapsed) || (!collapsed && !_collapsed)) {
    return;
  }
  _collapsed = collapsed;

  NSString* title = nil;
  if ([self notificationON]) {
    self.image = self.onLeft ? self.leftNotificationImage : self.rightNotificationImage;
    title = [self.delegate titleForTotalBadge];
  } else {
    BOOL showLeftImage = (self.onLeft && _collapsed) || (!self.onLeft && !_collapsed);
    self.image = showLeftImage ? self.imagePointToLeft : self.imagePointToRight;
  }
  [self setTitle:title forState:UIControlStateNormal];

  if (_collapsed) {
    [self.delegate collapse];
  } else {
    [self.delegate expand];
  }
}

//When there is no notification, should the arrow needs to point to left or not
//When there is notification, should the notification image point to left or not
-(BOOL)shouldPointToLeft
{
  return ((self.onLeft && self.collapsed) || (!self.onLeft && !self.collapsed)) ? YES : NO;
}

-(void)updatePosition:(GreeWidgetPosition)position
{
  BOOL moveToLeft = GreeWidgetPositionIsOnRight(position);
  //position is not changed
  if ((self.onLeft && moveToLeft) || (!self.onLeft && !moveToLeft)) {
    return;
  }
  self.onLeft = moveToLeft;

  if ([self notificationON]) {
    self.image = self.onLeft ? self.leftNotificationImage : self.rightNotificationImage;
  } else {
    self.image = [self shouldPointToLeft] ? self.imagePointToLeft : self.imagePointToRight;
  }
}

-(void)updateNotificationLabel
{
  if ([self notificationON] && self.image != self.leftNotificationImage && self.image != self.rightNotificationImage) {
    self.image = [self shouldPointToLeft] ? self.leftNotificationImage : self.rightNotificationImage;
  } else if(![self notificationON] && self.image != self.imagePointToLeft && self.image != self.imagePointToRight) {
    self.image = [self shouldPointToLeft] ? self.imagePointToLeft : self.imagePointToRight;
  }
  NSString* title = nil;
  if ([self notificationON]) {
    title = [self.delegate titleForTotalBadge];
  }
  [self setTitle:title forState:UIControlStateNormal];
}


#pragma mark - Public Interface
-(void)setImage:(UIImage*)image
{
  if (image == _image) {
    return;
  }
  [_image release];
  _image = [image retain];
  [self setBackgroundImage:_image forState:UIControlStateNormal];
}


-(CGFloat)widthNeeded
{
  return self.image.size.width;
}


@end
