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


#import "GreeJSInputViewController.h"
#import "GreeJSInputViewController+Height.h"
#import "GreeJSWebViewController+ModalView.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeJSTakePhotoActionSheet.h"
#import "GreeJSLocationUpdateActionSheet.h"
#import "GreeJSImageConfirmationViewController.h"
#import "GreeJSUIImage+TakePhoto.h"
#import "GreeJSTakePhotoPickerController.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeGlobalization.h"
#import "UIImage+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreePlatformSettings.h"
#import "GreeSettings.h"
#import "GreeLogger.h"
#import "NSString+GreeAdditions.h"
#import "GreeJSHandler.h"
#import "GreeJSModalNavigationController.h"
#import "GreeJSCommandFactory.h"
#import "GreeJSShowModalViewCommand.h"
#import "GreeJSWebViewController.h"
#import "GreeJSInputViewToolbar.h"
#import "GreeJSLocationNavigationController.h"
#import "UIViewController+GreeAdditions.h"
#import "UIView+GreeAdditions.h"
#import "GreeJSLocationCheckedInButton.h"
#import "GreeJSInputViewController+Height.h"
#import "NSObject+GreeAdditions.h"


NSString* const kGreeJSInputSingleLineParam = @"singleline";
int const kAlertTypeDisableLocation = 1;
int const kAlertTypeAgreementLocation = 2;

@interface GreeJSInputViewController ()

@property (nonatomic, retain) NSDictionary* initialParams;
@property (nonatomic, retain) NSSet* previousOrientations;
@property (nonatomic, retain) NSArray* atLeastOneRequiredFields;
@property (nonatomic, retain) NSArray* requiredFields;
@property (nonatomic, retain) NSString* inputtedText;
@property (nonatomic, retain) NSMutableArray* inputtedImages;
@property (nonatomic, assign) BOOL isEnabledResignFirstResponder;

-(void)setupTextLimit:(NSDictionary*)params;
-(void)createCallbackParams:(NSDictionary*)params;
-(void)showImagePicker:(UIButton*)sender;
-(void)showImagePickerSelected:(UIButton*)sender;
-(void)showImageTypeSelector:(BOOL)selected withTag:(NSInteger)tag;
-(void)setImage:(UIImage*)image atIndex:(NSInteger)index;
-(void)removeImageAtIndex:(NSInteger)index;
-(void)setPlaceholder:(NSString*)placeholder color:(UIColor*)color;
-(void)showPlaceholder;
-(void)hidePlaceholder;
-(void)onUIKeyboardWillHideNotification:(NSNotification*)notification;
-(void)onUIKeyboardWillChangeNotification:(NSNotification*)notification;
-(void)keyboardHeightWillChangeTo:(CGFloat)height duration:(NSTimeInterval)duration;
-(void)setupValidation:(NSDictionary*)params;
-(BOOL)validate;
-(NSArray*)parseAtLeastOneRequiredFieldsForParams:(NSDictionary*)params;
-(BOOL)isFieldRequired:(NSString*)fieldName forParams:(NSDictionary*)params;
-(BOOL)validateField:(NSString*)fieldName;
-(BOOL)validateTextField;
-(BOOL)validatePhotoField;
-(int)textLength;
-(void)takePhotoActionSheet:(GreeJSTakePhotoActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
-(void)locationUpdateActionSheetDidDismissWithButtonIndex:(NSInteger)buttonIndex;
-(BOOL)validateSpotField;
-(void)showUpdateLocationTypeSelector;
-(void)showLocationList;
-(void)buildPhotoButton:(NSDictionary*)params items:(NSMutableArray**)items;
-(void)buildSpotButton:(NSDictionary*)params items:(NSMutableArray**)items;
-(void)removeLocation;
-(int)photoCount;
-(void)showLocationInfo;
@end


@implementation GreeJSInputViewController

#pragma mark - Object Lifecycle

-(id)initWithParams:(NSDictionary*)params
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.initialParams = [[params copy] autorelease];
    [self setupTextLimit:self.initialParams];
    [self setupValidation:self.initialParams];
    [self createCallbackParams:self.initialParams];
    self.isEnabledResignFirstResponder = NO;
  }
  return self;
}

