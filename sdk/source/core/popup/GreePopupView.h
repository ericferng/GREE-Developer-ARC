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


#import <UIKit/UIKit.h>
#import "GreePopupURLHandler.h"
#import "GreeJSCommandEnvironment.h"


typedef enum {
  GreePopupViewTitleSettingMethodLogoOnly,
  GreePopupViewTitleSettingMethodFromTitleTagInContents,
  GreePopupViewTitleSettingMethodNothing,
  GreePopupViewTitleSettingMethodDefault = GreePopupViewTitleSettingMethodFromTitleTagInContents,
} GreePopupViewTitleSettingMethod;

@protocol GreePopupViewDelegate<NSObject, GreePopupURLHandlerDelegate>
@optional
-(GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle;
-(BOOL)popupViewShouldAcceptEmptyBody;
-(void)popupViewDidCancel;
-(void)popupViewDidComplete:(NSDictionary*)someResults;
-(void)popupViewWillLaunch;
-(void)popupViewDidLaunch;
-(void)popupViewWillDismiss;
-(void)popupViewDidDismiss;
-(void)popupViewWebViewDidStartLoad:(UIWebView*)aWebView;
-(void)popupViewWebViewDidFinishLoad:(UIWebView*)aWebView;
-(void)popupViewWebView:(UIWebView*)aWebView didFailLoadWithError:(NSError*)anError;
-(void)popupViewWebViewReload:(UIWebView*)aWebView;
@end


@class GreeJSHandler;


@interface GreePopupView : UIView<UIWebViewDelegate>
@property (retain, nonatomic) IBOutlet UIView* containerView;
@property (retain, nonatomic) IBOutlet UIView* contentView;
@property (retain, nonatomic) IBOutlet UIView* navigationBar;
@property (retain, nonatomic) IBOutlet UILabel* titleLabel;
@property (retain, nonatomic) IBOutlet UIImageView* logoImage;
@property (retain, nonatomic) IBOutlet UIButton* backButton;
@property (retain, nonatomic) IBOutlet UIButton* closeButton;
@property (retain, nonatomic) IBOutlet UIWebView* webView;
@property (nonatomic, assign) IBOutlet id<GreePopupViewDelegate> delegate;
@property (nonatomic, assign) id<GreeJSCommandEnvironment> commandEnvironment;
@property (retain, nonatomic) GreeJSHandler* handler;
@property (assign, nonatomic) BOOL connectionFailureContentsLoading;
-(void)show;
-(void)dismiss;
-(void)showActivityIndicator;
-(void)showHTTPErrorMessage:(NSError*)error;
-(IBAction)closeButtonTapped:(id)sender;
-(IBAction)backButtonTapped:(id)sender;
-(void)setTitleWithString:(NSString*)aTitleString;
@end
