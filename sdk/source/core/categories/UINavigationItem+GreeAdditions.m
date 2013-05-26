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

#import "UINavigationItem+GreeAdditions.h"

@implementation UINavigationItem (GreeAdditions)

-(BOOL)isSupportMultiItems
{
  return [UINavigationBar respondsToSelector:@selector(appearance)];
}

-(void)setSameRightBarButtonItems:(UINavigationItem*)item
{
  if ([self isSupportMultiItems]) {
    self.rightBarButtonItems = item.rightBarButtonItems;
  } else {
    self.rightBarButtonItem = item.rightBarButtonItem;
  }
}

-(void)setGreeRightBarButtonItems:(NSArray*)items
{
  if (!items || items.count == 0) {
    return;
  }

  if ([self isSupportMultiItems]) {
    self.rightBarButtonItems = items;
  } else {
    UIBarButtonItem* first = [items objectAtIndex:0];
    CGRect containerBounds = CGRectMake(0,
                                        0,
                                        first.customView.frame.size.width * items.count,
                                        first.customView.frame.size.height);
    UIView* buttonContainer = [[UIView alloc] initWithFrame:containerBounds];
    for (UIBarButtonItem* item in items) {
      [buttonContainer addSubview:item.customView];
    }
    self.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonContainer] autorelease];
    [buttonContainer release];
    [buttonContainer layoutSubviews];
  }
}

@end
