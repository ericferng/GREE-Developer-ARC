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
#import "JSONKit.h"

#import "GreeJSWebViewController.h"
#import "GreeJSWebViewControllerPool.h"
#import "GreeJSHandler.h"
#import "GreeJSCommandEnvironment.h"
#import "GreeJSWebViewMessageEvent.h"
#import "GreeJSSubnavigationView.h"
#import "GreeJSSubnavigationMenuView.h"
#import "GreeJSPullToRefreshHeaderView.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeJSWebViewController+PullToRefresh.h"
#import "GreeJSWebViewController+StateCommand.h"
#import "GreeJSWebViewController+Photo.h"
#import "GreeJSWebViewController+ModalView.h"
#import "GreeJSWebViewController+SubNavigation.h"

#import "GreeSettings.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeWebSessionRegenerator.h"
#import "NSString+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "GreeLogger.h"
#import "NSURL+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeBenchmark.h"

#import "GreeNotificationBoardViewController.h"

#define kGreeJSWebViewConnectionFailureFileName @"GreePopupConnectionFailure.html"

@interface GreeJSWebViewController ()<GreeJSCommandEnvironment>
@property (assign) BOOL isProton;
@property (assign) BOOL isDragging;
@property (assign) BOOL isPullLoading;
@property (nonatomic, retain) NSTimer* pullToRefreshTimeoutTimer;
@property (nonatomic, retain) UIView* pullToRefreshBackground;
@property (nonatomic, retain) GreeJSPullToRefreshHeaderView* pullToRefreshHeader;
@property (nonatomic, retain) GreeJSTakePhotoActionSheet* photoTypeSelector;
@property (nonatomic, retain) GreeJSTakePhotoPickerController* photoPickerController;
@property (nonatomic, retain) id popoverPhotoPicker;
@property (nonatomic, readwrite, retain) GreeJSSubnavigationView* subNavigationView;
@property (nonatomic, assign) BOOL connectionFailureContentsLoading;
@property (nonatomic, readwrite, assign) BOOL deadlyProtonErrorOccured;
@property (nonatomic, retain) NSSet* previousOrientations;
@property (nonatomic, retain, readwrite) UIWebView* webView;
@property (nonatomic, retain, readwrite) GreeJSHandler* handler;
@property (nonatomic, retain, readwrite) GreeJSLoadingIndicatorView* loadingIndicatorView;
@property (nonatomic, retain, readwrite) NSDictionary* pendingLoadRequest;

-(void)adjustWebViewContentInset;
-(void)onBackButtonPressed;
-(void)messageEventNotification:(NSNotification*)notification;
-(void)showHTTPErrorMessage:(NSError*)anError;
-(BOOL)shouldHandleRequest:(NSURLRequest*)request;
-(BOOL)handleSchemeItmsApps:(NSURLRequest*)request;
@end

@implementation GreeJSWebViewController

#pragma mark - Object Lifecycle

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.webView.delegate = nil;
  self.webView = nil;

  self.handler.currentCommand.environment = nil;
  self.handler = nil;

  self.nextWebViewController = nil;
  self.inputViewController = nil;
  self.pendingLoadRequest = nil;
  self.loadingIndicatorView = nil;
  self.subNavigationView = nil;
  self.pullToRefreshHeader = nil;
  self.pullToRefreshBackground = nil;

  self.modalRightButtonCallback = nil;
  self.modalRightButtonCallbackInfo = nil;
  self.beforeWebViewController = nil;
  self.pullToRefreshTimeoutTimer = nil;
  self.photoTypeSelector.delegate = nil;
  self.photoTypeSelector = nil;
  self.photoPickerController = nil;
  self.popoverPhotoPicker = nil;
  self.preloadInitializeBlock = nil;
  self.pool = nil;

  [super dealloc];
}

-(id)init
{
  self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
  return self;
}