-(void)dealloc
{
  self.initialParams = nil;
  self.params = nil;
  self.images = nil;
  self.imageView = nil;
  self.textView = nil;
  self.toolbar = nil;
  self.placeholderLabel = nil;
  self.imageTypeSelector = nil;
  self.updateLocationTypeSelector = nil;
  self.photoPickerController = nil;
  self.popoverImagePicker = nil;
  self.loadingIndicator = nil;
  self.previousOrientations = nil;
  self.atLeastOneRequiredFields = nil;
  self.checkedInButton = nil;
  self.showLocationListButton = nil;
  self.requiredFields = nil;
  self.inputtedText = nil;
  self.inputtedImages = nil;

  self.locationInfo = nil;
  self.scrollView = nil;
  [super dealloc];
}

#pragma mark - UIViewController Overrides

-(void)loadView
{
  [super loadView];
  UIView* myView = self.view;
  self.wantsFullScreenLayout = NO;
  myView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  myView.autoresizesSubviews = YES;

  [self buildSubViews:self.initialParams];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onUIKeyboardWillHideNotification:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onUIKeyboardWillChangeNotification:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0f) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUIKeyboardWillChangeNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
  }
}

-(void)viewDidLoad
{
  if(self.inputtedText) {
    self.textView.text = self.inputtedText;
    self.inputtedText = nil;
  }
  if(self.inputtedImages) {
    for (int i = 0; i < self.inputtedImages.count; i++) {
      UIImage* image = [self.inputtedImages objectAtIndex:i];
      if (image && ![image isEqual:[NSNull null]]) {
        [self setImage:image atIndex:i];

      }
    }
    self.inputtedImages = nil;
  }

  if(self.locationInfo) {
    [self showLocationInfo];
  }
}



-(void)viewDidAppear:(BOOL)animated
{
  if ([self.textView canBecomeFirstResponder]) {
    [self.textView becomeFirstResponder];
  }

  [self updateTextCounter];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)viewDidUnload
{
  if(self.textView.text && [self.textView.text length] != 0) {
    self.inputtedText = self.textView.text;
  }

  for (int i = 0; i < self.images.count; i++) {
    UIImage* image = [self.images objectAtIndex:i];
    if (image && ![image isEqual:[NSNull null]]) {
      self.inputtedImages = self.images;
      break;
    }
  }
}
#pragma mark - UIImagePickerControllerDelegate Methods

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{

  UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    [picker greeDismissViewControllerAnimated:YES completion:nil];

    [self setImage:image atIndex:self.photoPickerController.tag];
  } else {
    GreeJSImageConfirmationViewController* controller =
      [[[GreeJSImageConfirmationViewController alloc] init] autorelease];
    controller.delegate = self;
    controller.tag = self.photoPickerController.tag;
    controller.image = image;

    [picker pushViewController:controller animated:YES];
  }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && picker.sourceType != UIImagePickerControllerSourceTypeCamera) {
    [self.popoverImagePicker dismissPopoverAnimated:YES];
  } else {
    [picker greeDismissViewControllerAnimated:YES completion:nil];
  }
}

-(void)imageDidSelected:(GreeJSImageConfirmationViewController*)controller
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.popoverImagePicker dismissPopoverAnimated:YES];
  } else {
    UIImagePickerController* picker = self.photoPickerController.imagePickerController;
    [picker greeDismissViewControllerAnimated:YES completion:nil];
  }

  [self setImage:controller.image atIndex:controller.tag];
}


