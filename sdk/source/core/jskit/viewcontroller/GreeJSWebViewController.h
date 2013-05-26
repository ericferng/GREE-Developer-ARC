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

#import <UIKit/UIKit.h>
#import "GreeJSWebViewLocationDelegate.h"

@class GreeJSHandler;
@class GreeJSInputViewController;
@class GreeJSExternalWebViewController;
@class GreeJSLoadingIndicatorView;
@class GreeJSWebViewControllerPool;

@interface GreeJSWebViewController : UIViewController
  <
    UIWebViewDelegate, UIScrollViewDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIActionSheetDelegate, UIAlertViewDelegate
  >
{
  @protected
  GreeJSWebViewController* _nextWebViewController;
  UIScrollView* _scrollView;
  BOOL _canPullToRefresh;
  id _originalScrollViewDelegate;
}
@property (nonatomic, retain, readonly) UIWebView* webView;
@property (nonatomic, retain, readonly) GreeJSHandler* handler;
@property (nonatomic, retain, readonly) GreeJSLoadingIndicatorView* loadingIndicatorView;
@property (nonatomic, retain, readonly) NSDictionary* pendingLoadRequest;
@property (nonatomic, retain) NSDictionary* params;
@property (nonatomic, assign) GreeJSWebViewController* beforeWebViewController;
@property (nonatomic, retain) GreeJSWebViewController* nextWebViewController;
@property (nonatomic, retain) GreeJSInputViewController* inputViewController;
@property (nonatomic, copy) NSString* modalRightButtonCallback;
@property (nonatomic, retain) NSDictionary* modalRightButtonCallbackInfo;
@property (assign) BOOL isJavascriptBridgeEnabled;
@property (nonatomic, readwrite, retain) NSString* networkErrorMessageFilename;
@property (nonatomic, readonly, assign) BOOL deadlyProtonErrorOccured;
@property (nonatomic, retain) GreeJSWebViewControllerPool* pool;
@property (nonatomic, copy) void (^preloadInitializeBlock)(GreeJSWebViewController*, GreeJSWebViewController*);
@property (nonatomic, assign) id<GreeJSWebViewLocationDelegate> locationDelegate;

#pragma mark - Public Interface
-(id)initWithFrame:(CGRect)frame;
-(void)setBackgroundColor:(UIColor*)color;
-(void)displayLoadingIndicator:(BOOL)display;
-(void)setBackButtonForNavigationItem:(UINavigationItem*)item;
-(void)scrollToTop;
-(void)enableScrollsToTop;
-(void)disableScrollsToTop;
-(void)resetWebViewContents:(NSURL*)toURL;
-(void)retryToInitializeProton;
-(void)dismiss;
+(NSString*)viewNameFromURL:(NSURL*)url;

#pragma mark - Pending Request Handlers
-(void)setPendingLoadRequest:(NSString*)viewName params:(NSDictionary*)params;
-(void)setPendingLoadRequest:(NSString*)viewName params:(NSDictionary*)params options:(NSDictionary*)options;
-(void)resetPendingLoadRequest;

#pragma mark - Preload Next WebView Handlers.
-(GreeJSWebViewController*)preloadNextWebViewController;

@end
