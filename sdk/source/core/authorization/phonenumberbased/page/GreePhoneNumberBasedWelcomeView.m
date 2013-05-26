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

#import <QuartzCore/QuartzCore.h>
#import "GreePhoneNumberBasedWelcomeView.h"
#import "GreeGlobalization.h"
#import "GreePhoneNumberBasedController.h"
#import "GreeAuthorization.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeJSLoadingIndicatorView.h"

@interface GreePhoneNumberBasedWelcomeView ()
@property (nonatomic, retain) GreeJSLoadingIndicatorView* loadingView;
@property (nonatomic, assign) BOOL loginRetry;
-(BOOL)isIphone5;
-(BOOL)isLargerScreen;
-(void)resizeBackgroundImageView;
@end;

@implementation GreePhoneNumberBasedWelcomeNavigationController
-(void)viewDidLoad
{
  [super viewDidLoad];
  GreePhoneNumberBasedWelcomeView* controller = [[GreePhoneNumberBasedWelcomeView alloc] initWithNibName:nil bundle:[NSBundle greePlatformCoreBundle]];
  [self pushViewController:controller animated:NO];
  [controller release];
}
@end

@implementation GreePhoneNumberBasedWelcomeView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.createAccountButton = nil;
  self.loginButton = nil;
  self.welcomeLabel = nil;
  self.loadingView = nil;
  self.logoImage = nil;

  [super dealloc];
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  // Log when this screen is shown
  [[GreeAuthorization sharedInstance] logPageName:@"mg_top" block:nil];

  self.welcomeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.top.welcomeLabel");
  self.logoImage.frame = CGRectMake(self.logoImage.frame.origin.x, [UIScreen mainScreen].applicationFrame.size.height -  self.logoImage.frame.size.height - 5,
                                    self.logoImage.frame.size.width, self.logoImage.frame.size.height);

  if ([self isLargerScreen]) {
    [self resizeBackgroundImageView];
  } else {
    self.view.backgroundColor = [UIColor colorWithPatternImage:
                                 ([self isIphone5] ? [UIImage greeImageNamed:@"gree.reg.blueBackground.iphone5.png"]: [UIImage greeImageNamed:@"gree.reg.blueBackground.png"])];
  }

  [GreePhoneNumberBasedPage decorateButton:self.loginButton
                                      text:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.top.Login")
                                  fontSize:16
                                 fontColor:[GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorGrayButtonFont]
                               shadowColor:[GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorGrayButtonShadow]
                              defaultImage:[UIImage greeImageNamed:@"gree.onboarding.btn.default.png"]
                              touchedImage:[UIImage greeImageNamed:@"gree.onboarding.btn.highlighted.png"]];

  [GreePhoneNumberBasedPage decorateButton:self.createAccountButton
                                      text:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.top.register")
                                  fontSize:16
                                 fontColor:[GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorGrayButtonFont]
                               shadowColor:[GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorGrayButtonShadow]
                              defaultImage:[UIImage greeImageNamed:@"gree.onboarding.btn.default.png"]
                              touchedImage:[UIImage greeImageNamed:@"gree.onboarding.btn.highlighted.png"]];

  self.loadingView = [[[GreeJSLoadingIndicatorView alloc]
                       initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];

  [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil
                                                usingBlock:^(NSNotification* note){
     [self dismissLoadingView];
     self.loginRetry = NO;
   }];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
}

#pragma mark - Internal Methods

-(IBAction)onRegister:(id)sender
{
  [[GreeAuthorization sharedInstance] logPageName:@"mg_register_form" block:nil];
  [GreePhoneNumberBasedController sharedInstance].isNewRegistration = YES;
  [[GreePhoneNumberBasedController sharedInstance] showSignUpView];
}

-(IBAction)onLogin:(id)sender
{
  [self showLoadingView];
  [GreePhoneNumberBasedController sharedInstance].isNewRegistration = NO;
  self.loginRetry = YES;
  [self retryLogin];
}

-(void)retryLogin
{
  if (!self.loginRetry) {
    return;
  }

  [GreePlatform directAuthorizeWithDesiredGrade:GreeUserGradeStandard block:^(GreeUser* localUser, NSError* error){
     if (error) {
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self retryLogin];
                      });
     }
   }];
}

-(BOOL)isIphone5
{
  CGSize size = [UIScreen mainScreen].bounds.size;
  return size.width == 320.0 && size.height == 568.0;
}

-(BOOL)isLargerScreen
{
  CGSize size = [UIScreen mainScreen].bounds.size;
  return size.height > 568.0;
}

-(void)resizeBackgroundImageView
{
  UIImage* noticeImage = [UIImage imageWithContentsOfFile:[[NSBundle greePlatformCoreBundle] pathForResource:@"gree.reg.blueBackground.iphone5@2x" ofType:@"png"]];
  UIImage* resizableImage = [GreePhoneNumberBasedPage convertResizableImage:noticeImage];

  UIImageView* resultImageView = [[[UIImageView alloc] initWithImage:resizableImage] autorelease];
  resultImageView.frame = CGRectMake(0, 0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
  resultImageView.layer.zPosition = -1;

  [self.view addSubview:resultImageView];
}
@end