-(id)initWithFrame:(CGRect)frame
{
  self = [super init];
  if (self) {
    self.webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
    self.webView.scalesPageToFit = YES;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.webView.delegate = self;

    self.handler = [[[GreeJSHandler alloc] init] autorelease];
    self.handler.webView = self.webView;
    self.isJavascriptBridgeEnabled = YES;
    self.subNavigationView = [[[GreeJSSubnavigationView alloc] initWithDelegate:self] autorelease];
    self.subNavigationView.frame = frame;

    _scrollView = [self.webView valueForKey:@"_scrollView"];
    _originalScrollViewDelegate = [[self.webView valueForKey:@"_scrollView"] delegate];
    [_scrollView setDecelerationRate:UIScrollViewDecelerationRateNormal];
    _scrollView.delegate = self;

    self.loadingIndicatorView = [[[GreeJSLoadingIndicatorView alloc] initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];
    self.pullToRefreshHeader = [[[GreeJSPullToRefreshHeaderView alloc] init] autorelease];
    self.pullToRefreshBackground =
      [[[UIView alloc] initWithFrame:CGRectMake(0,
                                                -frame.size.height - kGreeJSRefreshHeaderHeight,
                                                frame.size.width,
                                                frame.size.height)] autorelease];
    self.pullToRefreshBackground.backgroundColor = self.pullToRefreshHeader.backgroundColor;
    self.pullToRefreshBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageEventNotification:)
                                                 name:kGreeJSWebViewMessageEventNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailWithErrorNotification:)
                                                 name:kGreeJSDidFailWithError object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationBoardDidLaunchNotification:)
                                                 name:GreeNotificationBoardDidLaunchNotification object:nil];
    [self setCanPullToRefresh:YES];

    self.modalRightButtonCallback = nil;
    self.modalRightButtonCallbackInfo = nil;
    self.networkErrorMessageFilename = kGreeJSWebViewConnectionFailureFileName;

    [self displayLoadingIndicator:YES];

  }
  return self;
}

#pragma mark - UIViewController Overrides
-(void)loadView
{
  self.view = self.subNavigationView;
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  [self.subNavigationView setContentView:self.webView];
  [self setCanPullToRefresh:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // Release next webview controller.
  // Next webview controller create at push/modal view. however, it is not released pop/dismiss view.
  // We should release it when displayed before view controller.
  if (self.nextWebViewController) {
    self.nextWebViewController = nil;
  }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                               duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self adjustWebViewContentInset];
}

#pragma mark - Message Event forwarder

-(void)messageEventNotification:(NSNotification*)notification
{
  GreeJSWebViewMessageEvent* event = [notification.userInfo objectForKey:kGreeJSWebViewMessageEventObjectKey];
  [event fireMessageEventInWebView:self.webView];
}

#pragma mark - UIWebViewDelegate methods

-(BOOL)              webView:(UIWebView*)webView
  shouldStartLoadWithRequest:(NSURLRequest*)request
              navigationType:(UIWebViewNavigationType)navigationType
{
  if ([[request.URL path] isEqualToString:@"/gd"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadStart)];
  }
  if ([[request.URL path] isEqualToString:@"/um"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadStart)];
  }


  if([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingShowConnectionServer]) {
    if (!([[request.URL path] isEqualToString:@"/"] && ![request.URL query] && ![request.URL fragment])) {
      [self.webView attachLabelWithURL:request.URL position:GreeWebViewUrlLabelPositionBottom];
    }
  }
  id regenerator =
    [GreeWebSessionRegenerator generatorIfNeededWithRequest:request webView:webView delegate:nil
                                         showHttpErrorBlock:^(NSError* error) {
       [self showHTTPErrorMessage:error];
     }];
  if (regenerator) {
    return NO;
  }

  if ([GreeJSHandler executeCommandFromRequest:request handler:self.handler environment:self]) {
    return NO;
  }

  if (self.connectionFailureContentsLoading) {
    self.deadlyProtonErrorOccured = YES;
    self.connectionFailureContentsLoading = NO;
    return YES;
  }

  if ([self shouldHandleRequest:request] == NO) {
    return NO;
  }

  return YES;
}

