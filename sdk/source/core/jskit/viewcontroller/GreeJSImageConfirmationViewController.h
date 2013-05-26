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

@interface GreeJSImageConfirmationViewController : UIViewController
{
  id delegate_;
  UIImage* image_;
  UIImageView* imageView_;
  NSInteger tag_;
}
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) UIImageView* imageView;
@property (nonatomic, assign) NSInteger tag;
@end

@interface NSObject (GreeJSImageConfirmationViewDelegate)
-(void)imageDidSelected:(GreeJSImageConfirmationViewController*)controller;
@end
