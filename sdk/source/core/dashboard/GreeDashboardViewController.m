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
#import "GreePopoverController.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>
#import <QuartzCore/CAMediaTimingFunction.h>

#import "GreeDashboardViewController.h"
#import "GreeJSWebViewController.h"
#import "GreeJSWebViewControllerPool.h"
#import "GreeJSWebViewController+PullToRefresh.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeWebAppCache.h"

#import "UIImage+GreeAdditions.h"
#import "UINavigationItem+GreeAdditions.h"

#import "GreeNotificationBoardViewController.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

#import "GreeJSNotificationButton.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeAnalyticsEvent.h"

#import "UIViewController+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeNSNotification.h"
#import "GreeDashboardViewControllerLaunchMode.h"
#import "GreeLogger.h"
#import "GreeNotificationLoader.h"
#import "GreeNotifications.h"

#import "GreeJSWebViewController.h"
#import "GreeJSExternalWebViewController.h"

#import "NSURL+GreeAdditions.h"

#import "GreeJSHandler.h"

#import "GreeDashboardURLGenerator.h"
#import "GreeBenchmark.h"
#import "GreeJSNotificationButton.h"
#import "GreeNotificationNavigationController.h"
#import "GreeNotificationTableViewController.h"
#import "GreeJSWebviewController+Notification.h"

#import "GreeUniversalMenuViewController.h"

#define kGreeJSWebViewUniversalMenuConnectionFailureFileName @"GreeUniversalMenuConnectionFailure.html"


@interface GreeDashboardViewController ()<GreePopoverControllerDelegate,
                                          GreeNotificationNavigationControllerDelegate>
@property (nonatomic, retain) UIImageView* iOS4NavBarBackground;
@property UIStatusBarStyle originalStatusBarStyle;
@property (nonatomic, retain) UIToolbar* notificationBar;
@property (nonatomic, retain) UIButton* umButton;
@property (nonatomic, retain) UIButton* popButton;
@property (nonatomic, retain) GreeJSNotificationButton* gameBadgeButton;
@property (nonatomic, retain) GreeJSNotificationButton* snsBadgeButton;
@property (nonatomic, retain) GreeJSNotificationButton* friendBadgeButton;
@property (nonatomic, retain) UIBarButtonItem* gameButtonItem;
@property (nonatomic, retain) UIBarButtonItem* snsButtonItem;
@property (nonatomic, retain) UIBarButtonItem* friendButtonItem;
@property (nonatomic, retain) UIButton* closeButton;
@property (nonatomic, retain) GreePopoverController* popover;
@property (nonatomic, assign) BOOL redisplayPopover;
@property (nonatomic, retain) id currentButtonItem;
@property (nonatomic, retain) id reachabilityHandle;

+(NSURL*)URLFromMenuViewController:(UIViewController*)viewController;

-(void)createViewControllers;
-(void)createRootViewController;
-(void)createMenuViewController;
-(void)enableScroll:(BOOL)enable subviewsOf:(UIView*)view;
-(void)enableMenuViewController:(BOOL)enable;
-(void)loadBadgeValue;
-(void)gameButtonTapped:(id)sender;
-(void)snsButtonTapped:(id)sender;
-(void)friendButtonTapped:(id)sender;
-(void)showNotificationBoardWithType:(GreeNotificationBoardType)type
                      fromButtonItem:(UIBarButtonItem*)buttonItem;
-(CGSize)popoverContentSize;
-(UIBarButtonItem*)dummyBarButtonItem;
-(NSArray*)navBarItems;

@end


@implementation GreeDashboardViewController

#pragma mark - Object Lifecycle

-(id)initWithPath:(NSString*)path
{
  NSString* gameDashboardBaseURLString = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlApps];

  NSURL* gameDashboardBaseURL = [NSURL URLWithString:gameDashboardBaseURLString];
  NSURL* URL = nil;

  if (path != nil) {
    URL = [NSURL URLWithString:path relativeToURL:gameDashboardBaseURL];
  } else {
    NSString* applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
    NSString* gameDashboardPath = [NSString stringWithFormat:@"gd?app_id=%@", applicationIdString];
    URL = [NSURL URLWithString:gameDashboardPath relativeToURL:gameDashboardBaseURL];
  }

  return [self initWithBaseURL:URL];
}

