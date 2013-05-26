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
#import "GreeJSModalViewControllable.h"

static const CGFloat kGreeJSTextToolbarHeight = 44.0f;

@class GreeJSWebViewController, GreeJSTakePhotoActionSheet, GreeJSTakePhotoPickerController, GreeJSLoadingIndicatorView, GreeJSModalNavigationController, GreeJSLocationUpdateActionSheet, GreeJSInputViewToolbar, GreeJSLocationCheckedInButton;
@interface GreeJSInputViewController : UIViewController
  <UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GreeJSModalViewControllable>

@property (nonatomic, assign) GreeJSWebViewController* beforeViewController;
@property (nonatomic, retain) UITextView* textView;
@property (nonatomic, retain) GreeJSInputViewToolbar* toolbar;
@property (nonatomic, retain) NSDictionary* params;
@property (nonatomic, retain) NSMutableArray* images;
@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, retain) UIImageView* imageView;
@property (nonatomic, retain) UILabel* placeholderLabel;
@property (nonatomic, retain) GreeJSLocationCheckedInButton* checkedInButton;
@property (nonatomic, retain) UIScrollView* scrollView;
@property (nonatomic, retain) GreeJSTakePhotoActionSheet* imageTypeSelector;
@property (nonatomic, retain) GreeJSTakePhotoPickerController* photoPickerController;
@property (nonatomic, retain) GreeJSLocationUpdateActionSheet* updateLocationTypeSelector;
@property (nonatomic, retain) id popoverImagePicker;
@property (nonatomic, retain) GreeJSLoadingIndicatorView* loadingIndicator;
@property (nonatomic, retain) NSDictionary* locationInfo;
@property (nonatomic, retain) UIButton* showLocationListButton;
@property (nonatomic) CGFloat keyboardHeight;
-(id)initWithParams:(NSDictionary*)params;
-(NSDictionary*)data;
-(NSDictionary*)callbackParams;
-(void)buildSubViews:(NSDictionary*)params;
-(void)buildTextViews:(NSDictionary*)params;
-(void)configureTextViews:(NSDictionary*)params;
-(void)buildToolbarViews:(NSDictionary*)params;
-(void)buildIndicatorViews:(NSDictionary*)params;
-(void)updateTextCounter;
-(void)validateEmpty;
-(NSString*)base64WithImage:(UIImage*)image;
-(void)showIndicator;
-(void)hideIndicator;
-(void)updateLocationInfo:(NSDictionary*)params;

@end
