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

#import <UIKit/UIApplication.h>

#import "GreePlatform.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "GreeSettings.h"
#import "GreeHTTPClient.h"
#import "GreeNetworkReachability.h"
#import "GreeAnalyticsEvent.h"
#import "GreeAnalyticsQueue.h"
#import "GreeNotificationQueue.h"
#import "GreeNotificationLoader.h"
#import "NSString+GreeAdditions.h"
#import "GreeWriteCache.h"
#import "GreeUser+Internal.h"
#import "GreeLogger.h"
#import <GameKit/GameKit.h>
#import "GreeNSNotification.h"
#import "GreeNSNotification+Internal.h"
#import "GreeDeviceIdentifier.h"
#import "NSData+GreeAdditions.h"
#import "GreeUtility.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeLocalNotification+Internal.h"
#import "NSURL+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeConsumerProtect.h"
#import "JSONKit.h"
#import "GreeAuthorization.h"
#import "GreeAuthorization+Internal.h"
#import "GreeAuthorizationPopup.h"
#import "GreePhoneNumberBasedController.h"

#import "GreeJSCommandFactory.h"
#import "GreeJSShowDashboardCommand.h"
#import "GreeRotator.h"
#import "GreeModelessAlertView.h"
#import "GreeBenchmark.h"
#import "SDURLCache.h"
#import "AFNetworking.h"

#define kNotificationQueueClassString @"GreeNotificationQueue"
#define kModerationListClassString @"GreeModerationList"

#define kDefaultCookieKeyURLScheme      @"URLScheme"
#define kDefaultCookieKeyUAType @"uatype"
#define kDefaultCookieKeyAppVersion     @"appVersion"
#define kDefaultCookieKeyBundleVersion  @"bundleVersion"
#define kDefaultCookieKeyiOSSDKVersion  @"iosSDKVersion"
#define kDefaultCookieKeyiOSSDKBuild    @"iosSDKBuild"

NSString* const GreeCookieKeyMiddlewareName = @"mdName";
NSString* const GreeCookieKeyMiddlewareVersion = @"mdVersion";

NSString* const GreeHTTPResponseMessageKey = @"GreeHTTPResponseMessageKey";

static GreePlatform* sSharedSDKInstance = nil;
static NSString* consumerScramble = nil;
static NSMutableArray* registeredComponentClassNames;
static const int kGreePlatformRemoteNotificationTypeSNS = 1;

typedef void (^GreePlatformAuthorizationBlock)(GreeUser* localUser, NSError* error);
typedef void (^GreePlatformRevokeBlock)(NSError* error);
typedef void (^GreePlatformPostDeviceTokenCallbackBlock)(NSError* error);

@interface GreePlatform (Components)
-(void)applyToComponentsUserLoggedIn:(GreeUser*)user;
-(void)applyToComponentsUserLoggedOut:(GreeUser*)user;
-(void)applyToComponentsRemoteNotification:(NSDictionary*)notificationDictionary;
/**
 * This method initializes all components registered with registerComponent.
 * Each component is expected to add itself through +addComponent: and these are called from +addComponenentToPlatform:
 */
-(void)initializeComponents;

/**
 * This method tears down all components registered with registerComponent.
 * This is accomplished by iterating over the registered components with calls to -removeComponentFromPlatform.
 */
-(void)removeComponents;

@end

@interface GreePlatform ()<GreeAuthorizationDelegate>
@property (nonatomic, retain) GreeLogger* logger;
@property (nonatomic, retain) GreeSettings* settings;
@property (nonatomic, retain) GreeWriteCache* writeCache;
@property (nonatomic, retain) GreeNetworkReachability* reachability;
@property (nonatomic, assign, readwrite) id reachabilityObserver;
@property (nonatomic, retain) NSMutableDictionary* components;
@property (nonatomic, retain) GreeAnalyticsQueue* analyticsQueue;
@property (nonatomic, retain, readonly) id rawNotificationQueue;
@property (nonatomic, retain) GreeLocalNotification* localNotification;
@property (nonatomic, assign) id<GreePlatformDelegate> delegate;
@property (nonatomic, retain) GreeHTTPClient* httpClient;
@property (nonatomic, retain) GreeHTTPClient* httpsClient;
@property (nonatomic, retain) GreeHTTPClient* httpClientForApi;
@property (nonatomic, retain) GreeHTTPClient* httpsClientForApi;
@property (nonatomic, retain) GreeUser* localUser;
@property (nonatomic, copy) NSString* localUserId;
@property (nonatomic, copy) NSData* deviceToken;
@property (nonatomic, retain, readonly) id moderationList;
@property (nonatomic, retain) GreeAuthorization* authorization;
@property (nonatomic, retain) NSMutableArray* authorizationBlocks;
@property (nonatomic, retain) NSMutableArray* revokeBlocks;
@property (nonatomic, copy) GreePlatformPostDeviceTokenCallbackBlock postDeviceTokenCallbackBlock;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, retain) GreeBadgeValues* badgeValues;
@property (nonatomic, assign) BOOL didGameCenterInitialization;
@property (nonatomic, assign) UIWindow* previousWindow;
@property (nonatomic, assign) UIViewController* previousRootController;
@property (nonatomic, assign) UIInterfaceOrientation previousOrientation;
@property (nonatomic, retain) NSMutableArray* deviceNotificationCountArray;
@property (nonatomic, retain) GreeRotator* rotator;
@property (nonatomic, assign) BOOL finished;  //tells performSelector targets they are finished
@property (nonatomic, assign) BOOL manuallyRotate;
@property (nonatomic, retain) NSDictionary* defaultCookieParameters;
@property (nonatomic, retain) GreeModelessAlertView* modelessAlertView;
@property (nonatomic, retain) GreeBenchmark* benchmark;
@property (nonatomic, assign) GreePlatformRegistrationFlow registrationFlow;
@property (nonatomic, retain) GreePhoneNumberBasedController* phoneNumberBasedController;
@property (nonatomic, assign) BOOL needPostAppStart; //grade1 & directAuthorize -> authorize_min flag
@property (assign, readwrite) int retryTimes;
@property (nonatomic, retain) GreeDashboardViewController* dashboardViewController;

-(id)initWithApplicationId:(NSString*)applicationId
               consumerKey:(NSString*)consumerKey
            consumerSecret:(NSString*)consumerSecret
                  settings:(NSDictionary*)settings
                  delegate:(id<GreePlatformDelegate>)delegate;