-(void)webViewDidStartLoad:(UIWebView*)webView
{
  self.isProton = NO;

  // Set a flag in window.name to distinguish proton clients from mobile safari.
  [self.webView stringByEvaluatingJavaScriptFromString:@"window.name='protonApp'"];
  if (!self.isPullLoading) {
    [self displayLoadingIndicator:YES];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)webViewDidFinishLoad:(UIWebView*)webView
{
  if ([[webView.request.URL path] isEqualToString:@"/gd"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadEnd)];
  }
  if ([[webView.request.URL path] isEqualToString:@"/um"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadEnd)];
  }

  self.isProton = [[self handler] isProtonPage];
  if (!self.isProton) {
    [self displayLoadingIndicator:NO];
    [self stopLoading];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
}

-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
  [self stopLoading];

  //MARK:Loading indicator will be removed after completion showHTTPErrorMessage.
  //[self displayLoadingIndicator:NO];
  [self showHTTPErrorMessage:error];
}

#pragma mark - GreeJSCommandEnvironment

-(UIViewController*)viewControllerForCommand:(GreeJSCommand*)command
{
  return self;
}

-(UIWebView*)webviewForCommand:(GreeJSCommand*)command
{
  return self.webView;
}

-(id)instanceOfProtocol:(Protocol*)protocol
{
  if ([self conformsToProtocol:protocol]) {
    return self;
  }

  return nil;
}

-(BOOL)shouldExecuteCommand:(GreeJSCommand*)command withParameters:(NSDictionary*)parameters
{
  return YES;
}

#pragma mark - Public Interface

-(void)setBackgroundColor:(UIColor*)color
{
  self.subNavigationView.backgroundColor = color;
}

-(void)setBackButtonForNavigationItem:(UINavigationItem*)item
{
  UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.autoresizingMask = UIViewAutoresizingNone;

  NSString* defaultBackButton;
  NSString* highlightedBackButton;
  if (self.navigationController.navigationBar.barStyle == UIBarStyleBlack) {
    defaultBackButton = @"gree_um_btn_back_default.png";
    highlightedBackButton = @"gree_um_btn_back_highlight.png";
  } else {
    defaultBackButton = @"navibar-back-def.png";
    highlightedBackButton = @"navibar-back-press.png";
  }

  UIImage* bg_image = [UIImage greeImageNamed:defaultBackButton];
  UIImage* bg_image_highlighted = [UIImage greeImageNamed:highlightedBackButton];

  button.frame = CGRectMake(0, 0, bg_image.size.width, bg_image.size.height);
  [button setBackgroundImage:bg_image forState:UIControlStateNormal];
  [button setBackgroundImage:bg_image_highlighted forState:UIControlStateHighlighted];

  [button addTarget:self action:@selector(onBackButtonPressed)forControlEvents:UIControlEventTouchUpInside];
  item.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
}

-(void)scrollToTop
{
  [self.webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0, 0)"];
}

-(void)enableScrollsToTop
{
  NSArray* subviews = [self.webView subviews];
  for (UIView* view in subviews) {
    if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
      [(UIScrollView*) view setScrollsToTop:YES];
    }
  }
}

-(void)disableScrollsToTop
{
  NSArray* subviews = [self.webView subviews];
  for (UIView* view in subviews) {
    if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
      [(UIScrollView*) view setScrollsToTop:NO];
    }
  }
}

-(void)displayLoadingIndicator:(BOOL)display
{
  if (display) {
    if (self.loadingIndicatorView.superview) {
      return;
    }
    self.loadingIndicatorView.center = self.view.center;
    [self.view addSubview:self.loadingIndicatorView];
  } else {
    [self.loadingIndicatorView removeFromSuperview];
  }
}

-(void)resetWebViewContents:(NSURL*)toURL
{
  if (self.isProton) {
    NSDictionary* params = [[toURL query] greeDictionaryFromQueryString];
    [[self handler] resetToView:[params objectForKey:@"view"] toParams:params];
  } else {
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = ''"];
  }
}

#pragma mark - Pending Request Handlers

