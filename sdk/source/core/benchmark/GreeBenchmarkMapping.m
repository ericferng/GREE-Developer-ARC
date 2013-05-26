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

#import "GreeBenchmarkMapping.h"
#import "GreePlatform+Internal.h"

NSString* const kGreeBenchmarkFlowName = @"flowName";
NSString* const kGreeBenchmarkPointName = @"pointName";
NSString* const kGreeBenchmarkLogin = @"login";
NSString* const kGreeBenchmarkInvite = @"invite";
NSString* const kGreeBenchmarkShare = @"share";
NSString* const kGreeBenchmarkRequest = @"request";
NSString* const kGreeBenchmarkPayment = @"payment";
NSString* const kGreeBenchmarkPaymentDeposit = @"payment deposit";
NSString* const kGreeBenchmarkPaymentHistory = @"payment history";
NSString* const kGreeBenchmarkUpgrade = @"upgrade";
NSString* const kGreeBenchmarkLogout = @"logout";
NSString* const kGreeBenchmarkDashboard = @"dashboard";
NSString* const kGreeBenchmarkDashboardUm = @"dashboard um";
NSString* const kGreeBenchmarkNotificationBoard = @"notification board";
NSString* const kGreeBenchmarkOs = @"os";
NSString* const kGreeBenchmarkOpen = @"open";
NSString* const kGreeBenchmarkPaymentApi = @"payment api";
NSString* const kGreeBenchmarkAuthorization = @"authorization";

NSString* const kGreeBenchmarkPopupStart = @"popupStart";
NSString* const kGreeBenchmarkUrlLoadStart = @"urlLoadStart";
NSString* const kGreeBenchmarkUrlLoadError = @"urlLoadError";
NSString* const kGreeBenchmarkUrlLoadEnd = @"urlLoadEnd";
NSString* const kGreeBenchmarkPostStart = @"postStart";
NSString* const kGreeBenchmarkDismiss = @"dismiss";
NSString* const kGreeBenchmarkCancel = @"cancel";
NSString* const kGreeBenchmarkLaunchNativeApp = @"launchNativeApp";

NSString* const kGreeBenchmarkApiUsage = @"apiUsage";
NSString* const kGreeBenchmarkEtc = @"etc";
NSString* const kGreeBenchmarkStart = @"Start";
NSString* const kGreeBenchmarkEnd = @"End";
NSString* const kGreeBenchmarkError = @"Error";

NSString* const kGreeBenchmarkHttpProtocolGet = @"GET";
NSString* const kGreeBenchmarkHttpProtocolPost = @"POST";
NSString* const kGreeBenchmarkHttpProtocolPut = @"PUT";
NSString* const kGreeBenchmarkHttpProtocolDelete = @"DELETE";

@interface GreeBenchmarkMapping ()
@property (nonatomic, retain) NSDictionary* flowNameMappingDictionary;
@property (nonatomic, retain) NSDictionary* pointNameMappingDictionary;
-(NSDictionary*)makeFlowNameMapping;
-(NSDictionary*)makePointNameMapping;
@end


@implementation GreeBenchmarkMapping

#pragma mark - Object lifecycle

-(void)dealloc
{
  self.flowNameMappingDictionary = nil;
  self.pointNameMappingDictionary = nil;

  [super dealloc];
}

-(id)init
{
  self = [super init];
  if (self) {
    self.flowNameMappingDictionary = [self makeFlowNameMapping];
    self.pointNameMappingDictionary = [self makePointNameMapping];
  }
  return self;
}

#pragma mark - public



-(NSNumber*)convertFlowIndexWithFlowName:(NSString*)flowName
{
  return [self.flowNameMappingDictionary objectForKey:flowName];
}

-(NSNumber*)convertPointIndexWithFlowName:(NSString*)flowName pointName:(NSString*)pointName
{
  return [[self.pointNameMappingDictionary objectForKey:flowName] objectForKey:pointName];
}

#pragma mark - Internal methods

