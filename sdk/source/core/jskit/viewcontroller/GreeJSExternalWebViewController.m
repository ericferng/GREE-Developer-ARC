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


#import "GreeJSExternalWebViewController.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeGlobalization.h"
#import "UIViewController+GreeAdditions.h"

@interface GreeJSExternalWebViewController ()<UIScrollViewDelegate>
-(void)updateAddressBar;
-(void)adjustWebViewForOrientation:(UIInterfaceOrientation)orientation;
@end

@implementation GreeJSExternalWebViewController


#pragma mark - Object Lifecycle

-(id)initWithURL:(NSURL*)url
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    CGSize viewSize = self.view.frame.size;
    self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, viewSize.width, viewSize.height)] autorelease];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;

    UIScrollView* scrollView = [self.webView valueForKey:@"_scrollView"];
    scrollView.delegate = self;
    [scrollView setDecelerationRate:UIScrollViewDecelerationRateNormal];

    CGRect addressBarFrame = CGRectMake(0, 0, scrollView.frame.size.width, kAddressBarPortraitHeight);
    self.addressBar = [[[GreeJSExternalAddressBarView alloc] initWithFrame:addressBarFrame] autorelease];
    self.addressBar.delegate = self;
    [scrollView addSubview:self.addressBar];

    [self adjustWebViewForOrientation:[self interfaceOrientation]];

    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
  }
  return self;
}

-(void)dealloc
{
  self.addressBar.delegate = nil;
  self.webView.delegate = nil;

  self.addressBar = nil;
  self.webView = nil;

  [super dealloc];
}

-(void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  if ([self isViewLoaded] && self.view.window == nil) {
    self.addressBar.delegate = nil;
    self.webView.delegate = nil;
    self.view = nil;
  }
  // Release any cached data, images, etc that aren't in use.
}


#pragma mark - UIViewController Overrides

-(void)viewWillDisappear:(BOOL)animated
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [super viewWillDisappear:animated];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self adjustWebViewForOrientation:toInterfaceOrientation];
}

#pragma mark - UIWebViewDelegate Methods

-(void)webViewDidStartLoad:(UIWebView*)webView
{
  self.addressBar.isLoading = YES;
  [self updateAddressBar];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)webViewDidFinishLoad:(UIWebView*)webView
{
  self.addressBar.isLoading = NO;
  [self updateAddressBar];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
  self.addressBar.isLoading = NO;
  [self updateAddressBar];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

  if (error.code == kCFURLErrorCancelled) {
    return;
  }

  NSString* title;
  NSString* message;
  if (error.code == kCFURLErrorCannotFindHost) {
    title = GreePlatformString(@"GreeJS.ExternalWebViewController.CannotFindHost.Alert.Title",
                               @"Cannot Open Page");
    message = GreePlatformString(@"GreeJS.ExternalWebViewController.CannotFindHost.Alert.Message",
                                 @"Safari cannot open the page because the server cannot be found.");
  } else if (error.code == kCFURLErrorNotConnectedToInternet) {
    title = GreePlatformString(@"GreeJS.ExternalWebViewController.NotConnectedToInternet.Alert.Title",
                               @"Cannot Open Page");
    message = GreePlatformString(@"GreeJS.ExternalWebViewController.NotConnectedToInternet.Alert.Message",
                                 @"Safari cannot open the page because it is not connected to the internet.");
  } else {
    title = GreePlatformString(@"GreeJS.ExternalWebViewController.Failure.Alert.Title",
                               @"Cannot Open Page");
    message = GreePlatformString(@"GreeJS.ExternalWebViewController.Failure.Alert.Message",
                                 @"Safari cannot open the page.");
  }
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
  [alert release];
}

#pragma mark - GreeJSExternalAddressBarViewDelegate Methods

-(void)onAddressBarViewStopButtonTap:(id)sender
{
  [self.webView stopLoading];
}

-(void)onAddressBarViewReloadButtonTap:(id)sender
{
  [self.webView reload];
}

-(void)onAddressBarViewBackButtonTap:(id)sender
{
  if ([self.webView canGoBack]) {
    [self.webView goBack];
  }
}

-(void)onAddressBarViewForwardButtonTap:(id)sender
{
  if ([self.webView canGoForward]) {
    [self.webView goForward];
  }
}

#pragma mark - Internal Methods

-(void)updateAddressBar
{
  self.addressBar.forwardButtonEnabled = [self.webView canGoForward];
  self.addressBar.backButtonEnabled = [self.webView canGoBack];
  NSString* address = [self.webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];
  if (![address isEqualToString:@"about:blank"]) {
    self.addressBar.addressBarText = address;
  }
}

-(void)adjustWebViewForOrientation:(UIInterfaceOrientation)orientation
{
  UIScrollView* scrollView = [self.webView valueForKey:@"_scrollView"];

  if (UIInterfaceOrientationIsPortrait(orientation)) {
    self.addressBar.frame = CGRectMake(0, 0, scrollView.frame.size.width, kAddressBarPortraitHeight);
  } else {
    self.addressBar.frame = CGRectMake(0, 0, scrollView.frame.size.width, kAddressBarLandscapeHeight);
  }
  for (UIView* v in [scrollView subviews]) {
    if (![v.class isSubclassOfClass:[GreeJSExternalAddressBarView class]]) {
      v.frame = CGRectMake(0, self.addressBar.frame.size.height, v.frame.size.width, v.frame.size.height);
    }
  }
}

#pragma mark - UIScrollView delegate Methods

-(UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  if ([self.webView respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
    return [self.webView viewForZoomingInScrollView:scrollView];
  } else {
    return nil;
  }
}

-(void)scrollViewWillBeginZooming:(UIScrollView*)scrollView withView:(UIView*)view
{
  if ([self.webView respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
    [self.webView scrollViewWillBeginZooming:scrollView withView:view];
  }
}

-(void)scrollViewDidEndZooming:(UIScrollView*)scrollView
                      withView:(UIView*)view
                       atScale:(float)scale
{
  if ([self.webView respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
    [self.webView scrollViewDidEndZooming:scrollView withView:view atScale:scale];
  }
}

-(void)scrollViewDidZoom:(UIScrollView*)scrollView
{
  if ([self.webView respondsToSelector:@selector(scrollViewDidZoom:)]) {
    [self.webView scrollViewDidZoom:scrollView];
  }
  CGPoint offset = scrollView.contentOffset;
  self.addressBar.frame = CGRectMake(offset.x, 0, self.addressBar.frame.size.width, self.addressBar.frame.size.height);
}

-(void)scrollViewDidScroll:(UIScrollView*)scrollView
{
  if ([self.webView respondsToSelector:@selector(scrollViewDidScroll:)]) {
    [self.webView scrollViewDidScroll:scrollView];
  }
  CGPoint offset = scrollView.contentOffset;
  self.addressBar.frame = CGRectMake(offset.x, 0, self.addressBar.frame.size.width, self.addressBar.frame.size.height);
}

@end
