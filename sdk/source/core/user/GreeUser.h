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
 * @file GreeUser.h
 * GreeUser class
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeSerializable.h"
#import "GreeEnumerator.h"

/**
 * @brief Describes the user's thumbnail size
 */
typedef enum {
/**
 * @brief Small size: 25x25
 */
  GreeUserThumbnailSizeSmall,
/**
 * @brief Standard size: 48x48
 */
  GreeUserThumbnailSizeStandard,
/**
 * @brief Large size: 76x48
 */
  GreeUserThumbnailSizeLarge,
  GreeUserThumbnailSizeXlarge,
/**
 * @brief Huge size: 190x120
 */
  GreeUserThumbnailSizeHuge
} GreeUserThumbnailSize;

/**
 * @brief Describes the user grade.
 * A user's grade determines what services he/she has access to.  Certain API
 * actions may trigger a prompt asking the user to upgrade.
 */
typedef enum {
/**
 * @brief A lite user has not been associated with a username and password.
 * Lite users have no API restrictions.
 */
  GreeUserGradeLite = 1,
/**
 * @brief A limited user has been registered with a username and password.
 * Limited users have no API restrictions.
 */
  GreeUserGradeLimited = 2,
/**
 * @brief A standard user has been registered with a username and password and has also been verified.
 * Standard users have no API restrictions, thus, the Platform SDK makes no functional distinction 
 * between GreeUserGradeLimited and GreeUserGradeStandard. 
 */
  GreeUserGradeStandard = 3
} GreeUserGrade;

/**
 * @brief The GreeUser interface represents a single user of the Gree Platform.
 *
 * GreeUser also exposes APIs for fetching user-related data: profiles, friends, etc.
 */
@interface GreeUser : NSObject<GreeSerializable>
/**
 * @brief Unique identifier for this user.
 */
@property (nonatomic, readonly, retain) NSString* userId;
/**
 * @brief The nickname of the user.
 */
@property (nonatomic, readonly, retain) NSString* nickname;
/**
 * @brief This user's grade.
 * @see GreeUserGrade
 */
@property (nonatomic, readonly, assign) GreeUserGrade userGrade;
/**
 * @brief User-entered introductory text.
 */
@property (nonatomic, readonly, retain) NSString* aboutMe;
/**
 * @brief This user's birthday.
 */
@property (nonatomic, readonly, retain) NSString* birthday;
/**
 * @brief Gender of this user.
 */
@property (nonatomic, readonly, retain) NSString* gender;
/**
 * @brief Age of this user.
 */
@property (nonatomic, readonly, retain) NSString* age;
/**
 * @brief Blood type of this user.
 */
@property (nonatomic, readonly, retain) NSString* bloodType;
/**
 * @brief User's country of registration. (i.e. US, JP, etc.)
 */
@property (nonatomic, readonly, retain) NSString* region;
/**
 * @brief User's state of registration. (i.e. CA, NM, AZ, NY, etc.)
 */
@property (nonatomic, readonly, retain) NSString* subRegion;
/**
 * @brief This user's local language. (i.e. jpn-Jpan-JP)
 */
@property (nonatomic, readonly, retain) NSString* language;
/**
 * @brief This user's local time zone
 */
@property (nonatomic, readonly, retain) NSString* timeZone;
/**
 * @brief The display name of the user.  Same as nickname.
 */
@property (nonatomic, readonly, retain) NSString* displayName;
/**
 * @brief The URL for user's profile page.
 */
@property (nonatomic, readonly, retain) NSURL* profileUrl;
/**
 * @brief The user hash of the user.  Can be used for incentive services.
 */
@property (nonatomic, readonly, retain) NSString* userHash;
/**
 * @brief The user type of the user.  Standard user is empty string.
 */
@property (nonatomic, readonly, retain) NSString* userType;
/**
 * @brief URL of thumbnail
 * @since 3.3.0
 */
@property (nonatomic, readonly, retain) NSURL* thumbnailUrl;
/**
 * @brief URL of thumbnail (small)
 * @since 3.3.0
 */
@property (nonatomic, readonly, retain) NSURL* thumbnailUrlSmall;
/**
 * @brief URL of thumbnail (large)
 * @since 3.3.0
 */
@property (nonatomic, readonly, retain) NSURL* thumbnailUrlLarge;
/**
 * @brief URL of thumbnail (xlarge)
 * @since 3.3.3
 */
@property (nonatomic, readonly, retain) NSURL* thumbnailUrlXlarge;
/**
 * @brief URL of thumbnail (huge)
 * @since 3.3.0
 */
@property (nonatomic, readonly, retain) NSURL* thumbnailUrlHuge;

/**
 * @brief Check if user registered a nickname
 * @return YES, if user registered a nickname, otherwise NO.
 * @since 3.4.0
 */
-(BOOL)isNicknameRegistered;

/**
 * @brief Register user nickname for lite users only. This nickname registration is allowed once.
 * @param nickname Nickname to register.
 * @param block Invoked when this registration completes.
 * @since 3.4.0
 */
+(void)registerNickName:(NSString*)nickname block:(void (^)(NSError*))block;

/**
 * @brief Load user information for a given userId.
 * @param userId User to load.
 * @param block Invoked when user load completes.
 */
+(void)loadUserWithId:(NSString*)userId block:(void (^)(GreeUser* user, NSError* error))block;

/**
 * @brief Load user information for a given userId.
 * @param userId User to load.
 * @param isLimitedInfo flag for showing full user info or limited. (limited can be used for non-friend/no hasApp users)
 * @param block Invoked when user load completes.
 */
+(void)loadUserWithId:(NSString*)userId isLimitedInfo:(BOOL)isLimitedInfo block:(void (^)(GreeUser* user, NSError* error))block;

/**
 * @brief Load the first page of friends for this user.
 * @param block Invoked when friend loading completes.
 * @return An enumerator object that you can use to fetch more pages of friends, if desired.
 */
-(id<GreeCountableEnumerator>)loadFriendsWithBlock:(void (^)(NSArray* friends, NSError* error))block;

/**
 * @brief Loads the first page of user ids on this user's ignore list.
 * @param block Invoked when ignore list loading completes.
 * @return An enumerator object that you can use to fetch more pages of ignored user ids, if desired.
 */
-(id<GreeEnumerator>)loadIgnoredUserIdsWithBlock:(void (^)(NSArray* ignoredUserIds, NSError* error))block;

/**
 * @brief Loads a user thumbnail image.
 * @param size Size of the thumbnail to load.
 * @param block Invoked when thumbnail image loading completes.
 * @see GreeUserThumbnailSize
 */
-(void)loadThumbnailWithSize:(GreeUserThumbnailSize)size block:(void (^)(UIImage* icon, NSError* error))block;

/**
 * @brief Cancels any outstanding thumbnail loads.
 */
-(void)cancelThumbnailLoad;

/**
 * @brief Determine if the receiver is ignoring a given user.
 * @param ignoredUserId Ignored user to check for.
 * @param block Invoked when the ignore check completes.
 */
-(void)isIgnoringUserWithId:(NSString*)ignoredUserId block:(void (^)(BOOL isIgnored, NSError* error))block;

/**
 * @return @c YES if the receiver has your application, @c NO if not.
 */
-(BOOL)hasThisApplication;

@end