-(void)authorizeWithBlock:(void (^)(GreeUser* localUser, NSError* error))block;
-(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade block:(void (^)(GreeUser* localUser, NSError* error))block;
-(void)directRevokeAuthorizationWithBlock:(void (^)(NSError* error))block;
-(void)revokeAuthorizationWithBlock:(void (^)(NSError* error))block;
-(void)setupHttpClients;
-(void)setDefaultCookies;
-(void)updateLocalUser:(GreeUser*)newUser;
-(void)updateLocalUser:(GreeUser*)newUser withNotification:(BOOL)notification;
-(void)retryToUpdateLocalUser;
+(void)showConnectionServer;
-(NSDictionary*)bootstrapSettingsDictionary;
-(void)writeBootstrapSettingsDictionary:(NSDictionary*)bootstrapSettings;
-(void)updateBootstrapSettingsWithAttemptNumber:(NSInteger)attemptNumber statusBlock:(BOOL (^)(BOOL didSucceed))statusBlock;
//this handles telling the various protocol, notification and blocks the end result
-(void)broadcastLocalUserWithError:(NSError*)error;
-(void)setURLCache;
-(void)startAsyncInitialization;
-(void)startPostLoginFlow;
@end

@implementation GreePlatform

#pragma mark - Object Lifecycle

// Designated initializer
-(id)initWithApplicationId:(NSString*)applicationId
               consumerKey:(NSString*)consumerKey
            consumerSecret:(NSString*)consumerSecret
                  settings:(NSDictionary*)settings
                  delegate:(id<GreePlatformDelegate>)delegate
{
  if (consumerScramble) {
    consumerKey = [GreeConsumerProtect decryptedHexString:consumerKey keyString:consumerScramble];
    consumerSecret = [GreeConsumerProtect decryptedHexString:consumerSecret keyString:consumerScramble];
  }
  NSAssert(applicationId != nil && consumerKey != nil && consumerSecret != nil, @"Missing required parameters!");
  self = [super init];
  if (self !=  nil) {
    self.settings = [[[GreeSettings alloc] init] autorelease];
    [self.settings applySettingDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                           applicationId, GreeSettingApplicationId,
                                           consumerKey, GreeSettingConsumerKey,
                                           consumerSecret, GreeSettingConsumerSecret,
                                           [NSNumber numberWithBool:YES], GreeSettingUpdateBadgeValuesAfterRemoteNotification,
                                           nil]];
    [self.settings applySettingDictionary:[self bootstrapSettingsDictionary]];
    [self.settings loadFromStorage];
    [self.settings applySettingDictionary:settings];
    [self.settings loadInternalSettingsFile];
    [self.settings finalizeSettings];

    [self setURLCache];

    self.authorizationBlocks = [NSMutableArray array];
    self.revokeBlocks = [NSMutableArray array];

    if ([[self.settings objectValueForSetting:GreeSettingRegistrationFlow] isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased]) {
      self.phoneNumberBasedController = [[[GreePhoneNumberBasedController alloc] init] autorelease];
    }

    self.phoneNumberBasedController.completionBlock =^(NSError* error) {
      if (error) {
        // couldn't complete the registration! log out!
        [GreePlatform revokeAuthorizationWithBlock:nil];
      } else {
        // broadcast user
        [self broadcastLocalUserWithError:nil];
      }
    };

    self.phoneNumberBasedController.pincodeVerifiedBlock =^(NSError* error) {
      if (error) {
        // couldn't complete the registration/upgrade! log out!
        [GreePlatform revokeAuthorizationWithBlock:nil];
      } else {
        [self.phoneNumberBasedController updateUserProfileIfNeeded];
      }
    };

    if ([self.settings boolValueForSetting:GreeSettingEnableLogging]) {
      BOOL shouldIncludeFileLineInfo = YES;
      NSString* level = GreeLogLevelWarn;
      if ([self.settings settingHasValue:GreeSettingLogLevel]) {
        level = [self.settings stringValueForSetting:GreeSettingLogLevel];
      } else if ([[self.settings stringValueForSetting:GreeSettingDevelopmentMode] isEqualToString:GreeDevelopmentModeProduction]) {
        level = GreeLogLevelPublic;
        shouldIncludeFileLineInfo = NO;
      }

      BOOL writeLogToFile = NO;
      if([self.settings boolValueForSetting:GreeSettingWriteLogToFile]) {
        writeLogToFile = YES;
      }

      self.logger = [[[GreeLogger alloc] init] autorelease];
      [self.logger setLoggerParameters:[level integerValue] includeFileLineInfo:shouldIncludeFileLineInfo logToFile:writeLogToFile folder:nil];
    }

    self.delegate = delegate;

    [self setupHttpClients];

    [self setDefaultCookies];

    __block GreePlatform* nonRetainedSelf = self;
    self.reachability = [[[GreeNetworkReachability alloc] initWithHost:@"http://www.apple.com"] autorelease];
    self.reachabilityObserver = [self.reachability addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
                                   if (!GreeNetworkReachabilityStatusIsConnected(previous) &&
                                       GreeNetworkReachabilityStatusIsConnected(current)) {
                                     [nonRetainedSelf.writeCache commitAllObjectsOfClass:NSClassFromString(@"GreeScore")];
                                     [nonRetainedSelf.writeCache commitAllObjectsOfClass:NSClassFromString(@"GreeAchievement")];
                                     [nonRetainedSelf.writeCache commitAllObjectsOfClass:NSClassFromString(@"GreeAddressBook")];
                                     [nonRetainedSelf updateBootstrapSettingsWithAttemptNumber:1 statusBlock:nil];
                                   }
                                 }];

    self.analyticsQueue = [[[GreeAnalyticsQueue alloc] initWithSettings:self.settings] autorelease];

    [self initializeComponents];

    self.localNotification = [[[GreeLocalNotification alloc] initWithSettings:self.settings] autorelease];

    _interfaceOrientation = (UIInterfaceOrientation)[self.settings integerValueForSetting : GreeSettingInterfaceOrientation];

    self.manuallyRotate = NO;
    if ([self.settings settingHasValue:GreeSettingManuallyRotateGreePlatform]) {
      self.manuallyRotate = [self.settings boolValueForSetting:GreeSettingManuallyRotateGreePlatform];
    }

    [GreeJSCommandFactory instance];

    
    // for each possible registration flow, deriving from a common base
    // with all the oauth/keychain etc stuff!

    self.authorization = [[[GreeAuthorization alloc]
                           initWithConsumerKey:[self.settings stringValueForSetting:GreeSettingConsumerKey]
                                consumerSecret:[self.settings stringValueForSetting:GreeSettingConsumerSecret]
                                      settings:self.settings
                                      delegate:self] autorelease];
    self.badgeValues = [[[GreeBadgeValues alloc] initWithSocialNetworkingServiceBadgeCount:0 applicationBadgeCount:0] autorelease];
    self.rotator = [[[GreeRotator alloc] init] autorelease];
    self.deviceNotificationCountArray = [NSMutableArray array];
    self.modelessAlertView = [[[GreeModelessAlertView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    if ([self.settings boolValueForSetting:GreeSettingEnablePerformanceLogging]) {
      self.benchmark = [[[GreeBenchmark alloc] init] autorelease];
    }
  }

  return self;
}

-(void)dealloc
{
  [self.writeCache cancelOutstandingOperations];
  self.analyticsQueue = nil;
  [self.reachability removeObserverBlock:self.reachabilityObserver];
  self.reachabilityObserver = nil;
  self.reachability = nil;
  self.localNotification = nil;
  self.settings = nil;
  self.httpClient = nil;
  self.httpsClient = nil;
  self.httpClientForApi = nil;
  self.httpsClientForApi = nil;
  self.writeCache = nil;
  self.logger = nil;
  self.localUser = nil;
  self.localUserId = nil;
  self.deviceToken = nil;
  self.authorization = nil;
  self.authorizationBlocks = nil;
  self.revokeBlocks = nil;
  self.postDeviceTokenCallbackBlock = nil;
  self.badgeValues = nil;
  [consumerScramble release];
  consumerScramble = nil;
  self.rotator = nil;
  self.deviceNotificationCountArray = nil;
  self.components = nil;
  self.defaultCookieParameters = nil;
  self.modelessAlertView = nil;
  self.phoneNumberBasedController = nil;
  self.benchmark = nil;
  self.dashboardViewController = nil;

  [super dealloc];
}

#pragma mark - Property Methods

-(id)rawNotificationQueue
{
  return [self.components valueForKey:kNotificationQueueClassString];
}

-(id)moderationList
{
  return [self.components valueForKey:kModerationListClassString];
}

#pragma mark - Public Interface

+(void)initializeWithApplicationId:(NSString*)applicationId
                       consumerKey:(NSString*)consumerKey
                    consumerSecret:(NSString*)consumerSecret
                          settings:(NSDictionary*)settings
                          delegate:(id<GreePlatformDelegate>)delegate;
{
  CFAbsoluteTime bootupBenchmarkTime = CFAbsoluteTimeGetCurrent();
  NSAssert(!sSharedSDKInstance, @"You must only initialize GreePlatform once!");
  if (!sSharedSDKInstance) {
    sSharedSDKInstance = [[GreePlatform alloc]
                          initWithApplicationId:applicationId
                                    consumerKey:consumerKey
                                 consumerSecret:consumerSecret
                                       settings:settings
                                       delegate:delegate];
    GreeLogPublic(@"Initialized Gree Platform SDK %@ (Build %@)", [GreePlatform version], [GreePlatform build]);

    [sSharedSDKInstance startAsyncInitialization];

#if DEBUG
    [GreePlatform showConnectionServer];
#endif
  }

  [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification* note) {
     sSharedSDKInstance.authorization.launchOptions = note.userInfo;
   }];
  [[NSNotificationCenter defaultCenter] addObserverForName:kGreeNSNotificationKeyUpdateNickname object:nil queue:nil usingBlock:^(NSNotification* note) {
     [sSharedSDKInstance updateLocalUser:(GreeUser*)note.object];
   }];

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkEtc position:GreeBenchmarkPosition(@"bootupStart") pointRole:GreeBenchmarkPointRoleStart pointTime:bootupBenchmarkTime];
}

