//
// Copyright 2011 GREE, Inc.
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
#import "GreeError.h"
#import "GreeJSCommandFactory.h"
#import "GreeJSHandler.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "GreeWebSession.h"
#import "NSURL+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreeError+Internal.h"
#import "GreePlatform+Internal.h"
#import "UIWebView+GreeAdditions.h"
#import "GreeWebSessionRegenerator.h"
#import "GreeLogger.h"
#import "GreeSettings.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeBenchmark.h"

#define kGreePopupConnectionFailureFileName @"GreePopupConnectionFailure.html"

#undef HEXCOLOR
#define HEXCOLOR(n) (((float)n)/ 255.0f)

CGFloat const GreePopupNavigationBarPortraitHeight = 40.0f;
CGFloat const GreePopupNavigationBarLandscapeHeight = 32.0f;
@interface GreePopupNavigationBar : UIView
@end
@implementation GreePopupNavigationBar
@end


@interface GreePopupBackButton : UIButton
@end
@implementation GreePopupBackButton
@end


@interface GreePopupCloseButton : UIButton
@end
@implementation GreePopupCloseButton
@end


@interface GreePopupView ()<UIWebViewDelegate>
-(void)adjustContentView;
-(void)setTitleFromTitleTagInWebView:(UIWebView*)aWebView;
-(void)setTitleAsGreeLogo;
-(void)hideIndicator;
-(void)benchmarkWithRequest:(NSURLRequest*)request pointName:(NSString*)pointName;
@property (nonatomic, retain) GreeJSLoadingIndicatorView* loadingIndicatorView;
@end


@implementation GreePopupView

#pragma mark - Object Lifecycle

-(void)awakeFromNib
{
  self.connectionFailureContentsLoading = NO;

  self.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.6f];
  self.titleLabel.text = @"";
  self.backButton.hidden = YES;
  self.loadingIndicatorView = [[[GreeJSLoadingIndicatorView alloc]
                                initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];
  self.handler = [[[GreeJSHandler alloc] init] autorelease];
  self.handler.webView = self.webView;
}

-(void)dealloc
{
  self.handler = nil;
  self.webView.delegate = nil;
  self.webView = nil;
  self.navigationBar = nil;
  self.closeButton = nil;
  self.titleLabel = nil;
  self.logoImage = nil;
  self.backButton = nil;
  self.contentView = nil;
  self.containerView = nil;
  self.loadingIndicatorView = nil;
  [super dealloc];
}


#pragma mark - Public Interface

-(void)show
{
  __block GreePopupView* nonRetainedSelf = self;
  CGAffineTransform transform = CGAffineTransformIdentity;

  // Prompt a layout if we haven't been already
  [self adjustContentView];

  self.contentView.transform = CGAffineTransformScale(transform, 0.05f, 0.05f);
  self.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.0f];

  if ([self.delegate respondsToSelector:@selector(popupViewWillLaunch)]) {
    [self.delegate popupViewWillLaunch];
  }

  [UIView animateWithDuration:0.12 animations:^{
     nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 1.1, 1.1);
     nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.4f];
   } completion:^(BOOL finished) {
     [UIView animateWithDuration:0.15 animations:^{
        nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 0.93f, 0.93f);
        nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.5f];
      } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
           nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 1.f, 1.f);
           nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.6f];
         } completion:^(BOOL finished) {

           if ([nonRetainedSelf.delegate respondsToSelector:@selector(popupViewDidLaunch)]) {
             [nonRetainedSelf.delegate popupViewDidLaunch];
           }
         }];
      }];
   }];
}

-(void)dismiss
{
  [self benchmarkWithRequest:self.webView.request pointName:kGreeBenchmarkDismiss];
  [self.webView stopLoading];

  CGAffineTransform transform = CGAffineTransformIdentity;

  if ([self.delegate respondsToSelector:@selector(popupViewWillDismiss)]) {
    [self.delegate popupViewWillDismiss];
  }

  [self retain];
  [UIView animateWithDuration:0.23 animations:^{
     self.contentView.transform = CGAffineTransformScale(transform, 0.01, 0.01);
     self.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.1f];
   } completion:^(BOOL finished) {
     self.hidden = YES;
     if ([self.delegate respondsToSelector:@selector(popupViewDidDismiss)]) {
       [self.delegate popupViewDidDismiss];
     }
     [self release];
   }];
}

