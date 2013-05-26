//
// Copyright 2010-2012 GREE, inc.
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

#import <CommonCrypto/CommonHMAC.h>
#import "GreeAuthorization.h"
#import "GreeAuthorization+Internal.h"
#import "GreeAgreementPopup.h"
#import "GreeGlobalization.h"
#import "GreeHTTPClient.h"
#import "GreeKeyChain.h"
#import "NSData+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "NSDictionary+GreeAdditions.h"
#import "GreeSettings.h"
#import "GreeDeviceIdentifier.h"
#import "GreeAuthorizationPopup.h"
#import "GreeSSO.h"
#import "GreeWebSession.h"
#import "GreeNetworkReachability.h"
#import "GreeUser+Internal.h"
#import "GreeLogger.h"
#import "AFNetworking.h"
#import "JSONKit.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeError+Internal.h"
#import "GreeBenchmark.h"
#import "GreeCampaignCode.h"
#import "GreeNSNotification.h"
#import "GreeUtility.h"

static NSString* const kCommandConfirmDialog = @"confirm-dialog";
static NSString* const kCommandApiSdkEnter = @"api-sdk-enter";

static NSString* const kCommandStartAuthorization = @"start-authorization";
static NSString* const kCommandGetAcccesstoken = @"get-accesstoken";
static NSString* const kCommandChooseAccount = @"choose-account";
static NSString* const kCommandSSORequire = @"sso-require";
static NSString* const kCommandEnter = @"enter";
static NSString* const kCommandLogout = @"logout";
static NSString* const kCommandUpgrade = @"upgrade";
static NSString* const kCommandReAuthorize = @"reauthorize";
static NSString* const kCommandReOpen = @"reopen";
static NSString* const kParamKeyTargetGrade = @"target_grade";
static NSString* const kParamAuthorizationTarget = @"target"; //self/browser/appId
static NSString* const kManageDirectoryName = @"gree.authorization";
static NSString* const kFlagFileName = @"did_install";
static NSString* const kGreeAuthorizationOAuthTokenKey = @"oauth_token";
static NSString* const kGreePhoneNumberForUserFormat = @"phoneNumberForUser%@";
static NSString* const kGreeCountryCodeForUserFormat = @"countryCodeForUser%@";
static NSString* const kGreeResourcesHtmlConfirmPath = @"download/resources/html/confirm.html";

static double const kPopupLaunchDelayTime = 0.4;
static double const kSSOServerDismissDelayTime = 1.0;
static double const kAppearCloseButtonDelayTime = 1.0;

static int const kRunloopOneTimeDelay = 0;

NSError* MakeGreeError(GreeAFHTTPRequestOperation* operation, NSError* originalError)
{
  NSError* error;
  id response = [[operation responseString] greeObjectFromJSONString];
  if ([response isKindOfClass:[NSDictionary class]]) {
    error = [GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError userInfo:response];
  } else {
    error = [GreeError convertToGreeError:originalError];
  }
  return error;
}

NSError* MakeGreeErrorIfParametersMissing(NSArray* names, ...)
{
  NSMutableArray* missingParameterNames = nil;

  va_list args;
  va_start(args, names);
  for (NSString* name in names) {
    if (va_arg(args, id)) {
      continue;
    }
    if (missingParameterNames) {
      [missingParameterNames addObject:name];
    } else {
      missingParameterNames = [NSMutableArray arrayWithObject:name];
    }
  }
  va_end(args);

  if (!missingParameterNames) {
    return nil;
  }

  return [NSError errorWithDomain:GreeErrorDomain
                             code:GreeErrorCodeParameterMissing
                         userInfo:[NSDictionary dictionaryWithObject:missingParameterNames
                                                              forKey:@"names"]];
}

#pragma mark - definition
typedef enum {
  AuthorizationStatusInit,
  AuthorizationStatusInitLoginPage,
  AuthorizationStatusEnter,
  AuthorizationStatusEnterConfirm,
  AuthorizationStatusRequestTokenBeforeGot,
  AuthorizationStatusRequestTokenGot,
  AuthorizationStatusAuthorizationSuccess,
  AuthorizationStatusAccessTokenGot,
} AuthorizationStatus;

typedef enum {
  AuthorizationTypeDefault,
  AuthorizationTypeUpgrade,
  AuthorizationTypeSSOServer,
  AuthorizationTypeSSOLegacyServer,
  AuthorizationTypeLogout,
} AuthorizationType;

typedef void (^GreeAuthorizationUpgradeBlock)(void);

#pragma mark - Category

@interface GreeAuthorization ()
+(GreeAuthorization*)sharedInstance;
-(void)downloadConfirmHtmlWithBlock:(void (^)(NSError* error))block;
-(BOOL)handleConfirmDialogWithCommand:(NSString*)command params:(NSMutableDictionary*)params;

-(void)authorizationFailedWithError:(NSError*)error;
-(void)relogin;
-(BOOL)hasWelcomeViewController;
-(void)resetAndRevoke;
-(BOOL)isSavedAccessToken;
-(BOOL)isOpenedWithUrlSchemeForSSO;
-(BOOL)isReloginPopup:(GreePopup*)aPopup;
-(void)attemptInstantPlayWithBlock:(void (^)(NSError*))block;

-(void)popupAuthorizeAction:(NSMutableDictionary*)params;
-(BOOL)handleResponseError:(NSError*)anError showErrorDetail:(BOOL)showErrorDetail;
-(void)doBeforeApiAccessWithPopup;

-(void)openURLAction:(NSURL*)url;

-(void)startInitialTopPagePopupAuthorizeAction;
-(void)startGetRequestTokenPopupAuthorizeAction:(NSMutableDictionary*)params;

-(void)loadTopPage:(NSMutableDictionary*)params;
-(void)backToTopPage:(NSMutableDictionary*)params;
-(void)loadEnterPage:(NSMutableDictionary*)params;
-(void)loadAuthorizePage:(NSMutableDictionary*)params;
-(void)loadConfirmUpgradePage:(NSDictionary*)params;
-(void)loadUpgradePage:(NSMutableDictionary*)params;
-(void)loadConfirmReAuthorizePage;
-(void)loadSSOAcceptPage;
-(void)loadReloginPage;

-(void)popupLaunch;
-(void)popupDismiss;
-(void)startSSO:(NSMutableDictionary*)handledParams;

-(void)getRequestTokenWithBlock:(void (^)(NSError*))block;
-(void)getAccessTokenWithBlock:(void (^)(NSError*))block;
-(NSString*)parseResponseError:(NSError*)anError;
-(BOOL)handleConfirmDialogWithCommand:(NSString*)command params:(NSMutableDictionary*)params;
-(BOOL)handleReOpenWithCommand:(NSString*)command params:(NSMutableDictionary*)params;
-(BOOL)handleStartAuthorizationWithCommand:(NSString*)command params:(NSMutableDictionary*)params;
-(BOOL)handleChooseAccountWithCommand:(NSString*)command params:(NSMutableDictionary*)params;
-(void)getGssidWithCompletionBlock:(void (^)(void))completion;
-(void)getGssidWithCompletionBlock:(void (^)(void))completion forceUpdate:(BOOL)forceUpdate;
-(void)resetStatus;
-(void)resetAccessToken;
-(void)resetCookies;
-(void)addAuthVerifierToHttpClient:(NSMutableDictionary*)params;
-(void)removeOfAuthorizationData;
-(int)timezoneOffsetMinutes;
-(void)getCampaignCodeWithServiceType:(NSString*)serviceType block:(void (^)(NSDictionary*, NSError*))block;

-(void)dismiss3rdPartyWelcomeViewController;
-(void)nonInteractiveAuthorizeAction:(NSMutableDictionary*)params;
-(void)applicationDidBecomeActive:(NSNotification*)note;
-(void)phoneNumberBasedReAuthorize;

@property (nonatomic, assign) id<GreeAuthorizationDelegate> delegate;
@property (nonatomic, assign) AuthorizationStatus authorizationStatus;
@property (nonatomic, assign) AuthorizationType authorizationType;
@property (nonatomic, retain) GreeHTTPClient* httpClient;
@property (nonatomic, retain) GreeHTTPClient* httpConsumerClient;
@property (nonatomic, retain) GreeHTTPClient* httpIdClient;
@property (nonatomic, retain) NSString* userOAuthKey;
@property (nonatomic, retain) NSString* userOAuthSecret;
@property (nonatomic, retain) GreeAuthorizationPopup* popup;
@property (nonatomic, retain) GreeSSO* greeSSOLegacy;
@property (nonatomic, copy) GreeAuthorizationUpgradeBlock upgradeSuccessBlock;
@property (nonatomic, copy) GreeAuthorizationUpgradeBlock upgradeFailureBlock;
@property (nonatomic, assign) BOOL upgradeComplete;
@property (nonatomic, assign) NSString* configServerUrlOpen;
@property (nonatomic, assign) NSString* configServerUrlOs;
@property (nonatomic, assign) NSString* configServerUrlId;
@property (nonatomic, assign) NSString* configGreeDomain;
@property (nonatomic, assign) NSString* configAppUrlScheme;
@property (nonatomic, assign) NSString* configSelfApplicationId;
@property (nonatomic, assign) NSString* configConsumerSecret;
@property (nonatomic, retain) NSArray* deviceContextKeys;
@property (nonatomic, retain) NSString* deviceContext;
@property (nonatomic, retain) NSURL* SSOClientRequestUrl;
@property (nonatomic, retain) NSString* SSOClientApplicationId;
@property (nonatomic, retain) NSString* SSOClientRequestToken;
@property (nonatomic, retain) NSString* SSOClientContext;
@property (nonatomic, retain) NSString* SSOServerApplicationId;
@property (nonatomic, retain) NSString* userId;
@property (nonatomic, retain) NSString* lastLoggedUserId;
@property (nonatomic, retain) NSString* greeUUID;
@property (nonatomic, retain) NSString* serviceCode;
@property (nonatomic, retain) NSString* temporaryStoredServiceCode;
@property (nonatomic, retain) GreeNetworkReachability* reachability;
@property (nonatomic) BOOL isNetworkConnected;
@property (nonatomic) BOOL reachabilityIsWork;
@property (nonatomic) BOOL isNonInteractive;
@property (nonatomic) BOOL nonInteractiveWaitingForBrowserReturn;
@property (nonatomic, retain) UIViewController* welcomeViewController;
@property (nonatomic) GreeUserGrade nonInteractiveTargetGrade;
@property (nonatomic, assign) BOOL allowUserOptOutOfGREE;
@property (nonatomic, assign) BOOL useInstantPlay;
@property (nonatomic, retain) id popupDismissObserver;
@property (nonatomic) BOOL grade1sandbox;

@end

#pragma mark - GreeAuthorization
@implementation GreeAuthorization

#pragma mark - Object Lifecycle
-(void)dealloc
{
  self.userOAuthKey = nil;
  self.userOAuthSecret = nil;
  self.httpClient = nil;
  self.httpConsumerClient = nil;
  self.httpIdClient = nil;
  self.popup = nil;
  self.greeSSOLegacy = nil;
  self.upgradeSuccessBlock = nil;
  self.upgradeFailureBlock = nil;
  self.deviceContextKeys = nil;
  self.deviceContext = nil;
  self.SSOClientRequestUrl = nil;
  self.SSOClientApplicationId = nil;
  self.SSOClientRequestToken = nil;
  self.SSOClientContext = nil;
  self.SSOServerApplicationId = nil;
  self.userId = nil;
  self.lastLoggedUserId = nil;
  self.greeUUID = nil;
  self.reachability = nil;
  self.serviceCode = nil;
  self.launchOptions = nil;
  self.welcomeViewController = nil;
  self.popupDismissObserver = nil;
  [super dealloc];
}