+(void)shutdown
{
  NSAssert(sSharedSDKInstance, @"You must initialize GreePlatform before calling shutdown!");
  if (sSharedSDKInstance) {
    sSharedSDKInstance.finished = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:sSharedSDKInstance]; //kill any outstanding requests
    [sSharedSDKInstance removeComponents];
    [sSharedSDKInstance release];
    sSharedSDKInstance = nil;
  }
}

+(GreePlatform*)sharedInstance
{
  return sSharedSDKInstance;
}

+(NSString*)version
{
  return @"3.4.25";
}

+(NSString*)build
{
  return @"release/v3.4.25_public_51";
}

+(NSString*)paddedAppVersion;
{
  static NSString* cachedCopy = nil;
  if(!cachedCopy) {
    NSString* rawVersion = [GreePlatform bundleVersion];
    cachedCopy = [[rawVersion formatAsGreeVersion] retain];
  }
  return cachedCopy;
}

+(NSString*)bundleVersion
{
  static NSString* bundleVersionString = nil;
  if(!bundleVersionString) {
    bundleVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
  }
  return bundleVersionString;
}

-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)params
{


  NSMutableDictionary* additionalParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               [self.settings stringValueForSetting:GreeSettingApplicationId], @"opensocial_app_id",
                                               nil];
  NSString* localUserId = [[self.localUserId copy] autorelease];
  if (!localUserId) {
    localUserId = @"";
  }

  [additionalParameters setObject:localUserId forKey:@"opensocial_viewer_id"];
  [additionalParameters setObject:localUserId forKey:@"opensocial_owner_id"];

  //need to add these parameters to the query
  NSString* additionalQuery = GreeAFQueryStringFromParametersWithEncoding(additionalParameters, NSUTF8StringEncoding);

  //stitch 'em together!
  NSMutableString* urlString = [[request.URL.absoluteString mutableCopy] autorelease];
  [urlString appendString:(request.URL.query ? @"&" : @"?")];

  [urlString appendString:additionalQuery];
  request.URL = [NSURL URLWithString:urlString];

  //and to the values sent for signing
  [additionalParameters addEntriesFromDictionary:params];
  [self.httpClient signRequest:request parameters:additionalParameters];
}

-(void)authorizeWithBlock:(void (^)(GreeUser* localUser, NSError* error))block
{
  [self.benchmark registerWithKey:kGreeBenchmarkEtc position:GreeBenchmarkPosition(@"bootupEnd") pointRole:GreeBenchmarkPointRoleEnd];

  self.needPostAppStart = NO;

  if (block) {
    [self.authorizationBlocks insertObject:[[block copy] autorelease] atIndex:0];
  }

  if ([[self.settings objectValueForSetting:GreeSettingRegistrationFlow] isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased]) {
    self.registrationFlow = GreePlatformRegistrationFlowPhoneNumberBased;
  } else if ([self.settings objectValueForSetting:GreeSettingWelcomeViewControllerClass]) {
    self.registrationFlow = GreePlatformRegistrationFlowDefault;
  } else {
    self.registrationFlow = GreePlatformRegistrationFlowLegacy;
  }

  [self.authorization authorize];
}