#pragma mark - UIActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if ([actionSheet isKindOfClass:[GreeJSTakePhotoActionSheet class]]) {
    [self takePhotoActionSheet:(GreeJSTakePhotoActionSheet*)actionSheet didDismissWithButtonIndex:buttonIndex];
  } else if ([actionSheet isKindOfClass:[GreeJSLocationUpdateActionSheet class]]) {
    [self locationUpdateActionSheetDidDismissWithButtonIndex:buttonIndex];
  }
}

#pragma mark - UITextViewDelegate Methods

-(BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
  [self performBlock:^{
     self.isEnabledResignFirstResponder = YES;
   } afterDelay:0.5];

  return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView*)textView
{
  BOOL val = YES;
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0f) {
    val = self.isEnabledResignFirstResponder;
  }
  return val;
}

-(BOOL)textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
  if ([self.params objectForKey:kGreeJSInputSingleLineParam] && [text isEqualToString:@"\n"]) {
    if ([self.beforeViewController respondsToSelector:@selector(greeJSModalRightButtonPressed:)]) {
      [self.beforeViewController performSelector:@selector(greeJSModalRightButtonPressed:)
                                      withObject:self.navigationItem.rightBarButtonItem];
    }
    return NO;
  }
  return YES;
}

-(void)textViewDidChange:(UITextView*)textView
{
  if ([self.params objectForKey:kGreeJSInputSingleLineParam] &&
      [self.textView.text rangeOfString:@"\n"].location != NSNotFound) {
    NSRange range = self.textView.selectedRange;
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    self.textView.selectedRange = range;
  }

  [self updateTextCounter];

  int textLength = [self textLength];
  if (textLength > 0) {
    [self showPlaceholder];
  } else {
    [self hidePlaceholder];
  }

  if (textLength > self.limit) {
    [self.toolbar setTextCounterColorOverLimit];
  } else {
    [self.toolbar setTextCounterColorNormal];
  }

}


#pragma mark - Public Interface

-(NSDictionary*)data
{
  NSMutableDictionary* data = [NSMutableDictionary dictionary];

  [data setValue:self.textView.text forKey:@"text"];
  if (self.toolbar) {
    for (int i = 0; i < self.images.count; i++) {
      UIImage* image = [self.images objectAtIndex:i];
      if (image && ![image isEqual:[NSNull null]]) {
        [data setValue:[self base64WithImage:image]
                forKey:[NSString stringWithFormat:@"image%d", i]];
      }
    }
  }

  [data addEntriesFromDictionary:self.locationInfo];

  return data;
}

-(NSDictionary*)callbackParams
{
  return self.params;
}

-(void)buildSubViews:(NSDictionary*)params
{
  self.view.backgroundColor = [UIColor colorWithRed:0xEE / 255.0f
                                              green:0xEE / 255.0f
                                               blue:0xEE / 255.0f
                                              alpha:1.0];

  [self buildTextViews:params];
  [self configureTextViews:params];
  [self buildToolbarViews:params];
  [self buildIndicatorViews:params];

  [self layoutHeight];
}

