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
#import <objc/runtime.h>
#import "GreeSettings.h"
#import "GreePhoneNumberBasedWelcomeView.h"
#import "JSONKit.h"
#import "NSString+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"

NSString* const GreeDevelopmentModeProduction = @"production";
NSString* const GreeDevelopmentModeSandbox = @"sandbox";
NSString* const GreeDevelopmentModeStaging = @"staging";
NSString* const GreeDevelopmentModeStagingSandbox = @"stagingSandbox";
NSString* const GreeDevelopmentModeDevelop = @"develop";
NSString* const GreeDevelopmentModeDevelopSandbox = @"developSandbox";

#pragma mark - Public Settings (declared in GreePlatformSettings.h)

NSString* const GreeSettingDevelopmentMode = @"developmentMode";
NSString* const GreeSettingInterfaceOrientation = @"interfaceOrientation";
NSString* const GreeSettingNotificationPosition = @"notificationPosition";
NSString* const GreeSettingNotificationEnabled = @"notificationEnabled";
NSString* const GreeSettingWidgetPosition = @"widgetPosition";
NSString* const GreeSettingWidgetExpandable = @"widgetExpandable";
NSString* const GreeSettingWidgetStartingPositionCollapsed = @"widgetStartingPositionCollapsed";
NSString* const GreeSettingGameCenterAchievementMapping = @"gameCenterAchievementMapping";
NSString* const GreeSettingGameCenterLeaderboardMapping = @"gameCenterLeaderboardMapping";
NSString* const GreeSettingEnableLogging = @"enableLogging";
NSString* const GreeSettingWriteLogToFile = @"writeToFile";
NSString* const GreeLogLevelPublic = @"0";
NSString* const GreeLogLevelWarn = @"50";
NSString* const GreeLogLevelInfo = @"100";
NSString* const GreeSettingLogLevel = @"logLevel";
NSString* const GreeSettingUpdateBadgeValuesAfterRemoteNotification= @"updateBadgeValuesAfterRemoteNotification";
NSString* const GreeSettingRemoveTokenWithReInstall  = @"removeTokenWithReInstall";
NSString* const GreeSettingAllowUserOptOutOfGREE = @"allowUserOptOutOfGREE";
NSString* const GreeSettingManuallyRotateGreePlatform = @"manuallyRotateGreePlatform";
NSString* const GreeSettingUseGreeCustomURLCache = @"useGreeCustomURLCache";

#pragma mark - Internal Settings (declared in GreeSettings.h)

NSString* const GreeSettingInternalSettingsFilename = @"internalSettingsFilename";
NSString* const GreeSettingApplicationId = @"applicationId";
NSString* const GreeSettingConsumerKey = @"consumerKey";
NSString* const GreeSettingConsumerSecret = @"consumerSecret";
NSString* const GreeSettingApplicationUrlScheme = @"applicationUrlScheme";
NSString* const GreeSettingServerUrlSuffix = @"serverUrlSuffix";
NSString* const GreeSettingAllowRegistrationCancel = @"GreeSettingAllowRegistrationCancel";
NSString* const GreeSettingAnalyticsMaximumStorageTime = @"analyticsMaximumStorageTime";
NSString* const GreeSettingAnalyticsPollingInterval = @"analyticsPollingInterval";
NSString* const GreeSettingEnableLocalNotification = @"enableLocalNotification";
NSString* const GreeSettingParametersForDeletingCookie = @"parametersForDeletingCookie";
NSString* const GreeSettingShowConnectionServer = @"showConnectionServer";
NSString* const GreeSettingUserThumbnailTimeoutInSeconds = @"userThumbnailTimeoutInSeconds";
NSString* const GreeSettingDisplayTimeForInGameNotification = @"displayTimeForInGameNotification";
NSString* const GreeSettingEnablePerformanceLogging = @"enablePerformanceLogging";
NSString* const GreeSettingRegistrationFlow                  = @"registrationFlow";
NSString* const GreeSettingRegistrationFlowPhoneNumberBased  = @"phoneNumberBased";
NSString* const GreeSettingWelcomeViewControllerClass        = @"welcomeViewControllerClass";
NSString* const GreeSettingWelcomeViewControllerNib          = @"welcomeViewControllerNib";
NSString* const GreeSettingWelcomeViewControllerBundle       = @"welcomeViewControllerBundle";
NSString* const GreeSettingAnimateWelcomeViewController      = @"animateWelcomeViewController";
NSString* const GreeSettingDisableSNSFeature = @"disableSNSFeature";
NSString* const GreeSettingUseInstantPlay = @"useInstantPlay";

