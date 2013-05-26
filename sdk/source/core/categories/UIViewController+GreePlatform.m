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

#import "UIViewController+GreePlatform.h"
#import "UIViewController+GreeAdditions.h"
#import "UIView+GreeAdditions.h"
#import "GreePopup+Internal.h"
#import "GreeWidget+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeDashboardViewController.h"
#import "GreeAuthorization.h"
#import "GreeCampaignCode.h"
#import "GreeAuthorizationPopup.h"
#import "GreeNSNotification.h"
#import "GreeBenchmark.h"
#import "GreeRotator.h"

static GreeNotificationBoardLaunchType sTypeMap[GreeNotificationBoardTypeSNS+1] = {
  GreeNotificationBoardLaunchWithPlatform,
  GreeNotificationBoardLaunchWithSns
};

@interface UIViewController (GreeAdditionsInternal)
-(void)greeNotifyDelegateWillDisplay;
-(void)greeNotifyDelegateDidDismiss;
@end

@implementation UIViewController (GreePlatform)

-(void)presentGreeDashboardWithURL:(NSURL*)url animated:(BOOL)animated
{
  [self presentGreeDashboardWithBaseURL:url
                               delegate:self
                               animated:animated
                             completion:nil];
}

-(void)presentGreeDashboardWithParameters:(NSDictionary*)parameters animated:(BOOL)animated
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(@"dashboardStart")];
  NSURL* dashboardURL = [GreeDashboardViewController dashboardURLWithParameters:parameters];
  [self presentGreeDashboardWithBaseURL:dashboardURL delegate:self animated:animated completion:nil];
}

-(void)presentGreeNotificationBoardWithType:(GreeNotificationBoardType)type animated:(BOOL)animated
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkNotificationBoard position:GreeBenchmarkPosition(@"notificationBoardStart")];
  [self
   presentGreeNotificationBoardWithType:sTypeMap[type]
                             parameters:nil
                               delegate:self
                               animated:animated
                             completion:nil];
}

-(void)dismissActiveGreeViewControllerAnimated:(BOOL)animated
{
  [self dismissGreeDashboardAnimated:animated completion:nil];
  [self dismissGreeNotificationBoardAnimated:animated completion:nil];
}

#pragma mark GreePopup Display Methods

-(void)showGreePopup:(GreePopup*)popup
{
  GreePopup* currentPopup = [self greeCurrentPopup];

  if (currentPopup != nil) {
    popup.hostViewController = currentPopup.hostViewController;
    currentPopup.popupView.containerView.hidden = YES;
  } else {
    popup.hostViewController = self;
  }

  if(![popup isKindOfClass:[GreeAuthorizationPopup class]]) {
    NSString* campaignCode = nil;
    if ([popup.action isEqualToString:GreePopupShareAction]) campaignCode = GreeCampaignCodeServiceTypeShare;
    if ([popup.action isEqualToString:GreePopupInviteAction]) campaignCode = GreeCampaignCodeServiceTypeInvite;
    if ([popup.action isEqualToString:GreePopupRequestServiceAction]) campaignCode = GreeCampaignCodeServiceTypeRequest;

    if (campaignCode != nil && [[GreeAuthorization sharedInstance] handleBeforeAuthorize:campaignCode]) {
      return;
    }
  }

  GreePopupBlock originalWillDismissBlock = popup.willDismissBlock;
  GreePopupBlock originalDidDismissBlock = popup.didDismissBlock;

  popup.view.frame = self.view.bounds;

  popup.willDismissBlock =^(GreePopup* sender) {
    currentPopup.popupView.containerView.hidden = NO;

    if (originalWillDismissBlock) {
      originalWillDismissBlock(sender);
    }
  };

  popup.didDismissBlock =^(GreePopup* sender) {
    if (originalDidDismissBlock) {
      originalDidDismissBlock(sender);
    }

    [sender.view greeRemoveRotatingSubviewFromSuperview];

    [sender.hostViewController greeRemovePopup];
    [sender.hostViewController greeNotifyDelegateDidDismiss];
    [sender greeNotifyDidCloseNSNotificationWithParameters:sender.results];
  };

  [self greeNotifyDelegateWillDisplay];
  [self greeNotifyWillOpenNSNotificationForViewController:popup];

  [popup.view greeAddRotatingSubviewToViewController:self];
  [self greeAddPopup:popup];
  [popup show];
}

-(void)dismissGreePopup
{
  GreePopup* popup = [self greeCurrentPopup];
  [popup dismiss];
}

#pragma mark GreeWidget Display Methods
-(void)showGreeWidgetWithDataSource:(id<GreeWidgetDataSource>)dataSource
{
  //lazy initialize the widget
  if (![self greeCurrentWidget]) {
    GreeWidget* widget = [[GreeWidget alloc] initWithSettings:[[GreePlatform sharedInstance] settings]];
    widget.dataSource = dataSource;
    widget.hostViewController = self;
    [self greeSetCurrentWidget:widget];
    [widget release];
  } else {
    if ([self greeCurrentWidget].dataSource != dataSource) {
      [self greeCurrentWidget].dataSource = dataSource;
    }
  }
  UIView* rotatingContainerView = [self greeCurrentWidget].superview;
  if (rotatingContainerView == nil) {
    [[self greeCurrentWidget] greeAddRotatingSubviewToViewController:self];
  } else {
    //when the application received a memory warning, viewDidUnload will be called,
    //this view controller may release it's views, also contrainer view and widget view.
    //To Fix this, you need to call this method in viewDidLoad, so that we can add container view back
    if ([self greeCurrentWidget].window == nil) {
      [self.view addSubview:rotatingContainerView];
    }
  }
}

-(void)hideGreeWidget
{
  [[self greeCurrentWidget] greeRemoveRotatingSubviewFromSuperview];
}

-(GreeWidget*)activeGreeWidget
{
  if ([self greeCurrentWidget] && [[self greeCurrentWidget] superview] != nil && [self greeCurrentWidget].window != nil) {
    return [self greeCurrentWidget];
  } else {
    return nil;
  }
}

@end
