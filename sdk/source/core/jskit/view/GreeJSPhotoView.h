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
#import "GreeJSImageScrollView.h"

@class GreeJSPhotoView;

@protocol GreeJSPhotoViewDelegate<NSObject>
-(NSInteger)numberOfPhotoImages:(GreeJSPhotoView*)photoView;
-(UIImage*)photoImage:(GreeJSPhotoView*)photoView
            imageView:(UIImageView*)imageView
         imageAtIndex:(NSUInteger)index;
@optional
-(void)didSingleTap:(GreeJSPhotoView*)photoView;
-(void)didDoubleTap:(GreeJSPhotoView*)photoView;
-(void)photoScrollViewDidEndDecelerating:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView;
-(void)photoScrollViewDidChangeNextPage:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView;
-(void)photoScrollViewDidChangePreviousPage:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView;
@end

@interface GreeJSPhotoView : UIView<UIScrollViewDelegate, GreeJSImageScrollViewDelegate>
@property (nonatomic, assign) id<GreeJSPhotoViewDelegate> delegate;
@property (nonatomic, assign) NSInteger currentPage;

-(void)setCurrentPage:(NSInteger)page animated:(BOOL)animated;
-(UIImageView*)currentPhotoImageView;
-(void)reloadPhotos;
@end