#pragma mark - Dependent Settings (declared in GreeSettings.h)

NSString* const GreeSettingServerUrlDomain = @"serverUrlDomain";
NSString* const GreeSettingServerHostNamePrefix = @"serverHostNamePrefix";
NSString* const GreeSettingServerHostNameSuffix = @"serverHostNameSuffix";
NSString* const GreeSettingServerUrlApps = @"appsUrl";
NSString* const GreeSettingServerUrlPf = @"pfUrl";
NSString* const GreeSettingServerUrlOpen = @"openUrl";
NSString* const GreeSettingServerUrlId = @"idUrl";
NSString* const GreeSettingServerUrlOs = @"osUrl";
NSString* const GreeSettingServerUrlOsWithSSL = @"osWithSSLUrl";
NSString* const GreeSettingServerUrlApi = @"apiUrl";
NSString* const GreeSettingServerUrlApiWithSSL = @"apiWithSSLUrl";
NSString* const GreeSettingServerUrlPayment = @"paymentUrl";
NSString* const GreeSettingServerUrlNotice = @"noticeUrl";
NSString* const GreeSettingServerUrlGames = @"gamesUrl";
NSString* const GreeSettingServerUrlGamesRequestDetail = @"requestDetailUrl";
NSString* const GreeSettingServerUrlGamesMessageDetail = @"messageDetailUrl";
NSString* const GreeSettingServerUrlHelp = @"helpUrl";
NSString* const GreeSettingServerUrlSns = @"snsUrl";
NSString* const GreeSettingServerPortSns = @"snsPort";
NSString* const GreeSettingServerUrlSnsApi = @"snsapiUrl";
NSString* const GreeSettingServerUrlSandbox = @"sandboxUrl";
NSString* const GreeSettingUniversalMenuUrl = @"universalMenuUrl";
NSString* const GreeSettingUniversalMenuPath = @"universalMenuPath";
NSString* const GreeSettingMyLoginNotificationPath = @"myLoginNotificationPath";
NSString* const GreeSettingFriendLoginNotificationPath = @"friendLoginNotificationPath";
NSString* const GreeSettingServerUrlConnect = @"connectUrl";
NSString* const GreeSettingServerUrlConnectWithSSL = @"connectWithSSLUrl";


NSString* const GreeSettingSnsAppName = @"sns.appname";

#define kGreeSettingsKeyInStorage @"GreeSettings"


@interface GreeSettings ()
@property (nonatomic, retain) NSMutableDictionary* settings;
@property (nonatomic, assign, getter=isFinalized) BOOL finalized;
@property (nonatomic, assign) BOOL usesSandbox;
@end

@implementation GreeSettings

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self != nil) {
    self.settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @"greeapp", GreeSettingApplicationUrlScheme,
                     [NSNumber numberWithInteger:UIInterfaceOrientationPortrait], GreeSettingInterfaceOrientation,
                     [NSNumber numberWithBool:YES], GreeSettingEnableLogging,
                     @"ggpsns", GreeSettingSnsAppName,
                     [NSNumber numberWithInt:60*5], GreeSettingUserThumbnailTimeoutInSeconds,
                     nil];
  }
  return self;
}