#pragma mark - Public Interface
-(id)initWithConsumerKey:(NSString*)consumerKey
          consumerSecret:(NSString*)consumerSecret
                settings:(GreeSettings*)settings
                delegate:(id<GreeAuthorizationDelegate>)delegate;
{
  self = [super init];
  if(self) {
    [self resetStatus];
    self.delegate = delegate;

    // Default value
    self.nonInteractiveTargetGrade = GreeUserGradeLite;

    self.configConsumerSecret = consumerSecret;
    self.configServerUrlOpen = [settings stringValueForSetting:GreeSettingServerUrlOpen];
    self.configServerUrlOs = [settings stringValueForSetting:GreeSettingServerUrlOsWithSSL];
    self.configServerUrlId = [settings stringValueForSetting:GreeSettingServerUrlId];
    self.configGreeDomain = [settings stringValueForSetting:GreeSettingServerUrlDomain];
    self.configAppUrlScheme = [settings stringValueForSetting:GreeSettingApplicationUrlScheme];
    self.configSelfApplicationId = [settings stringValueForSetting:GreeSettingApplicationId];
    self.allowUserOptOutOfGREE = [settings boolValueForSetting:GreeSettingAllowUserOptOutOfGREE];
    self.useInstantPlay = [settings boolValueForSetting:GreeSettingUseInstantPlay];

    // deviceContextKeys must be set before greeUUID.
    // note: we do an immutable copy of the mutable array.
    NSMutableArray* keys = [[@[
                              GreeDeviceIdentifierKeyUUID,
                              GreeDeviceIdentifierKeySecureUDID
                            ] mutableCopy] autorelease];

    self.deviceContextKeys = [[keys copy] autorelease];

    self.greeUUID = [GreeKeyChain readWithKey:GreeKeyChainUUIDIdentifier];

    NSURL* baseURLOpen = [NSURL URLWithString:self.configServerUrlOpen];
    self.httpClient = [[[GreeHTTPClient alloc] initWithBaseURL:baseURLOpen key:consumerKey secret:consumerSecret] autorelease];

    NSURL* baseURLOs = [NSURL URLWithString:self.configServerUrlOs];
    self.httpConsumerClient = [[[GreeHTTPClient alloc] initWithBaseURL:baseURLOs key:consumerKey secret:consumerSecret] autorelease];

    NSURL* baseURLId = [NSURL URLWithString:self.configServerUrlId];
    self.httpIdClient = [[[GreeHTTPClient alloc] initWithBaseURL:baseURLId key:consumerKey secret:consumerSecret] autorelease];

    NSString* OAuthCallbackUrl = [NSString stringWithFormat:@"%@%@://%@",
                                  self.configAppUrlScheme,
                                  self.configSelfApplicationId,
                                  kCommandGetAcccesstoken];
    [self.httpClient setOAuthCallback:OAuthCallbackUrl];
    self.reachability = [[[GreeNetworkReachability alloc] initWithHost:self.configServerUrlOpen] autorelease];

    __block GreeAuthorization* myself = self;
    [self.reachability addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
       myself.isNetworkConnected = GreeNetworkReachabilityStatusIsConnected(current);
       myself.reachabilityIsWork = YES;
     }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    BOOL removeTokenWithReInstall = [settings boolValueForSetting:GreeSettingRemoveTokenWithReInstall];
    if (removeTokenWithReInstall) {
      NSString* aFlagFilePath = [NSString stringWithFormat:@"%@/%@", kManageDirectoryName, kFlagFileName];
      NSString* aFileSystemPath = [NSString greeDocumentsPathForRelativePath:aFlagFilePath];
      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
      NSString* hasToken = [defaults objectForKey:@"hasToken"];
      BOOL sdkv2TokenAvailable = hasToken && ![hasToken isEqualToString:@"0"];
      if (![[NSFileManager defaultManager] fileExistsAtPath:aFileSystemPath] && !sdkv2TokenAvailable) {
        NSString* aDirectoryPath = [aFileSystemPath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:aDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createFileAtPath:aFileSystemPath contents:nil attributes:nil];
        [self resetAccessToken];
      }
    }
  }
  
  if (![self isSavedAccessToken]) {
    [self downloadConfirmHtmlWithBlock:nil];
  }
  
  return self;
}

+(GreeAuthorization*)sharedInstance
{
  return [GreePlatform sharedInstance].authorization;
}

-(void)setGreeUUID:(NSString*)value
{
  if (_greeUUID != value) {
    [_greeUUID release];
    _greeUUID = [value retain];
  }

  // unit tests set this property directly so we better create our device context here,
  // otherwise it might remain nil
  if (_greeUUID) {
    self.deviceContext = [GreeDeviceIdentifier deviceContextIdWithSecret:self.configConsumerSecret greeUUID:self.greeUUID keys:self.deviceContextKeys];
  } else {
    self.deviceContext = nil;
  }
}

-(void)authorize
{
  self.serviceCode = nil;
  self.userId = [GreeKeyChain readWithKey:GreeKeyChainUserIdIdentifier];

  if ([self isSavedAccessToken]) {
    self.authorizationStatus = AuthorizationStatusAccessTokenGot;
    self.isNonInteractive = YES;
    [self nonInteractiveAuthorizeAction:[NSMutableDictionary dictionary]];
    return;
  }

  // Silent the agreement popup forever
  [GreeAgreementPopup makeSilent];

  self.isNonInteractive = [self hasWelcomeViewController];

  double delayTime = (self.reachabilityIsWork) ? kRunloopOneTimeDelay : kPopupLaunchDelayTime;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                   //This runloop delay(0) is needed to use isOpenedWithUrlSchemeForSSO.

                   if ([self isOpenedWithUrlSchemeForSSO]) {
                     return;
                   }

                   if ([self hasWelcomeViewController]) {
                     [self presentWelcomeViewController];
                     return;
                   }

                   if (self.allowUserOptOutOfGREE && !self.isNetworkConnected) {
                     //offline game start
                     [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeAuthorizationFailWithOffline]];
                     return;
                   }

                  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkPopupStart)];
                   self.authorizationStatus = AuthorizationStatusInitLoginPage;
                   [self popupAuthorizeAction:nil];
                 });
}

-(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade
{
  if (grade == GreeUserGradeLite && [GreePlatform sharedInstance].settings.usesSandbox) {
    grade = GreeUserGradeLimited;
    self.grade1sandbox = YES;
  } else {
    self.grade1sandbox = NO;
  }
  self.serviceCode = nil;
  if (self.temporaryStoredServiceCode) {
    self.serviceCode = self.temporaryStoredServiceCode;
    self.temporaryStoredServiceCode = nil;
  }
  self.userId = [GreeKeyChain readWithKey:GreeKeyChainUserIdIdentifier];
  self.isNonInteractive = YES;
  self.nonInteractiveTargetGrade = grade;

  NSMutableDictionary* params = [NSMutableDictionary dictionary];

  if ([self isSavedAccessToken]) {
    self.authorizationStatus = AuthorizationStatusAccessTokenGot;
    [self nonInteractiveAuthorizeAction:params];
    return;
  }

  double delayTime = (self.reachabilityIsWork) ? kRunloopOneTimeDelay : kPopupLaunchDelayTime;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

                   if ([self isOpenedWithUrlSchemeForSSO]) {
                     return;
                   }


                   if (self.allowUserOptOutOfGREE && !self.isNetworkConnected) {
                     //offline game start
                     [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeAuthorizationFailWithOffline]];
                     return;
                   }

                   // Authorize
                   self.SSOServerApplicationId = nil; //sso app can be removed or installed at any time.
                   if (grade == GreeUserGradeLite) {
                     self.authorizationStatus = AuthorizationStatusInit;
                     [self nonInteractiveAuthorizeAction:params];
                   } else {
                     [self getSSOAppIdWithBlock:^(NSError* error) {
                       if (error) {
                         [self authorizationFailedWithError:error];
                         return;
                       }
                       if (![self.SSOServerApplicationId isEqualToString:kBrowserId]) {
                         self.authorizationStatus = AuthorizationStatusInit;
                         [self nonInteractiveAuthorizeAction:params];
                         return;
                       }

                       [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkPopupStart)];
                       self.authorizationStatus = AuthorizationStatusInitLoginPage;
                       [self popupAuthorizeAction:nil];
                     }];
                   }
                 });
}

-(void)revoke
{
  if(![self isSavedAccessToken]) {
    return;
  }
  [self loadReloginPage];
}

-(void)directRevoke
{
  if(![self isSavedAccessToken]) {
    return;
  }

  [self dismiss3rdPartyWelcomeViewController];

  __block GreeAuthorization* selfRef = self;

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"revokeStart")
         pointRole:GreeBenchmarkPointRoleStart];

  
  void (^block)(GreeAFHTTPRequestOperation*, id) =^(GreeAFHTTPRequestOperation* operation, id object) {
    if (operation.response.statusCode == 200) {
      // HTTP client expect JSON but will get HTML for this API call, so it
      // will "fail" with a HTTP status code of 200.

      [[GreePlatform sharedInstance].benchmark
       registerWithKey:kGreeBenchmarkAuthorization
              position:GreeBenchmarkPosition(@"revokeEnd")
             pointRole:GreeBenchmarkPointRoleEnd];

      [selfRef resetStatus];
      [selfRef resetAccessToken];
      [selfRef resetCookies];
      [selfRef removeOfAuthorizationData];

      if ([selfRef.delegate respondsToSelector:@selector(revokeDidFinish:)]) {
        [selfRef.delegate revokeDidFinish:nil];
      }
    } else if ([object isKindOfClass:[NSError class]]) {
      // Other failures that are not HTTP 200 (i.e. real errors)

      [[GreePlatform sharedInstance].benchmark
       registerWithKey:kGreeBenchmarkAuthorization
              position:GreeBenchmarkPosition(@"revokeError")
             pointRole:GreeBenchmarkPointRoleEnd];

      if ([selfRef.delegate respondsToSelector:@selector(revokeDidFinish:)]) {
        [selfRef.delegate revokeDidFinish:MakeGreeError(operation, object)];
      }
    }
  };

  NSDictionary* params = @{
    @"ignore_all_logout" : @1,
    @"backto" :            @"",
    @"context" :           self.deviceContext ? self.deviceContext : @""
  };

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=logout_commit" parameters:params success:block failure:block];
}

-(void)reAuthorize
{
  if (_popup) {
    return;
  }

  // Use the normal flow by default (3rdPartyUI flow doesn't support reauthorization yet
  // so it uses the default popup system)
  self.isNonInteractive = NO;

  // Temporarily log the user out
  [self resetAndRevoke];

  // Launch the reauthorization asynchronously
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPopupLaunchDelayTime * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^() {
                   switch ([GreePlatform sharedInstance].registrationFlow) {
                   case GreePlatformRegistrationFlowPhoneNumberBased:
                     [self phoneNumberBasedReAuthorize];
                     break;

                   case GreePlatformRegistrationFlowDefault:
                     
                     // if we're to going to get rid of this legacy code
                     // (delegate, notification, reauthorizeBlock…)
                     [self loadConfirmReAuthorizePage];
                     break;

                   case GreePlatformRegistrationFlowLegacy:
                     [self loadConfirmReAuthorizePage];
                     break;
                   }
                 });
}