-(NSDictionary*)makeFlowNameMapping
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:0], kGreeBenchmarkLogin,
          [NSNumber numberWithInt:1], kGreeBenchmarkInvite,
          [NSNumber numberWithInt:2], kGreeBenchmarkShare,
          [NSNumber numberWithInt:3], kGreeBenchmarkRequest,
          [NSNumber numberWithInt:4], kGreeBenchmarkPayment,
          [NSNumber numberWithInt:5], kGreeBenchmarkPaymentDeposit,
          [NSNumber numberWithInt:7], kGreeBenchmarkPaymentHistory,
          [NSNumber numberWithInt:8], kGreeBenchmarkUpgrade,
          [NSNumber numberWithInt:9], kGreeBenchmarkLogout,
          [NSNumber numberWithInt:10], kGreeBenchmarkDashboard,
          [NSNumber numberWithInt:11], kGreeBenchmarkDashboardUm,
          [NSNumber numberWithInt:12], kGreeBenchmarkNotificationBoard,
          [NSNumber numberWithInt:13], kGreeBenchmarkOs,
          [NSNumber numberWithInt:14], kGreeBenchmarkOpen,
          [NSNumber numberWithInt:15], kGreeBenchmarkPaymentApi,
          [NSNumber numberWithInt:16], kGreeBenchmarkApiUsage,
          [NSNumber numberWithInt:17], kGreeBenchmarkAuthorization,
          [NSNumber numberWithInt:99], kGreeBenchmarkEtc,
          nil];
}