-(id)initWithBaseURL:(NSURL*)baseURL;
{
  if ((self = [super initWithNibName:nil bundle:nil])) {
    self.baseURL = baseURL;

    GreeAnalyticsEvent* event = [GreeAnalyticsEvent eventWithType:@"pg"
                                                             name:[[GreeJSWebViewController class] viewNameFromURL:baseURL]
                                                             from:@"game"
                                                       parameters:[[baseURL query] greeDictionaryFromQueryString]];

    [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  }

  return self;
}

-(void)dealloc
{
  [[UIApplication sharedApplication] setStatusBarStyle:self.originalStatusBarStyle animated:YES];
  NSURL* fromURL = [[self class] URLFromMenuViewController:self.rootViewController];

  GreeAnalyticsEvent* event = [GreeAnalyticsEvent
                               eventWithType:@"pg"
                                        name:@"game"
                                        from:[[GreeJSWebViewController class] viewNameFromURL:fromURL] parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  self.results = nil;
  self.baseURL = nil;
  self.iOS4NavBarBackground  = nil;

  if ([GreePlatform sharedInstance].manuallyRotate) {
    [GreePlatform beginGeneratingRotation];
  }

  self.notificationBar = nil;
  self.umButton = nil;
  self.popButton = nil;
  self.gameBadgeButton = nil;
  self.snsBadgeButton = nil;
  self.friendBadgeButton = nil;
  self.closeButton = nil;
  self.gameButtonItem = nil;
  self.snsButtonItem = nil;
  self.friendButtonItem = nil;
  self.currentButtonItem = nil;
  self.popover = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[GreePlatform sharedInstance].reachability removeObserverBlock:self.reachabilityHandle];
  self.reachabilityHandle = nil;

  [super dealloc];
}

-(void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  if ([self isViewLoaded] && self.view.window == nil) {
    self.iOS4NavBarBackground = nil;
    self.view = nil;
  }
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Public Interface

+(NSURL*)dashboardURLWithParameters:(NSDictionary*)parameters
{
  return [GreeDashboardURLGenerator dashboardURLWithParameters:parameters];
}

#pragma mark - UIViewController Overrides

-(void)loadView
{
  [super loadView];

  [self createViewControllers];
  self.delegate = self;
  self.originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self loadBadgeValue];
}

-(void)viewDidAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
  [self enableMenuViewController:NO];
}

-(UIBarButtonItem*)dummyBarButtonItem
{
  UIBarButtonItem* dummy = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                          action:nil] autorelease];
  dummy.width = 1.f;
  return dummy;
}

-(NSArray*)navBarItems
{

  UIBarButtonItem* dummy = [self dummyBarButtonItem];

  UIBarButtonItem* flexibleButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil
                                                                                      action:nil];
  UIBarButtonItem* fixedButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                   target:nil
                                                                                   action:nil];
  fixedButtonItem.width = -8.f;
  self.gameButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.gameBadgeButton] autorelease];
  self.snsButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.snsBadgeButton] autorelease];
  self.friendButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.friendBadgeButton] autorelease];
  UIBarButtonItem* closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];

  NSMutableArray* items = [NSMutableArray arrayWithObjects:
                           dummy,
                           fixedButtonItem, nil];

  if (![GreePlatform shouldPersistUniversalMenuForIPad]) {
    UIBarButtonItem* umButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.umButton];
    [items addObject:umButtonItem];
    [umButtonItem release];
  } else {
    [items addObject:dummy];
  }

  [items addObject:flexibleButtonItem];
  [items addObject:self.gameButtonItem];

  if (![[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingDisableSNSFeature]) {
    self.snsButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.snsBadgeButton] autorelease];
    self.friendButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.friendBadgeButton] autorelease];

    [items addObject:self.snsButtonItem];
    [items addObject:self.friendButtonItem];
  }
  [items addObject:closeButtonItem];
  [items addObject:fixedButtonItem];
  [items addObject:dummy];

  [flexibleButtonItem release];
  [fixedButtonItem release];
  [closeButtonItem release];

  return items;
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  UINavigationBar* navBar = [(UINavigationController*)self.rootViewController navigationBar];
  [navBar addSubview:self.notificationBar];
  [self.notificationBar setItems:[self navBarItems]];

  self.reachabilityHandle = [[GreePlatform sharedInstance].reachability
                             addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
                               if (previous == GreeNetworkReachabilityNotConnected ||
                                   previous == GreeNetworkReachabilityUnknown) {
                                 [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:^(GreeBadgeValues* badgeValues) {
                                    if (badgeValues.applicationBadgeCount > 0) {
                                      [GreeNotificationLoader loadGameFeeds];
                                    }
                                    if (badgeValues.snsBadgeCount > 0) {
                                      [GreeNotificationLoader loadSNSFeeds];
                                    }
                                    if (badgeValues.friendBadgeCount > 0) {
                                      [GreeNotificationLoader loadFriendFeeds];
                                    }
                                  }];
                               }
                             }];

  [[NSNotificationCenter defaultCenter]
   addObserver:self
      selector:@selector(applicationDidBecomeActiveNotification:)
          name:UIApplicationDidBecomeActiveNotification
        object:nil];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation == toInterfaceOrientation;
  }
  return [[self greePresentingViewController] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

-(NSUInteger)supportedInterfaceOrientations
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return (1 << [GreePlatform sharedInstance].interfaceOrientation);
  }
  return [[self greePresentingViewController] supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotate
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    [GreePlatform endGeneratingRotation];
  }
  return YES;
}

