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


#import "GreeJSPopupCloseSharePopupCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"

@implementation GreeJSPopupCloseSharePopupCommand

#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"close_popup";
}

-(void)execute:(NSDictionary*)params
{
  GreePopup* popup = (GreePopup*)[self viewControllerWithRequiredBaseClass:[GreePopup class]];

  if ([popup.popupView.delegate respondsToSelector:@selector(popupViewDidComplete:)]) {
    [popup.popupView.delegate popupViewDidComplete:params];
  }
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
