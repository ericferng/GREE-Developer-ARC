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

#import <Foundation/Foundation.h>

@class GreeSettings;
@class GreeUser;

/**
 * @brief Adopting this protocol allows a given class to be initialized as a component in GreePlatform.
 * @since 3.2.0
 */
@protocol GreePlatformComponent<NSObject>
@required

/**
 * Creates and returns an autoreleased instance of the receiver class.
 * @since 3.2.0
 */
+(id)componentWithSettings:(GreeSettings*)settings;

@optional
/**
 * @brief Components that implement this can respond to remote notifications.
 * @since 3.2.0
 *
 * GreePlatform will call this on the component instance when it receives a remote notification on its delegate method.  
 */
-(void)handleRemoteNotification:(NSDictionary*)notificationDictionary;

/**
 * @brief Components implement this method if they want to clean up.
 * @since 3.2.0
 *
 * GreePlatform will call this on the component instance before it is removed from the component instance dictionary.  
 */
-(void)willRemoveComponentFromPlatform;

/**
 * GreePlatform will call this on the component instance when the user logs in.  
 * @since 3.2.0
 */
-(void)userLoggedIn:(GreeUser*)user;

/**
 * GreePlatform will call this on the component instance when the user logs out.  
 * @since 3.2.0
 */
-(void)userLoggedOut:(GreeUser*)user;
@end