-(void)dealloc
{
  self.settings = nil;
  [super dealloc];
}

#pragma mark - Public Interface

-(BOOL)settingHasValue:(NSString*)setting
{
  return [self.settings objectForKey:setting] != nil;
}

-(id)objectValueForSetting:(NSString*)setting
{
  return [self.settings objectForKey:setting];
}

-(BOOL)boolValueForSetting:(NSString*)setting
{
  return [[self.settings objectForKey:setting] boolValue];
}

-(NSInteger)integerValueForSetting:(NSString*)setting
{
  return [[self.settings objectForKey:setting] integerValue];
}

-(NSString*)stringValueForSetting:(NSString*)setting
{
  return [self.settings objectForKey:setting];
}

-(void)applySettingDictionary:(NSDictionary*)settings
{
  [self applySettingDictionary:settings caching:NO];
}

-(void)applySettingDictionary:(NSDictionary*)settings caching:(BOOL)caching
{
  if (caching) {
    NSDictionary* settingsInStorage = [[NSUserDefaults standardUserDefaults] objectForKey:kGreeSettingsKeyInStorage];
    NSMutableDictionary* savingSettings = nil;
    if (settingsInStorage) {
      savingSettings = [NSMutableDictionary dictionaryWithDictionary:settingsInStorage];
    } else {
      savingSettings = [NSMutableDictionary dictionary];
    }
    for (id key in settings) {
      if ([[GreeSettings needToSupportSavingToNonVolatileAreaArray] containsObject:key]) {
        [savingSettings setValue:[settings objectForKey:key] forKey:key];
      }
    }
    if (0 < [savingSettings count]) {
      [[NSUserDefaults standardUserDefaults] setObject:savingSettings forKey:kGreeSettingsKeyInStorage];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
  }

  [self.settings addEntriesFromDictionary:settings];
}

-(void)loadFromStorage
{
  NSDictionary* settingsInStorage = [[NSUserDefaults standardUserDefaults] objectForKey:kGreeSettingsKeyInStorage];
  for (id key in settingsInStorage) {
    [self.settings setObject:[settingsInStorage objectForKey:key] forKey:key];
  }
}

-(void)loadInternalSettingsFile
{
  NSString* filename = [self stringValueForSetting:GreeSettingInternalSettingsFilename];
  if ([filename length] > 0) {
    NSString* pathToSettingsFile = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToSettingsFile]) {
      NSError* parseError = nil;
      NSData* settingsData = [[[NSData alloc] initWithContentsOfFile:pathToSettingsFile] autorelease];
      GreeJSONDecoder* decoder = [[[GreeJSONDecoder alloc] initWithParseOptions:GreeJKParseOptionComments] autorelease];
      id settings = [decoder objectWithData:settingsData error:&parseError];
      if ([settings isKindOfClass:[NSDictionary class]]) {
        [self applySettingDictionary:settings];
      } else {
        NSLog(@"[Gree] Failed to load internal settings file %@, error: %@", filename, parseError);
      }
    } else {
      NSLog(@"[Gree] Failed to open internal settings file %@", filename);
    }
  }
}