-(void)buildTextViews:(NSDictionary*)params
{
  NSInteger leftMargin = 0;
  NSString* image = [params valueForKey:@"image"];
  if (image) {
    leftMargin = 44.0f;
    self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(8.0f, 8.0f, 36, 36)] autorelease];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.layer.cornerRadius = 4.0f;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.opaque = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;

    [[[GreePlatform sharedInstance] httpClient] downloadImageAtUrl:[NSURL URLWithString:image] withBlock:^(UIImage* icon, NSError* error) {
       if (error) {
         return;
       }
       self.imageView.image = icon;
     }];
    [self.view addSubview:self.imageView];
  }

  CGRect bounds = self.view.bounds;

  self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0,
                                                                    0,
                                                                    bounds.size.width,
                                                                    0)] autorelease];
  [self.scrollView setContentSize:CGSizeMake(bounds.size.width, 180)];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:self.scrollView];
  [self.view setBackgroundColor:[UIColor colorWithRed:0xf1 / 255.0f
                                                green:0xf2 / 255.0f
                                                 blue:0xf3 / 255.0f
                                                alpha:1.0f]];

  // for location service
  self.checkedInButton = [GreeJSLocationCheckedInButton buttonWithFrame:CGRectMake(0,
                                                                                   0,
                                                                                   bounds.size.width,
                                                                                   kGreeJSCheckedInButtonHeight)];
  [self.checkedInButton addTarget:self
                           action:@selector(updateSpotAction:)
                 forControlEvents:UIControlEventTouchUpInside];



  self.textView = [[[UITextView alloc] initWithFrame:CGRectMake(leftMargin,
                                                                0,
                                                                bounds.size.width - leftMargin,
                                                                0)] autorelease];
  self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  NSString* value = [params valueForKey:@"value"];
  self.textView.text = [value isKindOfClass:[NSString class]] ? value : @"";

  self.textView.editable = YES;
  self.textView.font = [UIFont systemFontOfSize:16.0f];
  self.textView.backgroundColor = [UIColor colorWithPatternImage:[UIImage greeImageNamed:@"gree_bg_texture.png"]];
  self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.textView.delegate = self;

  [self.scrollView addSubview:self.textView];
  [self.scrollView addSubview:self.checkedInButton];

  NSString* placeholder = [params valueForKey:@"placeholder"];
  [self setPlaceholder:placeholder color:[UIColor lightGrayColor]];
}


-(void)updateSpotAction:(UIButton*)sender
{
  if ([self validateSpotField]) {
    // if location info is already setted, show ActionSheet.
    [self showUpdateLocationTypeSelector];
  } else {
    // show spotList View
    [self showLocationList];
  }
}

#pragma mark -

-(void)buildToolbarViews:(NSDictionary*)params
{
  NSMutableArray* items = [NSMutableArray array];
  BOOL usePhoto = [[params valueForKey:@"usePhoto"] boolValue];
  if (usePhoto) {
    [self buildPhotoButton:params items:&items];
  }
  BOOL useSpot = [[params valueForKey:@"useSpot"] boolValue];
  if (useSpot) {
    [self buildSpotButton:params items:&items];
  }

  self.toolbar = [[[GreeJSInputViewToolbar alloc] initWithWidth:self.view.bounds.size.width] autorelease];
  self.toolbar.items = items;
  [self.toolbar buildTextCounterViewsWithLimit:self.limit];
  self.textView.inputAccessoryView = self.toolbar;
}

-(void)buildPhotoButton:(NSDictionary*)params items:(NSMutableArray**)items
{
  int photoCount = [self photoCount];

  self.images = [NSMutableArray arrayWithCapacity:photoCount];

  for (int i = 0; i < photoCount; i++) {
    [self.images addObject:[NSNull null]];

    UIImage* cameraNormalImage = [UIImage greeImageNamed:@"gree_btn_take_photo_default.png"];
    UIImage* cameraHighlightImage = [UIImage greeImageNamed:@"gree_btn_take_photo_highlight.png"];
    UIButton* cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame = CGRectMake(0, 0, 44.0f, 44.0f);
    [cameraButton addTarget:self action:@selector(showImagePicker:)forControlEvents:UIControlEventTouchUpInside];
    [cameraButton setBackgroundImage:cameraNormalImage forState:UIControlStateNormal];
    [cameraButton setBackgroundImage:cameraHighlightImage forState:UIControlStateHighlighted];
    cameraButton.tag = i;

    UIBarButtonItem* item = [[[UIBarButtonItem alloc] initWithCustomView:cameraButton] autorelease];
    item.tag = i;
    [*items addObject:item];


    if (photoCount == 1) {
      break;
    }
    UIBarButtonItem* space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                            target:nil
                                                                            action:nil] autorelease];
    space.width = 16.0;
    [*items addObject:space];
  }

  for (int i = 0; i < photoCount; i++) {
    NSString* imageValue = [params valueForKey:[NSString stringWithFormat:@"image%d", i]];
    if (imageValue) {
      UIImage* image = [UIImage greeImageWithBase64:imageValue];
      if (image) {
        [self setImage:image atIndex:i];
      }
    }
  }
}