-(void)upgradeWithParams:(NSDictionary*)params
            successBlock:(GreeAuthorizationUpgradeBlock)successBlock
            failureBlock:(GreeAuthorizationUpgradeBlock)failureBlock
{
  if (_popup) {
    return;
  }

  if (!successBlock || !failureBlock) {
    return;
  }

  if (![self isAuthorized] || !self.userId) {
    failureBlock ();
    return;
  }

  NSInteger targetGrade = [[params objectForKey:@"target_grade"] intValue];
  if (targetGrade <= 0) {
    failureBlock();
    return;
  }

  //wrap the success block so that it actually updates the local user
  GreeAuthorizationUpgradeBlock wrapSuccess =^{
    [GreeUser upgradeLocalUser:targetGrade];
    successBlock();
  };

  [self resetStatus];
  self.authorizationStatus = AuthorizationStatusAccessTokenGot;
  self.authorizationType = AuthorizationTypeUpgrade;
  self.upgradeSuccessBlock = wrapSuccess;
  self.upgradeFailureBlock = failureBlock;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPopupLaunchDelayTime * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                   // The following code avoids a problem which displays login view when app has the old session
                   [GreeWebSession regenerateWebSessionWithBlock:^(NSError* error) {
                      if (error) {
                        failureBlock();
                      } else {
                        [self loadConfirmUpgradePage:params];
                      }
                    }];
                 });
}

-(BOOL)handleOpenURL:(NSURL*)url
{
  [self openURLAction:url];
  return YES;
}

-(BOOL)handleBeforeAuthorize:(NSString*)serviceString
{
  if ([self isAuthorized]) {
    return NO;
  }

  self.temporaryStoredServiceCode = serviceString;
  [GreePlatform directAuthorizeWithDesiredGrade:GreeUserGradeLite block:nil];

  return YES;
}

-(BOOL)isAuthorized
{
  return (self.accessToken && self.accessTokenSecret) ? YES : NO;
}

-(NSString*)accessTokenData
{
  if (self.authorizationStatus == AuthorizationStatusAccessTokenGot) {
    return self.userOAuthKey;
  }
  return nil;
}

-(NSString*)accessTokenSecretData
{
  if (self.authorizationStatus == AuthorizationStatusAccessTokenGot) {
    return self.userOAuthSecret;
  }
  return nil;
}

-(void)updateUserIdIfNeeded:(NSString*)userId
{
  // the following situation means that a SDK2.x App will update to SDK3.x App.
  if (!self.userId && userId) {
    [GreeKeyChain saveWithKey:GreeKeyChainUserIdIdentifier value:userId];
    self.userId = userId;
  }
}

#pragma mark - GreePopup+Internal Methods

-(void)logout
{
  [self relogin];
}

#pragma mark - Internal Methods

-(void)authorizationFailedWithError:(NSError*)error
{
  [self resetStatus];
  [self resetAccessToken];

  //this is needed for executing the passed blocks of authorizeWithBlock.
  if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithGrade0:)]) {
    [self.delegate authorizeDidFinishWithGrade0:error];
  }
}

-(void)syncIdentifiers
{
  // Only sync the identifiers if:
  // - user is authenticated
  // - useInstantPlay is set
  if (![self isAuthorized] || !self.userId || !self.useInstantPlay || !self.greeUUID) {
    return;
  }

  NSData* liteContext = [self.greeUUID dataUsingEncoding:NSUTF8StringEncoding];

  // Compute the signature for our lite context
  NSData* secret = [self.configConsumerSecret dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableData* result = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, secret.bytes, secret.length, liteContext.bytes, liteContext.length, result.mutableBytes);
  NSString* liteContextSignature = [result greeBase64EncodedString];

  // Compare with the previous signature for this user, if any
  NSString* liteContextSignatureKey = [NSString stringWithFormat:@"liteContextSignatureForUser%@", self.userId];
  NSString* previousLiteContextSignature = [GreeKeyChain readWithKey:liteContextSignatureKey];
  if ([previousLiteContextSignature isEqualToString:liteContextSignature]) {
    // The two signatures match, so we've got nothing to do!
    return;
  }

  // We need to sync
  NSDictionary* params = @{
    @"app_id" : self.configSelfApplicationId,
    @"user_id": self.userId,
    @"context": self.deviceContext ? self.deviceContext : @""
  };

  __block NSString* key = [liteContextSignatureKey retain];
  __block NSString* value = [liteContextSignature retain];
  [self.httpIdClient postPath:@"/?action=api_sdk_sync_lite" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     // Identifiers sync'ed successfully. Update the keychain with the new signature
     [GreeKeyChain saveWithKey:key value:value];
     [key release];
     [value release];
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     // Don't report the error. We'll retry when we get the chance.
     [key release];
     [value release];
   }];
}

-(void)relogin
{
  [self resetAndRevoke];

  self.isNonInteractive = YES;
  [self doBeforeApiAccessWithPopup];
  [self getRequestTokenWithBlock:^(NSError* error) {
     if ([self handleResponseError:error showErrorDetail:YES]) {
       return;
     }

     NSString* urlString = [NSString stringWithFormat:
                            @"%@/oauth/authorize?oauth_token=%@&context=%@&tz_offset=%d&target=browser&forward_type=login&force_logout=1",
                            self.configServerUrlOpen,
                            self.userOAuthKey,
                            self.deviceContext,
                            [self timezoneOffsetMinutes]];
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];

     if ([self hasWelcomeViewController]) {
       [self.popup dismiss];
       [self presentWelcomeViewController];
     } else {
       self.authorizationStatus = AuthorizationStatusInitLoginPage;
       [self popupAuthorizeAction:nil];
     }
   }];
}

