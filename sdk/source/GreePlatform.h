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

/**
 * @file GreePlatform.h
 * GreePlatform Core Interface
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeWidget.h"
#import "GreeBadgeValues.h"
#import "GreeDeprecation.h"
#import "GreeUser.h"

@class GreePlatform;
@class GreeHTTPClient;
@class GreeWidget;
@class GreeNetworkReachability;

extern NSString* const GreeHTTPResponseMessageKey;

/**
 * The GreePlatformDelegate protocol declares methods that should be implemented by the delegate of the 
 * GreePlatform object. These methods are invoked when the Gree Platform needs to notify your application
 * about important events that occur with regards to the Gree Platform and it's interaction with your 
 * application. Such events include user state changes (login, logout), modal views, etc.
 */
@protocol GreePlatformDelegate<NSObject>
@required
/**
 * Sent to the receiver when Gree will show a modal view (dashboard, login dialogs,
 * etc.) that will interrupt your application.
 * @note It is recommended that you suspend your application logic here.
 */
-(void)greePlatformWillShowModalView:(GreePlatform*)platform;
/**
 * Sent to the receiver when Gree has dismissed a modal view (dashboard, login dialogs,
 * etc.) that was interrupting your application.
 * @note It is recommended that you resume your application logic here.
 */
-(void)greePlatformDidDismissModalView:(GreePlatform*)platform;
/**
 * Sent to the receiver when your application's user logs in to the Gree Platform.
 */
-(void)greePlatform:(GreePlatform*)platform didLoginUser:(GreeUser*)localUser;
/**
 * Sent to the receiver when your application's user logs out of the Gree Platform.
 */
-(void)greePlatform:(GreePlatform*)platform didLogoutUser:(GreeUser*)localUser;
/**
 @brief Notifies the parameter received when an application starts.
 @param params Parameter received when an application starts.
 */
-(void)greePlatformParamsReceived:(NSDictionary*)params;
@optional
/**
 @brief Sent to the receiver when the localUser property in GreePlatform has been updated.
 @see GreePlatform::localUser
 */
-(void)greePlatform:(GreePlatform*)platform didUpdateLocalUser:(GreeUser*)localUser;
@end

/**
 @brief Core interface for the Gree Platform SDK
 @see GreePlatformDelegate
 */
@interface GreePlatform : NSObject

/**
 * @brief Initialize the Gree SDK
 * @note This must be invoked before any other SDK operations can be performed.
 * @param applicationId   Unique application identifier from the Gree developer dashboard.
 * @param consumerKey     Consumer key for your application available on the Gree developer dashboard.
 * @param consumerSecret  Consumer secret for your application available on the Gree developer dashboard.
 * @param settings        Dictionary of setting values to configure the Gree Platform.
 * @param delegate        Delegate for important global platform events that should be handled by your application.
 */
+(void)initializeWithApplicationId:(NSString*)applicationId
                       consumerKey:(NSString*)consumerKey
                    consumerSecret:(NSString*)consumerSecret
                          settings:(NSDictionary*)settings
                          delegate:(id<GreePlatformDelegate>)delegate;

/**
 * @brief Shutdown the Gree Platform.
 * @note After invoking this no platform operations can be performed until the re-initialized.
 */
+(void)shutdown;

/**
 * @return The shared GreePlatform instance.
 */
+(GreePlatform*)sharedInstance;

/**
 * @return A string representation of the current version of the sdk.
 */
+(NSString*)version;

/**
 * @return A string representation of the current build of the sdk.
 */
+(NSString*)build;

/**
 * @brief Start Authorization, available since GreePlatformSDK v3.2.0
 * @since 3.2.0
 *
 * @param block Block will be invoked after authorization completes in all cases:
 * Online, offline, logged in, failure, etc, and the block will be invoked with 
 * local user and an NSError.
 *
 * @note The local user will be NIL in the following two cases if your app enables grade 0 user.
 * @see GreeErrorCodeAuthorizationFailWithOffline
 * @see GreeErrorCodeAuthorizationCancelledByUser
 */
+(void)authorizeWithBlock:(void (^)(GreeUser* localUser, NSError* error))block;

/**
 * @brief Try to authorize the user with the specified grade, with no UI interaction.
 * @since 3.4.0
 *
 * @param grade Desired user grade. User might have a different grade.
 * @param block Block to be invoked when the authorization completes.
 * @see GreePlatform::authorizeWithBlock
 */
