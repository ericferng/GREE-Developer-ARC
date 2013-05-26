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

#import "GreeJSWebViewController+PullToRefresh.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeJSWebViewController.h"
#import "GreeJSPullToRefreshHeaderView.h"
#import "GreeJSHandler.h"

@interface GreeJSWebViewController ()
@property (assign) BOOL isProton;
@property (assign) BOOL isDragging;
@property (assign) BOOL isPullLoading;
@property (nonatomic, retain) NSTimer* pullToRefreshTimeoutTimer;
@property (readonly) UIView* pullToRefreshBackground;
@property (readonly) GreeJSPullToRefreshHeaderView* pullToRefreshHeader;
-(void)adjustWebViewContentInset;
@end

@implementation GreeJSWebViewController (PullToRefresh)

#pragma mark - Public Interface

-(void)startLoading
{
  self.isPullLoading = YES;
  [self performSelector:@selector(monitoringRefreshTimeout)];

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.3f];
  [[self.webView valueForKey:@"_scrollView"] setContentInset:UIEdgeInsetsMake(kGreeJSRefreshHeaderHeight, 0, 0, 0)];
  [self.pullToRefreshHeader nowLoading:YES];
  [UIView commitAnimations];

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  if (self.isProton) {
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"pull_to_refresh"];
    [self.handler reloadWithOptions:options];
  } else {
    [self.webView reload];
  }
}

-(void)stopLoading
{
  if (self.isPullLoading) {
    // Hide the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3f];
    [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    [self adjustWebViewContentInset];
    [self.pullToRefreshHeader.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [[self.webView valueForKey:@"_scrollView"] setContentInset:UIEdgeInsetsZero];
    [UIView commitAnimations];

    [self.pullToRefreshHeader updateTimeOfRefreshed];
  }
}

#pragma mark Properties

-(void)setCanPullToRefresh:(BOOL)canPullToRefresh
{
  _canPullToRefresh = canPullToRefresh;
  if (canPullToRefresh) {
    [[self.webView valueForKey:@"_scrollView"] addSubview:self.pullToRefreshBackground];
    [[self.webView valueForKey:@"_scrollView"] addSubview:self.pullToRefreshHeader];
  } else {
    [self.pullToRefreshBackground removeFromSuperview];
    [self.pullToRefreshHeader removeFromSuperview];
  }
}

-(BOOL)canPullToRefresh
{
  return _canPullToRefresh;
}

#pragma mark - Internal Method

-(void)stopLoadingComplete:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context
{
  [self.pullToRefreshHeader nowLoading:NO];
  if (self.pullToRefreshTimeoutTimer) {
    [self.pullToRefreshTimeoutTimer invalidate];
    self.pullToRefreshTimeoutTimer = nil;
  }
  self.isPullLoading = NO;
  [[self.webView valueForKey:@"_scrollView"] setContentInset:UIEdgeInsetsZero];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)onWaitRefreshTimeout:(NSTimer*)timer
{
  [self stopLoading];

  NSString* urlString = [self.webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];
  NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:urlString forKey:@"url"];

  NSNotification* notification = [NSNotification notificationWithName:@"GreeJSDidFailWithError"
                                                               object:self
                                                             userInfo:errorInfo];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void)monitoringRefreshTimeout
{
  self.pullToRefreshTimeoutTimer =
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(onWaitRefreshTimeout:)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - UIScrollViewDelegate Methods

-(void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  if (self.canPullToRefresh) {
    if (self.isPullLoading) {
      return;
    }
    self.isDragging = YES;
  }
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
    [_originalScrollViewDelegate scrollViewWillBeginDragging:scrollView];
  }
}

-(void)scrollViewDidScroll:(UIScrollView*)scrollView
{
  if (self.canPullToRefresh) {
    if (self.isPullLoading) {
      // Update the content inset, good for section headers
      if (scrollView.contentOffset.y > 0) {
        [_scrollView setContentInset:UIEdgeInsetsZero];
      } else if (scrollView.contentOffset.y == 0) {
        [_scrollView scrollRectToVisible:CGRectMake(0, -kGreeJSRefreshHeaderHeight, 1, kGreeJSRefreshHeaderHeight)
                                animated:NO];
      } else if (scrollView.contentOffset.y >= -kGreeJSRefreshHeaderHeight) {
        [_scrollView setContentInset:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0)];
      }
    } else if (self.isDragging && scrollView.contentOffset.y < 0) {
      // Update the arrow direction and label
      [UIView beginAnimations:nil context:NULL];
      if (scrollView.contentOffset.y < -kGreeJSRefreshHeaderHeight - kGreeJSRefreshHeaderMargin) {
        // User is scrolling above the header
        self.pullToRefreshHeader.refreshLabel.text = self.pullToRefreshHeader.textReleaseToRefresh;
        [self.pullToRefreshHeader.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
      } else { // User is scrolling somewhere within the header
        self.pullToRefreshHeader.refreshLabel.text = self.pullToRefreshHeader.textPullToRefresh;
        [self.pullToRefreshHeader.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
      }
      [UIView commitAnimations];
    }
  }
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
    [_originalScrollViewDelegate scrollViewDidScroll:scrollView];
  }
}

-(void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
  if (self.canPullToRefresh) {
    if (self.isPullLoading) return;
    self.isDragging = NO;
    if (scrollView.contentOffset.y <= -kGreeJSRefreshHeaderHeight - kGreeJSRefreshHeaderMargin) {
      // Released above the header
      [self startLoading];
      [self adjustWebViewContentInset];
    }
  }
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
    [_originalScrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  }
}

-(void)scrollViewDidZoom:(UIScrollView*)scrollView
{
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
    [_originalScrollViewDelegate scrollViewDidZoom:scrollView];
  }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
    [_originalScrollViewDelegate scrollViewDidEndDecelerating:scrollView];
  }
}

-(void)scrollViewWillBeginZooming:(UIScrollView*)scrollView withView:(UIView*)view
{
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
    [_originalScrollViewDelegate scrollViewWillBeginZooming:scrollView withView:view];
  }
}

-(void)scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale
{
  if ([_originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
    [_originalScrollViewDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
  }
}

@end