-(BOOL)hasWelcomeViewController
{
  return [[[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingWelcomeViewControllerClass] isKindOfClass:[NSObject class]];
}

-(void)resetAndRevoke
{
  [self resetStatus];
  [self resetAccessToken];
  [self resetCookies];
  [self removeOfAuthorizationData];
  [GreeUser setIsAppStarted:NO];
  if ([self.delegate respondsToSelector:@selector(revokeDidFinish:)]) {
    [self.delegate revokeDidFinish:nil];
  }
}

-(BOOL)isSavedAccessToken;
{
  self.userOAuthKey = [GreeKeyChain readWithKey:GreeKeyChainAccessTokenIdentifier];
  self.userOAuthSecret = [GreeKeyChain readWithKey:GreeKeyChainAccessTokenSecretIdentifier];
  if (self.userOAuthKey && self.userOAuthSecret) {
    return YES;
  }
  return NO;
}

-(BOOL)isOpenedWithUrlSchemeForSSO
{
  //This case is that SSO Server App is launched by handling OpenURL but it doesn't login yet,
  //or back to SSO Client from SSO Server App.
  //To prevent the conflict with SSO process (the login process is delayed. So it conflicts with SSO process.),
  //do nothing about this case.
  NSURL* launchOptionUrl = [self.launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
  //reset launchOptions for recalling authorize after SSO.
  self.launchOptions = nil;

  return ([[launchOptionUrl host] isEqualToString:@"authorize"]
          && [[launchOptionUrl path] isEqualToString:@"/request"])
         || ([[launchOptionUrl host] isEqualToString:kCommandGetAcccesstoken]);
}

-(BOOL)isReloginPopup:(GreePopup*)aPopup
{
  NSDictionary* params = [[aPopup.popupView.webView.request URL].query greeDictionaryFromQueryString];
  return [[params objectForKey:@"action"] isEqualToString:@"logout"];
}

#pragma mark popup authorization

-(void)popupAuthorizeAction:(NSMutableDictionary*)params
{
  self.isNonInteractive = NO;
  [self popupLaunch];

  if (!self.greeUUID) {
    [self doBeforeApiAccessWithPopup];
    [self getUUIDWithBlock:^(NSError* error) {
       if ([self handleResponseError:error showErrorDetail:NO]) {
         return;
       }
       [self popupAuthorizeAction:params];
     }];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusInit) {
    [self.popup closeButtonHidden:NO];
    [self resetAccessToken];
    [self loadTopPage:params];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusInitLoginPage) {
    [self.popup closeButtonHidden:NO];
    [self resetAccessToken];
    [self loadLoginPage:params];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusEnter) {
    [self loadEnterPage:params];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusRequestTokenBeforeGot) {
    [self doBeforeApiAccessWithPopup];
    [self getRequestTokenWithBlock:^(NSError* error) {
       if ([self handleResponseError:error showErrorDetail:YES]) {
         return;
       }
       self.authorizationStatus = AuthorizationStatusRequestTokenGot;
       [self popupAuthorizeAction:params];
     }];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusRequestTokenGot) {
    [self loadAuthorizePage:params];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusAuthorizationSuccess) {
    [self doBeforeApiAccessWithPopup];
    [self getAccessTokenWithBlock:^(NSError* error) {
       if ([self handleResponseError:error showErrorDetail:YES]) {
         return;
       }
       self.authorizationStatus = AuthorizationStatusAccessTokenGot;
       [self popupAuthorizeAction:params];
     }];
    return;
  }

  if (self.authorizationStatus == AuthorizationStatusAccessTokenGot) {
    //after getting accesstoken, reopen openURLAction for SSO.
    if (self.SSOClientRequestUrl) {
      [self.httpIdClient setUserToken:self.accessToken secret:self.accessTokenSecret];
      if ([self.delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
        [self.delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
      }
      [self getGssidWithCompletionBlock:^{
         [self openURLAction:self.SSOClientRequestUrl];
       } forceUpdate:YES];
      return;
    }

    //success original , upgrade
    if (self.authorizationType == AuthorizationTypeUpgrade) {
      self.upgradeComplete = YES;
    }

    self.popupDismissObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GreeNSNotificationKeyDidCloseNotification object:nil queue:nil usingBlock:^(NSNotification* note) {
      if ([note.userInfo[@"type"] intValue] == GreeViewControllerTypeAuthorizationPopup) {
        [self dismiss3rdPartyWelcomeViewController];
        [[NSNotificationCenter defaultCenter] removeObserver:self.popupDismissObserver];
        self.popupDismissObserver = nil;
      }
    }];

    [self popupDismiss];
    return;
  }
}

-(BOOL)handleResponseError:(NSError*)anError showErrorDetail:(BOOL)showErrorDetail
{
  if (anError) {
    [self.popup loadErrorPage:(showErrorDetail ? [self parseResponseError:anError] : nil)];
    [self.popup closeButtonHidden:NO];
    return YES;
  }
  return NO;
}

-(void)doBeforeApiAccessWithPopup
{
  if (!self.popup) {
    return;
  }

  NSURLRequest* previousRequest = self.popup.popupView.webView.request;
  if ([previousRequest.URL.scheme hasPrefix:@"http"]) {
    self.popup.lastRequest = previousRequest;
  }
  [self.popup showActivityIndicator];
  [self.popup closeButtonHidden:YES];
}

-(void)popupLaunch
{
  if (_popup) {
    return;
  }

  self.popup = [GreeAuthorizationPopup popup];
  [self.popup closeButtonHidden:YES];
  [self.popup showActivityIndicator];

  self.popup.didDismissBlock  =^(GreePopup* aSender) {

    if(self.authorizationType == AuthorizationTypeUpgrade) {
      if(self.upgradeComplete) {
        if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
          [self.delegate authorizeDidFinishWithLogin:NO];
        }
        if(self.upgradeSuccessBlock) {
          self.upgradeSuccessBlock();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeAuthorizationDidSuccessUpgrade" object:self];
      } else {
        if(self.upgradeFailureBlock) {
          self.upgradeFailureBlock();
        }
      }
      [self resetStatus];
      self.authorizationStatus = AuthorizationStatusAccessTokenGot;
    } else if (self.authorizationType == AuthorizationTypeSSOLegacyServer
               || self.authorizationType == AuthorizationTypeSSOServer
               || self.authorizationType == AuthorizationTypeLogout) {
      if (self.authorizationType == AuthorizationTypeSSOLegacyServer
          || self.authorizationType == AuthorizationTypeSSOServer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeAuthorizationDidCloseSSOPopup" object:self];
        if (self.SSOClientRequestUrl) {
          if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
            [self.delegate authorizeDidFinishWithLogin:YES];
          }
          self.SSOClientRequestUrl = nil;
        }
      } else if (self.authorizationType == AuthorizationTypeLogout) {
        if ([self.delegate respondsToSelector:@selector(revokeDidFinish:)]) {
          NSError* anError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeLogoutCancelledByUser];
          [self.delegate revokeDidFinish:anError];
        }
      }
      [self resetStatus];
      self.authorizationStatus = AuthorizationStatusAccessTokenGot;
    } else if (self.authorizationType == AuthorizationTypeDefault) {

      if ([self isReloginPopup:aSender]) {
        self.popup = nil;
        return;
      }

      if ([self isAuthorized]) {
        if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
          [self.delegate authorizeDidFinishWithLogin:YES];
        }
        [self resetStatus];
        self.authorizationStatus = AuthorizationStatusAccessTokenGot;
      } else {
        [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeAuthorizationCancelledByUser]];
      }
    }

    self.popup = nil;
  };

  //greeapp{self appid} handling
  self.popup.selfURLSchemeHandlingBlock =^(NSURLRequest* aRequest) {
    NSString* handledCommand = [aRequest.URL host];
    NSMutableDictionary* handledParams = [[aRequest.URL query] greeDictionaryFromQueryString];
    GreeLog(@"greeapp{selfId} handled command:%@ params:%@", handledCommand, handledParams);

    //user tap do SSO @SSO client
    if ([handledCommand isEqualToString:kCommandSSORequire]) {
      [self startSSO:handledParams];
      return;
    }

    //"enter" from Top page to login as grade1
    if ([handledCommand isEqualToString:kCommandEnter]) {
      [self resetStatus];
      [self resetAccessToken];
      self.authorizationStatus = AuthorizationStatusEnter;
      [self popupAuthorizeAction:handledParams];
      return;
    }
    // "api_sdk_enter"
    if ([self handleApiSdkEnterWithCommand:handledCommand params:handledParams]) {
      return;
    }

    //"start-authorization" from enter page , stating reauthorize
    if ([self handleStartAuthorizationWithCommand:handledCommand params:handledParams]) {
      return;
    }

    //"get-accesstoken" from grade1 registration, finishing reauthorize
    if ([handledCommand isEqualToString:kCommandGetAcccesstoken]) {
      [self addAuthVerifierToHttpClient:handledParams];
      self.authorizationStatus = AuthorizationStatusAuthorizationSuccess;
      [self popupAuthorizeAction:nil];
      return;
    }

    //user tap upgrade
    if ([handledCommand isEqualToString:kCommandUpgrade]) {
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkUpgrade position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];
      dispatch_async(dispatch_get_main_queue(), ^{
                       [self loadUpgradePage:handledParams];
                     });
      return;
    }

    //user tap logout
    if ([handledCommand isEqualToString:kCommandLogout]) {
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogout position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];
      [self logout];
      return;
    }

    //"reopen" for sign up or upgrade
    if ([self handleReOpenWithCommand:handledCommand params:handledParams]) {
      return;
    }

    //"choose-account"
    if ([self handleChooseAccountWithCommand:handledCommand params:handledParams]) {
      return;
    }
  };

  self.popup.defaultURLSchemeHandlingBlock =^(NSURLRequest* aRequest){
    NSString* handledScheme = [aRequest.URL scheme];
    NSString* handledCommand = [aRequest.URL host];
    NSMutableDictionary* handledParams = [[aRequest.URL query] greeDictionaryFromQueryString];
    GreeLog(@"default after filter handled scheme:%@ command:%@ params:%@", handledScheme, handledCommand, handledParams);

    //back to SSO client after authorization by sso-oauth request
    if ([handledScheme isEqualToString:[NSString stringWithFormat:@"%@%@", self.configAppUrlScheme, self.SSOClientApplicationId]]) {
      //command is get-accesstoken or reopen
      [[UIApplication sharedApplication] openURL:aRequest.URL];
      [NSThread sleepForTimeInterval:kSSOServerDismissDelayTime];
      [self popupDismiss];
      return NO;
    }
    //user tap allow or not @SSO server display / This is the session auth.(for old version)
    if ([handledScheme isEqualToString:self.configAppUrlScheme]) {
      if ([handledCommand isEqualToString:@"authorize"]) {
        BOOL bAccept = ([[aRequest.URL path] isEqualToString:@"/accepted"]) ? YES : NO;
        NSURL* ssoAcceptUrl = [self.greeSSOLegacy ssoAcceptUrlWithFlag:bAccept];
        [[UIApplication sharedApplication] openURL:ssoAcceptUrl];
        [NSThread sleepForTimeInterval:kSSOServerDismissDelayTime];
        [self popupDismiss];
        return NO;
      }
    }
    return YES;
  };

  self.popup.didFailLoadHandlingBlock =^{
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkUrlLoadError)];
    if(self.authorizationType != AuthorizationTypeLogout) {
      [self.popup closeButtonHidden:NO];
    }
  };

  self.popup.didFinishLoadHandlingBlock =^(NSURLRequest* aRequest){
    NSString* resultString = [self.popup.popupView.webView stringByEvaluatingJavaScriptFromString:@"shouldPopupCloseButtonHidden()"];
    if ([resultString isEqualToString:@"1"] || [self isReloginPopup:self.popup]) {
      [self.popup closeButtonHidden:YES];
    } else if (self.authorizationType == AuthorizationTypeDefault || self.authorizationType == AuthorizationTypeUpgrade) {
      [self.popup closeButtonHidden:NO];
    }

    if (self.authorizationType == AuthorizationTypeUpgrade && [self.popup isShowingUpgradeCompletePage]) {
      self.upgradeComplete = YES;
    }
  };

  [[UIViewController greeLastPresentedViewController] showGreePopup:self.popup];
}

-(void)popupDismiss
{
  if (self.authorizationType == AuthorizationTypeSSOServer ||
      self.authorizationType == AuthorizationTypeSSOLegacyServer) {
    [self.popup dismiss];
  } else {
    [self.httpIdClient setUserToken:self.accessToken secret:self.accessTokenSecret];
    if ([self.delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
      [self.delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
    }
    [self getGssidWithCompletionBlock:^{
       [self.popup dismiss];
     } forceUpdate:YES];
  }
}

-(void)startSSO:(NSMutableDictionary*)handledParams
{
  [self doBeforeApiAccessWithPopup];

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"rootGetStart")];

  [self getSSOAppIdWithBlock:^(NSError* error) {
     if ([self handleResponseError:error showErrorDetail:NO]) {
       return;
     }
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"rootGetEnd")];

     // Next
     NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:handledParams];
     [params setObject:self.SSOServerApplicationId ? self.SSOServerApplicationId:kBrowserId forKey:kParamAuthorizationTarget];
     [self startGetRequestTokenPopupAuthorizeAction:params];
   }];
}

#pragma mark start popup AuthorizeAction

-(void)startInitialTopPagePopupAuthorizeAction
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkPopupStart)];

  self.authorizationStatus = AuthorizationStatusInit;
  [self popupAuthorizeAction:nil];
}

-(void)startGetRequestTokenPopupAuthorizeAction:(NSMutableDictionary*)params
{
  self.authorizationStatus = AuthorizationStatusRequestTokenBeforeGot;
  [self popupAuthorizeAction:params];
}

-(void)downloadConfirmHtmlWithBlock:(void (^)(NSError* error))block
{
  NSString* savePath = [NSString greeCachePathForRelativePath:kGreeResourcesHtmlConfirmPath];
  NSInteger maxTryCount = 5;

  GreeRetry(maxTryCount, ^(NSInteger count, double previousDelay, void(^retry)(BOOL, double)){
    GreeHTTPSuccessBlock success = ^(GreeAFHTTPRequestOperation* operation, id object){
      if (block) {
        block(nil);
      }
      retry(NO, 0);
    };

    GreeHTTPFailureBlock failure = ^(GreeAFHTTPRequestOperation* operation, NSError* error){
      if (count == maxTryCount && block) {
        block([GreeError convertToGreeError:error]);
      }
      retry(YES, (previousDelay < 10 ? previousDelay + 2 : 10));
    };

    [self.httpIdClient performTwoLeggedDownloadWithMethod:@"GET" path:@"/?action=resources_html_confirm" parameters:nil savePath:savePath success:success failure:failure];
  });
}

#pragma mark popup Authorization page
-(void)loadTopPage:(NSMutableDictionary*)params
{
  NSString* urlString = [NSString stringWithFormat                                                                          :@"%@/?action=top&context=%@%@",
                         self.configServerUrlId,
                         self.deviceContext,
                         ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.popup loadRequest:aRequest];
}

-(void)loadLoginPage:(NSMutableDictionary*)params
{
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=login&context=%@%@%@",
                                                   self.configServerUrlId,
                                                   self.deviceContext,
                                                   ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@"",
                                                   (self.grade1sandbox) ? @"&forward_type=login_lite" : @""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.popup loadRequest:aRequest];
}

-(void)backToTopPage:(NSMutableDictionary*)params
{
  if (self.serviceCode) {
    [params setObject:self.serviceCode forKey:@"service_code"];
  }
  [self loadTopPage:params]; //back to top, because of indicator showing
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAppearCloseButtonDelayTime * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                   [self.popup closeButtonHidden:NO];
                 });
}

-(void)loadEnterPage:(NSMutableDictionary*)params
{
  NSString* urlString = [NSString stringWithFormat                                                                          :@"%@/?action=enter&context=%@%@",
                         self.configServerUrlId,
                         self.deviceContext,
                         ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.popup loadRequest:aRequest];
}

