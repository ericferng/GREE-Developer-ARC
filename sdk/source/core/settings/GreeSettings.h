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

#import <Foundation/Foundation.h>

#import "GreePlatformSettings.h"

extern NSString* const GreeDevelopmentModeStaging;
extern NSString* const GreeDevelopmentModeStagingSandbox;
extern NSString* const GreeDevelopmentModeDevelop;
extern NSString* const GreeDevelopmentModeDevelopSandbox;

// Internal Settings
extern NSString* const GreeSettingInternalSettingsFilename;
extern NSString* const GreeSettingApplicationId;
extern NSString* const GreeSettingConsumerKey;
extern NSString* const GreeSettingConsumerSecret;
extern NSString* const GreeSettingApplicationUrlScheme;
extern NSString* const GreeSettingServerUrlSuffix;
extern NSString* const GreeSettingAnalyticsMaximumStorageTime;
extern NSString* const GreeSettingAnalyticsPollingInterval;
extern NSString* const GreeSettingParametersForDeletingCookie;
extern NSString* const GreeSettingUserThumbnailTimeoutInSeconds;
extern NSString* const GreeSettingDisplayTimeForInGameNotification;
extern NSString* const GreeSettingRegistrationFlow;
extern NSString* const GreeSettingRegistrationFlowPhoneNumberBased;
extern NSString* const GreeSettingDisableSNSFeature;
extern NSString* const GreeSettingUseInstantPlay;

// Dependent Settings
// These setting values are computed in finalizeSettings based on
// values for other settings
extern NSString* const GreeSettingServerUrlDomain;
extern NSString* const GreeSettingServerHostNamePrefix;
extern NSString* const GreeSettingServerHostNameSuffix;
extern NSString* const GreeSettingServerUrlApps;
extern NSString* const GreeSettingServerUrlPf;
extern NSString* const GreeSettingServerUrlOpen;
extern NSString* const GreeSettingServerUrlId;
extern NSString* const GreeSettingServerUrlOs;
extern NSString* const GreeSettingServerUrlOsWithSSL;
extern NSString* const GreeSettingServerUrlApi;
extern NSString* const GreeSettingServerUrlApiWithSSL;
extern NSString* const GreeSettingServerUrlPayment;
extern NSString* const GreeSettingServerUrlNotice;
extern NSString* const GreeSettingServerUrlGames;
extern NSString* const GreeSettingServerUrlGamesRequestDetail;
extern NSString* const GreeSettingServerUrlGamesMessageDetail;
extern NSString* const GreeSettingServerUrlHelp;
extern NSString* const GreeSettingServerUrlSns;
extern NSString* const GreeSettingServerPortSns;
extern NSString* const GreeSettingServerUrlSnsApi;
extern NSString* const GreeSettingServerUrlSandbox;
extern NSString* const GreeSettingUniversalMenuUrl;
extern NSString* const GreeSettingUniversalMenuPath;
extern NSString* const GreeSettingAllowRegistrationCancel;
extern NSString* const GreeSettingEnableLocalNotification;
extern NSString* const GreeSettingShowConnectionServer;
extern NSString* const GreeSettingMyLoginNotificationPath;
extern NSString* const GreeSettingFriendLoginNotificationPath;
extern NSString* const GreeSettingEnablePerformanceLogging;
extern NSString* const GreeSettingServerUrlConnect;
extern NSString* const GreeSettingServerUrlConnectWithSSL;


extern NSString* const GreeSettingSnsAppName;

@interface GreeSettings : NSObject

// Query if a setting has a value or not
-(BOOL)settingHasValue:(NSString*)setting;

// Generic setting accessor
-(id)objectValueForSetting:(NSString*)setting;

// Type-specific setting accessors
-(BOOL)boolValueForSetting:(NSString*)setting;
-(NSInteger)integerValueForSetting:(NSString*)setting;
-(NSString*)stringValueForSetting:(NSString*)setting;

// Create Server URL with host name.
-(NSString*)serverUrlWithHostName:(NSString*)hostname;

// Applies an NSDictionary of settings to this set. Keys
// are interpreted as setting names, values as setting values.
// Any duplicate entries will overwrite the current value.
-(void)applySettingDictionary:(NSDictionary*)settings;

// Use this method if you want to store settings to local cache (NSUserDefaults)
-(void)applySettingDictionary:(NSDictionary*)settings caching:(BOOL)caching;

// Loads settings from local cache (NSUserDefaults)
-(void)loadFromStorage;
// Loads the internal settings file, if specified.
-(void)loadInternalSettingsFile;

// Computes dependent settings and constantizes them.
-(void)finalizeSettings;

+(NSArray*)blackListForRemoteConfig;
+(NSArray*)needToSupportSavingToNonVolatileAreaArray;
+(NSArray*)blackListForGetConfig;
+(NSArray*)blackListForSetConfig;

@property (nonatomic, readonly, assign) BOOL usesSandbox;
@end