+(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade block:(void (^)(GreeUser* localUser, NSError* error))block;

/**
 * @brief Remove any authorization token, effectively logging out the user, available since GreePlatformSDK v3.4.0
 * @since 3.4.0
 *
 * @param block Block will be invoked after revoke completes and will be invoked with
 * an NSError.
 */
+(void)directRevokeAuthorizationWithBlock:(void (^)(NSError* error))block;

/**
 * @brief Remove any authorization token and relogin.
 * @since 3.2.0
 *
 * @param block Block will be invoked after revoke completes and will be invoked with 
 * an NSError.
 */
+(void)revokeAuthorizationWithBlock:(void (^)(NSError* error))block;

/**
 @return Returns YES if authorization has been done (login has been done by calling the @ref authorize method).
 */
+(BOOL)isAuthorized;

/**
 * @brief Upgrade user to target grade
 * @param params          Dictionary of values to upgrade. The minimum required is to set "target_grade".
 *                        ex. [NSDictionary dictionaryWithObject:@"2" forKey:@"target_grade"]
 * @param successBlock    block for notification of updrade success.
 * @param failureBlock    block for notification of updrade failure.
 */
+(void)upgradeWithParams:(NSDictionary*)params
            successBlock:(void (^)(void))successBlock
            failureBlock:(void (^)(void))failureBlock;

/**
 * @brief provide accessToken
 */
-(NSString*)accessToken;

/**
 * @brief provide accessTokenSecret
 */
-(NSString*)accessTokenSecret;

/**
 * @brief print encrypted consumerKey and consumerSecret to console
 * @param consumerKey      Raw consumerKey.
 * @param consumerSecret   Raw consumerSecret.
 */
+(void)printEncryptedStringWithConsumerKey:(NSString*)consumerKey
                            consumerSecret:(NSString*)consumerSecret
                                  scramble:(NSString*)scramble;

/**
 * @brief set scramble for encrypted consumerKey and consumerSecret
 * @param scramble         encryption key.
 */
+(void)setConsumerProtectionWithScramble:(NSString*)scramble;

/**
 * Set the interface orientation for all Gree views to present in.
 * @see GreeSettingInterfaceOrientation
 */
+(void)setInterfaceOrientation:(UIInterfaceOrientation)orientation;

/**
 * You should invoke this method in your UIApplicationDelegate's
 * -(void)application:handleOpenURL: method.
 * @param url The URL to handle
 */
+(BOOL)handleOpenURL:(NSURL*)url application:(UIApplication*)application;

/**
 * @brief Sign a request
 *
 * Use OAuth to sign the request with the client application key/secret or the user access token if logged in.
 * @param request   The NSMutableURLRequest object to be signed.
 * @param param     A dictionary containing any parameters that should be included in the signature.
 * 
 */
-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)params;

/**
 * @return The gree application URL scheme string. For example, @@"greeapp12345".
 */
+(NSString*)greeApplicationURLScheme;

/**
 * @return The local user object representing the currently authenticated Gree user. 
 * @see GreePlatformDelegate::greePlatform:didUpdateLocalUser:
 */
@property (nonatomic, retain, readonly) GreeUser* localUser;

/**
 * @return The local user id string representing the currently authenticated Gree user. 
 */
@property (nonatomic, copy, readonly) NSString* localUserId;

/**
 * This method should be called from within UIApplicationDelegate didRegisterForRemoteNotificationsWithDeviceToken:.
 * Failure to call this will prevent push notifications from succeeding.
 * @param deviceToken NSData object passed into NSApplicationDelegate didRegisterForRemoteNotificationsWithDeviceToken:.
 * @param block A block that will be executed when the token is ready, may contain an error if the server didn't accept the token
 */
+(void)postDeviceToken:(NSData*)deviceToken block:(void (^)(NSError* error))block;

/**
 * This method should be called from UIApplicationDelegate in didReceiveRemoteNotification: or
 * application:didFinishLaunchingWithOptions:. The BOOL value indicates whether or not the notification will
 * launch the game notification board.
 * @param notificationDictionary Pass in the value received from UIApplicationDelegate didReceiveRemoteNotification:.
 */
+(BOOL)handleRemoteNotification:(NSDictionary*)notificationDictionary application:(UIApplication*)application;

/**
 * This method should be called from UIApplicationDelegate in didReceiveLocalNotification: when you use the Local Notification feature in the SDK.
 * @param notification dictionary is passed from UIApplicationDelegate didReceiveLocalNotification
 */
+(void)handleLocalNotification:(UILocalNotification*)notification application:(UIApplication*)application;

/**
 * @brief This method gives the SDK a chance to handle local and remote notifications.
 * @param launchOptions Pass the didFinishLaunchingWithOptions: argument of the application:didFinishLaunchingWithOptions:.
 * @param application Pass the application parameter of the application:didFinishLaunchingWithOptions: method.
 * @note Be sure to call this method in application:didFinishLaunchingWithOptions: of your application.
 * @note Call this method after calling the @ref GreePlatform::authorize method.
 */
+(void)handleLaunchOptions:(NSDictionary*)launchOptions application:(UIApplication*)application;

/**
 * This method will update the notification badges to the latest values.
 * @param block A callback block which passes the value of the most recent badge update.
 */
-(void)updateBadgeValuesWithBlock:(void (^)(GreeBadgeValues* badgeValues))block;

/**
 * A property containing the most recently updated values of the notification badges.
 */
@property (nonatomic, retain, readonly) GreeBadgeValues* badgeValues;

/**
 @brief Shared GreeNetworkReachability instance.
 @see GreeNetworkReachability
 @since 3.2.0
 */
-(GreeNetworkReachability*)reachability;

/**
 * Show no internet connection alert. It is like Android's Toast Notification.
 @since 3.2.0
 */
-(void)showNoConnectionModelessAlert;

@end

