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

#import "GreeJSNotificationButton.h"
#import "UIImage+GreeAdditions.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeBadgeView.h"

@interface GreeJSNotificationButton ()
@property (nonatomic, assign) GreeNotifyButtonType internalNotifyButtonType;
@property (nonatomic, retain) GreeBadgeView* badgeView;
-(void)updateBadge:(id)sender;
@end

@implementation GreeJSNotificationButton

#pragma mark - Object Lifecycle

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.badgeView = nil;
  self.didUpdateBlock = nil;

  [super dealloc];
}

+(id)greeButtonWithType:(UIButtonType)type notifyButtonType:(GreeNotifyButtonType)notifyButtonType
{
  if (!(notifyButtonType == GreeNotifyButtonTypeGame ||
        notifyButtonType == GreeNotifyButtonTypeSNS ||
        notifyButtonType == GreeNotifyButtonTypeFriend)) {
    return nil;
  }
  GreeJSNotificationButton* button = [GreeJSNotificationButton buttonWithType:type];
  button.internalNotifyButtonType = notifyButtonType;

  button.frame = CGRectMake(0.0, 0.0, 40, 36);
  button.badgeView = [[[GreeBadgeView alloc] initWithParentView:button
                                                      alignment:GreeBadgeViewAlignmentTopRight] autorelease];
  button.badgeView.hideWhenZero = YES;
  button.badgeView.badgeText = @"0";
  button.badgeView.positionAdjustment = CGPointMake(-8.0f, 9.0f);
  button.exclusiveTouch = YES;

  [[NSNotificationCenter defaultCenter] addObserver:button
                                           selector:@selector(updateBadge:)
                                               name:GreeBadgeValuesDidUpdateNotification
                                             object:nil];

  return button;
}

#pragma mark - Public Methods

-(NSUInteger)badgeNumber
{
  return [self.badgeView.badgeText integerValue];
}

-(void)setBadgeNumber:(NSUInteger)badgeNumber
{
  if (badgeNumber > 99) {
    [self.badgeView setBadgeText:[NSString stringWithFormat:@"99+"]];
  } else {
    [self.badgeView setBadgeText:[NSString stringWithFormat:@"%d", badgeNumber]];
  }
  if (self.didUpdateBlock) {
    self.didUpdateBlock(self);
  }
}

-(GreeNotifyButtonType)notifyButtonType
{
  return self.internalNotifyButtonType;
}

#pragma mark - Internal Methods

-(void)updateBadge:(id)sender
{
  NSNotification* notification = (NSNotification*)sender;
  GreeBadgeValues* badge = (GreeBadgeValues*)notification.object;
  if (!badge) {
    return;
  }
  NSUInteger number = 0;
  if (self.internalNotifyButtonType == GreeNotifyButtonTypeGame) {
    number = badge.applicationBadgeCount;
  } else if (self.internalNotifyButtonType == GreeNotifyButtonTypeSNS) {
    number = badge.snsBadgeCount;
  } else if (self.internalNotifyButtonType == GreeNotifyButtonTypeFriend) {
    number = badge.friendBadgeCount;
  }
  [self setBadgeNumber:number];
}

@end
