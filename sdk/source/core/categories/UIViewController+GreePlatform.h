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
 * @file UIViewController+GreePlatform.h
 * The GreePlatform category on UIViewController exposes methods for
 * managing the display of GREE platform views such as the dashboard,
 * notification board, widget, and popups.
 */

#import <UIKit/UIKit.h>
#import "GreeWidget.h"
#import "GreeDeprecation.h"

@class GreePopup;

/**
 * Enumeration for the available default views for presenting the
 * notification board.
 */
typedef enum {
  /**
   * Notification board will display notifications specific to the 
   * current game by default.
   */
  //#indocEnd "GreeNotificationBoardTypeGame" en
  GreeNotificationBoardTypeGame,
  /**
   * Notification board will display notifications for the GREE
   * social network (such as friend requests) by default.
   */
  GreeNotificationBoardTypeSNS
} GreeNotificationBoardType;

/**
 @brief Value defined for specifying a unique UIViewController to be displayed by SDK.
 @since 3.2.0
 
 This value is included as userInfo in the @ref GreeNSNotificationKeyWillOpenNotification or the @ref GreeNSNotificationKeyDidCloseNotification notification received by an App.
 This value is used for showing which UIViewController has opened/closed.
 
 @see GreeNSNotificationKeyWillOpenNotification
 @see GreeNSNotificationKeyDidCloseNotification
 */
typedef enum {
  GreeViewControllerTypeSDK                       = 0x0000,
  /**
   @brief Shows that the notifier is the Dashboard.
   @since 3.2.0
   */
  GreeViewControllerTypeDashboard                 = GreeViewControllerTypeSDK + 0,
  /**
   @brief Shows that the notifier is the notification board.
   @since 3.2.0
   */
  GreeViewControllerTypeNotificationBoard         = GreeViewControllerTypeSDK + 1,
  /**
   @brief Shows that the notifier is Invite Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeInvitePopup               = GreeViewControllerTypeSDK + 2,
  /**
   @brief Shows that the notifier is Share Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeSharePopup                = GreeViewControllerTypeSDK + 3,
  /**
   @brief Shows that the notifier is Request Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeRequestPopup              = GreeViewControllerTypeSDK + 4,
  /**
   @brief Shows that the notifier is Authorization Popup (log-in, log-out, or upgrade).
   @since 3.2.0
   */
  GreeViewControllerTypeAuthorizationPopup        = GreeViewControllerTypeSDK + 5,
  /**
   @brief Shows that the notifier is Payment Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeWalletPaymentPopup        = GreeViewControllerTypeSDK + 6,
  /**
   @brief Shows that the notifier is Deposit Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeWalletDepositPopup        = GreeViewControllerTypeSDK + 7,
  /**
   @brief Shows that the notifier is Deposit History Popup.
   @since 3.2.0
   */
  GreeViewControllerTypeWalletDepositHistoryPopup = GreeViewControllerTypeSDK + 8,
  /**
   @brief Shows that the notifier is other UIViewController.
   @since 3.2.0
   */
  GreeViewControllerTypeOther                     = 0x1000,
} GreeViewControllerType;

/**
 * The GreePlatform category on UIViewController is your primary interface
 * for managing GREE platform views.
 */
@interface UIViewController (GreePlatform)

/**
 * Present the GREE dashboard with the page of specified URL from the receiver. 
 *
 * @since 3.5.0
 * @param url       The URL of a page to display in GREE dashboard.
 * @param animated  Animate the presentation if @c YES is specified.
 */
-(void)presentGreeDashboardWithURL:(NSURL*)url animated:(BOOL)animated;
/**
 @brief Present the GREE dashboard modally from the receiver.

 @param parameters  Parameters to initialize the GREE dashboard. nil is acceptable.
 @param animated    Animate the presentation if @c YES is specified.

 @note GreePlatformDelegate's greePlatformWillShowModalView will be invoked if necessary
 
 @c The following keys and their values can be specified for parameters. Other keys will be ignored.
 
 @par GameDashboard front
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeTop.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Ranking list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeRankingList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Ranking details (User list for a particular ranking)
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeRankingDetails.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 <tr><td>@ref GreeDashboardLeaderboardId</td><td>Leader board ID</td><td>Mandatory</td></tr>
 </table>
 
 @par Achievement list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeAchievementList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Playing user/Friend list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeUsersList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 </table>
 
 @par Application setting
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeAppSetting.</td></tr>
 </table>
 
 @par Friend invitation
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeUsersInvites.</td></tr>
 </table>

 @par Community
 @since 3.3.0
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeCommunity.</td></tr>
 <tr><td>@ref GreeDashboardCommunityId</td><td>Community ID</td><td>Optional (If this key is not specified, transition to the community list top.)</td></tr>
 <tr><td>@ref GreeDashboardThreadId</td><td>Thread ID</td><td>Optional (If this key is not specified, transition to the community top.)</td></tr>
 </table>

 @par User profile
 @since 3.3.0
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeUserProfile.</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Required</td></tr>
 </table>
 */
-(void)presentGreeDashboardWithParameters:(NSDictionary*)parameters animated:(BOOL)animated;
/**
 * Present the GREE notification board modal from the receiver.
 *
 * @deprecated in 3.3.3
 * @param type      Determines the default notifiaction board view.
 * @param animated  Animate the presentation if @c YES is specified.
 *
 * @note This method is deprecated in GreePlatformSDK v3.3.3, use presentGreeDashboardWithParameters:parameters.
 * @code
 NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
 GreeDashboardModeGameNotice, GreeDashboardMode,
 nil];
 [viewController presentGreeDashboardWithParameters:parameters animated:YES];
 * @endcode
 */
-(void)presentGreeNotificationBoardWithType:(GreeNotificationBoardType)type animated:(BOOL)animated GREEPLATFORM_DEPRECATED;
/**
 * Dismiss any GREE dashboard or notification board presented from the receiver.
 *
 * @param animated  Animate the dismissal if @c YES is specified.
 */
-(void)dismissActiveGreeViewControllerAnimated:(BOOL)animated;

/**
 * Show a GREE popup view modally from the receiver.
 *
 * @param popup  An instance of GreePopup to be displayed.
 *
 * @see GreePopup
 *
 * @note GreePopup display will always be animated.
 */
-(void)showGreePopup:(GreePopup*)popup;
/**
 * Dismiss any GREE popup view being shown from the reeiver.
 */
-(void)dismissGreePopup;

/**
 * Show the GREE in-game widget in the receiver's view.
 * @param dataSource The widget's data source to provide screenshot image data.
 * @note If you pass in nil, there will be NO screenshot button on this widget.
 * @see GreeWidget
 */
-(void)showGreeWidgetWithDataSource:(id<GreeWidgetDataSource>)dataSource;

/**
 * Removes the GREE in-game widget being shown in the receiver's view.
 * @note This method has no effect if there is no displayed widget.
 */
-(void)hideGreeWidget;
/**
 * Accessor for the GREE in-game widget shown in the receiver's view.
 * @note This method will return nil if you hide the widget.
 */
-(GreeWidget*)activeGreeWidget;

@end