/*
 * This change doesn't seem to have any effect,
 * however, it allows for the correct application-wide orientation configuration
 * to be applied to the initial dashboard activation when running under Unity. - GGPCLIENTSDK-4370
 */
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation;
  }
  return [self greePresentingViewController].interfaceOrientation;
}

-(void)presentGreeDashboardWithBaseURL:(NSURL*)URL
                              delegate:(id<GreeDashboardViewControllerDelegate>)delegate
                              animated:(BOOL)animated
                            completion:(void (^)(void))completion
{
  UIViewController* topViewController = self.rootViewController.topViewController;
  if ([topViewController isKindOfClass:[GreeJSExternalWebViewController class]]) {
    [self.rootViewController popViewControllerAnimated:YES];
  }
  GreeJSWebViewController* webViewController = (GreeJSWebViewController*)self.rootViewController.topViewController;
  [webViewController.webView loadRequest:[NSURLRequest requestWithURL:URL]];

  if (completion) {
    completion();
  }
}

-(void)presentGreeDashboardWithParameters:(NSDictionary*)parameters animated:(BOOL)animated
{
  NSURL* URL = [[self class] dashboardURLWithParameters:parameters];
  [self presentGreeDashboardWithBaseURL:URL delegate:self.dashboardDelegate animated:animated completion:nil];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  if (self.popover.isPopoverVisible) {
    self.redisplayPopover = YES;
    self.currentButtonItem = self.popover.context;
    [self.popover dismissPopoverAnimated:NO];
    self.popover = nil;;
  }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  if (self.redisplayPopover) {
    GreeNotificationBoardType boardType = NSIntegerMax;
    if ([self.currentButtonItem isEqual:self.gameButtonItem]) {
      boardType = GreeNotificationBoardTypeGame;
    } else if([self.currentButtonItem isEqual:self.snsButtonItem]) {
      boardType = GreeNotificationBoardTypeSns;
    } else if([self.currentButtonItem isEqual:self.friendButtonItem]) {
      boardType = GreeNotificationBoardTypeFriend;
    }
    [self showNotificationBoardWithType:boardType fromButtonItem:self.currentButtonItem];
    self.redisplayPopover = NO;
    self.currentButtonItem = nil;
  }
}

#pragma mark - Internal Methods

+(NSURL*)URLFromMenuViewController:(UIViewController*)viewController
{
  return nil;
}

-(void)createViewControllers
{
  [self createRootViewController];
  [self createMenuViewController];
}

