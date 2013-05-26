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
#import "GreeUser.h"

@class GreeAFHTTPRequestOperation;

extern NSError* MakeGreeError(GreeAFHTTPRequestOperation* operation, NSError* originalError);
extern NSError* MakeGreeErrorIfParametersMissing(NSArray* names, ...);

//Delegate Method define for GreePlatform
@protocol GreeAuthorizationDelegate<NSObject>
//For update access token/secret before authorizeDidFinishWithLogin: method call
-(void)authorizeDidUpdateUserId:(NSString*)userId withToken:(NSString*)token withSecret:(NSString*)secret;
//Login or reAuthorize success
-(void)authorizeDidFinishWithLogin:(BOOL)blogin;
//case1: enable grade 0 user and offline
//case2: enable grade 0 user and user cancelled log-in popup
-(void)authorizeDidFinishWithGrade0:(NSError*)error;
//Logout or when recieving 401
-(void)revokeDidFinish:(NSError*)error;
@end

@class GreeSettings;
@interface GreeAuthorization : NSObject
@property (nonatomic, readonly, getter=accessTokenData) NSString* accessToken;
@property (nonatomic, readonly, getter=accessTokenSecretData) NSString* accessTokenSecret;
@property (nonatomic, retain) NSDictionary* launchOptions;
@property (nonatomic, readonly) BOOL allowUserOptOutOfGREE;

//initialize
-(id)initWithConsumerKey:(NSString*)consumerKey
          consumerSecret:(NSString*)consumerSecret
                settings:(GreeSettings*)settings
                delegate:(id<GreeAuthorizationDelegate>)delegate;

//authorize before login
-(void)authorize;

//revoke after logged in
-(void)revoke;
-(void)directRevoke;

//When recieving 401 this is called
-(void)reAuthorize;

//When needed upgrade this is called
-(void)upgradeWithParams:(NSDictionary*)params
            successBlock:(void (^)(void))successBlock
            failureBlock:(void (^)(void))failureBlock;

//handling openURL
-(BOOL)handleOpenURL:(NSURL*)url;

//handling before authorize
-(BOOL)handleBeforeAuthorize:(NSString*)serviceString;

//check if finishing authorization
-(BOOL)isAuthorized;

//sharedInstance
+(GreeAuthorization*)sharedInstance;

// update user id from GreePlatform
-(void)updateUserIdIfNeeded:(NSString*)userId;


// retrieve (and cache internally) the name of the SSO server app to
// be used henceforth.
-(void)getSSOAppIdWithBlock:(void (^)(NSError*))block;

// retrieve (and cache internally) the UUID
-(void)getUUIDWithBlock:(void (^)(NSError*))block;

// register a new user using the Pincode API
-(void)registerBySMSWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;
-(void)registerByIVRWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;
-(void)confirmRegisterWithPincode:(NSString*)pincode phoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;

// upgrade a grade 1 or 2 user using the Pincode API
-(void)upgradeBySMSWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;
-(void)upgradeByIVRWithPhoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;
-(void)confirmUpgradeWithPincode:(NSString*)pincode phoneNumber:(NSString*)phoneNumber countryCode:(NSString*)countryCode block:(void (^)(NSError*))block;

// complete a user's profile
-(void)updateUserProfileWithNickname:(NSString*)nickname birthday:(NSDate*)birthday block:(void (^)(NSError*))block;

// get currently authorized user's auth bits
#define GreeUserAuthBitsDeviceIdSet    (1U << 0)
#define GreeUserAuthBitsEMailSet       (1U << 1)
#define GreeUserAuthBitsPhoneUIDSet    (1U << 2)
#define GreeUserAuthBitsPhoneNumberSet (1U << 3)
#define GreeUserAuthBitsBirthDaySet    (1U << 4)
#define GreeUserAuthBitsNicknameSet    (1U << 5)
-(void)getUserAuthBitsWithBlock:(void (^)(NSNumber* authBits, NSError* error))block;

// log authorization steps when the user has not logged in yet (for conversion rate)
-(void)logPageName:(NSString*)pageName block:(void (^)(NSError*))block;

// present welcome view controller, unless it is currently presented
-(void)presentWelcomeViewController;

// authorize directly with a desired grade
-(void)directAuthorizeWithDesiredGrade:(GreeUserGrade)grade;

// synchronize the user and device identifiers
-(void)syncIdentifiers;
@end