-(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade block:(void (^)(GreeUser* localUser, NSError* error))block
{
  if (grade == GreeUserGradeLite) {
    self.needPostAppStart = YES;
  }

  if (block) {
    [self.authorizationBlocks insertObject:[[block copy] autorelease] atIndex:0];
  }

  if ([[self.settings objectValueForSetting:GreeSettingRegistrationFlow] isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased]) {
    self.registrationFlow = GreePlatformRegistrationFlowPhoneNumberBased;
  } else {
    self.registrationFlow = GreePlatformRegistrationFlowDefault;
  }

  [self.authorization directAuthorizeWithDesiredGrade:grade];
}

-(void)directRevokeAuthorizationWithBlock:(void (^)(NSError* error))block
{
  if (block) {
    [self.revokeBlocks insertObject:[[block copy] autorelease] atIndex:0];
  }

  self.registrationFlow = GreePlatformRegistrationFlowDefault;
  [self.authorization directRevoke];
}

-(void)revokeAuthorizationWithBlock:(void (^)(NSError* error))block
{
  if (block) {
    [self.revokeBlocks insertObject:[[block copy] autorelease] atIndex:0];
  }
  if ([[self.settings objectValueForSetting:GreeSettingRegistrationFlow] isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased]) {
    self.registrationFlow = GreePlatformRegistrationFlowPhoneNumberBased;
  } else {
    self.registrationFlow = GreePlatformRegistrationFlowDefault;
  }

  [self.authorization revoke];
}

-(void)setupHttpClients
{
  GreeHTTPClient** clients[] = {&_httpClient, &_httpsClient, &_httpClientForApi, &_httpsClientForApi};
  NSString* settingKeys[] = {GreeSettingServerUrlOs, GreeSettingServerUrlOsWithSSL, GreeSettingServerUrlApi, GreeSettingServerUrlApiWithSSL};

  for (int i = 0; i < 4; i++) {
    *clients[i] = [[GreeHTTPClient alloc]
                   initWithBaseURL:[NSURL URLWithString:[self.settings stringValueForSetting:settingKeys[i]]]
                               key:[self.settings stringValueForSetting:GreeSettingConsumerKey]
                            secret:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
    (*clients[i]).denyRequestWithoutAuthorization = YES;
  }
}

-(void)setDefaultCookies
{
  NSString* appId = [self.settings stringValueForSetting:GreeSettingApplicationId];
  NSString* urlSchemeString = [NSString stringWithFormat:@"%@%@", [self.settings stringValueForSetting:GreeSettingApplicationUrlScheme], appId];
  self.defaultCookieParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                  urlSchemeString, kDefaultCookieKeyURLScheme,
                                  @"iphone-app", kDefaultCookieKeyUAType,
                                  [GreePlatform paddedAppVersion], kDefaultCookieKeyAppVersion,
                                  [GreePlatform bundleVersion], kDefaultCookieKeyBundleVersion,
                                  [GreePlatform version], kDefaultCookieKeyiOSSDKVersion,
                                  [GreePlatform build], kDefaultCookieKeyiOSSDKBuild,
                                  nil];
  [NSHTTPCookieStorage greeDuplicateCookiesForAdditionalDomains];
  [NSHTTPCookieStorage greeSetCookieWithParams:self.defaultCookieParameters domain:[self.settings stringValueForSetting:GreeSettingServerUrlDomain]];
}

-(void)addAnalyticsEvent:(GreeAnalyticsEvent*)event
{
  [self.analyticsQueue addEvent:event];
}

-(void)flushAnalyticsQueueWithBlock:(void (^)(NSError* error))block
{
  [self.analyticsQueue flushWithBlock:block];
}

-(void)updateBadgeValuesWithBlock:(void (^)(GreeBadgeValues* badgeValues))block
{
  BOOL forAllApplications = [GreePlatform isSnsApp];
  [self updateBadgeValuesWithBlock:block forAllApplications:forAllApplications];
}

-(void)updateBadgeValuesWithBlock:(void (^)(GreeBadgeValues* badgeValues))block forAllApplications:(BOOL)forAllApplications
{

  void (^completionBlock)(GreeBadgeValues*, NSError*) =^(GreeBadgeValues* badgeValues, NSError* error){
    if (error) {
      GreeLogWarn(@"Badge Values could not be loaded: %@", [error localizedDescription]);
      if (block) {
        // If there is a network problem, return the existing badge value
        block(self.badgeValues);
      }
    } else {
      dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      dispatch_sync(concurrentQueue, ^{
                      self.badgeValues = badgeValues;
                    });
      if (block) {
        block(badgeValues);
      }
    }
  };

  if (forAllApplications) {
    [GreeBadgeValues loadBadgeValuesForAllApplicationsWithBlock:completionBlock];
  } else {
    [GreeBadgeValues loadBadgeValuesForCurrentApplicationWithBlock:completionBlock];
  }
}

+(NSString*)greeApplicationURLScheme
{
  static dispatch_once_t onceToken;
  static NSString* theApplicationURLScheme;

  dispatch_once(&onceToken, ^{
                  NSString* aGreeURLScheme = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationUrlScheme];
                  NSString* anApplicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
                  theApplicationURLScheme = [[NSString stringWithFormat:@"%@%@", aGreeURLScheme, anApplicationIdString] retain];
                });

  return theApplicationURLScheme;
}

+(void)authorizeWithBlock:(void (^)(GreeUser* localUser, NSError* error))block;
{
  [[GreePlatform sharedInstance] authorizeWithBlock:block];
}

+(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade block:(void (^)(GreeUser* localUser, NSError* error))block
{
  [[GreePlatform sharedInstance] directAuthorizeWithDesiredGrade:grade block:block];
}

+(void)directRevokeAuthorizationWithBlock:(void (^)(NSError* error))block;
{
  [[GreePlatform sharedInstance] directRevokeAuthorizationWithBlock:block];
}

+(void)revokeAuthorizationWithBlock:(void (^)(NSError* error))block;
{
  [[GreePlatform sharedInstance] revokeAuthorizationWithBlock:block];
}

+(BOOL)isAuthorized
{
  return [[GreeAuthorization sharedInstance] isAuthorized];
}

+(void)upgradeWithParams:(NSDictionary*)params
            successBlock:(void (^)(void))successBlock
            failureBlock:(void (^)(void))failureBlock
{
  [[GreeAuthorization sharedInstance] upgradeWithParams:params
                                           successBlock:successBlock
                                           failureBlock:failureBlock];
}

-(NSString*)accessToken
{
  return self.authorization.accessToken;
}

-(NSString*)accessTokenSecret
{
  return self.authorization.accessTokenSecret;
}

+(void)printEncryptedStringWithConsumerKey:(NSString*)consumerKey
                            consumerSecret:(NSString*)consumerSecret
                                  scramble:(NSString*)scramble
{
  NSString*  encryptedConsumerKey = [GreeConsumerProtect encryptedHexString:consumerKey keyString:scramble];
  NSLog(@"[Encrypted ConsumerKey:%@]", encryptedConsumerKey);
  NSString*  encryptedConsumerSecret = [GreeConsumerProtect encryptedHexString:consumerSecret keyString:scramble];
  NSLog(@"[Encrypted ConsumerSecret:%@]", encryptedConsumerSecret);
}

+(void)setConsumerProtectionWithScramble:(NSString*)scramble
{
  consumerScramble = [scramble copy];
}

+(void)setInterfaceOrientation:(UIInterfaceOrientation)orientation
{
  sSharedSDKInstance.interfaceOrientation = orientation;
  [sSharedSDKInstance.rotator rotateViewsToInterfaceOrientation:orientation animated:YES duration:0.3f];
}

+(BOOL)handleOpenURL:(NSURL*)url application:(UIApplication*)application
{
  if([url isSelfGreeURLScheme]) {
    NSString* handledCommand = [url host];
    if([handledCommand isEqualToString:@"start"]) {
      NSString* handledCommandType = nil;
      if([[url pathComponents] count] > 1) handledCommandType = [[url pathComponents] objectAtIndex:1];

      // Request - greeappXXXX://start/request?.id=xxx&.type=xxx&...
      if([handledCommandType isEqualToString:@"request"] || [handledCommandType isEqualToString:@"message"]) {
        NSDictionary* query = [url.query greeDictionaryFromQueryString];
        NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                               [query objectForKey:@".id"], @"info-key",
                               query, @"params",
                               nil];

        UIViewController* presentingViewController = [UIViewController greeLastPresentedViewController];

        if ([presentingViewController isKindOfClass:[GreeDashboardViewController class]]) {
          UIViewController* presentingPresentingViewController = [presentingViewController greePresentingViewController];
          [presentingPresentingViewController dismissGreeDashboardAnimated:YES completion:^(id results){

             // close dashboard and notify params to app
             [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];

           }];
        } else {

          // just notifying params to app
          [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];

        }

        return TRUE;
      }
    }
  }

  return [[GreeAuthorization sharedInstance] handleOpenURL:url];
}