-(void)createRootViewController
{
  if (self.rootViewController) {
    return;
  }

  CGRect bounds = [[UIScreen mainScreen] bounds];
  GreeJSWebViewController* webViewController = [[[GreeJSWebViewController alloc] initWithFrame:CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width - OPEN_MENU_OFFSET, bounds.size.height)] autorelease];
  webViewController.pool = [[[GreeJSWebViewControllerPool alloc] init] autorelease];
  webViewController.pool.preloadURL =
    [NSURL URLWithString:[[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns]];

  __block void (^initializer)(GreeJSWebViewController*) =^(GreeJSWebViewController* webViewController) {
    webViewController.view.backgroundColor = [UIColor colorWithRed:(0xE7/255.0f)
                                                             green:(0xE8/255.0f)
                                                              blue:(0xE9/255.0f)
                                                             alpha:1.0f];
    webViewController.webView.opaque = NO;
    webViewController.webView.backgroundColor = [UIColor colorWithRed:(0xE4/255.0f)
                                                                green:(0xE5/255.0f)
                                                                 blue:(0xE6/255.0f)
                                                                alpha:1.0f];
  };

  webViewController.preloadInitializeBlock =^(GreeJSWebViewController* current, GreeJSWebViewController* preload) {
    initializer(preload);
  };
  initializer(webViewController);

  [webViewController.webView loadRequest:[NSURLRequest requestWithURL:self.baseURL]];

  UINavigationController* rootNavigationController =
    [[[UINavigationController alloc] initWithRootViewController:webViewController] autorelease];
  rootNavigationController.delegate = self;

  self.rootViewController = rootNavigationController;
}

-(void)createMenuViewController
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(@"umStart")];

  if (self.menuViewController) {
    return;
  }

  UIViewController* universalMenuViewController = [[[GreeUniversalMenuViewController alloc] init] autorelease];

  UINavigationController* universalMenuNavigationController =
    [[[UINavigationController alloc] initWithRootViewController:universalMenuViewController] autorelease];
  universalMenuNavigationController.navigationBarHidden = YES;
  universalMenuNavigationController.delegate = self;

  self.menuViewController = universalMenuNavigationController;
}

-(void)showNotificationView:(id)sender
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(@"goToNotificationBoard")];

  [self presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchAutoSelect
                                  parameters:nil
                                    delegate:self
                                    animated:YES
                                  completion:nil];
}

-(void)dismissDashboard:(id)sender
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(kGreeBenchmarkDismiss)];
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(kGreeBenchmarkDismiss)];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  if ([self.dashboardDelegate respondsToSelector:@selector(dashboardCloseButtonPressed:)]) {
    [self.dashboardDelegate dashboardCloseButtonPressed:self];
  }
}

-(void)loadBadgeValue
{
  [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:^(GreeBadgeValues* badgeValues) {
     if (badgeValues.applicationBadgeCount > 0) {
       [GreeNotificationLoader loadGameFeeds];
     }
     if (badgeValues.snsBadgeCount > 0) {
       [GreeNotificationLoader loadSNSFeeds];
     }
     if (badgeValues.friendBadgeCount > 0) {
       [GreeNotificationLoader loadFriendFeeds];
     }
   }];
}

-(void)revealButtonPushed
{
  [super revealButtonPushed];
  [self.popover dismissPopoverAnimated:NO];
}

-(UIToolbar*)notificationBar
{
  if (!_notificationBar) {
    UINavigationBar* navBar = [(UINavigationController*)self.rootViewController navigationBar];
    _notificationBar = [[UIToolbar alloc] initWithFrame:navBar.bounds];
    _notificationBar.autoresizingMask =
      UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    UIImage* imagePortrait = [UIImage greeImageNamed:@"nav_bar_bg_portrait.png"];
    if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
      UIImage* imageLandscape = [UIImage greeImageNamed:@"nav_bar_bg_landscape.png"];
      UIEdgeInsets insets = UIEdgeInsetsMake(0.f, 6.f, 0.f, 6.f);
      [_notificationBar setBackgroundImage:[imagePortrait resizableImageWithCapInsets:insets]
                        forToolbarPosition:UIToolbarPositionAny
                                barMetrics:UIBarMetricsDefault];
      [_notificationBar setBackgroundImage:[imageLandscape resizableImageWithCapInsets:insets]
                        forToolbarPosition:UIToolbarPositionAny
                                barMetrics:UIBarMetricsLandscapePhone];
      _notificationBar.backgroundColor = [UIColor blackColor];
    } else {
      self.iOS4NavBarBackground = [[[UIImageView alloc] initWithImage:[imagePortrait stretchableImageWithLeftCapWidth:4 topCapHeight:0]] autorelease];
      self.iOS4NavBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      self.iOS4NavBarBackground.frame = CGRectMake(0, 0, navBar.bounds.size.width, navBar.bounds.size.height);
      self.iOS4NavBarBackground.backgroundColor = [UIColor blackColor];
      self.iOS4NavBarBackground.layer.zPosition = -1;
      [_notificationBar insertSubview:self.iOS4NavBarBackground atIndex:0];
    }
  }
  return _notificationBar;
}