-(void)loadAuthorizePage:(NSMutableDictionary*)params
{
  NSString* requestToken;
  NSString* context;
  BOOL bTargetSelf = NO;

  if (self.accessToken && self.SSOClientRequestToken) {
    bTargetSelf = YES;
    requestToken = self.SSOClientRequestToken;
    context = self.SSOClientContext;
  } else {
    requestToken = self.userOAuthKey;
    context = self.deviceContext;
  }

  NSString* urlString = [NSString stringWithFormat                                                                                            :
                         @"%@/oauth/authorize?%@context=%@&tz_offset=%d%@",
                         self.configServerUrlOpen,
                         (self.authorizationType != AuthorizationTypeSSOServer) ? [NSString stringWithFormat:@"oauth_token=%@&", requestToken]: @"",
                         context,
                         [self timezoneOffsetMinutes],
                         ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@""];
  NSURL* aRequestUrl = [NSURL URLWithString:urlString];
  NSString* target = [params objectForKey:kParamAuthorizationTarget];

  if ([target isEqualToString:kSelfId] || bTargetSelf) { //Here should be sso server or grade1. open internal webview.
    [self.popup loadRequest:[NSURLRequest requestWithURL:aRequestUrl]];

  } else if ([target isEqualToString:kBrowserId]) {   //Here should be sso client. open browser.
    [[UIApplication sharedApplication] openURL:aRequestUrl];
    [self backToTopPage:params];

  } else { //Here should be sso client. open sso server app
    [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkPostStart)];

    [[UIApplication sharedApplication] openURL:
     [self.greeSSOLegacy ssoRequireUrlWithServerApplicationId:target
                                                 requestToken:self.userOAuthKey
                                                      context:self.deviceContext
                                                   parameters:params]];
    [self backToTopPage:params];
  }
}

-(void)loadConfirmUpgradePage:(NSDictionary*)params
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkUpgrade position:GreeBenchmarkPosition(kGreeBenchmarkPopupStart)];
  [self popupLaunch];
  NSString* urlString = [NSString stringWithFormat                                                                          :@"%@/?action=confirm_upgrade%@",
                         self.configServerUrlId,
                         ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.popup loadRequest:aRequest];
  [self.popup closeButtonHidden:NO];
}

-(void)loadUpgradePage:(NSMutableDictionary*)params
{
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=upgrade&user_id=%@&app_id=%@&context=%@%@",
                         self.configServerUrlId,
                         self.userId,
                         self.configSelfApplicationId,
                         self.deviceContext,
                         ([params greeBuildQueryString]) ? [NSString stringWithFormat:@"&%@", [params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

  NSString* target = [params objectForKey:kParamAuthorizationTarget];
  if ([target isEqualToString:kSelfId]) {
    [self.popup loadRequest:aRequest];
  } else if ([target isEqualToString:kBrowserId]) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  } else {
    //nop for now
  }
}

-(void)loadConfirmReAuthorizePage
{
  [self popupLaunch];
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=confirm_reauthorize", self.configServerUrlId];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.popup loadRequest:aRequest];
  [self.popup closeButtonHidden:YES];
}

-(void)loadSSOAcceptPage
{
  [self popupLaunch];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[self.greeSSOLegacy acceptPageUrl]];
  [self.popup loadRequest:aRequest];
}

-(void)loadReloginPage
{
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogout position:GreeBenchmarkPosition(kGreeBenchmarkPopupStart)];
  [self popupLaunch];
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=logout&relogin=1", self.configServerUrlId];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
}

#pragma mark token

-(void)getRequestTokenWithBlock:(void (^)(NSError*))block
{
  // Get new request token
  [self.httpClient setUserToken:nil secret:nil];
  [self.httpClient setOAuthVerifier:nil];
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthRequestTokenGetStart")];

  [self.httpClient
   rawRequestWithMethod:@"GET"
                   path:@"/oauth/request_token"
             parameters:@{@"context" : self.deviceContext ? self.deviceContext : @""}
                success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSDictionary* response = [[operation responseString] greeDictionaryFromQueryString];

     NSString* oauthToken             = [response objectForKey:@"oauth_token"];
     NSString* oauthTokenSecret       = [response objectForKey:@"oauth_token_secret"];
     NSString* oauthCallbackConfirmed = [response objectForKey:@"oauth_callback_confirmed"];

     if (![oauthToken isKindOfClass:[NSString class]] ||
         ![oauthTokenSecret isKindOfClass:[NSString class]] ||
         ![oauthCallbackConfirmed isEqualToString:@"true"]) {
       // Validation error
       [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthRequestTokenGetError")];
       block([GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer]);
       return;
     }
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthRequestTokenGetEnd")];

     // Save the token pair to keychain
     NSString* requestTokenPairsString = [GreeKeyChain readWithKey:GreeKeyChainRequestTokenPairs];
     requestTokenPairsString = requestTokenPairsString ? requestTokenPairsString : @"";
     NSMutableDictionary* requestTokenPairs = [requestTokenPairsString greeDictionaryFromQueryString];
     [requestTokenPairs setObject:oauthTokenSecret forKey:oauthToken];
     [GreeKeyChain saveWithKey:GreeKeyChainRequestTokenPairs value:[requestTokenPairs greeBuildQueryString]];

     // Next
     self.userOAuthKey    = oauthToken;
     self.userOAuthSecret = oauthTokenSecret;
     block(nil);
   }
                failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthRequestTokenGetError")];
     block(MakeGreeError(operation, error));
   }
  ];
}

-(void)getAccessTokenWithBlock:(void (^)(NSError*))block
{
  // Get new access token
  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthAccessTokenGetStart")];
  [self.httpClient setUserToken:self.userOAuthKey secret:self.userOAuthSecret];
  [self.httpClient
   rawRequestWithMethod:@"GET"
                   path:@"/oauth/access_token"
             parameters:@{@"context" : self.deviceContext ? self.deviceContext : @""}
                success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSDictionary* response = [[operation responseString] greeDictionaryFromQueryString];
     NSString* oauthToken       = [response objectForKey:@"oauth_token"];
     NSString* oauthTokenSecret = [response objectForKey:@"oauth_token_secret"];
     NSString* userId           = [response objectForKey:@"user_id"];

     if (![oauthToken isKindOfClass:[NSString class]] ||
         ![oauthTokenSecret isKindOfClass:[NSString class]] ||
         ![userId isKindOfClass:[NSString class]]) {
       [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthAccessTokenGetError")];
       block([GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer]);
       return;
     }
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthAccessTokenGetEnd")];

     // success to getting access token
     [GreeKeyChain saveWithKey:GreeKeyChainUserIdIdentifier value:userId];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenIdentifier value:oauthToken];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenSecretIdentifier value:oauthTokenSecret];
     [GreeKeyChain removeWithKey:GreeKeyChainRequestTokenPairs];

     // Next
     self.userOAuthKey    = oauthToken;
     self.userOAuthSecret = oauthTokenSecret;
     self.userId          = userId;
     block(nil);
   }
                failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOpen position:GreeBenchmarkPosition(@"oauthAccessTokenGetError")];
     block(MakeGreeError(operation, error));
   }
  ];
}

-(NSString*)parseResponseError:(NSError*)anError
{
  if ([anError.userInfo isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  NSDictionary* dict = anError.userInfo;
  GreeLog(@"error:%@", dict);
  return [NSString stringWithFormat:@"%@[%@]",
          [dict objectForKey:@"message"],
          [dict objectForKey:@"code"]];
}

#pragma mark URL schema handling

-(void)openURLAction:(NSURL*)url
{
  NSString* handledScheme = [url scheme];
  NSString* handledCommand = [url host];
  NSMutableDictionary* handledParams = [[url query] greeDictionaryFromQueryString];
  GreeLog(@"openURLAction handled scheme:%@ command:%@ params:%@", handledScheme, handledCommand, handledParams);
  // "confirm_dialog"
  if ([self handleConfirmDialogWithCommand:handledCommand params:handledParams]) {
    return;
  }

  // "api_sdk_enter"
  if ([self handleApiSdkEnterWithCommand:handledCommand params:handledParams]) {
    return;
  }


  //"reopen" from browser for sign up or upgrade
  if ([self handleReOpenWithCommand:handledCommand params:handledParams]) {
    return;
  }

  //"choose-account"
  if ([self handleChooseAccountWithCommand:handledCommand params:handledParams]) {
    return;
  }

  //"start-authorization" from NSURLRequest (redirect from api_sdk_enter)
  if ([self handleStartAuthorizationWithCommand:handledCommand params:handledParams]) {
    return;
  }

  //"get-accesstoken" From browser or SSO server app
  if ([handledCommand isEqualToString:kCommandGetAcccesstoken]) {
    if ([handledParams objectForKey:@"denied"]) {
      // not allowed SSO
      [self resetStatus];
      if (self.isNonInteractive) {
        [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeAuthorizationCancelledByUser]];
      } else {
        [self popupAuthorizeAction:nil];
      }
      [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkLogin position:GreeBenchmarkPosition(kGreeBenchmarkCancel)];
    } else {
      // allowed SSO
      [self addAuthVerifierToHttpClient:handledParams];
      self.authorizationStatus = AuthorizationStatusAuthorizationSuccess;
      self.userOAuthKey = [[[url query] greeDictionaryFromQueryString] objectForKey:kGreeAuthorizationOAuthTokenKey];
      NSMutableDictionary* requestTokenPairs = [(NSString*)[GreeKeyChain readWithKey:GreeKeyChainRequestTokenPairs] greeDictionaryFromQueryString];
      self.userOAuthSecret = [requestTokenPairs objectForKey:self.userOAuthKey];

      NSString* encodedGcid = [handledParams objectForKey:@"gcid"];
      NSString* gcid = [[[NSString alloc] initWithData:[encodedGcid greeBase64DecodedData] encoding:NSUTF8StringEncoding] autorelease];
      [NSHTTPCookieStorage greeSetCookie:gcid forName:@"gcid" domain:[[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain]];

      if (self.isNonInteractive) {
        [self nonInteractiveAuthorizeAction:handledParams];
      } else {
        [self popupAuthorizeAction:handledParams];
      }
    }
    return;
  }

  //boot as SSOServer
  if ([handledCommand isEqualToString:@"authorize"] && [[url path] isEqualToString:@"/request"]) {
    if (self.accessToken && self.accessTokenSecret) {
      NSString* requestTokenOfSSOClient = [handledParams objectForKey:@"oauth_token"];
      if (requestTokenOfSSOClient) {
        //SSO by oauth
        NSMutableDictionary* aParams = [NSMutableDictionary dictionaryWithDictionary:handledParams];
        [aParams setObject:kSelfId forKey:kParamAuthorizationTarget];
        dispatch_async(dispatch_get_main_queue(), ^{
                         self.authorizationType = AuthorizationTypeSSOServer;
                         self.authorizationStatus = AuthorizationStatusAccessTokenGot;
                         self.SSOClientApplicationId = [handledParams objectForKey:@"app_id"];
                         self.SSOClientContext = [handledParams objectForKey:@"context"];
                         self.SSOClientRequestToken = requestTokenOfSSOClient;
                         [self popupLaunch];
                         [self.popup closeButtonHidden:YES];
                         [self loadAuthorizePage:aParams];
                       });

        [aParams removeObjectForKey:@"context"];  // avoid multiple keys
      } else {
        //SSO by session
        self.greeSSOLegacy = [[[GreeSSO alloc]
                               initAsServerWithSeedKey:[handledParams objectForKey:@"key"]
                                   clientApplicationId:[handledParams objectForKey:@"app_id"]] autorelease];
        dispatch_async(dispatch_get_main_queue(), ^{
                         self.authorizationType = AuthorizationTypeSSOLegacyServer;
                         [self loadSSOAcceptPage];
                       });
      }
    } else {
      //This is the case which selected SSO server actually has not logged in yet.
      dispatch_async(dispatch_get_main_queue(), ^{
                       //1. let this SSO-server-app's user login. 2.after login, recall this method [(void)openURLAction:(NSURL*)url].
                       //save the SSO-client's request url to the following property.
                       //and use this property as the flag of recalling this openURLAction method in authorizeAction method.
                       self.SSOClientRequestUrl = url;
                       [self resetStatus];
                       [self resetAccessToken];
                       if ([GreePlatform sharedInstance].registrationFlow == GreePlatformRegistrationFlowLegacy) {
                         [self startGetRequestTokenPopupAuthorizeAction:[NSMutableDictionary dictionaryWithObject:kSelfId forKey:kParamAuthorizationTarget]];
                       } else {
                         [self directAuthorizeWithDesiredGrade:_nonInteractiveTargetGrade];
                       }
                     });
    }
    return;
  }

  //reboot as SSOClient
  if ([handledCommand isEqualToString:@"sso"]) {
    NSString* key = [handledParams objectForKey:@"key"];
    if ([key length]) {
      dispatch_async(dispatch_get_main_queue(), ^{
                       [self resetStatus];
                       [self resetAccessToken];
                       if (_popup == nil) {
                         [self popupAuthorizeAction:nil];
                       } else {
                         [self.greeSSOLegacy setDecryptGssIdWithEncryptedGssId:key];
                         [self handleStartAuthorizationWithCommand:kCommandStartAuthorization params:[NSMutableDictionary dictionaryWithObject:kSelfId forKey:kParamAuthorizationTarget]];
                       }
                     });
    }
    return;
  }
}

-(BOOL)handleConfirmDialogWithCommand:(NSString*)command params:(NSMutableDictionary*)params
{
  if (![command isEqualToString:kCommandConfirmDialog]) {
    return NO;
  }
  
  self.isNonInteractive = NO;
  [self popupLaunch];
  
  NSString* filePath    = [NSString greeCachePathForRelativePath:kGreeResourcesHtmlConfirmPath];
  NSString* requestPath = [NSString stringWithFormat:@"%@?%@",
                           [[NSURL fileURLWithPath:filePath] absoluteString],
                           [params greeBuildQueryString]];
  
  void (^loadFileBlock)(NSError*) = ^(NSError* error){
    if (!self.popup) {
      return;
    }
    if ([self handleResponseError:error showErrorDetail:NO]) {
      return;
    }
    
    [self.popup loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestPath]]];
  };
  
  NSError* error = nil;
  NSDictionary* fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
  
  if (error || [fileInfo[NSFileModificationDate] timeIntervalSinceNow] < -600) {
    [self downloadConfirmHtmlWithBlock:loadFileBlock];
  } else {
    loadFileBlock(nil);
  }
  
  return YES;
}