-(void)buildSpotButton:(NSDictionary*)params items:(NSMutableArray**)items
{
  self.showLocationListButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.showLocationListButton.frame = CGRectMake(0, 0, 44.0f, 44.0f);
  [self.showLocationListButton addTarget:self action:@selector(updateSpotAction:)forControlEvents:UIControlEventTouchUpInside];
  [self.showLocationListButton setBackgroundImage:[UIImage greeImageNamed:@"gree_btn_location_default.png"]
                                         forState:UIControlStateNormal];
  [self.showLocationListButton setBackgroundImage:[UIImage greeImageNamed:@"gree_btn_location_highlight.png"]
                                         forState:UIControlStateHighlighted];

  UIBarButtonItem* item = [[[UIBarButtonItem alloc] initWithCustomView:self.showLocationListButton] autorelease];
  [*items addObject:item];
}

-(void)buildIndicatorViews:(NSDictionary*)params
{
  self.loadingIndicator = [[[GreeJSLoadingIndicatorView alloc]
                            initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];
}

-(void)updateTextCounter
{
  [self validateEmpty];
  [self.toolbar updateTextCounterWidthWithTextLength:[self textLength]];
}

-(int)photoCount
{
  int photoCount = [[self.params valueForKey:@"photoCount"] integerValue];

  // Didn't support spot and multi photos at same time.
  BOOL useSpot = [[self.params valueForKey:@"useSpot"] boolValue];
  if (photoCount <= 1 || useSpot) {
    photoCount = 1;
  }

  return photoCount;
}

-(void)validateEmpty
{
  self.navigationItem.rightBarButtonItem.enabled = [self validate];
}

-(BOOL)validate
{
  int textLength = [self textLength];

  if (textLength > self.limit) {
    return NO;
  }

  for (NSString* field in self.requiredFields) {
    if (![self validateField:field]) {
      return NO;
    }
  }

  if (self.atLeastOneRequiredFields.count) {
    BOOL atLeastOnePresent = NO;
    for (NSString* field in self.atLeastOneRequiredFields) {
      if ([self validateField:field]) {
        atLeastOnePresent = YES;
      }
    }
    return atLeastOnePresent;
  }

  return YES;
}

-(NSString*)base64WithImage:(UIImage*)image
{
  UIImage* resizedImage = [UIImage greeResizeImage:image maxPixel:480 rotation:0];
  return [resizedImage greeBase64EncodedString];
}


#pragma mark Indicator Interface

-(void)showIndicator
{
  self.loadingIndicator.center = self.textView.center;
  if (!self.loadingIndicator.superview)
    [self.view addSubview:self.loadingIndicator];
}

-(void)hideIndicator
{
  [self.loadingIndicator removeFromSuperview];
}


#pragma mark - Keyboard Notifications

-(void)onUIKeyboardWillHideNotification:(NSNotification*)notification
{
  NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [self keyboardHeightWillChangeTo:0 duration:duration];
}

-(void)onUIKeyboardWillChangeNotification:(NSNotification*)notification
{
  CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  keyboardRect = [[self.view superview] convertRect:keyboardRect fromView:nil];
  NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [self keyboardHeightWillChangeTo:keyboardRect.size.height duration:duration];
}

-(void)keyboardHeightWillChangeTo:(CGFloat)height duration:(NSTimeInterval)duration
{
  [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
  [UIView setAnimationDuration:duration];

  self.keyboardHeight = height;
  [self layoutHeight];

  [UIView commitAnimations];
}

#pragma mark - GreeJSModalViewControllable Interface

-(void)greeJSModalDisplayLoadingIndicator:(BOOL)show
{
  if (show) {
    [self showIndicator];
  } else {
    [self hideIndicator];
  }
}

-(void)greeJSModalSetUserInteractionEnabled:(BOOL)enable
{
  self.navigationItem.rightBarButtonItem.enabled = enable;
  self.navigationItem.leftBarButtonItem.enabled = enable;
  self.toolbar.userInteractionEnabled = enable;

  // Want to do
  //   self.textView.editable = enable;
  // but software keyboard is hidden.
}

-(void)greeJSModalSetCallback:(NSString*)callback toHandler:(GreeJSHandler*)handler
{
  NSDictionary* data = [self data];
  NSDictionary* params = [self callbackParams];
  NSArray* arguments = [NSArray arrayWithObjects:data, params, nil];
  [handler callback:callback arguments:arguments];
}


#pragma mark - Internal Methods

-(void)configureTextViews:(NSDictionary*)params
{
  if ([params objectForKey:kGreeJSInputSingleLineParam]) {
    self.textView.returnKeyType = UIReturnKeyDone;
  }
}

-(void)setupTextLimit:(NSDictionary*)params
{
  NSUInteger limit = [[params valueForKey:@"limit"] unsignedIntegerValue];
  self.limit = limit > 0 ? limit : 500;
}

-(void)createCallbackParams:(NSDictionary*)params
{
  NSMutableDictionary* p = [[params mutableCopy] autorelease];
  [p removeObjectForKey:@"type"];
  [p removeObjectForKey:@"limit"];
  [p removeObjectForKey:@"title"];
  [p removeObjectForKey:@"button"];
  [p removeObjectForKey:@"placeholder"];
  [p removeObjectForKey:@"image"];
  [p removeObjectForKey:@"value"];
  [p removeObjectForKey:@"usePhoto"];
  [p removeObjectForKey:@"photoCount"];
  [p removeObjectForKey:@"callback"];
  self.params = p;
}

-(int)textLength
{
  return [self.textView.text greeTextLengthGreeNormalized];
}

-(void)takePhotoActionSheet:(GreeJSTakePhotoActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  self.photoPickerController = [[[GreeJSTakePhotoPickerController alloc] init] autorelease];
  self.photoPickerController.imagePickerController.delegate = self;
  self.photoPickerController.tag = actionSheet.tag;

  if (buttonIndex == self.imageTypeSelector.cancelButtonIndex) {
    self.imageTypeSelector = nil;
    return;
  }

  if (buttonIndex == self.imageTypeSelector.takePhotoButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else if (buttonIndex == self.imageTypeSelector.chooseFromAlbumButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  } else if (buttonIndex == self.imageTypeSelector.removePhotoButtonIndex) {
    [self removeImageAtIndex:actionSheet.tag];
    self.imageTypeSelector = nil;
    return;
  } else {
    self.imageTypeSelector = nil;
    return;
  }

  self.imageTypeSelector = nil;

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && self.photoPickerController.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera) {
    if (!self.popoverImagePicker) {
      Class popoverController = NSClassFromString(@"UIPopoverController");
      self.popoverImagePicker =
        [[[popoverController alloc] initWithContentViewController:self.photoPickerController.imagePickerController] autorelease];
    } else {
      [self.popoverImagePicker setContentViewController:self.photoPickerController.imagePickerController];
    }
    [self.popoverImagePicker presentPopoverFromRect:CGRectMake(self.view.center.x, self.view.center.y, 32, 32)
                                             inView:self.view
                           permittedArrowDirections:UIPopoverArrowDirectionUp
                                           animated:YES];
  } else {
    [self.textView resignFirstResponder];
    [self.navigationController greePresentViewController:self.photoPickerController.imagePickerController animated:YES completion:nil];
  }
}

-(void)locationUpdateActionSheetDidDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == self.updateLocationTypeSelector.updateLocationButtonIndex) {
    // update
    [self showLocationList];
  } else if (buttonIndex == self.updateLocationTypeSelector.removeLocationButtonIndex) {
    // remove
    [self removeLocation];
  }
}


