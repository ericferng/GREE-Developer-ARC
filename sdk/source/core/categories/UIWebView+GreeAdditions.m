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

#import "GreeGlobalization.h"
#import "GreeError.h"

#import "UIWebView+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeBenchmark.h"

#define kUIWebViewGreeAdditionsErrorMessageKey @"message"

static int const kUrlLabelTag = 1001;


@implementation UIWebView (GreeAdditions)

-(void)showHTTPErrorMessage:(NSError*)anError loadingFlag:(BOOL*)flag bodyStreamExhaustedErrorFilePath:(NSString*)aFilePath
{
  if (anError.code == kCFURLErrorCancelled) {
    // ignore it.
    return;
  }
  NSString* aHtmlString = [NSString stringWithContentsOfFile:aFilePath encoding:NSUTF8StringEncoding error:nil];
  aHtmlString = [aHtmlString
                 greeStringByReplacingHtmlLocalizedStringWithKey:@"GreePopupConnectionFailure#reload"
                                                      withString:GreePlatformString(@"GreePopupConnectionFailure#reload", @"reload")];
  NSString* errorMessage = [anError.userInfo objectForKey:kUIWebViewGreeAdditionsErrorMessageKey];

  switch (anError.code) {
  case GreeErrorCodeNetworkError:
  case GreeErrorCodeBadDataFromServer:
  case kCFURLErrorUnknown:
  case kCFURLErrorTimedOut:
  case kCFURLErrorCannotFindHost:
  case kCFURLErrorCannotConnectToHost:
  case kCFURLErrorNetworkConnectionLost:
  case kCFURLErrorDNSLookupFailed:
  case kCFURLErrorResourceUnavailable:
  case kCFURLErrorNotConnectedToInternet:
  case kCFURLErrorInternationalRoamingOff:
  case kCFErrorHTTPProxyConnectionFailure:
  case kCFURLErrorRequestBodyStreamExhausted: {
    if ([errorMessage length] <= 0) {
      errorMessage = GreePlatformString(@"GreePopupConnectionFailure#checkSignalStrength",
                                        @"Please check the signal strength and try to connect again.");
    }
  }
  break;
  default: {
    errorMessage = GreePlatformString(@"GreePopupConnectionFailure#failure", @"Can't open page.");
  }
  break;
  }

  aHtmlString = [aHtmlString
                 greeStringByReplacingHtmlLocalizedStringWithKey:@"GreePopupConnectionFailure#checkSignalStrength"
                                                      withString:errorMessage];

  NSString* URLStringToReload = [anError.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
  NSString* escaped = (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                         (CFStringRef)URLStringToReload,
                                                                         NULL,
                                                                         CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                         kCFStringEncodingUTF8);
  NSURL* errorPageURL = [NSURL URLWithString:errorPageBaseURL];
  NSURL* aBaseURL = [NSURL URLWithString:escaped relativeToURL:errorPageURL];
  [self loadHTMLString:aHtmlString baseURL:aBaseURL];
  *flag = YES;
  [escaped release];

  NSURL* failingUrl = [NSURL URLWithString:[anError.userInfo objectForKey:@"NSErrorFailingURLStringKey"]];
  if ([[failingUrl host] hasPrefix:@"notice."]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkNotificationBoard position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadError)];
  } else if ([[failingUrl path] isEqualToString:@"gd"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboard position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadError)];
  } else if ([[failingUrl fragment] hasPrefix:@"view=universalmenu_top"]) {
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkDashboardUm position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadError)];
  }


}

-(CGRect)greeActiveElementFrame
{
  NSString* coordinatesAsString = [self
                                   stringByEvaluatingJavaScriptFromString:
                                   @"(function (){"
                                   @"  var e = document.activeElement;                                                    "
                                   @"  var offsetLeft = e.offsetLeft;                                                     "
                                   @"  var offsetTop = e.offsetTop;                                                       "
                                   @"  var offsetWidth = e.offsetWidth;                                                   "
                                   @"  var offsetHeight = e.offsetHeight;                                                 "
                                   @"                                                                                     "
                                   @"  while(e.offsetParent) {                                                            "
                                   @"    if (e == document.getElementsByTagName('body')[0]) {                             "
                                   @"      break;                                                                         "
                                   @"    } else {                                                                         "
                                   @"      offsetLeft = offsetLeft + e.offsetParent.offsetLeft;                           "
                                   @"      offsetTop = offsetTop + e.offsetParent.offsetTop;                              "
                                   @"      e = e.offsetParent;                                                            "
                                   @"    }                                                                                "
                                   @"  }                                                                                  "
                                   @"  return offsetLeft + ',' + offsetTop + ',' + offsetWidth + ',' + offsetHeight;      "
                                   @"})();                                                                                "];

  if (0 < [coordinatesAsString length]) {
    NSArray* coordinateComponents = [coordinatesAsString componentsSeparatedByString:@","];
    NSInteger originX = [[coordinateComponents objectAtIndex:0] integerValue];
    NSInteger originY = [[coordinateComponents objectAtIndex:1] integerValue];
    NSInteger width = [[coordinateComponents objectAtIndex:2] integerValue];
    NSInteger height = [[coordinateComponents objectAtIndex:3] integerValue];
    return CGRectMake(originX, originY, width, height);
  } else {
    return CGRectZero;
  }
}

-(void)attachLabelWithURL:(NSURL*)anUrl position:(GreeWebViewUrlLabelPosition)aPosition
{
  if (![[anUrl scheme] hasPrefix:@"http"]) {
    return;
  }

  UILabel* urlLabel = (UILabel*)[self viewWithTag:kUrlLabelTag];
  if ([urlLabel.text isEqualToString:[anUrl absoluteString]] ) {
    return;
  }

  CGRect outerFrame = self.frame;
  CGSize size = [[anUrl absoluteString] sizeWithFont:[UIFont systemFontOfSize:14.0]
                                   constrainedToSize:CGSizeMake(outerFrame.size.width - 15, 300)
                                       lineBreakMode:UILineBreakModeCharacterWrap];

  if (!urlLabel) {
    urlLabel = [[UILabel alloc] init];
    urlLabel.textColor = [UIColor whiteColor];
    urlLabel.font = [UIFont systemFontOfSize:14.0];
    urlLabel.backgroundColor = [UIColor grayColor];
    urlLabel.lineBreakMode = UILineBreakModeCharacterWrap;
    urlLabel.numberOfLines = 0;
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    urlLabel.tag = kUrlLabelTag;

    [self addSubview:urlLabel];
    [urlLabel release];
    [self sendSubviewToBack:urlLabel];
  }

  CGRect labelRect;
  if (aPosition == GreeWebViewUrlLabelPositionTop) {
    labelRect = CGRectMake(5, 5, outerFrame.size.width - 15, size.height);
  } else {
    labelRect = CGRectMake(5, outerFrame.size.height - size.height - 65, outerFrame.size.width - 15, size.height);
  }

  [urlLabel setFrame:labelRect];
  urlLabel.text = [anUrl absoluteString];
}

@end
