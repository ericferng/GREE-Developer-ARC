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

#import "GreeJSWebViewController+Photo.h"
#import "GreeJSHandler.h"
#import "GreeJSUIImage+TakePhoto.h"
#import "GreeJSImageConfirmationViewController.h"
#import "GreeGlobalization.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "UIViewController+GreeAdditions.h"

@interface GreeJSWebViewController ()
@property (nonatomic, retain) GreeJSTakePhotoActionSheet* photoTypeSelector;
@property (nonatomic, retain) GreeJSTakePhotoPickerController* photoPickerController;
@property (nonatomic, retain) id popoverPhotoPicker;
@property (nonatomic, retain) NSSet* previousOrientations;
@property NSUInteger deviceOrientationCount;
@end

@implementation GreeJSWebViewController (Photo)

#pragma mark - GreeJSShowPhotoCommandDelegate Methods

-(void)greeJSShowPhotoViewer:(NSDictionary*)params
{
  
}

#pragma mark - GreeJSTakePhotoCommandDelegate Methods

-(void)greeJSShowTakePhotoSelector:(NSDictionary*)params
{
  if (self.photoTypeSelector) {
    return;
  }

  self.photoTypeSelector = [[[GreeJSTakePhotoActionSheet alloc] initWithDelegate:self
                                                                showRemoveButton:!![params valueForKey:@"resetCallback"]] autorelease];
  self.photoTypeSelector.callbackFunction = [params valueForKey:@"callback"];
  self.photoTypeSelector.resetCallbackFunction = [params valueForKey:@"resetCallback"];
  self.photoTypeSelector.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  [self.photoTypeSelector showInView:self.view];
}

#pragma mark - UIActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSString* callback = self.photoTypeSelector.callbackFunction;
  NSString* resetCallback = self.photoTypeSelector.resetCallbackFunction;

  self.photoPickerController = [[[GreeJSTakePhotoPickerController alloc] init] autorelease];
  self.photoPickerController.imagePickerController.delegate = self;
  self.photoPickerController.callbackFunction = callback;

  if (buttonIndex == self.photoTypeSelector.takePhotoButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else if (buttonIndex == self.photoTypeSelector.chooseFromAlbumButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  } else if (buttonIndex == self.photoTypeSelector.removePhotoButtonIndex) {
    [self.handler callback:resetCallback params:nil];
    self.photoTypeSelector = nil;
    return;
  } else {
    self.photoTypeSelector = nil;
    return;
  }

  self.photoTypeSelector = nil;

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && self.photoPickerController.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera) {
    if (!self.popoverPhotoPicker) {
      Class popoverController = NSClassFromString(@"UIPopoverController");
      self.popoverPhotoPicker =
        [[[popoverController alloc] initWithContentViewController:self.photoPickerController.imagePickerController] autorelease];
    } else {
      [self.popoverPhotoPicker setContentViewController:self.photoPickerController.imagePickerController];
    }
    [self.popoverPhotoPicker presentPopoverFromRect:CGRectMake(self.view.center.x, self.view.center.y, 32, 32)
                                             inView:self.view
                           permittedArrowDirections:0
                                           animated:YES];
  } else {
    [[UIViewController greeLastPresentedViewController] greePresentViewController:self.photoPickerController.imagePickerController
                                                                         animated:YES
                                                                       completion:nil];
  }
}

#pragma mark - UIImagePickerViewControllerDelegate Methods

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
    [self applyBase64StringFromImage:image];
  } else {
    GreeJSImageConfirmationViewController* controller =
      [[[GreeJSImageConfirmationViewController alloc] init] autorelease];
    controller.delegate = self;
    [controller setImage:image];

    [picker pushViewController:controller animated:YES];
  }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && picker.sourceType != UIImagePickerControllerSourceTypeCamera) {
    [self.popoverPhotoPicker dismissPopoverAnimated:YES];
  } else {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - GreeJSImageConfirmationViewControllerDelegate Methods

-(void)imageDidSelected:(GreeJSImageConfirmationViewController*)controller
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.popoverPhotoPicker dismissPopoverAnimated:YES];
  } else {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  }
  [self applyBase64StringFromImage:controller.image];
}

#pragma mark - Internal Method

-(void)applyBase64StringFromImage:(UIImage*)image
{
  UIImage* resizedImage = [UIImage greeResizeImage:image maxPixel:480 rotation:0];
  NSString* b64s = [resizedImage greeBase64EncodedString];
  if (b64s) {
    NSString* callback = self.photoPickerController.callbackFunction;
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithFloat:resizedImage.size.width], @"width",
                            [NSNumber numberWithFloat:resizedImage.size.height], @"height",
                            b64s, @"base64_image",
                            nil
                           ];
    [self.handler callback:callback params:params];
  }
}

@end