#pragma mark - Image Picker Methods

-(void)showImagePicker:(UIButton*)sender
{
  [self showImageTypeSelector:NO withTag:sender.tag];
}

#pragma mark Location Methods

-(void)showLocationList
{
  GreeJSLocationNavigationController* controller =
    [[[GreeJSLocationNavigationController alloc] initWithViewName:[self.params valueForKey:@"spotView"] parent:self] autorelease];
  [self greePresentViewController:controller animated:YES completion:nil];
}

-(void)updateLocationInfo:(NSDictionary*)params
{

  self.locationInfo = params;
  [self showLocationInfo];
}

-(void)showLocationInfo
{
  [self.checkedInButton showWithText:[self.locationInfo objectForKey:@"spotName"]];
  [self.showLocationListButton setImage:[UIImage greeImageNamed:@"gree_btn_location_active.png"]
                               forState:UIControlStateNormal];
  [self layoutHeight];
}

-(void)removeLocation
{
  [self.checkedInButton hide];
  self.locationInfo = nil;
  [self.textView greeChangeFrameYRelatively:-kGreeJSCheckedInButtonHeight];
  [self.textView greeChangeFrameHeightRelatively:+kGreeJSCheckedInButtonHeight];
  [self.showLocationListButton setImage:[UIImage greeImageNamed:@"gree_btn_location_default.png"]
                               forState:UIControlStateNormal];
  [self layoutHeight];
}

