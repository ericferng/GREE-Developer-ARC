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

#import "GreeWidget+Internal.h"
#import "GreeWidgetItem.h"
#import "UIImage+GreeAdditions.h"


@interface GreeWidgetItem ()
@property (nonatomic, readwrite, retain) UIImage* inactiveImage;
@property (nonatomic, readwrite, retain) UIImage* activeImage;

@end

@implementation GreeWidgetItem

#pragma mark - Object Lifecycle
+(id)itemWithImage:(UIImage*)image callbackBlock:(void (^)())callbackBlock
{
  GreeWidgetItem* item = [self buttonWithType:UIButtonTypeCustom];
  [item setImage:image];
  item.callback = Block_copy (callbackBlock);
  [item addTarget:item action:@selector(buttonTouched:)forControlEvents:UIControlEventTouchUpInside];
  return item;
}

+(id)itemWithImage:(UIImage*)inactiveImage activeImage:(UIImage*)activeImage callbackBlock:(void (^)())callbackBlock
{
  GreeWidgetItem* item = [self buttonWithType:UIButtonTypeCustom];
  item.inactiveImage = inactiveImage;
  item.activeImage = activeImage;
  [item setImage:inactiveImage];

  item.callback = Block_copy (callbackBlock);
  [item addTarget:item action:@selector(buttonTouched:)forControlEvents:UIControlEventTouchUpInside];

  [item.titleLabel setFont:[UIFont fontForGreeWidgetBadgeLabel]];
  [item.titleLabel setTextColor:[UIColor colorWithRed:0xf7/255.0f green:0xf8/255.0f blue:0xf9/255.0f alpha:1]];
  [item.titleLabel setBackgroundColor:[UIColor clearColor]];
  [item.titleLabel setTextAlignment:UITextAlignmentCenter];
  [item.titleLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1-0xaa/255.0f]];
  [item.titleLabel setShadowOffset:CGSizeMake(0, -1)];

  [item setTitleEdgeInsets:UIEdgeInsetsMake(GreeWidgetBubbleTopEdge, 0, GreeWidgetBubbleBottomEdge, 0.)];
  return item;
}

-(void)dealloc
{
  self.callback = nil;
  self.image = nil;
  self.inactiveImage = nil;
  self.activeImage = nil;
  [super dealloc];
}

#pragma mark - Internal Methods
-(void)buttonTouched:(id)sender
{
  if (self.callback) {
    self.callback();
  }
}

#pragma mark - Public Interface
-(CGFloat)widthNeeded
{
  return self.image.size.width;
}

-(void)setImage:(UIImage*)image
{
  if (image == _image) {
    return;
  }
  [_image release];
  _image = [image retain];

  [self setBackgroundImage:_image forState:UIControlStateNormal];
}

-(void)setBadgeCount:(int)count
{
  if (count == _badgeCount) {
    return;
  }
  //change item background image
  if (_badgeCount == 0 && count > 0) {
    self.image = self.activeImage;
  } else if (_badgeCount >0 && count == 0) {
    self.image = self.inactiveImage;
  }
  //set badge count to new count
  _badgeCount = count;
  //update title
  NSString* title = nil;
  if (_badgeCount > 0) {
    title = [NSString stringWithFormat:@"%d", _badgeCount];
    if (count > GreeWidgetBadgeDefaultMaxCount) {
      title = [NSString stringWithFormat:@"%d+", GreeWidgetBadgeDefaultMaxCount];
    }
  }
  [self setTitle:title forState:UIControlStateNormal];
}



@end