-(UIButton*)umButton
{
  if (!_umButton) {
    _umButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    UIImage* defaultImage = [UIImage greeImageNamed:@"navibar-um-def.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"navibar-um-highlight.png"];
    CGRect frame = CGRectMake(0.0,
                              0.0,
                              40.0,
                              36.0);
    _umButton.frame = frame;
    [_umButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_umButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];

    if ([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingDisableSNSFeature])
      _umButton.hidden = YES;
    else
      [_umButton addTarget:self action:@selector(revealButtonPushed)forControlEvents:UIControlEventTouchUpInside];
  }
  return _umButton;
}

-(UIButton*)popButton
{
  if (!_popButton) {
    _popButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    UIImage* defaultImage = [UIImage greeImageNamed:@"navibar-back-def.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"navibar-back-press.png"];
    [_popButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_popButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    CGRect frame = CGRectMake(0.0,
                              0.0,
                              40.0,
                              36.0);
    _popButton.frame = frame;
    [_popButton addTarget:self action:@selector(onBackButtonPressed)forControlEvents:UIControlEventTouchUpInside];
  }
  return _popButton;
}

-(GreeJSNotificationButton*)gameBadgeButton
{
  if (!_gameBadgeButton) {
    _gameBadgeButton = [[GreeJSNotificationButton greeButtonWithType:UIButtonTypeCustom
                                                    notifyButtonType:GreeNotifyButtonTypeGame] retain];
    [_gameBadgeButton addTarget:self action:@selector(gameButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];
    UIImage* defaultImage = [UIImage greeImageNamed:@"navibar-nb-game-def.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"navibar-nb-game-press.png"];
    UIImage* onImage = [UIImage greeImageNamed:@"navibar-nb-game-on.png"];
    _gameBadgeButton.didUpdateBlock =^(GreeJSNotificationButton* badge) {
      if (badge.badgeNumber > 0) {
        [badge setBackgroundImage:onImage forState:UIControlStateNormal];
      } else {
        [badge setBackgroundImage:defaultImage forState:UIControlStateNormal];
      }
    };
    [_gameBadgeButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_gameBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [_gameBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateSelected];
  }
  return _gameBadgeButton;
}

-(GreeJSNotificationButton*)snsBadgeButton
{
  if (!_snsBadgeButton) {
    _snsBadgeButton = [[GreeJSNotificationButton greeButtonWithType:UIButtonTypeCustom
                                                   notifyButtonType:GreeNotifyButtonTypeSNS] retain];
    [_snsBadgeButton addTarget:self action:@selector(snsButtonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
    UIImage* defaultImage = [UIImage greeImageNamed:@"navibar-nb-sns-def.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"navibar-nb-sns-press.png"];
    UIImage* onImage = [UIImage greeImageNamed:@"navibar-nb-sns-on.png"];
    _snsBadgeButton.didUpdateBlock =^(GreeJSNotificationButton* button) {
      if (button.badgeNumber > 0) {
        [button setBackgroundImage:onImage forState:UIControlStateNormal];
      } else {
        [button setBackgroundImage:defaultImage forState:UIControlStateNormal];
      }
    };
    [_snsBadgeButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_snsBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [_snsBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateSelected];
  }
  return _snsBadgeButton;
}

-(GreeJSNotificationButton*)friendBadgeButton
{
  if (!_friendBadgeButton) {
    _friendBadgeButton = [[GreeJSNotificationButton greeButtonWithType:UIButtonTypeCustom
                                                      notifyButtonType:GreeNotifyButtonTypeFriend] retain];
    [_friendBadgeButton addTarget:self action:@selector(friendButtonTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
    UIImage* defaultImage = [UIImage greeImageNamed:@"navibar-nb-friend-def.png"];
    UIImage* highlightedImage = [UIImage greeImageNamed:@"navibar-nb-friend-press.png"];
    UIImage* onImage = [UIImage greeImageNamed:@"navibar-nb-friend-on.png"];
    _friendBadgeButton.didUpdateBlock =^(GreeJSNotificationButton* button) {
      if (button.badgeNumber > 0) {
        [button setBackgroundImage:onImage forState:UIControlStateNormal];
      } else {
        [button setBackgroundImage:defaultImage forState:UIControlStateNormal];
      }
    };
    [_friendBadgeButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_friendBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [_friendBadgeButton setBackgroundImage:highlightedImage forState:UIControlStateSelected];
  }
  return _friendBadgeButton;
}

-(UIButton*)closeButton
{
  if (!_closeButton) {
    _closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    UIImage* buttonImage = [UIImage greeImageNamed:@"navibar-close-def.png"];
    UIImage* buttonImageHighlight = [UIImage greeImageNamed:@"navibar-close-press.png"];
    _closeButton.frame = CGRectMake(0, 0, 40.0, 36.0);
    [_closeButton setImage:buttonImage
                  forState:UIControlStateNormal];
    [_closeButton setImage:buttonImageHighlight
                  forState:UIControlStateHighlighted];
    [_closeButton addTarget:self
                     action:@selector(dismissDashboard:)
           forControlEvents:UIControlEventTouchUpInside];
  }
  return _closeButton;
}

-(void)onBackButtonPressed
{
  [self.rootViewController popViewControllerAnimated:YES];
}

-(void)gameButtonTapped:(id)sender
{
  GreeAnalyticsEvent* event = [GreeAnalyticsEvent eventWithType:@"evt"
                                                           name:@"ngame"
                                                           from:@"nb"
                                                     parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  [self showNotificationBoardWithType:GreeNotificationBoardTypeGame
                       fromButtonItem:self.gameButtonItem];
}

-(void)snsButtonTapped:(id)sender
{
  GreeAnalyticsEvent* event = [GreeAnalyticsEvent eventWithType:@"evt"
                                                           name:@"nsns"
                                                           from:@"nb"
                                                     parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  [self showNotificationBoardWithType:GreeNotificationBoardTypeSns
                       fromButtonItem:self.snsButtonItem];
}

-(void)friendButtonTapped:(id)sender
{
  GreeAnalyticsEvent* event = [GreeAnalyticsEvent eventWithType:@"evt"
                                                           name:@"nfriend"
                                                           from:@"nb"
                                                     parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  [self showNotificationBoardWithType:GreeNotificationBoardTypeFriend
                       fromButtonItem:self.friendButtonItem];
}

-(void)showNotificationBoardWithType:(GreeNotificationBoardType)type
                      fromButtonItem:(UIBarButtonItem*)buttonItem
{
  if (self.popover.isPopoverVisible) {
    if ([self.popover.context isEqual:buttonItem]) {
      ((UIButton*)buttonItem.customView).selected = NO;
      [self.popover dismissPopoverAnimated:NO];
      return;
    }
  }
  if (self.popover.isPopoverVisible) {
    [self.popover dismissPopoverAnimated:NO];
  }
  GreeNotificationNavigationController* navigation = [[GreeNotificationNavigationController alloc] initWithNotificationType:type];
  navigation.delegate = self;


  self.popover = [[[GreePopoverController alloc] initWithContentViewController:navigation] autorelease];
  self.popover.delegate = self;
  self.popover.context = buttonItem;

  if (![[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingDisableSNSFeature])
    self.popover.passthroughViews  =[NSArray arrayWithObjects:
                                     self.gameBadgeButton,
                                     self.snsBadgeButton,
                                     self.friendBadgeButton, nil];

  self.popover.popoverContentSize = [self popoverContentSize];
  GreePopoverContainerViewProperties* properties = [[GreePopoverContainerViewProperties alloc] init];
  CGSize imageSize = CGSizeMake(30.0f, 30.0f);
  CGFloat bgMargin = 10.0f;
  CGFloat contentMargin = 3.0f;
  CGFloat rightcontentMarginAdjust = 1.f;
  properties.leftBgMargin = bgMargin;
  properties.rightBgMargin = bgMargin;
  properties.topBgMargin = bgMargin;
  properties.bottomBgMargin = bgMargin;
  properties.leftBgCapSize = imageSize.width/2.f;
  properties.topBgCapSize = imageSize.height/2.f;
  properties.leftContentMargin = contentMargin;
  properties.rightContentMargin = contentMargin-rightcontentMarginAdjust;
  properties.topContentMargin = contentMargin;
  properties.bottomContentMargin = contentMargin;
  properties.roundCorner = NO;
  properties.bgImageName = @"nb-window-base.png";
  properties.upArrowImageName = @"nb-window-arw.png";
  self.popover.containerViewProperties = properties;
  [self.popover presentPopoverFromBarButtonItem:buttonItem
                       permittedArrowDirections:UIPopoverArrowDirectionUp
                                       animated:NO];

  CGRect barRect = navigation.topBar.frame;
  barRect.origin.x -= properties.leftContentMargin;
  barRect.origin.y -= properties.topContentMargin;
  barRect.size.width = self.popover.popoverContentSize.width+(properties.leftContentMargin*2)-1;
  barRect.size.height += properties.topContentMargin;
  navigation.topBar.frame = barRect;
  [self.popover.contentViewController.view addSubview:navigation.topBar];
  navigation.titleLabel.frame =  CGRectOffset(barRect, 0.f, 4.f);
  [navigation.topBar addSubview:navigation.titleLabel];
  [properties release];
  [navigation release];

  GreeJSNotificationButton* badge = (GreeJSNotificationButton*)buttonItem.customView;
  if ([badge isKindOfClass:[GreeJSNotificationButton class]]) {
    if (badge.notifyButtonType == GreeNotifyButtonTypeSNS ||
        badge.notifyButtonType == GreeNotifyButtonTypeFriend) {
      badge.badgeNumber = 0;
    }
    if (badge.badgeNumber == 0) {
      badge.selected = YES;
    }
  }
}

-(CGSize)popoverContentSize
{
  CGSize contentSize = CGSizeZero;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    contentSize = CGSizeMake(300.0f, 576.0f);
  } else {
    BOOL landscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    if (frame.size.height==548.0f || frame.size.height==568.0f) { //iPhone 4inch
      contentSize = (landscape) ? CGSizeMake(540.0f, 245.0f) : CGSizeMake(294.0f, 490.0f);
    } else { // iPhone 3.5inch
      contentSize = (landscape) ? CGSizeMake(454.0f, 245.0f) : CGSizeMake(294.0f, 394.0f);
    }
  }
  return contentSize;
}

#pragma mark - Nav Bar Delegate Methods

-(void)navigationController:(UINavigationController*)navigationController
     willShowViewController:(UIViewController*)viewController
                   animated:(BOOL)animated
{
  [super navigationController:navigationController willShowViewController:viewController animated:animated];

  if (self.menuViewController == navigationController) {
    if (navigationController.viewControllers.count > 1)
      [navigationController setNavigationBarHidden:NO animated:YES];
    else
      [navigationController setNavigationBarHidden:YES animated:YES];
  } else if(self.rootViewController == navigationController) {
    NSMutableArray* items = [[self.notificationBar items] mutableCopy];
    if (items == nil || items.count < 3) {
      [items release];
      return;
    }
    UIView* customView = nil;
    UIBarButtonItem* replaceItem = [items objectAtIndex:2];
    if (navigationController.viewControllers.count > 1) {
      customView = self.popButton;
    } else if (![GreePlatform shouldPersistUniversalMenuForIPad]) {
      customView = self.umButton;
    } else {
      [items replaceObjectAtIndex:2 withObject:[self dummyBarButtonItem]];
      [self.notificationBar setItems:items animated:YES];
    }
    if (customView && ![replaceItem.customView isEqual:customView]) {
      UIBarButtonItem* newItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
      [items replaceObjectAtIndex:2 withObject:newItem];
      [self.notificationBar setItems:items animated:YES];
      [newItem release];
    }
    [items release];
  }

  // Force to call the viewWillAppear methoad of push viewController, because iOS4 is not call viewwillAppear methoad on GreeMenuNavController.
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
    [viewController viewWillAppear:animated];
  }
}

-(void)navigationController:(UINavigationController*)navigationController
      didShowViewController:(UIViewController*)viewController
                   animated:(BOOL)animated
{
  // Force to call the viewDidAppear methoad of push viewController, because iOS4 is not call viewDidAppear methoad on GreeMenuNavController.
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
    [viewController viewDidAppear:animated];
  }
}


#pragma mark - GreeMenuNavControllerDelegate Methods

-(void)enableScroll:(BOOL)enable subviewsOf:(UIView*)view
{
  if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
    view.userInteractionEnabled = enable;
  }
  for (UIView* subview in view.subviews) {
    [self enableScroll:enable subviewsOf:subview];
  }
}

-(void)enableMenuViewController:(BOOL)enable
{
  //For iPad, both view controllers should always be open and thus scrollable
  if ([GreePlatform shouldPersistUniversalMenuForIPad]) {
    [self enableScroll:YES subviewsOf:((UINavigationController*)self.menuViewController).topViewController.view];
    [self enableScroll:YES subviewsOf:self.rootViewController.topViewController.view];
  } else {
    [self enableScroll:enable subviewsOf:((UINavigationController*)self.menuViewController).topViewController.view];
    [self enableScroll:(!enable) subviewsOf:self.rootViewController.topViewController.view];
  }
}

-(void)menuController:(GreeMenuNavController*)controller didShowViewController:(UIViewController*)leftViewController
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(@"goToUM")];

  NSURL* fromURL = [[self class] URLFromMenuViewController:leftViewController];

  GreeAnalyticsEvent* event = [GreeAnalyticsEvent
                               eventWithType:@"pg" name:@"universalmenu_top"
                                        from:[[GreeJSWebViewController class] viewNameFromURL:fromURL]
                                  parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  [self enableMenuViewController:YES];
}

-(void)menuController:(GreeMenuNavController*)controller didHideViewController:(UIViewController*)leftViewController
{
  [self enableMenuViewController:NO];
}

-(void)menuController:(GreeMenuNavController*)controller willShowViewController:(UIViewController*)leftViewController
{
  [(GreeUniversalMenuViewController*)([(UINavigationController*)controller.menuViewController topViewController]) universalMenuWillOpen];
}

-(void)menuController:(GreeMenuNavController*)controller willHideViewController:(UIViewController*)leftViewController
{
}

-(void)popoverControllerDidDismissPopover:(GreePopoverController*)popoverController
{
  if (self.redisplayPopover) {
    return;
  }
  UIBarButtonItem* item = (UIBarButtonItem*)popoverController.context;
  if ([item isKindOfClass:[UIBarButtonItem class]]) {
    UIButton* button = (UIButton*)item.customView;
    if ([button isKindOfClass:[UIButton class]]) {
      button.selected = NO;
    }
  }

  self.popover = nil;
}

-(BOOL)popoverControllerShouldDismissPopover:(GreePopoverController*)popoverController
{
  return YES;
}

-(void)didSelectedFeedUrl:(NSString*)url
           launchExternal:(BOOL)launchExternal
               controller:(GreeNotificationNavigationController*)controller
{

  NSURL* fromURL = [[self class] URLFromMenuViewController:self.rootViewController];
  GreeAnalyticsEvent* event = [GreeAnalyticsEvent
                               eventWithType:@"pg"
                                        name:url
                                        from:[[GreeJSWebViewController class] viewNameFromURL:fromURL]
                                  parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  if (launchExternal) {
    NSURL* openUrl = [[NSURL alloc] initWithString:url];
    [[UIApplication sharedApplication] openURL:openUrl];
    [openUrl release];
  } else {
    [self.popover dismissPopoverAnimated:NO];
    UIViewController* topViewController = self.rootViewController.topViewController;
    if ([topViewController isKindOfClass:[GreeJSExternalWebViewController class]]) {
      [self.rootViewController popViewControllerAnimated:NO];
    }
    GreeJSWebViewController* web = (GreeJSWebViewController*)[self.rootViewController topViewController];
    if ([web isKindOfClass:[GreeJSWebViewController class]] &&
        [web respondsToSelector:@selector(didSelectedFeedUrl:controller:)]) {
      [web performSelector:@selector(didSelectedFeedUrl:controller:)withObject:url withObject:controller];
    }
  }
}

#pragma mark - UIGestureRecognizer delegate methoads

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  [self.popover dismissPopoverAnimated:NO];
  return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

#pragma mark - UIApplication delegate methoads

-(void)applicationDidBecomeActiveNotification:(id)sender
{
  [self loadBadgeValue];
}

@end