-(void)showUpdateLocationTypeSelector
{
  if (!self.updateLocationTypeSelector) {
    self.updateLocationTypeSelector = [[[GreeJSLocationUpdateActionSheet alloc] initWithDelegate:self] autorelease];
  }

  [self.updateLocationTypeSelector showInView:self.view];
}

#pragma mark Image Methods

-(void)showImagePickerSelected:(UIButton*)sender
{
  [self showImageTypeSelector:YES withTag:sender.tag];
}

-(void)showImageTypeSelector:(BOOL)selected withTag:(NSInteger)tag
{
  if (self.imageTypeSelector) {
    return;
  }

  self.imageTypeSelector = [[[GreeJSTakePhotoActionSheet alloc] initWithDelegate:self
                                                                showRemoveButton:selected] autorelease];
  self.imageTypeSelector.tag = tag;
  self.imageTypeSelector.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  [self.imageTypeSelector showInView:self.view];
}

-(void)setImage:(UIImage*)image atIndex:(NSInteger)index
{
  [self.images replaceObjectAtIndex:index withObject:image];
  [self validateEmpty];

  UIButton* customButton = [[[UIButton alloc] initWithFrame:CGRectMake(6, 6, 32, 32)] autorelease];
  [customButton setImage:image forState:UIControlStateNormal];
  [customButton addTarget:self action:@selector(showImagePickerSelected:)forControlEvents:UIControlEventTouchUpInside];
  customButton.layer.cornerRadius = 5.0f;
  customButton.layer.masksToBounds = YES;
  customButton.tag = index;
  customButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  UIView* containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
  [containerView addSubview:customButton];
  UIBarButtonItem* buttonItem = [[[UIBarButtonItem alloc] initWithCustomView:containerView] autorelease];
  buttonItem.tag = index;

  NSMutableArray* items  = [[self.toolbar.items mutableCopy] autorelease];
  [items replaceObjectAtIndex:(index * 2) withObject:buttonItem];
  self.toolbar.items = items;
}