-(BOOL)handleApiSdkEnterWithCommand:(NSString*)command params:(NSMutableDictionary*)params
{
  if (![command isEqualToString:kCommandApiSdkEnter]) {
    return NO;
  }

  self.authorizationStatus = AuthorizationStatusEnter;
  [self nonInteractiveAuthorizeAction:params];

  return YES;
}

-(BOOL)handleReOpenWithCommand:(NSString*)command params:(NSMutableDictionary*)params
{
  if ([command isEqualToString:kCommandReOpen]) {
    if (!self.accessToken || !self.accessTokenSecret) {
      //finished sign up
      [self handleStartAuthorizationWithCommand:kCommandStartAuthorization params:params];
    } else {
      //finished upgrade
      if ([[params objectForKey:@"result"] isEqualToString:@"succeeded"]) {
        if (self.authorizationType == AuthorizationTypeUpgrade) {
          self.upgradeComplete = YES;
        }
      }
      [self popupDismiss];
    }
    return YES;
  }
  return NO;
}

-(BOOL)handleStartAuthorizationWithCommand:(NSString*)command params:(NSMutableDictionary*)params
{
  if (![command isEqualToString:kCommandStartAuthorization]) {
    return NO;
  }
  if (self.isNonInteractive) {
    self.authorizationStatus = AuthorizationStatusRequestTokenBeforeGot;
    [self nonInteractiveAuthorizeAction:params];
  } else {
    [self startGetRequestTokenPopupAuthorizeAction:params];
  }
  return YES;
}

-(BOOL)handleChooseAccountWithCommand:(NSString*)command params:(NSMutableDictionary*)params
{
  if (![command isEqualToString:kCommandChooseAccount]) {
    return NO;
  }

  // Launch Enter page
  params[kParamAuthorizationTarget] = kSelfId;
  self.authorizationStatus = AuthorizationStatusEnter;
  [self popupAuthorizeAction:params];

  return YES;
}

#pragma mark web session

-(void)getGssidWithCompletionBlock:(void (^)(void))completion
{
  [self getGssidWithCompletionBlock:completion forceUpdate:NO];
}

-(void)getGssidWithCompletionBlock:(void (^)(void))completion forceUpdate:(BOOL)forceUpdate
{
  if (forceUpdate || ![GreeWebSession hasWebSession]) {
    [GreeWebSession regenerateWebSessionWithBlock:^(NSError* error) {
       if (completion)
         completion();
     }];
  } else {
    if (completion)
      completion();
  }
}

#pragma mark reset

-(void)resetStatus
{
  self.authorizationStatus = AuthorizationStatusInit;
  self.authorizationType = AuthorizationTypeDefault;
  self.upgradeComplete = NO;
  self.SSOClientApplicationId = nil;
  self.SSOClientRequestToken = nil;
  self.SSOClientContext = nil;
}

-(void)resetAccessToken
{
  self.userOAuthKey = nil;
  self.userOAuthSecret = nil;
  self.userId = nil;
  [self.httpClient setUserToken:nil secret:nil];
  [self.httpClient setOAuthVerifier:nil];
  [self.httpIdClient setUserToken:nil secret:nil];
  [NSHTTPCookieStorage greeDeleteCookieWithName:@"gssid" domain:self.configGreeDomain];
  [NSHTTPCookieStorage greeDeleteCookieWithName:@"gssid_smsandbox" domain:self.configGreeDomain];
  // Do not delete GreeKeyChainUserIdIdentifier (it would break reAuthorize)
  [GreeKeyChain removeWithKey:GreeKeyChainAccessTokenIdentifier];
  [GreeKeyChain removeWithKey:GreeKeyChainAccessTokenSecretIdentifier];
}

-(void)resetCookies
{
  NSHTTPCookieStorage* storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  for (NSHTTPCookie* cookie in storage.cookies) {
    [storage deleteCookie:cookie];
  }
  [[GreePlatform sharedInstance] performSelector:@selector(setDefaultCookies)];
}

#pragma mark etc

-(void)addAuthVerifierToHttpClient:(NSMutableDictionary*)params
{
  NSString* verifier = [params objectForKey:@"oauth_verifier"];
  if (verifier) {
    [self.httpClient setOAuthVerifier:verifier];
  }
}

-(void)removeOfAuthorizationData
{
  [GreeDeviceIdentifier removeOfAccessToken];
  [GreeDeviceIdentifier removeOfApplicationId];
  [GreeDeviceIdentifier removeOfUserId];
}

-(void)getSSOAppIdWithBlock:(void (^)(NSError*))block
{
  if (!self.deviceContext) {
    [self getUUIDWithBlock:^(NSError* error) {
       if (error) {
         if (block) {
           block(error);
         }
       } else {
         // Call back this method now we have a UUID and a context
         [self getSSOAppIdWithBlock:block];
       }
     }];
    return;
  }

  if (self.SSOServerApplicationId
    && [self.greeSSOLegacy openAvailableApplicationWithApps:@[self.SSOServerApplicationId]]) {
    if (block) {
      block(nil);
    }
    return;
  }

  // Sandbox
  if ([GreePlatform sharedInstance].settings.usesSandbox) {
    self.SSOServerApplicationId = kBrowserId;
    if (block) {
      block(nil);
    }
    return;
  }

  self.greeSSOLegacy = [[[GreeSSO alloc] initAsClient] autorelease];

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"getSSOAppIdStart")
         pointRole:GreeBenchmarkPointRoleStart];

  NSDictionary* params = @{
    @"action" :  @"sso_app_candidate",
    @"app_id" :  self.configSelfApplicationId,
    @"context" : self.deviceContext ? self.deviceContext : @""
  };

  [self.httpClient
      getPath:@"/"
   parameters:params
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     id entry = [responseObject objectForKey:@"entry"];
     NSMutableArray* appList = [NSMutableArray array];
     if ([entry isKindOfClass:[NSArray class]]) {
       for (NSDictionary* appinfo in entry) {
         [appList addObject:[appinfo objectForKey:@"i"]];
       }
     }

     if (![appList count]) {
       self.SSOServerApplicationId = nil;

       [[GreePlatform sharedInstance].benchmark
        registerWithKey:kGreeBenchmarkAuthorization
               position:GreeBenchmarkPosition(@"getSSOAppIdError")
              pointRole:GreeBenchmarkPointRoleEnd];

       if (block) {
         block([GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError]);
       }
       return;
     }

     self.SSOServerApplicationId = [self.greeSSOLegacy openAvailableApplicationWithApps:appList];

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"getSSOAppIdEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(nil);
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     
     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"getSSOAppIdError")
            pointRole:GreeBenchmarkPointRoleEnd];

     self.SSOServerApplicationId = nil;
     if (block) {
       block(MakeGreeError(operation, error));
     }
   }
  ];
}

-(void)getUUIDWithBlock:(void (^)(NSError*))block
{
  if (self.greeUUID) {
    if (block) {
      block(nil);
    }
    return;
  }

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"getUUIDStart")         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpConsumerClient
      getPath:@"/api/rest/generateuuid"
   parameters:nil
      success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"getUUIDEnd")            pointRole:GreeBenchmarkPointRoleEnd];

     NSString* uuid = [responseObject objectForKey:@"entry"];
     if (![uuid isKindOfClass:[NSString class]]) {
       block([GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer userInfo:responseObject]);
       return;
     }

     [GreeKeyChain saveWithKey:GreeKeyChainUUIDIdentifier value:uuid];
     self.greeUUID = uuid;
     if (block) {
       block(nil);
     }
   }
      failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"getUUIDError")            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }
  ];
}

-(void)attemptInstantPlayWithBlock:(void (^)(NSError*))block
{
  NSDictionary* params = @{
    @"target" : @"browser",
    @"context" : self.deviceContext ? self.deviceContext : @"",
    @"app_id": self.configSelfApplicationId
  };
  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_enter" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     block(nil);
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     block(MakeGreeError(operation, error));
   }];
}

#pragma mark phoneNumberBased