+(void)postDeviceToken:(NSData*)deviceToken block:(void (^)(NSError* error))block
{
  dispatch_block_t handler =^{
    NSString* macAddr = [GreeDeviceIdentifier macAddress];
    NSString* uiid = [GreeApplicationUuid () stringByReplacingOccurrencesOfString:@"-" withString:@""];

    NSString* deviceId = [NSString stringWithFormat:@"%@%@", macAddr, uiid];
    NSString* deviceTokenString = [deviceToken greeBase64EncodedString];

    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ios", @"device",
                            deviceId, @"device_id",
                            deviceTokenString, @"notification_key",
                            nil];

    GreeLog(@"params:%@", params);

    [[GreePlatform sharedInstance].httpClient
       postPath:@"/api/rest/registerpnkey/@me/@self/@app"
     parameters:params
        success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
       GreeLog(@"Okay, posted a token");
       if (block) {
         block(nil);
       }
     }
        failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
       GreeLogWarn(@"error:%@", error);
       if (block) {
         block(error);
       }
     }];
  };

  [GreePlatform sharedInstance].deviceToken = deviceToken;
  [GreePlatform sharedInstance].postDeviceTokenCallbackBlock = block;
  if ([GreePlatform sharedInstance].localUserId && [GreePlatform sharedInstance].deviceToken) {
    handler();
  }
}

+(void)handleLaunchOptions:(NSDictionary*)launchOptions application:(UIApplication*)application
{
  dispatch_block_t handler =^{
    //Local Notification
    Class localNotificationClass = NSClassFromString(@"UILocalNotification");
    if (localNotificationClass != nil) {
      if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification* localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        [[GreePlatform sharedInstance].localNotification handleLocalNotification:localNotification application:application];
      }
    }
    //Remote Notification
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
      NSDictionary* userInfo = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
      [self handleRemoteNotification:userInfo application:application];
    }
  };

  GreeLog(@"launchOptions:%@", launchOptions);

  if ([GreePlatform sharedInstance].localUserId) {
    handler();
  } else {
    GreeLog(@"Tasks in %s have been skipped since user has not logged in.", __FUNCTION__);

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
                     if ([GreePlatform sharedInstance].localUserId) {
                       handler();
                     }
                   });
  }
}

+(BOOL)handleRemoteNotification:(NSDictionary*)notificationDictionary application:(UIApplication*)application
{
  dispatch_block_t handler =^{
    if (application.applicationState != UIApplicationStateActive) {
      NSString* appId = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId];
      NSNumber* notificationType = [notificationDictionary valueForKey:@"ntype"];

      NSMutableDictionary* analyticsParamters = [NSMutableDictionary dictionaryWithObject:appId forKey:@"app_id"];
      if (notificationType) {
        [analyticsParamters setObject:notificationType forKey:@"ntype"];
      }

      if([notificationDictionary objectForKey:@"aps"]) {
        NSDictionary* aps = [notificationDictionary valueForKey:@"aps"];
        __block NSURL* URL = nil;
        if([aps objectForKey:@"request_id"]) {
          NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [aps valueForKey:@"request_id"], @"info-key",
                                 nil];
          URL = [GreeNotificationBoardViewController URLForLaunchType:GreeNotificationBoardLaunchWithRequestDetail withParameters:param];
          [analyticsParamters setObject:[aps valueForKey:@"request_id"] forKey:@"request_id"];
        } else if([aps objectForKey:@"message_id"]) {
          NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [aps valueForKey:@"message_id"], @"info-key",
                                 nil];
          URL = [GreeNotificationBoardViewController URLForLaunchType:GreeNotificationBoardLaunchWithMessageDetail withParameters:param];
          [analyticsParamters setObject:[aps valueForKey:@"message_id"] forKey:@"message_id"];
        } else if([notificationType isEqualToNumber:[NSNumber numberWithInt:kGreePlatformRemoteNotificationTypeSNS]]) {
          URL = [GreeNotificationBoardViewController URLForLaunchType:GreeNotificationBoardLaunchAutoSelect withParameters:nil];
        }

        if (URL) {
          // launch notification board
          GreeDashboardViewController* dashboard = [GreePlatform sharedInstance].dashboardViewController;
          if (dashboard) {
            [dashboard greeDismissViewControllerAnimated:NO completion:nil];
            [dashboard.rootViewController popToRootViewControllerAnimated:NO];
            if ([dashboard.rootViewController respondsToSelector:@selector(webView)]) {
              UIWebView* webView = [dashboard.rootViewController performSelector:@selector(webView)];
              [webView loadRequest:[NSURLRequest requestWithURL:URL]];
            }
          } else {
            UIViewController* viewController = [UIViewController greeLastPresentedViewController];
            [viewController presentGreeDashboardWithBaseURL:URL delegate:viewController animated:YES completion:nil];
          }
        }
      }

      [[GreePlatform sharedInstance] addAnalyticsEvent:[GreeAnalyticsEvent eventWithType:@"evt"
                                                                                    name:@"boot_app"
                                                                                    from:@"push_notification"
                                                                              parameters:analyticsParamters]];
    }

    if ([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingUpdateBadgeValuesAfterRemoteNotification]) {
      [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:nil];
    }

    [[GreePlatform sharedInstance] applyToComponentsRemoteNotification:notificationDictionary];
  };

  GreeLog(@"notificationDictionary:%@", notificationDictionary);

  if ([GreePlatform sharedInstance].localUserId) {
    handler();
    return YES;
  } else {
    GreeLog(@"Received a push notification, but ignored since user has not logged in.");

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
                     if ([GreePlatform sharedInstance].localUserId) {
                       handler();
                     }
                   });
    return NO;
  }
}