-(IBAction)closeButtonTapped:(id)sender
{
  [self benchmarkWithRequest:self.webView.request pointName:kGreeBenchmarkCancel];

  if ([self.delegate respondsToSelector:@selector(popupViewDidCancel)]) {
    [self.delegate popupViewDidCancel];
  }
}

-(IBAction)backButtonTapped:(id)sender
{
  if ([self.webView canGoBack]) {
    [self.webView goBack];
  }
}

-(void)setTitleWithString:(NSString*)aTitleString
{
  self.logoImage.hidden = YES;
  self.titleLabel.text = aTitleString;
}


#pragma mark - UIVIew Overrides

-(void)layoutSubviews
{
  CGFloat navBarHeight;

  if (self.superview.bounds.size.width > self.superview.bounds.size.height) {
    navBarHeight = GreePopupNavigationBarLandscapeHeight;
  } else {
    navBarHeight = GreePopupNavigationBarPortraitHeight;
  }

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    CGRect frame = self.contentView.bounds;
    frame.size.height = 510;
    frame.size.width  = 410;
    self.contentView.bounds = frame;
  }

  self.navigationBar.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, navBarHeight);
  self.webView.frame = CGRectMake(0, navBarHeight, self.contentView.bounds.size.width, self.contentView.bounds.size.height - navBarHeight);
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p navigationBar:%@ webView:%@ delegate:%@>", NSStringFromClass([self class]), self, self.navigationBar, self.webView, self.delegate];
}

#pragma mark - Internal Methods

