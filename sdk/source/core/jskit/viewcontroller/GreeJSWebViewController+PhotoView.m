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

#import "GreeJSWebViewController+PhotoView.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeJSPushViewWithUrlCommand.h"
#import "UINavigationItem+GreeAdditions.h"

@implementation GreeJSWebViewController (PhotoView)

#pragma mark - Internal Methods

-(void)showContentDetailWithPhotoInfo:(GreePhotoInfo*)info
{
  NSString* urn = [NSString string];
  if ([[[info content] contentType] isEqualToString:GreeContentTypeMood]) {
    urn = [NSString stringWithFormat:@"mood:md:%d_%d",
           [info.content userId],
           [info.content contentId]];
  } else if([[[info content] contentType] isEqualToString:GreeContentTypePhoto]) {
    urn = [NSString stringWithFormat:@"urn:gree:photo:%d_%d",
           [info.content contentId],
           [info.content userId]
          ];
  }
  NSString* urlString = [NSString stringWithFormat:@"%@/#view=stream_permalink&urn=%@",
                         [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns],
                         urn];

  GreeJSWebViewController* nextViewController = [self preloadNextWebViewController];
  nextViewController.beforeWebViewController = self;

  nextViewController.navigationItem.leftBarButtonItem = nil;
  [nextViewController.navigationItem setSameRightBarButtonItems:self.navigationItem];

  [self setBackButtonForNavigationItem:nextViewController.navigationItem];
  [nextViewController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
  [self.navigationController pushViewController:nextViewController animated:YES];
}

-(void)showContentEditWithPhotoInfo:(GreePhotoInfo*)info
{
  NSString* urlString = [NSString stringWithFormat:@"%@/#view=photoalbum_editphoto&photo_id=%d",
                         [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns],
                         [[info content] contentId]];

  GreeJSWebViewController* nextViewController = [self preloadNextWebViewController];
  nextViewController.beforeWebViewController = self;

  nextViewController.navigationItem.leftBarButtonItem = nil;
  [nextViewController.navigationItem setSameRightBarButtonItems:self.navigationItem];

  [self setBackButtonForNavigationItem:nextViewController.navigationItem];
  [nextViewController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
  [self.navigationController pushViewController:nextViewController animated:YES];
}

#pragma mark - GreeJSPhotoViewController delegate methods

-(void)photoViewController:(GreeJSPhotoViewController*)controller
                 didAction:(GreePhotoAction)action
                 photoInfo:(GreePhotoInfo*)info
{
  if (!info) {
    return;
  }
  if (action == GreePhotoActionShowDetail) {
    [self showContentDetailWithPhotoInfo:info];
  } else if (action == GreePhotoActionShowEdit) {
    [self showContentEditWithPhotoInfo:info];
  }
}


@end
