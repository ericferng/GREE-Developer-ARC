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


#import "GreeJSTakePhotoActionSheet.h"
#import "GreeGlobalization.h"

@implementation GreeJSTakePhotoActionSheet

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.callbackFunction = nil;
  self.resetCallbackFunction = nil;
  [super dealloc];
}

-(id)initWithDelegate:(id<UIActionSheetDelegate>)delegate showRemoveButton:(BOOL)showRemoveButton
{
  self = [super    initWithTitle:nil
                        delegate:delegate
               cancelButtonTitle:nil
          destructiveButtonTitle:nil
               otherButtonTitles:nil];
  if (self) {
    BOOL isCameraAvailable = ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]);
    if (isCameraAvailable) {
      self.takePhotoButtonIndex =
        [self addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.TakePhotoButton.Title", @"Take Photo")];
    } else {
      self.takePhotoButtonIndex = -1;
    }

    self.chooseFromAlbumButtonIndex =    [self addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.ChooseFromAlbumButton.Title", @"Choose From Album")];

    if (showRemoveButton) {
      self.removePhotoButtonIndex =
        [self addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.RemovePhotoButton.Title", @"Remove Photo")];
    } else {
      self.removePhotoButtonIndex = -1;
    }

    self.cancelButtonIndex =
      [self addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.CancelButton.Title", @"Cancel")];
  }
  return self;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
