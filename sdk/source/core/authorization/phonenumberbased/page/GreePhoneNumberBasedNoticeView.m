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

#import "GreePhoneNumberBasedNoticeView.h"
#import "GreePhoneNumberBasedController.h"
#import "GreeGlobalization.h"


@interface GreePhoneNumberBasedNoticeView ()
@end

@implementation GreePhoneNumberBasedNoticeView

#pragma mark - Object Lifecycle

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.accessDenied.title")];
  self.noticeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.accessDenied.notice");
  [GreePhoneNumberBasedPage fitLabel:self.noticeLabel font:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontNoticeLabel]];
  [self resizeNoticeImageView:self.noticeBackgroundImage height:self.noticeLabel.frame.size.height];
}

@end