+(void)handleLocalNotification:(UILocalNotification*)notification application:(UIApplication*)application
{
  [[GreePlatform sharedInstance].localNotification handleLocalNotification:notification application:application];
}

-(void)showNoConnectionModelessAlert
{
  [self.modelessAlertView showNoConnectionAlert];
}

-(void)notifyLaunchParameterToApp:(NSDictionary*)param
{
  if ([self.delegate respondsToSelector:@selector(greePlatformParamsReceived:)]) {
    [self.delegate greePlatformParamsReceived:param];
  }
}

-(GreeNetworkReachability*)analyticsReachability
{
  return self.reachability;
}

-(void)broadcastLocalUserWithError:(NSError*)error
{
  [self updateBadgeValuesWithBlock:nil];
  [self applyToComponentsUserLoggedIn:self.localUser];

  NSDictionary* info = self.localUser ? [NSDictionary dictionaryWithObject:self.localUser forKey:GreeNSNotificationKeyUser] : nil;
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserLogin object:nil userInfo:info];
  if ([self.delegate respondsToSelector:@selector(greePlatform:didLoginUser:)]) {
    [self.delegate greePlatform:self didLoginUser:self.localUser];
  }

  for (GreePlatformAuthorizationBlock block in self.authorizationBlocks) {
    block(self.localUser, error);
  }
  [self.authorizationBlocks removeAllObjects];
}

-(void)updateLocalUser:(GreeUser*)newUser
{
  [self updateLocalUser:newUser withNotification:NO];
}

-(void)updateLocalUser:(GreeUser*)newUser withNotification:(BOOL)notification
{
  if (newUser == self.localUser) {
    return;
  }

  self.localUser = newUser;

  if (!self.localUserId && newUser) {
    [[GreeAuthorization sharedInstance] updateUserIdIfNeeded:newUser.userId];
    self.localUserId = newUser.userId;
  }

  if (newUser) {
    self.writeCache = [[[GreeWriteCache alloc] initWithUserId:newUser.userId] autorelease];
    [self.writeCache setHashKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  } else {
    self.writeCache = nil;
  }

  if (newUser) {
    [GreeUser storeLocalUser:newUser];
  } else {
    [GreeUser removeLocalUserInCache];
  }

  // Ask authorization to sync UUID
  [self.authorization syncIdentifiers];

  NSDictionary* info = nil;
  if (newUser) {
    info = [NSDictionary dictionaryWithObject:newUser forKey:GreeNSNotificationKeyUser];
  }

  if (notification) {
    [self startPostLoginFlow];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationKeyDidUpdateLocalUserNotification object:nil userInfo:info];
  if ([self.delegate respondsToSelector:@selector(greePlatform:didUpdateLocalUser:)]) {
    [self.delegate greePlatform:self didUpdateLocalUser:self.localUser];
  }
}


static int const MAXMUM_RETRY_LOADUSER_TIMES = 5;
-(double)retryDelaySeconds:(int)retryTimes
{
  NSAssert((retryTimes > 0) && (retryTimes < MAXMUM_RETRY_LOADUSER_TIMES), @"attemptTimes should be larger than 0 and smaller than MAXMUM_RETRY_LOADUSER_TIMES!");
  double seconds = pow(2.0, (double)retryTimes);
  //add a random millseconds, so that we can avoid sending all retry requests at the same time to hit the same server.
  double randomMillSeconds = (arc4random() % 1000)* 0.001; //random number from 0 to 0.999
  return seconds + randomMillSeconds;
}

-(void)retryToUpdateLocalUser
{
  if(self.finished) {
    return;
  }
  [GreeUser loadUserWithId:@"@me" block:^(GreeUser* user, NSError* error) {
     if (user) {
       BOOL sameUser = [self.localUser.userId isEqualToString:user.userId];
       [self updateLocalUser:user withNotification:!sameUser];
     } else {
       @synchronized(self){
         self.retryTimes++;

         //We will send the same request at most 5 times
         if (self.retryTimes < MAXMUM_RETRY_LOADUSER_TIMES) {
           double delaySeconds = [self retryDelaySeconds:self.retryTimes];
           dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds* NSEC_PER_SEC));
           dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                            [self performSelector:@selector(retryToUpdateLocalUser) withObject:nil afterDelay:0.f];
                          });
         } else {
           GreeLog(@"Download failed after retrying %d times!", MAXMUM_RETRY_LOADUSER_TIMES);
           self.retryTimes = 0;
         }
       }
     }
   }];
}

-(void)postAppStartApi
{
  if ([GreeUser isAppStarted] || !self.needPostAppStart) {
    [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationKeyDidAppStartNotification object:nil];
    return;
  }

  void (^retryBlock)(GreeAFHTTPRequestOperation*, NSError*) =^(GreeAFHTTPRequestOperation* operation, NSError* error){
    [self performSelector:@selector(postAppStartApi) withObject:nil afterDelay:2];
    GreeLog(@"retry AppStartApi");
  };

  if (![self.reachability isConnectedToInternet]) {
    retryBlock(nil, nil);
    return;
  }

  [self.httpClient
     postPath:@"api/rest/appstart"
   parameters:@{
     @"device" : @"ios",
     @"context" : (self.authorization.deviceContext ? self.authorization.deviceContext : @"")
   }
      success:
   ^(GreeAFHTTPRequestOperation* operation, id responseObject){
     if (operation.response.statusCode != 200) {
       retryBlock(nil, nil);
       return;
     }

     [GreeUser setIsAppStarted:YES];
     [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationKeyDidAppStartNotification object:nil];
     self.needPostAppStart = NO; //reset flag
   }
   failure:retryBlock];
}

+(void)showConnectionServer
{
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  if(![settings boolValueForSetting:GreeSettingShowConnectionServer]) {
    return;
  }

  //this delay is for the competition of the startup login popup.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
                   NSString* title = @"Current settings";
                   NSString* message = [NSString stringWithFormat:@"mode:%@\nsuffix:%@",
                                        [settings stringValueForSetting:GreeSettingDevelopmentMode],
                                        [settings stringValueForSetting:GreeSettingServerUrlSuffix]];
                   UIAlertView* alert = [[[UIAlertView alloc]
                                              initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil] autorelease];
                   [alert show];
                   GreeLogWarn(@"%@\n%@", title, message);
                 });
}

