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
 * @file GreeScore.h
 * GreeScore class
 */

#import <Foundation/Foundation.h>
#import "GreeWriteCacheable.h"
#import "GreeSerializable.h"
#import "GreeEnumerator.h"

@class GreeUser;
@class GreeLeaderboard;

/**
 * @brief A sentinel representing an unranked score.
 */
extern int64_t GreeScoreUnranked;

/**
 * @brief Describes the time period filters available when loading lists of scores.
 */
typedef enum {
/**
 * @brief Score lists will include only the most recent day's scores.
 */
  GreeScoreTimePeriodDaily,
/**
 * @brief Score lists will include only the most recent week's scores.
 */
  GreeScoreTimePeriodWeekly,
/**
 * @brief Score lists are not restricted to a particular time period.
 */
  GreeScoreTimePeriodAlltime,
} GreeScoreTimePeriod;

/**
 * @brief Describes the people filter availab when loading lists of scores.
 */
typedef enum {
/**
 * @brief Score lists will only include the current user's score
 */
  GreePeopleScopeSelf,
/**
 * @brief Score lists will only include scores of the current user's friends.
 */
  GreePeopleScopeFriends,
/**
 * @brief Score lists will include scores from everyone.
 */
  GreePeopleScopeAll,
} GreePeopleScope;

/**
 * @brief The GreeScore interface encapsulates all of the Gree Platform's score functionality.
 *
 * A score is a single play of a game for a given user (i.e. time to complete track 1, number of points
 * accumulated on level 2.)
 */
@interface GreeScore : NSObject<GreeWriteCacheable, GreeSerializable>

/**
 * @brief The user who submitted this score.
 */
@property (nonatomic, retain, readonly) GreeUser* user;
/**
 * @brief The integral score value.
 * @note This value will be in seconds for all scores read from leaderboards with GreeLeaderboardFormatTime. 
 */
@property (nonatomic, assign, readonly) int64_t score;
/**
 * @brief The leaderboardId that this score is a member of.
 */
@property (nonatomic, retain, readonly) NSString* leaderboardId;
/**
 * @brief The score's rank.
 * @note The rank is not set for scores created with initWithLeaderboard:score:.
 */
@property (nonatomic, assign, readonly) int64_t rank;

/** 
 * @brief Initializes a new score for submission to the given leaderboard.
 * @note This is the designated initializer.
 * @param leaderboardId The identifier for the GreeLeaderboard to which you are submitting this score.
 * @param score The integral score value.  Units for this value are defined on the developer center.
 */
-(id)initWithLeaderboard:(NSString*)leaderboardId score:(int64_t)score;

/**
 * Loads the current user's score for a given leaderboard.
 * @param leaderboardId The leaderboard to load scores from.
 * @param timePeriod Time period over which to load scores.
 * @param block Invoked when loading is complete.
 */
+(void)loadMyScoreForLeaderboard:(NSString*)leaderboardId
                      timePeriod:(GreeScoreTimePeriod)timePeriod
                           block:(void (^)(GreeScore* score, NSError* error))block;

/**
 * Loads the top scores for a given leaderboard.
 * @param leaderboardId The leaderboard from which to load scores.
 * @param timePeriod Time period over which to load scores.
 * @param block Invoked when loading is complete.
 * @return An enumerator that can be used to page through all of the scores on the leaderboard.
 */
+(id<GreeEnumerator>)loadTopScoresForLeaderboard:(NSString*)leaderboardId
                                      timePeriod:(GreeScoreTimePeriod)timePeriod
                                           block:(void (^)(NSArray* scoreList, NSError* error))block;

/**
 * Loads the top scores of the current user's friends for a given leaderboard.
 * @param leaderboardId The leaderboard from which to load scores.
 * @param timePeriod Time period over which to load scores.
 * @param block Invoked when loading is complete.
 * @return An enumerator that can be used to page through all of the user's friends scores on the leaderboard.
 */
+(id<GreeEnumerator>)loadTopFriendScoresForLeaderboard:(NSString*)leaderboardId
                                            timePeriod:(GreeScoreTimePeriod)timePeriod
                                                 block:(void (^)(NSArray* scoreList, NSError* error))block;

/**
 * @return An enumerator that can be used to page through scores on a leaderboard.
 * @param leaderboardId The leaderboard from which to load scores from.
 * @param timePeriod Time period over which to load scores.
 * @param peopleScope Scope defining which user's scores to include.
 */
+(id<GreeEnumerator>)scoreEnumeratorForLeaderboard:(NSString*)leaderboardId
                                        timePeriod:(GreeScoreTimePeriod)timePeriod
                                       peopleScope:(GreePeopleScope)peopleScope;

/**
 * Submit this score to its associated leaderboard for the current user.
 * @param block Invoked when the submission operation has completed.
 */
-(void)submitWithBlock:(void (^)(void))block;

/**
 * Delete the user's score from the given leaderboard.  Intended for testing purposes only.
 * @note This will also remove any scores queued for later submission.
 */
+(void)deleteMyScoreForLeaderboard:(NSString*)leaderboardId withBlock:(void (^)(NSError* error))block;

/**
 * @brief Assign a response block for the GameCenter score submission.
 *
 * Scores will be submitted to GameCenter upon -(void)submit if the setting
 * @c GreeSettingGameCenterLeaderboardMapping was provided with a valid mapping
 * between this score's leaderboard identifier and its corresponding GameCenter
 * identifier.
 *
 * @see GreePlatformSettings.h
 */
-(void)setGameCenterResponseBlock:(void (^)(NSError*))responseBlock;

/**
 * Access a formatted string version of the receiver within the context of a 
 * given leaderboard suitable for display.
 *
 * @param leaderboard The leaderboard used to format the score.
 *
 * @note  Leaderboard may be nil, meaning the returned string will lack any
 *        format suffix.
 */
-(NSString*)formattedScoreWithLeaderboard:(GreeLeaderboard*)leaderboard;

@end
