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
#import "GreeJSLocationUpdateActionSheet.h"
#import "GreeGlobalization.h"

@interface GreeJSLocationUpdateActionSheet ()

@property (nonatomic, readwrite) NSInteger removeLocationButtonIndex;
@property (nonatomic, readwrite) NSInteger updateLocationButtonIndex;

@end

@implementation GreeJSLocationUpdateActionSheet

#pragma mark - Object Lifecycle

-(id)initWithDelegate:(id<UIActionSheetDelegate>)delegate
{
  self = [super    initWithTitle:nil
                        delegate:delegate
               cancelButtonTitle:nil
          destructiveButtonTitle:nil
               otherButtonTitles:nil];
  if (self) {
    // update location
    self.updateLocationButtonIndex =
      [self addButtonWithTitle:GreePlatformString(@"location.action.button.place.change", @"actionSheet change")];

    // remove location
    self.removeLocationButtonIndex =
      [self addButtonWithTitle:GreePlatformString(@"location.action.button.place.delete", @"actionSheet delete")];

    // cancel
    self.cancelButtonIndex =
      [self addButtonWithTitle:GreePlatformString(@"location.action.button.place.cancel", @"actionSheet cancel")];

    self.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  return self;
}

#pragma mark - NSObject overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