+(NSMutableDictionary*)dictionaryWithTypeForViewController:(UIViewController*)aViewController
{
  NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
  NSNumber* aType = nil;

  if ([aViewController isKindOfClass:[GreeDashboardViewController class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeDashboard];
  } else if ([aViewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeNotificationBoard];
  } else if ([aViewController isKindOfClass:[GreeInvitePopup class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeInvitePopup];
  } else if ([aViewController isKindOfClass:[GreeSharePopup class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeSharePopup];
  } else if ([aViewController isKindOfClass:[GreeRequestServicePopup class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeRequestPopup];
  } else if ([aViewController isKindOfClass:[GreeAuthorizationPopup class]]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeAuthorizationPopup];
  } else if ([aViewController isKindOfClass:NSClassFromString(@"GreeWalletPaymentPopup")]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeWalletPaymentPopup];
  } else if ([aViewController isKindOfClass:NSClassFromString(@"GreeWalletDepositPopup")]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeWalletDepositPopup];
  } else if ([aViewController isKindOfClass:NSClassFromString(@"GreeWalletDepositIAPHistoryPopup")]) {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeWalletDepositHistoryPopup];
  } else {
    aType = [NSNumber numberWithInt:GreeViewControllerTypeOther];
  }

  [userInfo setObject:aType forKey:@"type"];

  return userInfo;
}

+(BOOL)isSnsApp
{
  NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  BOOL isSnsApp =  [bundleIdentifier hasPrefix:@"jp.gree.greeapp"];
  return isSnsApp;
}

+(BOOL)shouldPersistUniversalMenuForIPad
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && ![[GreePlatform sharedInstance].localUser.region isEqualToString:@"JP"]) {
    return YES;
  }
  return NO;
}

-(void)setURLCache
{
  NSString* key = GreeSettingUseGreeCustomURLCache;
  if ([self.settings settingHasValue:key] && ![self.settings boolValueForSetting:key]) {
    return;
  }

  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString* path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"GreeURLCache"];
  NSURLCache* urlCache = [[GreeSDURLCache alloc]
                          initWithMemoryCapacity:1024*1024   // 1MB mem cache
                                    diskCapacity:          1024*1024*5 // 5MB disk cache
                                        diskPath:path];
  [NSURLCache setSharedURLCache:urlCache];
  [urlCache release];
}

-(void)startAsyncInitialization
{
  if (![self.delegate respondsToSelector:@selector(greePlatformInitializationCompleted)]) {
    return;
  }

  // getSSOAppIdWithBlock: needs a valid context, so it will also fetch a new UUID
  // if none is found.
  [[GreeAuthorization sharedInstance] getSSOAppIdWithBlock:^(NSError* error) {
     if (error) {
       if ([self.delegate respondsToSelector:@selector(greePlatformInitializationFailedWithError:)]) {
         [self.delegate performSelector:@selector(greePlatformInitializationFailedWithError:) withObject:error];
       }
       return;
     }

     [self.delegate performSelector:@selector(greePlatformInitializationCompleted) withObject:nil];
   }];
}

-(void)startPostLoginFlow
{
  
  // things there
  if (self.registrationFlow == GreePlatformRegistrationFlowPhoneNumberBased) {
    [self.phoneNumberBasedController updateUserProfileIfNeeded];
  } else {
    // Nothing to do!
    [self broadcastLocalUserWithError:nil];
  }
}

#pragma mark Bootstrap Settings

-(NSDictionary*)bootstrapSettingsDictionary
{
  NSDictionary* bootstrapSettings = nil;

  NSString* path = [NSString greeCachePathForRelativePath:@"bootstrapSettings"];
  NSData* data = [[NSData alloc] initWithContentsOfFile:path];
  NSString* hash = [data greeHashWithKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  NSString* expectedHash = [[NSUserDefaults standardUserDefaults] stringForKey:@"GreeBootstrapSettings"];
  if ([hash isEqualToString:expectedHash]) {
    NSDictionary* deserialized = [data greeObjectFromJSONData];
    if ([deserialized count] > 0) {
      bootstrapSettings = deserialized;
    }
  }

  [data release];
  return bootstrapSettings;
}

-(void)writeBootstrapSettingsDictionary:(NSDictionary*)bootstrapSettings
{
  if ([bootstrapSettings count] == 0)
    return;

  NSString* path = [NSString greeCachePathForRelativePath:@"bootstrapSettings"];
  [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:0x0 error:nil];
  NSData* data = [bootstrapSettings greeJSONData];
  NSString* hash = [data greeHashWithKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  NSError* writeError = nil;
  BOOL succeeded = [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
  if (succeeded && writeError == nil) {
    [[NSUserDefaults standardUserDefaults] setObject:hash forKey:@"GreeBootstrapSettings"];
  }
}

-(void)updateBootstrapSettingsWithAttemptNumber:(NSInteger)attemptNumber statusBlock:(BOOL (^)(BOOL didSucceed))statusBlock
{
  __block GreePlatform* nonRetainedSelf = self;

  void (^failureBlock)(NSInteger) =^(NSInteger failingAttempt) {
    BOOL retryHint = YES;
    if (statusBlock != NULL) {
      retryHint = statusBlock(NO);
    }
    if (retryHint && failingAttempt < 5) {
      double delay = pow(3.0, (double)failingAttempt);
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                       if (sSharedSDKInstance == nonRetainedSelf) {
                         [nonRetainedSelf updateBootstrapSettingsWithAttemptNumber:failingAttempt+1 statusBlock:statusBlock];
                       }
                     });
    }
  };

  NSMutableString* path = [NSMutableString stringWithFormat:@"api/rest/sdkbootstrap/%@/ios", [self.settings stringValueForSetting:GreeSettingApplicationId]];

  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }

  if (self.localUserId) {
    [path appendFormat:@"/%@", self.localUserId];
  }
  [self.httpsClient
   performTwoLeggedRequestWithMethod:@"GET"
                                path:path
                          parameters:nil
                             success:^(GreeAFHTTPRequestOperation* operation, id settings_) {
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
     NSDictionary* settings = (NSDictionary*)settings_;
     settings = [settings valueForKeyPath:@"entry.settings"];
     if ([settings isKindOfClass:[NSDictionary class]] && [settings count] > 0) {
       [self writeBootstrapSettingsDictionary:settings];
       if (statusBlock) {
         statusBlock(YES);
       }
     } else {
       if (statusBlock) {
         statusBlock(NO);
       }
     }
   }
                             failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
     failureBlock(attemptNumber);
   }];
}

#pragma mark Components

+(void)registerComponentClass:(Class<GreePlatformComponent>)klass
{
  if (registeredComponentClassNames == nil) {
    registeredComponentClassNames = [[NSMutableArray alloc] initWithCapacity:1];
  }

  [registeredComponentClassNames addObject:NSStringFromClass(klass)];
}

