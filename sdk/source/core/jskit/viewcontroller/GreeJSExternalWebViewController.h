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
#import "GreeJSExternalAddressBarView.h"

static float const kAddressBarPortraitHeight = 44.0f;
static float const kAddressBarLandscapeHeight = 35.0f;

@interface GreeJSExternalWebViewController : UIViewController<UIWebViewDelegate, GreeJSExternalAddressBarViewDelegate>

@property (nonatomic, retain) GreeJSExternalAddressBarView* addressBar;
@property (nonatomic, retain) UIWebView* webView;

-(id)initWithURL:(NSURL*)url;

@end