-(void)registerBySMSWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", nil],
    phoneNumber, countryCode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = @{
    @"country" : countryCode,
    @"telno" :   phoneNumber,
    @"context" : self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"registerBySNSwithPhoneNumberStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_register_by_sms_pin" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"registerBySNSwithPhoneNumberEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"registerBySNSwithPhoneNumberError")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)registerByIVRWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", nil],
    phoneNumber, countryCode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = @{
    @"is_ivr" :  @1,
    @"country" : countryCode,
    @"telno" :   phoneNumber,
    @"context" : self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"registerByIVRwithPhoneNumberStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_register_by_sms_pin"  parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"registerByIVRwithPhoneNumberEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"registerByIVRwithPhoneNumberError")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)upgradeBySMSWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", nil],
    phoneNumber, countryCode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = @{
    @"country" : countryCode,
    @"telno":   phoneNumber,
    @"context": self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"upgradeBySMSwithPhoneNumberStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_upgrade_by_sms_pin" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"upgradeBySMSwithPhoneNumberEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"upgradeBySMSwithPhoneNumberError")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)upgradeByIVRWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", nil],
    phoneNumber, countryCode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = @{
    @"is_ivr":  @1,
    @"country": countryCode,
    @"telno":   phoneNumber,
    @"context": self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"upgradeByIVRwithPhoneNumberStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_upgrade_by_sms_pin" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"upgradeByIVRwithPhoneNumberEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"upgradeByIVRwithPhoneNumberError")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)confirmRegisterWithPincode:(NSString*)pincode phoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  if (!self.deviceContext) {
    [self getUUIDWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         // Call back this method now we have a UUID and a context
         [self confirmRegisterWithPincode:pincode phoneNumber:phoneNumber countryCode:countryCode block:block];
       }
     }];
    return;
  }

  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", @"pincode", nil],
    phoneNumber, countryCode, pincode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"confirmRegisterWithPincodeStart")
         pointRole:GreeBenchmarkPointRoleStart];

  NSDictionary* params = @{
    @"country" : countryCode,
    @"telno" :   phoneNumber,
    @"pincode" : pincode,
    @"context" : self.deviceContext ? self.deviceContext : @""
  };

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_register_by_sms_commit" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSString* oauthToken       = [responseObject objectForKey:@"oauth_token"];
     NSString* oauthTokenSecret = [responseObject objectForKey:@"oauth_token_secret"];
     NSString* userId           = [responseObject objectForKey:@"user_id"];

     if (![oauthToken isKindOfClass:[NSString class]] ||
         ![oauthTokenSecret isKindOfClass:[NSString class]] ||
         ![userId isKindOfClass:[NSString class]]) {

       [[GreePlatform sharedInstance].benchmark
        registerWithKey:kGreeBenchmarkAuthorization
               position:GreeBenchmarkPosition(@"confirmRegisterWithPincodeError")
              pointRole:GreeBenchmarkPointRoleEnd];

       [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError]];
       return;
     }

     [GreeKeyChain saveWithKey:[NSString stringWithFormat:kGreeCountryCodeForUserFormat, userId] value:countryCode];
     [GreeKeyChain saveWithKey:[NSString stringWithFormat:kGreePhoneNumberForUserFormat, userId] value:phoneNumber];

     [GreeKeyChain saveWithKey:GreeKeyChainUserIdIdentifier value:userId];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenIdentifier value:oauthToken];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenSecretIdentifier value:oauthTokenSecret];
     [GreeKeyChain removeWithKey:GreeKeyChainRequestTokenPairs];

     // notify we got an access token
     self.userOAuthKey = oauthToken;
     self.userOAuthSecret = oauthTokenSecret;
     [self.httpIdClient setUserToken:oauthToken secret:oauthTokenSecret];
     self.userId = userId;
     self.authorizationStatus = AuthorizationStatusAccessTokenGot;
     if ([self.delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
       [self.delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
     }

     // notify we got a gssid
     [NSHTTPCookieStorage greeDuplicateCookiesForAdditionalDomains];
     [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeWebSessionDidUpdateNotification" object:nil];

     // notify we got a login!
     [self dismiss3rdPartyWelcomeViewController];

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"confirmRegisterWithPincodeEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
       [self.delegate authorizeDidFinishWithLogin:YES];
     }
     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     // Do not call [self dismiss3rdPartyWelcomeViewController], and
     // let the block handle the error
     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"confirmRegisterWithPincodeError")
            pointRole:GreeBenchmarkPointRoleEnd];
     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)confirmUpgradeWithPincode:(NSString*)pincode phoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block
{
  if (!self.deviceContext) {
    [self getUUIDWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         // Call back this method now we have a UUID and a context
         [self confirmUpgradeWithPincode:pincode phoneNumber:phoneNumber countryCode:countryCode block:block];
       }
     }];
    return;
  }

  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", @"pincode", nil],
    phoneNumber, countryCode, pincode
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"confirmUpgradeWithPincodeStart")
         pointRole:GreeBenchmarkPointRoleStart];

  NSDictionary* params = @{
    @"country" : countryCode,
    @"telno" :   phoneNumber,
    @"pincode" : pincode,
    @"context" : self.deviceContext ? self.deviceContext : @""
  };

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_upgrade_by_sms_commit" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     [GreeUser upgradeLocalUser:GreeUserGradeStandard];
     self.upgradeComplete = YES;
     [self dismiss3rdPartyWelcomeViewController];
     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"confirmUpgradeWithPincodeEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     [GreeKeyChain saveWithKey:[NSString stringWithFormat:kGreeCountryCodeForUserFormat, self.userId] value:countryCode];
     [GreeKeyChain saveWithKey:[NSString stringWithFormat:kGreePhoneNumberForUserFormat, self.userId] value:phoneNumber];
     if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
       [self.delegate authorizeDidFinishWithLogin:NO];
     }
     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"confirmUpgradeWithPincodeError")
            pointRole:GreeBenchmarkPointRoleEnd];
     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)phoneNumberBasedReAuthorize
{
  if (!self.deviceContext) {
    [self getUUIDWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         // Call back this method now we have a UUID and a context
         [self phoneNumberBasedReAuthorize];
       }
     }];
    return;
  }

  // Prepare parameters for RPC
  NSString* countryCode = [GreeKeyChain readWithKey:[NSString stringWithFormat:kGreeCountryCodeForUserFormat, self.lastLoggedUserId]];
  NSString* phoneNumber = [GreeKeyChain readWithKey:[NSString stringWithFormat:kGreePhoneNumberForUserFormat, self.lastLoggedUserId]];
  NSString* context     = self.deviceContext;
  NSString* user_id     = self.lastLoggedUserId;

  __block void (^onError)(NSError*) =^(NSError* error) {
    GreeLog(@"Automatic reauthorizing failed with error: %@\n\t(will try the full authorization flow now...)", error);
    // Can't reauthorize, so just authorize again
    NSString* message = GreePlatformStringWithKey(@"phoneNumberBaseRegistration.reauthorize.sessionExpiredPleaseSignIn.message");
    NSString* button  = GreePlatformStringWithKey(@"phoneNumberBaseRegistration.reauthorize.sessionExpiredPleaseSignIn.closeButton");
    [[[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:button otherButtonTitles:nil] autorelease] show];
    [self directAuthorizeWithDesiredGrade:GreeUserGradeStandard];
  };

  // RPC parameters validation
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"phoneNumber", @"countryCode", @"context", @"user_id", nil],
    phoneNumber, countryCode, context, user_id
    );

  if (error) {
    onError(error);
    return;
  }

  NSDictionary* params = @{
    @"user_id" : user_id,
    @"country" : countryCode,
    @"telno" :   phoneNumber,
    @"format" :  @"json",
    @"context" : context
  };

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_reauthorize" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     // Validate response
     NSString* oauthToken       = [responseObject objectForKey:@"oauth_token"];
     NSString* oauthTokenSecret = [responseObject objectForKey:@"oauth_token_secret"];
     NSString* userId           = [responseObject objectForKey:@"user_id"];

     if (![oauthToken isKindOfClass:[NSString class]] ||
         ![oauthTokenSecret isKindOfClass:[NSString class]] ||
         ![userId isKindOfClass:[NSString class]]) {
       onError([GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer userInfo:responseObject]);
       return;
     }

     // Save token to keychain
     [GreeKeyChain saveWithKey:GreeKeyChainUserIdIdentifier value:userId];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenIdentifier value:oauthToken];
     [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenSecretIdentifier value:oauthTokenSecret];
     [GreeKeyChain removeWithKey:GreeKeyChainRequestTokenPairs];

     // notify we got an access token
     self.userOAuthKey    = oauthToken;
     self.userOAuthSecret = oauthTokenSecret;
     [self.httpIdClient setUserToken:oauthToken secret:oauthTokenSecret];
     self.userId          = userId;
     self.authorizationStatus = AuthorizationStatusAccessTokenGot;
     if ([self.delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
       [self.delegate authorizeDidUpdateUserId:userId withToken:oauthToken withSecret:oauthTokenSecret];
     }

     // notify we got a gssid
     [NSHTTPCookieStorage greeDuplicateCookiesForAdditionalDomains];
     [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeWebSessionDidUpdateNotification" object:nil];

     // notify we got a login!
     if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
       [self.delegate authorizeDidFinishWithLogin:YES];
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     
     onError(MakeGreeError(operation, error));
   }];
}

-(void)updateUserProfileWithNickname:(NSString*)nickname birthday:(NSDate*)birthday block:(void (^)(NSError* error))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"nickname", @"birthday", nil],
    nickname, birthday
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSMutableDictionary* birth = [NSMutableDictionary dictionaryWithCapacity:3];
  [birth setObject:[[NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy"] stringFromDate:birthday] forKey:@"year"];
  [birth setObject:[[NSDateFormatter greeUTCDateFormatterWithFormat:@"MM"] stringFromDate:birthday] forKey:@"month"];
  [birth setObject:[[NSDateFormatter greeUTCDateFormatterWithFormat:@"dd"] stringFromDate:birthday] forKey:@"day"];

  NSDictionary* params = @{
    @"app_id":    self.configSelfApplicationId,
    @"nick_name": nickname,
    @"birth":     birth,
    @"context": self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"updateUserProfileWithNicknameStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_update_profile" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"updateUserProfileWithNicknameEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     // Update local user with new nickname and/or birthday
     [GreeUser setLocalUserNickname:nickname];
     [GreeUser setLocalUserBirthday:birthday];
     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"updateUserProfileWithNicknameError")
            pointRole:GreeBenchmarkPointRoleEnd];

     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(void)getUserAuthBitsWithBlock:(void (^)(NSNumber* authBits, NSError* error))block
{
  if (!block) {
    return;
  }

  NSError* error = MakeGreeErrorIfParametersMissing(@[@"userId", @"context"], self.userId, self.deviceContext);
  if (error) {
    block(nil, error);
    return;
  }

  NSDictionary* params = @{
    @"app_id":  self.configSelfApplicationId,
    @"user_id": self.userId,
    @"context": self.deviceContext
  };

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_get_authbit" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSString* userId   = [responseObject objectForKey:@"user_id"];
     NSNumber* authBits = [responseObject objectForKey:@"auth_bit"];

     if (![authBits isKindOfClass:[NSNumber class]] ||
         ![userId isKindOfClass:[NSString class]]) {
       block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer userInfo:responseObject]);
       return;
     }

     block(authBits, nil);
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     block(nil, MakeGreeError(operation, error));
   }];
}

-(void)logPageName:(NSString*)pageName block:(void (^)(NSError*))block
{
  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"pageName", nil],
    pageName
    );

  if (error) {
    if (block) {
      block(error);
    }
    return;
  }

  NSDictionary* params = @{
    @"action_name":  pageName,
    @"context": self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"logPageNameStart") pointRole:GreeBenchmarkPointRoleStart];
  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_log_registtrack" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"logPageNameEnd") pointRole:GreeBenchmarkPointRoleEnd];
     if (block) {
       block(nil);
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkAuthorization position:GreeBenchmarkPosition(@"logPageNameStartError") pointRole:GreeBenchmarkPointRoleEnd];
     if (block) {
       block(MakeGreeError(operation, error));
     }
   }];
}