-(void)finalizeSettings
{
  if (!self.finalized) {
    NSString* developmentMode = [self stringValueForSetting:GreeSettingDevelopmentMode];

    NSString* prefix = @"https://";
    NSString* suffix = @".";
    NSString* domain = @"gree.net";

    self.usesSandbox = [developmentMode isEqualToString:GreeDevelopmentModeSandbox] ||
                       [developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox] ||
                       [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox];

    if ([developmentMode isEqualToString:GreeDevelopmentModeSandbox]) {
      prefix = @"http://";
      suffix = @"-sb.";
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeStaging] || [developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox]) {
      NSAssert([self settingHasValue:GreeSettingServerUrlSuffix], @"Must specify a serverUrl suffix if you are using development mode: staging");
      prefix = @"http://";
      NSString* sbSuffix = self.usesSandbox ? @"sb" : @"";
      suffix = [NSString stringWithFormat:@"-%@%@.", sbSuffix, [self stringValueForSetting:GreeSettingServerUrlSuffix]];
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] || [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
      NSAssert([self settingHasValue:GreeSettingServerUrlSuffix], @"Must specify a serverUrl suffix if you are using development mode: develop or developSandbox");
      prefix = @"http://";
      NSString* sbSuffix = self.usesSandbox ? @"-sb" : @"";
      suffix = [NSString stringWithFormat:@"%@-dev-%@.", sbSuffix, [self stringValueForSetting:GreeSettingServerUrlSuffix]];
      domain = @"dev.gree-dev.net";
    }

    [self.settings setObject:domain forKey:GreeSettingServerUrlDomain];
    [self.settings setObject:prefix forKey:GreeSettingServerHostNamePrefix];
    [self.settings setObject:suffix forKey:GreeSettingServerHostNameSuffix];

    NSString* defaultHosts[] = {
      GreeSettingServerUrlApps,           @"apps",
      GreeSettingServerUrlPf,             @"pf",
      GreeSettingServerUrlOpen,           @"open",
      GreeSettingServerUrlId,             @"id",
      GreeSettingServerUrlOs,             @"os",
      GreeSettingServerUrlOsWithSSL,      @"os",
      GreeSettingServerUrlApi,            @"api",
      GreeSettingServerUrlApiWithSSL,     @"api",
      GreeSettingServerUrlPayment,        @"payment",
      GreeSettingServerUrlNotice,         @"notice",
      GreeSettingServerUrlHelp,           @"help",
      GreeSettingServerUrlSns,            @"sns",
      GreeSettingServerUrlSnsApi,         @"api-sns",
      GreeSettingServerUrlGames,          @"games",
      GreeSettingServerUrlConnect,        @"connect",
      GreeSettingServerUrlConnectWithSSL, @"connect",
      NULL
    };

    NSArray* noHttps = nil;
    if ([developmentMode isEqualToString:GreeDevelopmentModeProduction]) {
      noHttps = [NSArray arrayWithObjects:
                 GreeSettingServerUrlApps,
                 GreeSettingServerUrlGames,
                 GreeSettingServerUrlSns,
                 GreeSettingServerUrlOs,
                 GreeSettingServerUrlApi,
                 GreeSettingServerUrlNotice,
                 GreeSettingServerUrlPf,
                 GreeSettingServerUrlConnect,
                 nil];
    }

    NSString** p = defaultHosts;
    while (NULL != *p) {
      NSString* key = *p++;
      NSString* hostname = *p++;
      if ([self.settings objectForKey:key] == nil) {
        NSString* protocol = [noHttps containsObject:key] ? @"http://" : prefix;
        [self.settings setObject:[NSString stringWithFormat:@"%@%@%@%@", protocol, hostname, suffix, domain] forKey:key];
      }
    }

    // Notification Board URL
    NSString* defaultNBURL[] = {
      GreeSettingServerUrlGamesMessageDetail, @"/service/message/detail/",
      GreeSettingServerUrlGamesRequestDetail, @"/service/request/detail/",
      NULL
    };

    NSString** q = defaultNBURL;
    while (NULL != *q) {
      NSString* key = *q++;
      NSString* path = *q++;
      if ([self.settings objectForKey:key] == nil) {
        [self.settings setObject:[NSString stringWithFormat:@"%@%@", [self.settings objectForKey:GreeSettingServerUrlGames], path] forKey:key];
      }
    }

    if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop]) {
      NSString* settingPort = [self.settings objectForKey:GreeSettingServerPortSns];
      NSString* port = settingPort ? settingPort : @"3030";
      [self.settings setObject:port forKey:GreeSettingServerPortSns];
      if (port) {
        NSString* url = [NSString stringWithFormat:@"%@:%@", [self.settings objectForKey:GreeSettingServerUrlSns], port];
        [self.settings setObject:url forKey:GreeSettingServerUrlSns];
      }
    }

    if (![self.settings objectForKey:GreeSettingUniversalMenuPath]) {
      if (self.usesSandbox) {
        [self.settings setObject:@"?action=universalmenu" forKey:GreeSettingUniversalMenuPath];
      } else {
        NSURL* gameDashboardBaseURL = [NSURL URLWithString:[self stringValueForSetting:GreeSettingServerUrlApps]];
        NSString* applicationIdString = [self stringValueForSetting:GreeSettingApplicationId];
        NSString* gameDashboardPath = [NSString stringWithFormat:@"gd?app_id=%@", applicationIdString];
        NSURL* gameDashboardURL = [NSURL URLWithString:gameDashboardPath relativeToURL:gameDashboardBaseURL];
        [self.settings setObject:[NSString stringWithFormat:@"/um#view=universalmenu_top&gamedashboard=%@&appportal=%@",
                                  [[gameDashboardURL absoluteString] greeURLEncodedString],
                                  [[self stringValueForSetting:GreeSettingServerUrlGames] greeURLEncodedString]]
                          forKey:GreeSettingUniversalMenuPath];
      }
    }

    [self.settings setObject:[NSString stringWithFormat:@"%@%@%@", prefix, [suffix substringFromIndex:1], domain]
                      forKey:GreeSettingServerUrlSandbox];
    if ([developmentMode isEqualToString:GreeDevelopmentModeProduction] ||
        [developmentMode isEqualToString:GreeDevelopmentModeStaging]) {
      [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSns] forKey:GreeSettingUniversalMenuUrl];
    } else if (self.usesSandbox) {
      [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSandbox]
                        forKey:GreeSettingUniversalMenuUrl];
    } else {
      if (![self.settings objectForKey:GreeSettingUniversalMenuUrl]) {
        [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSns] forKey:GreeSettingUniversalMenuUrl];
      }
    }

    if (![self.settings objectForKey:GreeSettingMyLoginNotificationPath]) {
      [self.settings setObject:@"?view=stream_home" forKey:GreeSettingMyLoginNotificationPath];
    }

    if (![self.settings objectForKey:GreeSettingFriendLoginNotificationPath]) {
      [self.settings setObject:@"?view=profile_info" forKey:GreeSettingFriendLoginNotificationPath];
    }

    const NSString* registrationFlow = [self.settings objectForKey:GreeSettingRegistrationFlow];
    if (registrationFlow) {
      // There's only one extra registration flow bundled for now
      NSAssert2([registrationFlow isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased],
                @"Bad value for %@: %@", GreeSettingRegistrationFlow, registrationFlow);
    }

    if (!self.settings[GreeSettingAllowUserOptOutOfGREE]) {
      self.settings[GreeSettingAllowUserOptOutOfGREE] = @NO;
    }

    if (!self.settings[GreeSettingUseInstantPlay]) {
      self.settings[GreeSettingUseInstantPlay] = @YES;
    }

    // we set a cookie reflecting the value of useInstantPlay, so that server-side
    // can differentiate between apps that set this setting and apps that don't (for
    // analytics purpose).
    if ([self.settings[GreeSettingUseInstantPlay] boolValue]) {
      [NSHTTPCookieStorage greeSetCookie:@"1" forName:@"uip" domain:domain];
    } else {
      [NSHTTPCookieStorage greeDeleteCookieWithName:@"uip" domain:domain];
    }

    if ([registrationFlow isEqualToString:GreeSettingRegistrationFlowPhoneNumberBased]) {
      // If phone-number based registration flow is chosen, we force
      // GreePhoneNumberBasedWelcomeNavigationController as welcome view controller
      [self.settings setObject:[GreePhoneNumberBasedWelcomeNavigationController class] forKey:GreeSettingWelcomeViewControllerClass];
      [self.settings setObject:[NSBundle greePlatformCoreBundle] forKey:GreeSettingWelcomeViewControllerBundle];
      [self.settings removeObjectForKey:GreeSettingWelcomeViewControllerNib];
    } else {
      // 3rd party is now a synonym to default
      [self.settings removeObjectForKey:GreeSettingRegistrationFlow];

      id welcomeViewControllerClass = [self.settings objectForKey:GreeSettingWelcomeViewControllerClass];
      NSString* welcomeViewControllerNib = [self.settings objectForKey:GreeSettingWelcomeViewControllerNib];
      BOOL welcomeViewControllerNibWasSpecified = (welcomeViewControllerNib != nil);
      NSBundle* welcomeViewControllerBundle = [self.settings objectForKey:GreeSettingWelcomeViewControllerBundle];

      // If we have a NIB but no class, make it the class name
      if (welcomeViewControllerNib && !welcomeViewControllerClass) {
        welcomeViewControllerClass = welcomeViewControllerNib;
      }

      // Sanitize the class
      if (welcomeViewControllerClass) {
        if ([welcomeViewControllerClass isKindOfClass:[NSString class]]) {
          // If the setting is a NSString, load the corresponding class
          NSString* className = (NSString*)welcomeViewControllerClass;
          welcomeViewControllerClass = NSClassFromString(className);
          NSAssert1(welcomeViewControllerClass, @"Couldn't find class \"%@\"", className);
        } else {
          NSAssert1(class_isMetaClass(object_getClass(welcomeViewControllerClass)),
                    @"%@ is not a class nor a class name", welcomeViewControllerClass);
          NSAssert1([welcomeViewControllerClass isSubclassOfClass:[UIViewController class]],
                    @"%@ is not a subclass of UIViewController", welcomeViewControllerClass);
        }
      }

      // If we have a class but no NIB, try to find a NIB that matches our class name
      if (welcomeViewControllerClass && !welcomeViewControllerNib) {
        welcomeViewControllerNib = NSStringFromClass(welcomeViewControllerClass);
      }

      // If we don't have anything to look for in a bundle, we can ignore it
      if (!welcomeViewControllerNib) {
        welcomeViewControllerBundle = nil;
      }

      // Sanitize bundle
      if (welcomeViewControllerBundle) {
        if ([welcomeViewControllerBundle isKindOfClass:[NSString class]]) {
          // Setting is a string, try to load the corresponding bundle from the app's bundle
          NSString* bundleName = (NSString*)welcomeViewControllerBundle;
          NSString* bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
          NSAssert1(bundlePath, @"Could not find bundle named %@", bundleName);
          welcomeViewControllerBundle = [NSBundle bundleWithPath:bundlePath];
          NSAssert1(welcomeViewControllerBundle, @"Could not load bundle named %@", bundleName);
        } else {
          NSAssert1([welcomeViewControllerBundle isKindOfClass:[NSBundle class]],
                    @"%@ is not a NSBundle", welcomeViewControllerBundle);
        }
      }

      // If a bundle was specified, we must have a NIB
      if (welcomeViewControllerBundle) {
        NSAssert2([welcomeViewControllerBundle pathForResource:welcomeViewControllerNib ofType:@"nib"],
                  @"Could not find NIB named %@ in %@", welcomeViewControllerNib, welcomeViewControllerBundle);
      }
      // If we don't have a bundle but we're trying to find a NIB, try
      // both the SDK bundle and the application bundle, in order
      else if (welcomeViewControllerNib) {
        welcomeViewControllerBundle = [NSBundle greePlatformCoreBundle];
        if (![welcomeViewControllerBundle pathForResource:welcomeViewControllerNib ofType:@"nib"]) {
          welcomeViewControllerBundle = [NSBundle mainBundle];
          if (![welcomeViewControllerBundle pathForResource:welcomeViewControllerNib ofType:@"nib"]) {
            welcomeViewControllerBundle = nil;
          }
        }

        // If no NIB was found:
        // * if the settings specified one, fail.
        // * otherwise it just mean our class doesn't use a NIB
        if (!welcomeViewControllerBundle) {
          NSAssert1(!welcomeViewControllerNibWasSpecified,
                    @"Could not find NIB named %@ in any bundle", welcomeViewControllerNib);
          welcomeViewControllerNib = nil;
        }
      }

      // Store finalized class
      if (welcomeViewControllerClass) {
        [self.settings setObject:welcomeViewControllerClass forKey:GreeSettingWelcomeViewControllerClass];
      } else {
        [self.settings removeObjectForKey:GreeSettingWelcomeViewControllerClass];
      }

      // Store finalized NIB
      if (welcomeViewControllerNib) {
        [self.settings setObject:welcomeViewControllerNib forKey:GreeSettingWelcomeViewControllerNib];
      } else {
        [self.settings removeObjectForKey:GreeSettingWelcomeViewControllerNib];
      }

      // Store finalized bundle
      if (welcomeViewControllerBundle) {
        [self.settings setObject:welcomeViewControllerBundle forKey:GreeSettingWelcomeViewControllerBundle];
      } else {
        [self.settings removeObjectForKey:GreeSettingWelcomeViewControllerBundle];
      }
    }

    // Animate the welcome view controller by default
    if (![self.settings objectForKey:GreeSettingAnimateWelcomeViewController]) {
      [self.settings setObject:[NSNumber numberWithBool:NO] forKey:GreeSettingAnimateWelcomeViewController];
    }

    self.finalized = YES;
  }
}

