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

/**
   NSNotifications that can be sent by the GreePlatform subsystems.
 */


/*
   GreeNotificationKeyUser:  userdata key for the login user
 */
extern NSString* const GreeNSNotificationKeyUser;
/*
   GreeNotificationKey userdata key for revalidation
 */
extern NSString* const GreeNSNotificationKeyRequest;

/**
   Notification sent when a user logs into the system
   The GreeUser record will be in the userdata under the key GreeNotificationKeyUser
 */
extern NSString* const GreeNSNotificationUserLogin;
/**
   Notification sent when a user is invalidated by the server
   This generally happens when the user upgrades to a more secure verification
 */
extern NSString* const GreeNSNotificationUserInvalidated;
/**
   Notification sent when a user failed to login due to network or server error
 */
extern NSString* const GreeNSNotificationUserLoginError;
/**
   Notification sent when a user logs out
 */
extern NSString* const GreeNSNotificationUserLogout;
/**
   Notification sent when revalidation is required by the server
   The object in GreeNSNotificationKeyRequest should be sent to GreeHTTPClient's resubmit if
   proper authorization can be found.  Otherwise call resubmissionFailed
 */
extern NSString* const GreeNSNotificationRequestNeedsRevalidation;
