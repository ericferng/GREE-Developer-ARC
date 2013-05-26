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


#import "GreeJSTakePhotoPickerController.h"

@implementation GreeJSTakePhotoPickerController

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
  }
  return self;
}

-(void)dealloc
{
  self.imagePickerController.delegate = nil;
  self.callbackFunction = nil;
  self.imagePickerController = nil;

  [super dealloc];
}

@end