-(NSString*)serverUrlWithHostName:(NSString*)hostname
{
  NSString* domain = [self stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* prefix = [self stringValueForSetting:GreeSettingServerHostNamePrefix];
  NSString* suffix = [self stringValueForSetting:GreeSettingServerHostNameSuffix];
  return [NSString stringWithFormat:@"%@%@%@%@", prefix, hostname, suffix, domain];
}

+(NSArray*)blackListForRemoteConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
                  anArray = [[NSArray arrayWithObjects:
                              GreeSettingApplicationId,
                              GreeSettingConsumerKey,
                              GreeSettingConsumerSecret,
                              nil] retain];
                  atexit_b (^{
                              [anArray release], anArray = nil;
                            });
                });

  return anArray;
}

+(NSArray*)needToSupportSavingToNonVolatileAreaArray
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
                  anArray = [[NSArray arrayWithObjects:
                              GreeSettingNotificationEnabled,
                              GreeSettingEnableLogging,
                              GreeSettingWriteLogToFile,
                              GreeSettingLogLevel,
                              GreeSettingEnableLocalNotification,
                              nil] retain];
                  atexit_b (^{
                              [anArray release], anArray = nil;
                            });
                });

  return anArray;
}

+(NSArray*)blackListForGetConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
                  anArray = [[NSArray arrayWithObjects:
                              GreeSettingConsumerKey,
                              GreeSettingConsumerSecret,
                              GreeSettingParametersForDeletingCookie,
                              nil] retain];
                  atexit_b (^{
                              [anArray release], anArray = nil;
                            });
                });

  return anArray;
}

+(NSArray*)blackListForSetConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
                  anArray = [[NSArray arrayWithObjects:
                              GreeSettingApplicationId,
                              GreeSettingConsumerKey,
                              GreeSettingConsumerSecret,
                              GreeSettingParametersForDeletingCookie,
                              nil] retain];
                  atexit_b (^{
                              [anArray release], anArray = nil;
                            });
                });

  return anArray;
}


#pragma mark - NSObject Overrides

-(NSString*)description;
{
  return [NSString stringWithFormat:
          @"<%@:%p, settings:%@, finalized:%@>",
          NSStringFromClass([self class]),
          self,
          self.settings,
          self.finalized ? @"YES": @"NO"];
}

@end
