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
 @file 

 Provides the definitions related to the parameter to start the dashboard.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */

#import <Foundation/Foundation.h>

/**
 This key is used as a parameter to start the dashboard when specifying an application ID.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardAppId;
/**
 This key is used as a parameter to start the dashboard when specifying a user ID.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardUserId;
/**
 This key is used as a parameter to start the dashboard when specifying a leader board ID.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardLeaderboardId;
/**
 This key is used as a parameter to start the dashboard when specifying a Community ID.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardCommunityId;
/**
 This key is used as a parameter to start the dashboard when specifying a Thread ID of a community.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardThreadId;
/**
 This key is used as a parameter to start the dashboard when specifying a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardMode;
/**
 This key is used as a parameter to start the dashboard when specifying the GameDashboard front as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeTop;
/**
 This key is used as a parameter to start the dashboard when specifying the ranking list as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeRankingList;
/**
 This key is used as a parameter to start the dashboard when specifying the ranking details (user list for a particular ranking) as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeRankingDetails;
/**
 This key is used as a parameter to start the dashboard when specifying the achievement list as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeAchievementList;
/**
 This key is used as a parameter to start the dashboard when specifying the playing user/friend list as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeUsersList;
/**
 This key is used as a parameter to start the dashboard when specifying the application setting as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeAppSetting;
/**
 This key is used as a parameter to start the dashboard when specifying a friend invitation as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeUsersInvites;
/**
 This key is used as a parameter to start the dashboard when specifying a community as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 */
extern NSString* const GreeDashboardModeCommunity;
/**
 This key is used as a parameter to start the dashboard when specifying a user profile as a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 @since 3.3.0
 */
extern NSString* const GreeDashboardModeUserProfile;
/**
 This key is used as a parameter to start the dashboard when specifying a user notification a dashboard mode.
 @see UIViewController(GreePlatform)::presentGreeDashboardWithParameters:animated:
 @since 3.3.3
 */
extern NSString* const GreeDashboardModeGameNotice;