-(void)setPendingLoadRequest:(NSString*)viewName params:(NSDictionary*)params
{
  [self setPendingLoadRequest:viewName params:params options:nil];
}

-(void)setPendingLoadRequest:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options
{
  [self resetPendingLoadRequest];
  self.pendingLoadRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                             viewName, @"view",
                             params, @"params",
                             options, @"options",
                             nil];
}

-(void)resetPendingLoadRequest
{
  self.pendingLoadRequest = nil;
}

-(void)retryToInitializeProton
{
  [self.webView reload];
  self.deadlyProtonErrorOccured = NO;
}

#pragma mark - Preload Instance Initialize Handlers

-(GreeJSWebViewController*)preloadNextWebViewController
{
  GreeJSWebViewController* webViewController = nil;
  if (self.pool) {
    webViewController = [self.pool take];
    webViewController.pool = self.pool;
  } else {
    webViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  }

  if (self.preloadInitializeBlock) {
    self.preloadInitializeBlock(self, webViewController);
    webViewController.preloadInitializeBlock = self.preloadInitializeBlock;
  }

  self.nextWebViewController = webViewController;
  return webViewController;
}

#pragma mark - Internal Methods

-(void)adjustWebViewContentInset
{
  // interfaceOrientation of rootController of Universal menu controller is not updated after rotation
  // so that use the orientation set by willRotateToInterfaceOrientation instead.
  [self.subNavigationView setNeedsLayout];
  [self.pullToRefreshHeader setNeedsLayout];
}

-(void)onBackButtonPressed
{
  [self.navigationController popViewControllerAnimated:YES];
}

-(void)showHTTPErrorMessage:(NSError*)anError
{
  if (anError.code != kCFURLErrorCancelled) {
    [self setCanPullToRefresh:NO];
    [self configureSubnavigationMenuWithParams:nil];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [self.webView showHTTPErrorMessage:anError loadingFlag:&_connectionFailureContentsLoading
    bodyStreamExhaustedErrorFilePath:[[NSBundle greePlatformCoreBundle] pathForResource:self.networkErrorMessageFilename ofType:nil]];
}

-(void)didFailWithErrorNotification:(NSNotification*)notification
{
  NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
  NSString* urlString = [info objectForKey:@"url"];
  NSURL* url = [NSURL URLWithString:urlString];
  if (url) {
    [info setObject:url forKey:@"NSErrorFailingURLKey"];
    [info setObject:urlString forKey:NSURLErrorFailingURLStringErrorKey];
  }
  NSError* error = [NSError errorWithDomain:@"" code:kCFURLErrorUnknown userInfo:info];
  [self showHTTPErrorMessage:error];
}
-(void)notificationBoardDidLaunchNotification:(NSNotification*)notification
{
  if (self.navigationController.topViewController == self) {
    [self.webView endEditing:YES];
  }
}

-(BOOL)shouldHandleRequest:(NSURLRequest*)request
{
  NSString* scheme = request.URL.scheme;
  if (
    [scheme isEqualToString:@"http"] ||
    [scheme isEqualToString:@"https"]
    ) {
    return YES;
  } else if (
    [scheme isEqualToString:@"itms-apps"] ||
    [scheme isEqualToString:@"itms"]
    ) {
    return [self handleSchemeItmsApps:request];
  }
  return NO;
}

-(BOOL)handleSchemeItmsApps:(NSURLRequest*)request
{
  [[UIApplication sharedApplication] openURL:request.URL];
  return NO;
}

-(void)dismiss
{
  if ([self.locationDelegate respondsToSelector:@selector(spotViewCloseButtonPressed:)]) {
    [self.locationDelegate spotViewCloseButtonPressed:self];
  }
}

+(NSString*)viewNameFromURL:(NSURL*)url
{
  NSURL* snsURL = [NSURL URLWithString:[[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlSns]];
  if ([[url host] isEqualToString:[snsURL host]]) {
    return [[[url fragment] greeDictionaryFromQueryString] objectForKey:@"view"];
  } else {
    return [[url URLByDeletingQuery] absoluteString];
  }
}

@end
