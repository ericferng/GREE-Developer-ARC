//
// Copyright 2011 GREE, Inc.
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

#import "GreeNotificationContainerView.h"

const CGFloat darkComponents[8] = {
  0.0, 0.0, 0.0, 1.0,      // Start color
  0.0, 0.0, 0.0, 1.0       // End color
};

CGFloat const notificationHeight = 44.0f;

@interface GreeNotificationContainerView ()
@property (nonatomic, retain, readwrite) UIView* contentView;
@end

@implementation GreeNotificationContainerView

#pragma mark - Object Lifecycle

-(id)initWithDisplayPosition:(GreeNotificationDisplayPosition)displayPosition
{
  self = [super initWithFrame:CGRectZero];

  if (self) {
    self.contentView = [[[UIView alloc] initWithFrame:CGRectMake(
                           0,
                           0,
                           self.bounds.size.width,
                           self.bounds.size.height
                           )] autorelease];

    self.contentView.clipsToBounds = YES;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self addSubview:self.contentView];

    self.displayPosition = displayPosition;
  }
  return self;
}

-(void)dealloc
{
  self.contentView = nil;
  [super dealloc];
}

-(void)didMoveToSuperview
{
  if (self.superview == nil) {
    return;
  }

  switch (self.displayPosition) {
  default:
  case GreeNotificationDisplayTopPosition:
    self.frame = CGRectMake(
      0.0f,
      0.0f,
      self.superview.bounds.size.width,
      notificationHeight
      );
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    break;
  case GreeNotificationDisplayBottomPosition:
    self.frame = CGRectMake(
      0.0f,
      self.superview.bounds.size.height - notificationHeight,
      self.superview.bounds.size.width,
      notificationHeight
      );
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin  | UIViewAutoresizingFlexibleRightMargin;;
    break;
  }

  self.contentView.frame = self.bounds;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, frame:%@>",
          NSStringFromClass([self class]),
          self,
          NSStringFromCGRect(self.frame)];
}


@end
