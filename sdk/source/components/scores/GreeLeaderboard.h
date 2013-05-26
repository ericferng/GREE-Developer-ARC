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

/**
 * @file GreeLeaderboard.h
 * GreeLeaderboard class
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeSerializable.h"
#import "GreeEnumerator.h"

/**
 * @brief Describes the order in which a leaderboard sorts it's scores.
 */
typedef enum {
/**
 * @brief Scores will be sorted in descending order (high values first).
 */
  GreeLeaderboardSortOrderDescending,
/**
 * @brief Scores will be sorter in ascending order (low values first).
 */
  GreeLeaderboardSortOrderAscending,
} GreeLeaderboardSortOrder;

/**
 * @brief Describes the display format for leaderboard scores.
 */
typedef enum {
/**
 * @brief Scores will be displayed as integer numerals (3, 100, 4000).
 */
  GreeLeaderboardFormatInteger = 0,
/**
 * @brief Scores will be displayed according to time format.
 */
  GreeLeaderboardFormatTime = 2,
} GreeLeaderboardFormat;

/**
 * @brief The GreeLeaderboard interface encapsulates all of the Gree Platform's leaderboard functionality.
 * 
 * A leaderboard is a collection of scores in a single category of your application (i.e. highest score.)
 * Leaderboards are defined on the GREE developer website. You can use the GreeLeaderboard interface to
 * load leaderboard details. For details about how your users can populate your leaderboards with data, 
 * please see GreeScore.
 *
 * @see GreeScore.h
 */
@interface GreeLeaderboard : NSObject<GreeSerializable>

/**
 * @brief The unique identifier for this leaderboard.
 */
@property (nonatomic, retain, readonly) NSString* identifier;
/**
 * @brief The leaderboard name as entered on the developer dashboard.
 */
@property (nonatomic, retain, readonly) NSString* name;
/**
 * @brief Determines how score values in this leaderboard are displayed.
 * @see GreeLeaderboardFormat
 */
@property (nonatomic, assign, readonly) GreeLeaderboardFormat format;
/**
 * @brief A suffix appended to the display string for each of this leaderboard's scores.
 */
@property (nonatomic, retain, readonly) NSString* formatSuffix;
/**
 * @brief The number of decimal places to display.
 */
@property (nonatomic, assign, readonly) NSInteger formatDecimal;
/**
 * @brief The format of time.
 * @note
 * <table>
 * <tr><th>value</th><th>description</th></tr>
 * <tr><td>second</td><td>The format of time is "second".</td></tr>
 * <tr><td>minute</td><td>The format of time is "minute".</td></tr>
 * <tr><td>hour</td><td>The format of time is "hour".</td></tr>
 * </table>
 * @since 3.3.1
 */
@property (nonatomic, retain, readonly) NSString* timeFormat;
/**
 * @brief Determines how score values are sorted.
 * @see GreeLeaderboardSortOrder
 */
@property (nonatomic, assign, readonly) GreeLeaderboardSortOrder sortOrder;
/**
 * @brief Determines if a user can post scores worse than they already posted.
 */
@property (nonatomic, assign, readonly) BOOL allowWorseScore;
/**
 * @brief Determines leaderboard visibility. @c NO means the leaderboard is visible, @c YES means it is not.
 */
@property (nonatomic, assign, readonly) BOOL isSecret;

/**
 * @brief Loads the first page of leaderboard for your application.
 * @param block Invoked when loading is complete with an array of leaderboards and, potentially, an error.
 * @return An enumerator object that you can use to fetch more pages of leaderboards, if applicable.
 */
+(id<GreeEnumerator>)loadLeaderboardsWithBlock:(void (^)(NSArray* leaderboards, NSError* error))block;

/**
 * @brief Load the leaderboard icon.
 * @param block Invoked when the icon loading is complete with a UIImage and, potentially, an error.
 */
-(void)loadIconWithBlock:(void (^)(UIImage* image, NSError* error))block;

/**
 * @brief Cancel any outstanding icon load.
 */
-(void)cancelIconLoad;

@end