-(NSDictionary*)makePointNameMapping
{
  NSDictionary* defaultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:0], kGreeBenchmarkPopupStart,
                                     [NSNumber numberWithInt:1], kGreeBenchmarkUrlLoadStart,
                                     [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadError,
                                     [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadEnd,
                                     [NSNumber numberWithInt:4], kGreeBenchmarkPostStart,
                                     [NSNumber numberWithInt:5], kGreeBenchmarkDismiss,
                                     [NSNumber numberWithInt:6], kGreeBenchmarkCancel, nil];

  NSMutableDictionary* shareDictionary = [NSMutableDictionary dictionaryWithDictionary:defaultDictionary];
  [shareDictionary setObject:[NSNumber numberWithInt:7] forKey:@"screenShotStart"];
  [shareDictionary setObject:[NSNumber numberWithInt:8] forKey:@"screenShotEnd"];

  NSMutableDictionary* paymentDictionary = [NSMutableDictionary dictionaryWithDictionary:defaultDictionary];
  [paymentDictionary removeObjectForKey:kGreeBenchmarkDismiss];
  [paymentDictionary setObject:[NSNumber numberWithInt:5] forKey:@"finish"];
  [paymentDictionary setObject:[NSNumber numberWithInt:7] forKey:@"goToDeposit"];

  NSDictionary* paymentDepositDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:0], kGreeBenchmarkPopupStart,
                                            [NSNumber numberWithInt:1], kGreeBenchmarkUrlLoadStart,
                                            [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadError,
                                            [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadEnd,
                                            [NSNumber numberWithInt:4], kGreeBenchmarkDismiss,
                                            [NSNumber numberWithInt:5], kGreeBenchmarkCancel,
                                            [NSNumber numberWithInt:6], @"depositStart",
                                            [NSNumber numberWithInt:7], @"depositError", nil];

  NSDictionary* paymentHistoryDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:0], @"initializeIAB",
                                            [NSNumber numberWithInt:1], kGreeBenchmarkPopupStart,
                                            [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadStart,
                                            [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadError,
                                            [NSNumber numberWithInt:4], kGreeBenchmarkUrlLoadEnd,
                                            [NSNumber numberWithInt:5], kGreeBenchmarkDismiss,
                                            [NSNumber numberWithInt:6], kGreeBenchmarkCancel,
                                            [NSNumber numberWithInt:7], @"contact urlLoadStart",
                                            [NSNumber numberWithInt:8], @"contact urlLoadError",
                                            [NSNumber numberWithInt:9], @"contact urlLoadEnd",
                                            [NSNumber numberWithInt:10], @"collateStart",
                                            nil];

  NSDictionary* dashBoardDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:0], @"dashboardStart",
                                       [NSNumber numberWithInt:1], kGreeBenchmarkUrlLoadStart,
                                       [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadError,
                                       [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadEnd,
                                       [NSNumber numberWithInt:4], kGreeBenchmarkDismiss,
                                       [NSNumber numberWithInt:5], @"goToNotificationBoard",
                                       [NSNumber numberWithInt:6], @"goToUM",
                                       [NSNumber numberWithInt:7], @"selectSubNavi",
                                       [NSNumber numberWithInt:8], @"selectUMItem",
                                       [NSNumber numberWithInt:9], @"startPushView",
                                       [NSNumber numberWithInt:10], @"startPopView",
                                       nil];

  NSDictionary* dashBoardUmDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:0], @"umStart",
                                         [NSNumber numberWithInt:1], kGreeBenchmarkUrlLoadStart,
                                         [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadError,
                                         [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadEnd,
                                         [NSNumber numberWithInt:4], kGreeBenchmarkDismiss,
                                         [NSNumber numberWithInt:5], kGreeBenchmarkLaunchNativeApp,
                                         nil];

  NSDictionary* notificationBoardDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInt:0], @"notificationBoardStart",
                                               [NSNumber numberWithInt:1], kGreeBenchmarkUrlLoadStart,
                                               [NSNumber numberWithInt:2], kGreeBenchmarkUrlLoadError,
                                               [NSNumber numberWithInt:3], kGreeBenchmarkUrlLoadEnd,
                                               [NSNumber numberWithInt:4], kGreeBenchmarkDismiss,
                                               [NSNumber numberWithInt:5], kGreeBenchmarkLaunchNativeApp,
                                               nil];
  NSDictionary* osDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:0], @"peopleGetStart",
                                [NSNumber numberWithInt:1], @"peopleGetError",
                                [NSNumber numberWithInt:2], @"peopleGetEnd",
                                [NSNumber numberWithInt:3], @"ignoreListGetStart",
                                [NSNumber numberWithInt:4], @"ignoreListGetError",
                                [NSNumber numberWithInt:5], @"ignoreListGetEnd",
                                [NSNumber numberWithInt:6], @"sgpScoreGetStart",
                                [NSNumber numberWithInt:7], @"sgpScoreGetError",
                                [NSNumber numberWithInt:8], @"sgpScoreGetEnd",
                                [NSNumber numberWithInt:9], @"sgpScorePostStart",
                                [NSNumber numberWithInt:10], @"sgpScorePostError",
                                [NSNumber numberWithInt:11], @"sgpScorePostEnd",
                                [NSNumber numberWithInt:12], @"sgpScoreDeleteStart",
                                [NSNumber numberWithInt:13], @"sgpScoreDeleteError",
                                [NSNumber numberWithInt:14], @"sgpScoreDeleteEnd",
                                [NSNumber numberWithInt:15], @"sgpRankingGetStart",
                                [NSNumber numberWithInt:16], @"sgpRankingGetError",
                                [NSNumber numberWithInt:17], @"sgpRankingGetEnd",
                                [NSNumber numberWithInt:18], @"sgpLeaderboardGetStart",
                                [NSNumber numberWithInt:19], @"sgpLeaderboardGetError",
                                [NSNumber numberWithInt:20], @"sgpLeaderboardGetEnd",
                                [NSNumber numberWithInt:21], @"sgpLeaderboardPutStart",
                                [NSNumber numberWithInt:22], @"sgpLeaderboardPutError",
                                [NSNumber numberWithInt:23], @"sgpLeaderboardPutEnd",
                                [NSNumber numberWithInt:24], @"sgpAchievementGetStart",
                                [NSNumber numberWithInt:25], @"sgpAchievementGetError",
                                [NSNumber numberWithInt:26], @"sgpAchievementGetEnd",
                                [NSNumber numberWithInt:27], @"sgpAchievementPostStart",
                                [NSNumber numberWithInt:28], @"sgpAchievementPostError",
                                [NSNumber numberWithInt:29], @"sgpAchievementPostEnd",
                                [NSNumber numberWithInt:30], @"sgpAchievementPutStart",
                                [NSNumber numberWithInt:31], @"sgpAchievementPutError",
                                [NSNumber numberWithInt:32], @"sgpAchievementPutEnd",
                                [NSNumber numberWithInt:33], @"touchSessionGetStart",
                                [NSNumber numberWithInt:34], @"touchSessionGetError",
                                [NSNumber numberWithInt:35], @"touchSessionGetEnd",
                                [NSNumber numberWithInt:36], @"badgeGetStart",
                                [NSNumber numberWithInt:37], @"badgeGetError",
                                [NSNumber numberWithInt:38], @"badgeGetEnd",
                                [NSNumber numberWithInt:39], @"sdkbootstrapGetStart",
                                [NSNumber numberWithInt:40], @"sdkbootstrapGetError",
                                [NSNumber numberWithInt:41], @"sdkbootstrapGetEnd",
                                [NSNumber numberWithInt:42], @"moderationGetStart",
                                [NSNumber numberWithInt:43], @"moderationGetError",
                                [NSNumber numberWithInt:44], @"moderationGetEnd",
                                [NSNumber numberWithInt:45], @"moderationPostStart",
                                [NSNumber numberWithInt:46], @"moderationPostError",
                                [NSNumber numberWithInt:47], @"moderationPostEnd",
                                [NSNumber numberWithInt:48], @"moderationPutStart",
                                [NSNumber numberWithInt:49], @"moderationPutError",
                                [NSNumber numberWithInt:50], @"moderationPutEnd",
                                [NSNumber numberWithInt:51], @"moderationDeleteStart",
                                [NSNumber numberWithInt:52], @"moderationDeleteError",
                                [NSNumber numberWithInt:53], @"moderationDeleteEnd",
                                [NSNumber numberWithInt:54], @"friendcodeGetStart",
                                [NSNumber numberWithInt:55], @"friendcodeGetError",
                                [NSNumber numberWithInt:56], @"friendcodeGetEnd",
                                [NSNumber numberWithInt:57], @"friendcodePostStart",
                                [NSNumber numberWithInt:58], @"friendcodePostError",
                                [NSNumber numberWithInt:59], @"friendcodePostEnd",
                                [NSNumber numberWithInt:60], @"friendcodeDeleteStart",
                                [NSNumber numberWithInt:61], @"friendcodeDeleteError",
                                [NSNumber numberWithInt:62], @"friendcodeDeleteEnd",
                                [NSNumber numberWithInt:63], @"imageGetStart",
                                [NSNumber numberWithInt:64], @"imageGetError",
                                [NSNumber numberWithInt:65], @"imageGetEnd",
                                [NSNumber numberWithInt:66], @"productEntriesGetStart",
                                [NSNumber numberWithInt:67], @"productEntriesGetError",
                                [NSNumber numberWithInt:68], @"productEntriesGetEnd",
                                [NSNumber numberWithInt:69], @"userStatusGetStart",
                                [NSNumber numberWithInt:70], @"userStatusGetError",
                                [NSNumber numberWithInt:71], @"userStatusGetEnd",
                                [NSNumber numberWithInt:72], @"productTransactionCommitPutStart",
                                [NSNumber numberWithInt:73], @"productTransactionCommitPutError",
                                [NSNumber numberWithInt:74], @"productTransactionCommitPutEnd",
                                [NSNumber numberWithInt:75], @"balanceGetStart",
                                [NSNumber numberWithInt:76], @"balanceGetError",
                                [NSNumber numberWithInt:77], @"balanceGetEnd",
                                [NSNumber numberWithInt:78], @"priceGetStart",
                                [NSNumber numberWithInt:79], @"priceGetError",
                                [NSNumber numberWithInt:80], @"priceGetEnd",
                                nil];

  NSDictionary* openDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:0], @"rootGetStart",
                                  [NSNumber numberWithInt:1], @"rootGetError",
                                  [NSNumber numberWithInt:2], @"rootGetEnd",
                                  [NSNumber numberWithInt:3], @"oauthRequestTokenGetStart",
                                  [NSNumber numberWithInt:4], @"oauthRequestTokenGetError",
                                  [NSNumber numberWithInt:5], @"oauthRequestTokenGetEnd",
                                  [NSNumber numberWithInt:6], @"oauthAuthorizeUrlLoadStart",
                                  [NSNumber numberWithInt:7], @"oauthAuthorizeUrlLoadError",
                                  [NSNumber numberWithInt:8], @"oauthAuthorizeUrlLoadEnd",
                                  [NSNumber numberWithInt:9], @"oauthAccessTokenGetStart",
                                  [NSNumber numberWithInt:10], @"oauthAccessTokenGetError",
                                  [NSNumber numberWithInt:11], @"oauthAccessTokenGetEnd",
                                  nil];

  NSDictionary* paymentApiDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:0], @"onceAppleIapMenuPostStart",
                                        [NSNumber numberWithInt:1], @"onceAppleIapMenuPostError",
                                        [NSNumber numberWithInt:2], @"onceAppleIapMenuPostEnd",
                                        [NSNumber numberWithInt:3], @"resourcesPurchaseListGetStart",
                                        [NSNumber numberWithInt:4], @"resourcesPurchaseListGetError",
                                        [NSNumber numberWithInt:5], @"resourcesPurchaseListGetEnd",
                                        [NSNumber numberWithInt:6], @"SKProductLoadStart",
                                        [NSNumber numberWithInt:7], @"SKProductLoadError",
                                        [NSNumber numberWithInt:8], @"SKProductLoadEnd",
                                        [NSNumber numberWithInt:9], @"SKPaymentLoadStart",
                                        [NSNumber numberWithInt:10], @"SKPaymentLoadError",
                                        [NSNumber numberWithInt:11], @"SKPaymentLoadEnd",
                                        nil];

  NSDictionary* apiUsageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:0], @"leaderboardEnumeratorStart",
                                      [NSNumber numberWithInt:1], @"leaderboardEnumeratorError",
                                      [NSNumber numberWithInt:2], @"leaderboardEnumeratorEnd",
                                      [NSNumber numberWithInt:3], @"achievementEnumeratorStart",
                                      [NSNumber numberWithInt:4], @"achievementEnumeratorError",
                                      [NSNumber numberWithInt:5], @"achievementEnumeratorEnd",
                                      [NSNumber numberWithInt:6], @"friendEnumeratorStart",
                                      [NSNumber numberWithInt:7], @"friendEnumeratorError",
                                      [NSNumber numberWithInt:8], @"friendEnumeratorEnd",
                                      nil];

  NSDictionary* authorizationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:0], @"getSSOAppIdStart",
                                           [NSNumber numberWithInt:1], @"getSSOAppIdError",
                                           [NSNumber numberWithInt:2], @"getSSOAppIdEnd",
                                           [NSNumber numberWithInt:3], @"getUUIDStart",
                                           [NSNumber numberWithInt:4], @"getUUIDError",
                                           [NSNumber numberWithInt:5], @"getUUIDEnd",
                                           [NSNumber numberWithInt:6], @"registerBySMSwithPhoneNumberStart",
                                           [NSNumber numberWithInt:7], @"registerBySMSwithPhoneNumberError",
                                           [NSNumber numberWithInt:8], @"registerBySMSwithPhoneNumberEnd",
                                           [NSNumber numberWithInt:9], @"registerByIVRwithPhoneNumberStart",
                                           [NSNumber numberWithInt:10], @"registerByIVRwithPhoneNumberError",
                                           [NSNumber numberWithInt:11], @"registerByIVRwithPhoneNumberEnd",
                                           [NSNumber numberWithInt:12], @"upgradeBySMSwithPhoneNumberStart",
                                           [NSNumber numberWithInt:13], @"upgradeBySMSwithPhoneNumberError",
                                           [NSNumber numberWithInt:14], @"upgradeBySMSwithPhoneNumberEnd",
                                           [NSNumber numberWithInt:15], @"upgradeByIVRwithPhoneNumberStart",
                                           [NSNumber numberWithInt:16], @"upgradeByIVRwithPhoneNumberError",
                                           [NSNumber numberWithInt:17], @"upgradeByIVRwithPhoneNumberEnd",
                                           [NSNumber numberWithInt:18], @"confirmRegisterWithPincodeStart",
                                           [NSNumber numberWithInt:19], @"confirmRegisterWithPincodeError",
                                           [NSNumber numberWithInt:20], @"confirmRegisterWithPincodeEnd",
                                           [NSNumber numberWithInt:21], @"confirmUpgradeWithPincodeStart",
                                           [NSNumber numberWithInt:22], @"confirmUpgradeWithPincodeError",
                                           [NSNumber numberWithInt:23], @"confirmUpgradeWithPincodeEnd",
                                           [NSNumber numberWithInt:24], @"updateUserProfileWithNicknameStart",
                                           [NSNumber numberWithInt:25], @"updateUserProfileWithNicknameError",
                                           [NSNumber numberWithInt:26], @"updateUserProfileWithNicknameEnd",
                                           [NSNumber numberWithInt:27], @"revokeStart",
                                           [NSNumber numberWithInt:28], @"revokeError",
                                           [NSNumber numberWithInt:29], @"revokeEnd",
                                           nil];


  NSDictionary* etcDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:0], @"bootupStart",
                                 [NSNumber numberWithInt:1], @"bootupEnd",
                                 nil];

  return [NSDictionary dictionaryWithObjectsAndKeys:
          defaultDictionary, kGreeBenchmarkLogin,
          defaultDictionary, kGreeBenchmarkInvite,
          shareDictionary, kGreeBenchmarkShare,
          defaultDictionary, kGreeBenchmarkRequest,
          paymentDictionary, kGreeBenchmarkPayment,
          paymentDepositDictionary, kGreeBenchmarkPaymentDeposit,
          paymentHistoryDictionary, kGreeBenchmarkPaymentHistory,
          defaultDictionary, kGreeBenchmarkUpgrade,
          defaultDictionary, kGreeBenchmarkLogout,
          dashBoardDictionary, kGreeBenchmarkDashboard,
          dashBoardUmDictionary, kGreeBenchmarkDashboardUm,
          notificationBoardDictionary, kGreeBenchmarkNotificationBoard,
          osDictionary, kGreeBenchmarkOs,
          openDictionary, kGreeBenchmarkOpen,
          paymentApiDictionary, kGreeBenchmarkPaymentApi,
          apiUsageDictionary, kGreeBenchmarkApiUsage,
          authorizationDictionary, kGreeBenchmarkAuthorization,
          etcDictionary, kGreeBenchmarkEtc,
          nil];
}

@end
