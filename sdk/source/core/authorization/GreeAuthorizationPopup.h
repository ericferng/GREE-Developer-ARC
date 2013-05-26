//
// Copyright 2010-2011 GREE, inc.
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

#import <Foundation/Foundation.h>
#import "GreePopup.h"
#import "GreePopupView.h"

typedef void (^GreeAuthorizationPopupUrlSelfURLSchemeHandlingBlock)(NSURLRequest* aRequest);
typedef BOOL (^GreeAuthorizationPopupDefaultUrlHandlingBlock)(NSURLRequest* aRequest);
typedef void (^GreeAuthorizationPopupDidFailLoadHandlingBlock)(void);
typedef void (^GreeAuthorizationPopupDidFinishLoadHandlingBlock)(NSURLRequest* aRequest);

@interface GreeAuthorizationPopup : GreePopup
@property (copy) GreeAuthorizationPopupUrlSelfURLSchemeHandlingBlock selfURLSchemeHandlingBlock;
@property (copy) GreeAuthorizationPopupDefaultUrlHandlingBlock defaultURLSchemeHandlingBlock;
@property (copy) GreeAuthorizationPopupDidFailLoadHandlingBlock didFailLoadHandlingBlock;
@property (copy) GreeAuthorizationPopupDidFinishLoadHandlingBlock didFinishLoadHandlingBlock;
@property (nonatomic, retain) NSURLRequest* lastRequest;
-(void)closeButtonHidden:(BOOL)aHidden;
-(void)showActivityIndicator;
-(BOOL)isShowingUpgradeCompletePage;
-(void)loadErrorPage:(NSString*)errorString;
@end
