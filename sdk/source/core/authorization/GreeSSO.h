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

static NSString* const kSNSApplicationId = @"370";
static NSString* const kSNSApplicationIdOnDevelop = @"1350";
static NSString* const kBrowserId = @"browser";
static NSString* const kSelfId = @"self";
static NSString* const kNotSNSApplicationUrlScheme = @"greesso";

@interface GreeSSO : NSObject

//initialize as SSO Client
-(id)initAsClient;

//initialize as SSO Server
-(id)initAsServerWithSeedKey:(NSString*)seedKey clientApplicationId:(NSString*)applicationId;

//get greeapp client request to SSO server
-(NSURL*)ssoRequireUrlWithServerApplicationId:(NSString*)serverApplicationId
                                 requestToken:(NSString*)requestToken
                                      context:(NSString*)context
                                   parameters:(NSDictionary*)parameters;

//set gssid from SSO server
-(void)setDecryptGssIdWithEncryptedGssId:(NSString*)encryptedGssId;

//find applicationId of SSO Server
-(NSString*)openAvailableApplicationWithApps:(NSArray*)apps;

//get the greeapp url for returning to client
-(NSURL*)ssoAcceptUrlWithFlag:(BOOL)flag;

//get the web page url for allowing SSO at SSO Server.
-(NSURL*)acceptPageUrl;

@end