-(void)adjustContentView
{
  self.contentView.layer.cornerRadius = 5.f;
  self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

-(void)setTitleFromTitleTagInWebView:(UIWebView*)aWebView
{
  NSString* title = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (0 < [title length]) {
    self.titleLabel.text = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.logoImage.hidden = YES;
  } else {
    [self setTitleAsGreeLogo];
  }
}

-(void)setTitleAsGreeLogo
{
  self.titleLabel.text = @"";
  self.logoImage.hidden = NO;
}

-(void)showActivityIndicator
{
  if (!self.loadingIndicatorView.superview) {
    self.loadingIndicatorView.center = self.containerView.center;
    [self.containerView addSubview:self.loadingIndicatorView];
  }
}

-(void)hideIndicator
{
  if (self.loadingIndicatorView.superview) {
    [self.loadingIndicatorView removeFromSuperview];
  }
}

-(void)showHTTPErrorMessage:(NSError*)anError
{
  [self.webView showHTTPErrorMessage:anError loadingFlag:&_connectionFailureContentsLoading
    bodyStreamExhaustedErrorFilePath:[[NSBundle greePlatformCoreBundle] pathForResource:kGreePopupConnectionFailureFileName ofType:nil]];
}

#pragma mark - UIWebViewDelegate Methods

-(void)webView:(UIWebView*)aWebView didFailLoadWithError:(NSError*)anError
{
  if (([anError.domain isEqualToString:@"WebKitErrorDomain"] && [anError code] == 102) ||
      [anError code] == kCFURLErrorCancelled) {
    // Ignore it.
    return;
  }

  GreeLog(@"url:%@ error:%@", aWebView.request.URL, anError);

  [self benchmarkWithRequest:aWebView.request pointName:kGreeBenchmarkUrlLoadError];

  if ([self.delegate respondsToSelector:@selector(popupViewWebView:didFailLoadWithError:)]) {
    [self.delegate popupViewWebView:aWebView didFailLoadWithError:anError];
  } else {
    [self showHTTPErrorMessage:anError];
  }
}

-(BOOL)webView:(UIWebView*)aWebView shouldStartLoadWithRequest:(NSURLRequest*)aRequest navigationType:(UIWebViewNavigationType)aNavigationType
{
  [self benchmarkWithRequest:aRequest pointName:kGreeBenchmarkUrlLoadStart];
  NSString* body = [[NSString alloc] initWithData:aRequest.HTTPBody encoding:NSUTF8StringEncoding];
  GreeLog(@"request:%@\n"
          @"navigationType:%d\n"
          @"headers:%@\n"
          @"body length:%d",
          aRequest, aNavigationType, [aRequest allHTTPHeaderFields], [body length]);
  [body release];

  if ([aRequest.URL isGreeDomain] && [[[aRequest URL] scheme] hasPrefix:@"http"]) {
    [self showActivityIndicator];
  }

  if([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingShowConnectionServer]) {
    [self.webView attachLabelWithURL:aRequest.URL position:GreeWebViewUrlLabelPositionTop];
  }

  if (self.connectionFailureContentsLoading) {
    self.connectionFailureContentsLoading = NO;
    return YES;
  }

  NSURL* aURL = aRequest.URL;
  // handle reload
  if (aNavigationType == UIWebViewNavigationTypeReload) {
    if ([aURL isGreeDomain] == YES || [aURL isGreeErrorURL] == YES) {
      if ([self.delegate respondsToSelector:@selector(popupViewWebViewReload:)]) {
        [self.delegate popupViewWebViewReload:aWebView];
        return NO;
      }
    }
  }

  // handle web session regenerating if necessary
  id regenerator =
    [GreeWebSessionRegenerator generatorIfNeededWithRequest:aRequest webView:self.webView delegate:self.delegate
                                         showHttpErrorBlock:^(NSError* error) {
       [self showHTTPErrorMessage:error];
     }
    ];
  if (regenerator) {
    return NO;
  }

  // handle any proton commands
  if ([GreeJSHandler executeCommandFromRequest:aRequest handler:self.handler environment:self.commandEnvironment]) {
    //Share popupview don't call webViewDidFinishLoad sometimes. So stop indicator when calling contents_ready command.
    if ([[[aRequest URL] host] isEqualToString:@"contents_ready"]) {
      [self hideIndicator];
    }
    return NO;
  }

  // handle self url cheme
  if ([aURL isSelfGreeURLScheme]) {
    if ([self.delegate respondsToSelector:@selector(popupURLHandlerReceivedSelfURLSchemeRequest:)]) {
      [self.delegate popupURLHandlerReceivedSelfURLSchemeRequest:aRequest];
      return NO;
    }
  }

  // handle Ad URL
  if ([aURL isGreeAdRedirectorURL]) {
    if ([self.delegate respondsToSelector:@selector(popupURLHandlerReceivedAdRedirectorURLRequest:)]) {
      [self.delegate popupURLHandlerReceivedAdRedirectorURLRequest:aRequest];
      return NO;
    } else {
      
    }
  }

  // can be any url handling if necessary
  if ([self.delegate respondsToSelector:@selector(popupURLHandlerWebView:shouldStartLoadWithRequest:navigationType:)]) {
    return [self.delegate popupURLHandlerWebView:aWebView shouldStartLoadWithRequest:aRequest navigationType:aNavigationType];
  }

  return YES;
}

-(void)webViewDidStartLoad:(UIWebView*)aWebView
{
  if ([self.delegate respondsToSelector:@selector(popupViewWebViewDidStartLoad:)]) {
    [self.delegate popupViewWebViewDidStartLoad:aWebView];
  }

  // Set a flag in window.name to distinguish proton clients from mobile safari.
  // Set every time because external page have the potential of change window.name.
  [aWebView stringByEvaluatingJavaScriptFromString:@"window.name='protonApp'"];
}

-(void)webViewDidFinishLoad:(UIWebView*)aWebView
{
  [self benchmarkWithRequest:aWebView.request pointName:kGreeBenchmarkUrlLoadEnd];
  NSURL* anURL = aWebView.request.URL;
  GreeLog(@"anURL:%@", anURL);
  [self hideIndicator];

  if ([self.delegate respondsToSelector:@selector(popupViewHowDoesSetTitle)]) {
    switch ([self.delegate popupViewHowDoesSetTitle]) {
    case GreePopupViewTitleSettingMethodNothing:
      // nothing to do
      break;
    case GreePopupViewTitleSettingMethodLogoOnly:
      [self setTitleAsGreeLogo];
      break;
    case GreePopupViewTitleSettingMethodFromTitleTagInContents:
    default:
      [self setTitleFromTitleTagInWebView:aWebView];
      break;
    }
  } else {
    [self setTitleFromTitleTagInWebView:aWebView];
  }

  if ([self.delegate respondsToSelector:@selector(popupViewShouldAcceptEmptyBody)] &&
      [self.delegate popupViewShouldAcceptEmptyBody]) {
    // fall through
  } else {
    // occur an error if body content is empty when http result is 200 OK
    NSString* htmlContents = [aWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].innerHTML"];
    if ([anURL.scheme isEqualToString:@"http"] && [htmlContents length] == 0) {
      NSDictionary* aParameter = [NSDictionary dictionaryWithObject:anURL forKey:@"NSErrorFailingURLKey"];
      NSError* anError = [[[NSError alloc] initWithDomain:GreeErrorDomain code:GreeErrorCodeBadDataFromServer userInfo:aParameter] autorelease];
      [self showHTTPErrorMessage:anError];
    }
  }

  // can be any contents handling if necessary
  if ([self.delegate respondsToSelector:@selector(popupViewWebViewDidFinishLoad:)]) {
    [self.delegate popupViewWebViewDidFinishLoad:aWebView];
  }
}

-(void)benchmarkWithRequest:(NSURLRequest*)request pointName:(NSString*)pointName
{
  if (![GreePlatform sharedInstance].benchmark) {
    return;
  }
  if ([request.URL.scheme isEqualToString:@"about"] || [request.URL.scheme isEqualToString:@"proton"]) {
    return;
  }

  if ([request.URL.query hasPrefix:@"action=top&context="]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(pointName)];
  } else if ([request.URL.query isEqualToString:@"action=logout"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogout position:GreeBenchmarkPosition(pointName)];
  } else if ([request.URL.query hasPrefix:@"oauth/authorize"]) {
    pointName = [NSString stringWithFormat:@"%@%@", @"oauthAuthorize", pointName];
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(pointName)];
  } else if ([request.URL.query hasPrefix:@"action=upgrade"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkUpgrade position:GreeBenchmarkPosition(pointName)];
  } else if ([request.URL.query hasPrefix:@"action=confirm_upgrade"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkUpgrade position:GreeBenchmarkPosition(pointName)];
  } else if ([self.delegate isKindOfClass:[GreeInvitePopup class]]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkInvite position:GreeBenchmarkPosition(pointName)];
  } else if ([self.delegate isKindOfClass:[GreeSharePopup class]]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkShare position:GreeBenchmarkPosition(pointName)];
  } else if ([self.delegate isKindOfClass:[GreeSharePopup class]] && [request.URL.host isEqualToString:@"close"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkShare position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];
  } else if ([self.delegate isKindOfClass:[GreeRequestServicePopup class]]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkRequest position:GreeBenchmarkPosition(pointName)];
  } else if ([[NSString stringWithUTF8String:object_getClassName(self.delegate)] isEqualToString:@"GreeWalletPaymentPopup"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkPayment position:GreeBenchmarkPosition(pointName)];
  } else if ([[NSString stringWithUTF8String:object_getClassName(self.delegate)] isEqualToString:@"GreeWalletDepositPopup"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkPaymentDeposit position:GreeBenchmarkPosition(pointName)];
  } else if ([[NSString stringWithUTF8String:object_getClassName(self.delegate)] isEqualToString:@"GreeWalletDepositIAPHistoryPopup"]) {
    if ([[request.URL scheme] isEqualToString:@"http"] && [pointName hasPrefix:@"urlLoad"]) {
      NSString* contactPointName = [NSString stringWithFormat:@"contact %@", pointName];
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkPaymentHistory position:GreeBenchmarkPosition(contactPointName)];
    } else {
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkPaymentHistory position:GreeBenchmarkPosition(pointName)];
    }
  }
}

@end

