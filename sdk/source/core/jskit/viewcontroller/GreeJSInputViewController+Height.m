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

#import "GreeJSInputViewController+Height.h"
#import "UIView+GreeAdditions.h"

@interface GreeJSInputViewController ()
-(void)layoutScrollView:(CGFloat)scrollViewHeight;
@end

@implementation GreeJSInputViewController (Height)

-(void)layoutHeight
{
  CGFloat y = 0;
  CGFloat yBottom = self.view.frame.size.height;

  // keyboard
  yBottom -= self.keyboardHeight;

  CGFloat scrollViewHeight = yBottom - y;
  [self.scrollView greeChangeFrameY:y];
  [self.scrollView greeChangeFrameHeight:scrollViewHeight];

  [self layoutScrollViewHeight:scrollViewHeight];
}

-(void)layoutScrollViewHeight:(CGFloat)scrollViewHeight
{
  CGFloat y = 0;
  CGFloat scrollViewContentHeight = 0;

  // checked in button
  if (self.checkedInButton.enabled) {
    y += kGreeJSCheckedInButtonHeight;
    scrollViewContentHeight += kGreeJSCheckedInButtonHeight;
  }

  // text view
  scrollViewContentHeight += scrollViewHeight;
  [self.textView greeChangeFrameY:y];
  [self.textView greeChangeFrameHeight:scrollViewHeight];

  self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, scrollViewContentHeight);
}
@end