-(void)removeImageAtIndex:(NSInteger)index
{
  [self.images replaceObjectAtIndex:index withObject:[NSNull null]];
  [self validateEmpty];

  UIImage* cameraNormalImage = [UIImage greeImageNamed:@"gree_btn_take_photo_default.png"];
  UIImage* cameraHighlightImage = [UIImage greeImageNamed:@"gree_btn_take_photo_highlight.png"];
  UIButton* cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  cameraButton.frame = CGRectMake(0, 0, 44.0f, 44.0f);
  [cameraButton addTarget:self action:@selector(showImagePicker:)forControlEvents:UIControlEventTouchUpInside];
  [cameraButton setBackgroundImage:cameraNormalImage forState:UIControlStateNormal];
  [cameraButton setBackgroundImage:cameraHighlightImage forState:UIControlStateHighlighted];

  UIBarButtonItem* buttonItem = [[[UIBarButtonItem alloc] initWithCustomView:cameraButton] autorelease];
  buttonItem.tag = index;

  NSMutableArray* items  = [[self.toolbar.items mutableCopy] autorelease];
  [items replaceObjectAtIndex:(index * 2) withObject:buttonItem];
  self.toolbar.items = items;
}


#pragma mark UITextView Placeholder Methods

-(void)setPlaceholder:(NSString*)placeholder color:(UIColor*)color
{
  self.placeholderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(8.0, 0.0, self.textView.frame.size.width - 20.0, 34.0)] autorelease];
  [self.placeholderLabel setText:placeholder];
  [self.placeholderLabel setBackgroundColor:[UIColor clearColor]];
  [self.placeholderLabel setFont:[self.textView font]];
  [self.placeholderLabel setTextColor:color];

  [self.textView addSubview:self.placeholderLabel];
}

-(void)showPlaceholder
{
  [self.placeholderLabel setHidden:YES];
}

-(void)hidePlaceholder
{
  [self.placeholderLabel setHidden:NO];
}

#pragma mark Validation

-(void)setupValidation:(NSDictionary*)params
{
  self.atLeastOneRequiredFields = [self parseAtLeastOneRequiredFieldsForParams:params];

  NSArray* fields = [NSArray arrayWithObjects:@"title", @"text", @"photo", @"spot", nil];
  NSMutableArray* requiredFields = [NSMutableArray arrayWithCapacity:fields.count];
  for (NSString* field in fields) {
    if ([self isFieldRequired:field forParams:params]) {
      [requiredFields addObject:field];
    }
  }
  self.requiredFields = requiredFields;
}

-(NSArray*)parseAtLeastOneRequiredFieldsForParams:(NSDictionary*)params
{
  NSString* fieldsString = [params objectForKey:@"required"];
  NSArray* unstrippedFields = [fieldsString componentsSeparatedByString:@","];
  NSMutableArray* fields = [NSMutableArray arrayWithCapacity:unstrippedFields.count];

  for (NSString* field in unstrippedFields) {
    [fields addObject:[field stringByReplacingOccurrencesOfString:@" " withString:@""]];
  }

  return fields;
}

-(BOOL)isFieldRequired:(NSString*)fieldName forParams:(NSDictionary*)params
{
  return [[params objectForKey:[NSString stringWithFormat:@"%@Required", fieldName]] boolValue];
}

-(BOOL)validateField:(NSString*)fieldName
{
  NSString* selectorName = [NSString stringWithFormat:@"validate%@Field", [fieldName capitalizedString]];
  SEL selector = NSSelectorFromString(selectorName);
  if ([self respondsToSelector:selector]) {
    return [self performSelector:selector] != nil;
  } else {
    GreeLog(@"%@ did not declare a validation method for %@ field; assuming field is valid.", [self class], fieldName);
    return YES;
  }
}

-(BOOL)validateTextField
{
  return [self textLength] != 0;
}

-(BOOL)validatePhotoField
{
  for (UIImage* image in self.images) {
    if (image && ![image isEqual:[NSNull null]]) {
      return YES;
    }
  }
  return NO;
}

-(BOOL)validateSpotField
{
  return ([self.locationInfo objectForKey:@"spotName"] &&
          [self.locationInfo objectForKey:@"spotId"]);
}

@end