-(int)timezoneOffsetMinutes
{
  return [[NSTimeZone localTimeZone] secondsFromGMT] / 60; // convert sec to min
}

-(void)getCampaignCodeWithServiceType:(NSString*)serviceType block:(void (^)(NSDictionary*, NSError*))block
{
  // This function has no side effect beside calling the block,
  // so we can skip everything if no block is provided.
  if (!block) {
    return;
  }

  NSError* error = MakeGreeErrorIfParametersMissing(
    [NSArray arrayWithObjects:@"serviceType", nil],
    serviceType
    );

  if (error) {
    block(nil, error);
    return;
  }

  NSDictionary* params = @{
    @"service_type": serviceType,
    @"app_id":       self.configSelfApplicationId,
    @"context":      self.deviceContext ? self.deviceContext : @""
  };

  [[GreePlatform sharedInstance].benchmark
   registerWithKey:kGreeBenchmarkAuthorization
          position:GreeBenchmarkPosition(@"getCampaignCodeWithServiceTypeStart")
         pointRole:GreeBenchmarkPointRoleStart];

  [self.httpIdClient performTwoLeggedRequestWithMethod:@"POST" path:@"/?action=api_sdk_get_regcode" parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSDictionary* response = [[operation responseString] greeObjectFromJSONString];

     NSString* registrationCode = [response objectForKey:@"reg_code"];
     NSString* entryCode        = [response objectForKey:@"ent_code"];

     if (![registrationCode isKindOfClass:[NSString class]] || ![entryCode isKindOfClass:[NSString class]]) {
       [[GreePlatform sharedInstance].benchmark
        registerWithKey:kGreeBenchmarkAuthorization
               position:GreeBenchmarkPosition(@"getCampaignCodeWithServiceTypeError")
              pointRole:GreeBenchmarkPointRoleEnd];
       block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer userInfo:response]);
       return;
     }

     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"getCampaignCodeWithServiceTypeEnd")
            pointRole:GreeBenchmarkPointRoleEnd];

     block(response, nil);
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     [[GreePlatform sharedInstance].benchmark
      registerWithKey:kGreeBenchmarkAuthorization
             position:GreeBenchmarkPosition(@"getCampaignCodeWithServiceTypeError")
            pointRole:GreeBenchmarkPointRoleEnd];
     block(nil, MakeGreeError(operation, error));
   }];
}

-(void)presentWelcomeViewController
{
  if (!self.welcomeViewController) {
    GreeSettings* settings = [GreePlatform sharedInstance].settings;
    Class welcomeViewControllerClass      = [settings objectValueForSetting:GreeSettingWelcomeViewControllerClass];
    NSString* welcomeViewControllerNib    = [settings objectValueForSetting:GreeSettingWelcomeViewControllerNib];
    NSBundle* welcomeViewControllerBundle = [settings objectValueForSetting:GreeSettingWelcomeViewControllerBundle];
    BOOL animateWelcomeViewController     = [settings boolValueForSetting:GreeSettingAnimateWelcomeViewController];

    if (welcomeViewControllerClass) {
      self.welcomeViewController = [[[welcomeViewControllerClass alloc]
                                     initWithNibName:welcomeViewControllerNib
                                              bundle:welcomeViewControllerBundle]
                                    autorelease];

      [[UIViewController greeLastPresentedViewController]
       greePresentViewController:self.welcomeViewController
                        animated:animateWelcomeViewController
                      completion:nil];
    }
  }
}

-(void)setUserId:(NSString*)userId
{
  if (userId) {
    // Update lastLoggedUserId whenever we get a non-nil userId,
    // so we can reauthorize the previous user with its phone
    // number
    self.lastLoggedUserId = userId;
  }
  if (_userId != userId) {
    [_userId release];
    _userId = [userId retain];
  }
}

#pragma mark nonInteractive

-(void)dismiss3rdPartyWelcomeViewController
{
  if (self.welcomeViewController) {
    BOOL animateWelcomeViewController = [[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingAnimateWelcomeViewController];
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:animateWelcomeViewController completion:nil];
    self.welcomeViewController = nil;
  }
}

-(void)applicationDidBecomeActive:(NSNotification*)note
{
  [self syncIdentifiers];

  if (self.nonInteractiveWaitingForBrowserReturn) {
    self.nonInteractiveWaitingForBrowserReturn = NO;

    // Reopened the application before getting called from the browser.
    // If we have a welcome screen, we can start the authorization process
    // again. Otherwise we can only return an error.
    if (self.welcomeViewController) {
      self.authorizationStatus = AuthorizationStatusInit;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeAuthorizationAbortedByUser" object:self];
    } else {
      [self authorizationFailedWithError:[GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError]];
    }
  }
};

-(void)nonInteractiveAuthorizeAction:(NSMutableDictionary*)params
{
  self.isNonInteractive = YES;
  if (!self.greeUUID) {
    [self getUUIDWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         [self nonInteractiveAuthorizeAction:params];
       }
     }];
    return;
  }
  
  switch (self.authorizationStatus) {
  case AuthorizationStatusInit: {
    [self resetAccessToken];

    // Query the list of applicable SSO apps
    [self getSSOAppIdWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
         return;
       }

       // Next
      self.authorizationStatus =
        (self.nonInteractiveTargetGrade == GreeUserGradeLite && ![GreePlatform sharedInstance].settings.usesSandbox)
          ? AuthorizationStatusEnterConfirm : AuthorizationStatusEnter;

      [self nonInteractiveAuthorizeAction:params];
     }];
    break;
  }

  case AuthorizationStatusInitLoginPage: {
      break;//nothing to do
  }
    case AuthorizationStatusEnterConfirm: {

      BOOL useSSO = self.SSOServerApplicationId
        && ![self.SSOServerApplicationId isEqualToString:kSelfId]
        && ![self.SSOServerApplicationId isEqualToString:kBrowserId];

      if (useSSO) {
        self.authorizationStatus = AuthorizationStatusRequestTokenBeforeGot;
        [self nonInteractiveAuthorizeAction:params];
        break;
      }

      NSDictionary* params = @{
        @"context" : self.deviceContext ? self.deviceContext : @"",
        @"app_id"  : self.configSelfApplicationId ? self.configSelfApplicationId : @""
      };

      void (^failure)(GreeAFHTTPRequestOperation*, NSError*) = ^(GreeAFHTTPRequestOperation* operation, NSError* error) {
        [self authorizationFailedWithError:MakeGreeError(operation, error)];
      };

      //Server returns the url scheme(confirm_dialog or api_sdk_enter).
      [self.httpIdClient
        performTwoLeggedRequestWithMethod:@"POST"
                                     path:@"/?action=api_sdk_enter_confirm"
                               parameters:params
                                  success:nil
                                  failure:failure];

      break;
    }

    case AuthorizationStatusEnter: {
    // If:
    // - There is no SSO application (beside the browser or the app itself),
    // - The desired grade is Grade 1,
    // - useInstantPlay is set,
    // …then we try to login the user without opening any page except maybe
    // an account selector if multiple accounts are bound to the device.
    BOOL dontUseSSO = [self.SSOServerApplicationId isEqualToString:kSelfId] ||
                      [self.SSOServerApplicationId isEqualToString:kBrowserId] ||
                      !self.SSOServerApplicationId;

    if (dontUseSSO &&
        self.nonInteractiveTargetGrade == GreeUserGradeLite &&
        self.useInstantPlay) {

      [self attemptInstantPlayWithBlock:^(NSError* error) {
         if (error) {
           [self authorizationFailedWithError:error];
           return;
         }

         // Server sets gcid and gssid cookies then redirect to greeapp://
         [NSHTTPCookieStorage greeDuplicateCookiesForAdditionalDomains];
       }];
    } else {
      // Just skip this step and proceed with normal authorization
      // (will open SSO app or browser)
      self.authorizationStatus = AuthorizationStatusRequestTokenBeforeGot;
      [self nonInteractiveAuthorizeAction:params];
    }
    break;
  }

  case AuthorizationStatusRequestTokenBeforeGot: {
    if (self.popup) {//the popup of terms confirmation
      [self.popup dismiss];
    }

    [self getRequestTokenWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         self.authorizationStatus = AuthorizationStatusRequestTokenGot;
         [self nonInteractiveAuthorizeAction:params];
       }
     }];
    break;
  }

  case AuthorizationStatusRequestTokenGot: {
    NSString* target = self.SSOServerApplicationId ? self.SSOServerApplicationId : kBrowserId;

    [params setObject:target forKey:kParamAuthorizationTarget];
    if (self.nonInteractiveTargetGrade == GreeUserGradeLite) {
      [params setObject:@"login_lite" forKey:@"forward_type"];
    } else {
      [params setObject:@"login" forKey:@"forward_type"];
    }

    NSURL* targetURL;
    if ([target isEqualToString:kBrowserId]) {
      NSString* path = @"/oauth/authorize";
      params[@"oauth_token"] = self.userOAuthKey  ? self.userOAuthKey  : @"";
      params[@"context"]     = self.deviceContext ? self.deviceContext : @"";
      params[@"tz_offset"]   = @([self timezoneOffsetMinutes]);

      // For grade 1, we use a special API that do not perform start app
      if (self.nonInteractiveTargetGrade == GreeUserGradeLite) {
        path = @"/";
        params[@"mode"] = @"oauth";
        params[@"act"]  = @"authorize_min";

        // For instant play, we also authorize in the background
        if (self.useInstantPlay) {
          [self.httpClient getPath:path parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
             // We don't do anything on success, as we're being called through
             // greeappXXXX://get-accesstoken?...
           } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
             [self authorizationFailedWithError:MakeGreeError(operation, error)];
           }];
          break;
        }
      }

      NSString* urlString = [NSString stringWithFormat:@"%@%@?%@", self.configServerUrlOpen, path, [params greeBuildQueryString]];
      targetURL = [NSURL URLWithString:urlString];
    } else {
      targetURL = [self.greeSSOLegacy
                   ssoRequireUrlWithServerApplicationId:target
                                           requestToken:self.userOAuthKey
                                                context:self.deviceContext
                                             parameters:params];
    }

    [[UIApplication sharedApplication] openURL:targetURL];
    self.nonInteractiveWaitingForBrowserReturn = YES;
    break;
  }

  case AuthorizationStatusAuthorizationSuccess: {
    self.nonInteractiveWaitingForBrowserReturn = NO;
    [self getAccessTokenWithBlock:^(NSError* error) {
       if (error) {
         [self authorizationFailedWithError:error];
       } else {
         self.authorizationStatus = AuthorizationStatusAccessTokenGot;
         [self nonInteractiveAuthorizeAction:params];
       }
     }];
    break;
  }

  case AuthorizationStatusAccessTokenGot: {
    [self.httpIdClient setUserToken:self.accessToken secret:self.accessTokenSecret];

    if ([self.delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
      [self.delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
    }

    [self getGssidWithCompletionBlock:^{
       [self dismiss3rdPartyWelcomeViewController];

       if (self.SSOClientRequestUrl) {
         [self openURLAction:self.SSOClientRequestUrl];
       }

       if ([self.delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
         [self.delegate authorizeDidFinishWithLogin:YES];
       }
     } forceUpdate:YES];
    break;
  }
  }
}

@end
