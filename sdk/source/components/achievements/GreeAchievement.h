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
 * @file GreeAchievement.h
 * GreeAchievement class
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeWriteCacheable.h"
#import "GreeSerializable.h"
#import "GreeEnumerator.h"

/**
 * @brief The GreeAchievement interface encapsulates all of the Gree Platform's achievement functionality.
 *
 * An achievement is a discrete accomplishment made by the user in your application (i.e. beating level 3.)
 * Achievements and their details are pre-defined and created on the GREE developer website.  It is your
 * responsibility to unlock the achievement at a particular point in your application once the user has
 * earned it.
 */
@interface GreeAchievement : NSObject<GreeWriteCacheable, GreeSerializable>

/**
 * @brief The unique identifier for this achievement in your application.
 */
@property (nonatomic, retain, readonly) NSString* identifier;
/**
 * @brief The achievement name as entered on the developer dashboard.
 */
@property (nonatomic, retain, readonly) NSString* name;
/**
 * @brief The achievement description as entered on the developer dashboard.
 */
@property (nonatomic, retain, readonly) NSString* descriptionText;
/**
 * @brief Indicates the achievement only appears after it is unlocked.
 */
@property (nonatomic, assign, readonly) BOOL isSecret;
/**
 * @brief The score value for this achievement.
 */
@property (nonatomic, assign, readonly) NSInteger score;
/**
 * @brief The achievement state. @c YES if unlocked, @c NO if locked.
 */
@property (nonatomic, assign, readonly) BOOL isUnlocked;

/**
 * @brief Initializes a new achievement for submission with the given identifier.
 * @note This is the designated initializer.
 * @note The returned achievement will only have it's identifier field filled out.
 */
-(id)initWithIdentifier:(NSString*)identifier;

/**
 * Loads the first page of achievements for your application.  Achievement state will
 * be set according to the current user.
 * @param block Invoked when loading is complete.
 * @return An enumerator that can be used to page through all of the achievements.
 */
+(id<GreeEnumerator>)loadAchievementsWithBlock:(void (^)(NSArray* achievements, NSError* error))block;

/**
 * @brief Load the achievement icon.
 * @note The icon loaded will depend on the current unlock state. 
 */
-(void)loadIconWithBlock:(void (^)(UIImage* image, NSError* error))block;

/**
 * @brief Cancel any outstanding icon load.
 */
-(void)cancelIconLoad;

/**
 * @brief Unlock this achievement
 * @param block Invoked when unlock operation has completed.
 */
-(void)unlockWithBlock:(void (^)(void))block;

/**
 * @brief Relock this achievement.
 * @param block Invoked when relock operation has completed.
 * @note This is intended solely for testing purposes and should not be used in release code
 */
-(void)relockWithBlock:(void (^)(void))block;

/**
 * @brief Assign a response block for the GameCenter achievement unlock.
 *
 * Achievements will be submitted to GameCenter upon -(void)unlock if the setting
 * @c GreeSettingGameCenterAchievementMapping was provided with a valid mapping
 * between this achievement identifier and its corresponding GameCenter identifier.
 *
 * @see GreePlatformSettings.h
 */
-(void)setGameCenterResponseBlock:(void (^)(NSError* error))responseBlock;

@end