-(void)initializeComponents
{
  self.components = [NSMutableDictionary dictionaryWithCapacity:1];

  [registeredComponentClassNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
     Class klass = NSClassFromString(obj);
     if ([klass respondsToSelector:@selector(componentWithSettings:)]) {
       id component = [klass componentWithSettings:self.settings];
       [self.components setObject:component forKey:(NSString*)obj];
     }
   }];
}

-(void)applyToComponentsRemoteNotification:(NSDictionary*)notificationDicitonary
{
  [self.components enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     if ([obj respondsToSelector:@selector(handleRemoteNotification:)]) {
       [obj handleRemoteNotification:notificationDicitonary];
     }
   }];
}

-(void)applyToComponentsUserLoggedIn:(GreeUser*)user
{
  [self.components enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     if ([obj respondsToSelector:@selector(userLoggedIn:)]) {
       [obj userLoggedIn:user];
     }
   }];
}

-(void)applyToComponentsUserLoggedOut:(GreeUser*)user
{
  [self.components enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     if ([obj respondsToSelector:@selector(userLoggedOut:)]) {
       [obj userLoggedOut:user];
     }
   }];
}

-(void)removeComponents
{
  [self.components enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
     if ([obj respondsToSelector:@selector(willRemoveComponentFromPlatform)]) {
       [obj willRemoveComponentFromPlatform];
     }
   }];
  [self.components removeAllObjects];
}



#pragma mark - GreeAuthorization Delegate Method

-(void)authorizeDidUpdateUserId:(NSString*)userId withToken:(NSString*)token withSecret:(NSString*)secret
{
  self.localUserId = userId;
  [self.httpClient setUserToken:token secret:secret];
  [self.httpsClient setUserToken:token secret:secret];
  [self.httpClientForApi setUserToken:token secret:secret];
  [self.httpsClientForApi setUserToken:token secret:secret];
  [GreePlatform postDeviceToken:self.deviceToken block:self.postDeviceTokenCallbackBlock];

  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationKeyDidAcquireAccessTokenNotification object:nil];
}

-(void)logoutWithPreviousUser:(GreeUser*)previousUser
{
  if ([self.delegate respondsToSelector:@selector(greePlatform:didLogoutUser:)]) {
    [self.delegate greePlatform:self didLogoutUser:previousUser];
  }
  for (GreePlatformRevokeBlock block in self.revokeBlocks) {
    block(nil);
  }
  [self.revokeBlocks removeAllObjects];

  [self applyToComponentsUserLoggedOut:previousUser];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserLogout object:nil userInfo:nil];
}

-(void)authorizeDidFinishWithLogin:(BOOL)blogin
{
  if(!self.didGameCenterInitialization) {
    self.didGameCenterInitialization = YES;
    if ([[self.settings objectValueForSetting:GreeSettingGameCenterAchievementMapping] count] > 0 ||
        [[self.settings objectValueForSetting:GreeSettingGameCenterLeaderboardMapping] count] > 0) {
      [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
    }
  }

  //great, now if we have a token, we should try to get the user
  //otherwise, we have somehow lost the user, so we should log out

  //we should clear out the old user during this time period
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserInvalidated object:nil userInfo:nil];
  GreeUser* previousUser = [self.localUser retain];
  [self updateLocalUser:nil]; //when the app starts(self.localUser is nil), nothing to do

  if([GreeAuthorization sharedInstance].accessToken) {
    GreeUser* cachedUser = [GreeUser localUserFromCache];
    self.retryTimes = 0;

    //auto login from the second time.
    if (self.localUserId && [cachedUser.userId isEqualToString:self.localUserId]) { //self.localUserId is set, when access token is got.
      if (cachedUser.userGrade == GreeUserGradeLite) {
        self.needPostAppStart = YES;
      }
      if (!cachedUser.hasThisApplication) {
        [GreeUser setIsAppStarted:NO];
      }

      [self updateLocalUser:cachedUser withNotification:blogin];
      // localUser should update also there is cache because user can update him/herself profile on the web.
      [self performSelector:@selector(retryToUpdateLocalUser) withObject:nil afterDelay:1.f];

    } else { //the first time login (no cached userInfo) or other user(not logout, but other user. rare case)
      [GreeUser setIsAppStarted:NO];
      [self retryToUpdateLocalUser];
    }

    [self postAppStartApi];

  } else {
    [self logoutWithPreviousUser:previousUser];
  }
  [previousUser release];

  [self.logger sendExceptionLog];
}

-(void)authorizeDidFinishWithGrade0:(NSError*)error
{
  for (GreePlatformAuthorizationBlock block in self.authorizationBlocks) {
    block(nil, error);
  }
  [self.authorizationBlocks removeAllObjects];
}

-(void)revokeDidFinish:(NSError*)error
{
  if (error) {
    for (GreePlatformRevokeBlock block in self.revokeBlocks) {
      block(error);
    }
    [self.revokeBlocks removeAllObjects];
  } else {
    GreeUser* oldUser = [self.localUser retain];
    [self updateLocalUser:nil];
    [self logoutWithPreviousUser:oldUser];
    [oldUser release];

    self.localUserId = nil;

    self.badgeValues = [[[GreeBadgeValues alloc] initWithSocialNetworkingServiceBadgeCount:0 applicationBadgeCount:0] autorelease];
    [GreeBadgeValues resetBadgeValues];
    [GreeNotificationLoader clearFeedsCache];
  }
}

+(void)endGeneratingRotation
{
  NSInteger tries = 0;
  while ([[UIDevice currentDevice] isGeneratingDeviceOrientationNotifications]) {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    tries++;

    // for safety, in case something goes wrong
    if (tries > 1000) {
      break;
    }
  }
  [sSharedSDKInstance.deviceNotificationCountArray addObject:[NSNumber numberWithInt:tries]];
}

+(void)beginGeneratingRotation
{
  if(sSharedSDKInstance.deviceNotificationCountArray.count) {
    NSNumber* lastObject = [sSharedSDKInstance.deviceNotificationCountArray lastObject];
    [sSharedSDKInstance.deviceNotificationCountArray removeLastObject];
    for (int i = 0; i < [lastObject intValue]; i++) {
      [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
  }
}

#pragma mark GreePlatform+GreeMiddlewareAdditions
-(void)setOriginalCookie:(NSString*)value key:(NSString*)key
{
  if(0 < value.length && 0 < key.length) {
    if (![self.defaultCookieParameters objectForKey:key]) {
      NSString* greeDomain = [self.settings stringValueForSetting:GreeSettingServerUrlDomain];
      [NSHTTPCookieStorage greeSetCookie:value forName:key domain:greeDomain];
    }
  }
}

@end

