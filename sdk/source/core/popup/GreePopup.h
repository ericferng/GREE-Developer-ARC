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
 * @file GreePopup.h
 * @brief Provides an API to display the pop-up.
 */

#import <UIKit/UIKit.h>
#import "GreeIncentive.h"
#import "GreeDeprecation.h"

/**
 * @brief NSNotification is called before displaying the pop-up. 
 */
extern NSString* const GreePopupWillLaunchNotification;
/**
 * @brief NSNotification is called after displaying the pop-up.
 */
extern NSString* const GreePopupDidLaunchNotification;
/**
 * @brief NSNotification is called before closing the pop-up. 
 */
extern NSString* const GreePopupWillDismissNotification;
/**
 * @brief NSNotification is called after closing the pop-up. 
 */
extern NSString* const GreePopupDidDismissNotification;

/**
 * @internal
 * @brief Action string for the Invite Popup. For internal implementation.
 */
extern NSString* const GreePopupInviteAction;
/**
 * @internal
 * @brief Action string for the Share Service Popup. For internal implementation.
 */
extern NSString* const GreePopupShareAction;
/**
 * @internal
 * @brief Action string for the Request Service Popup. For internal implementation.
 */
extern NSString* const GreePopupRequestServiceAction;

/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupTitle;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupBody;
/**
 @brief Will be ignored.
 @deprecated in 3.6.0
 */
extern NSString* const GreeRequestServicePopupImageURL GREEPLATFORM_DEPRECATED;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupRedirectURL;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupAttributes;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupListType;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupToUserId;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupExpireTime;

/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup when using GreeRequestServicePopupListType.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupListTypeAll;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup when using GreeRequestServicePopupListType.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupListTypeJoined;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup when using GreeRequestServicePopupListType.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupListTypeNotJoined;
/**
 @brief Will be used as a key of the @ref parameters property of GreeRequestServicePopup when using GreeRequestServicePopupListType.
 @see See the description about GreeRequestServicePopup.
 */
extern NSString* const GreeRequestServicePopupListTypeSpecified;

@class GreePopupView;
@class GreePopup;

/**
 * Describes the block signature for all GreePopup callback blocks.
 * @param aSender GreePopup instance.
 */
typedef void (^GreePopupBlock)(GreePopup* aSender);

/**
 * @brief The GreePopup class provides an API to display pop-ups for various Gree Platform services.
 *
 * GreePopup should not be used directly; rather, each service will define it's own subclass. Examples 
 * include GreeSharePopup, GreeRequestPopup, etc.
 */
@interface GreePopup : UIViewController
/**
 * @internal
 * @brief Server action for this popup.
 */
@property (copy) NSString* action;
/**
 * @brief Optional parameter dictionary. 
 */
@property (retain) NSDictionary* parameters;
/**
 * @brief Results dictionary.
 * @note Not all popup actions have results.
 */
@property (retain) NSDictionary* results;
/**
 * @brief Invoked when the user cancels this popup.
 */
@property (copy) GreePopupBlock cancelBlock;
/**
 * @brief Invoked when the popup completes successfully.
 */
@property (copy) GreePopupBlock completeBlock;
/**
 * @brief Invoked before the popup appears.
 */
@property (copy) GreePopupBlock willLaunchBlock;
/**
 * @brief Invoked after the popup appears.
 */
@property (copy) GreePopupBlock didLaunchBlock;
/**
 * @brief Invoked before the popup disappears.
 */
@property (copy) GreePopupBlock willDismissBlock;
/**
 * @brief Invoked after the popup disappears.
 */
@property (copy) GreePopupBlock didDismissBlock;
/**
 * @brief GreePopupView responsible for drawing this popup.
 */
@property (nonatomic, readonly) GreePopupView* popupView;

/**
 @internal 
 @see UIViewController+GreePlatform.h
 */
@property (nonatomic, assign) UIViewController* hostViewController;

/**
 @brief Generates a popup.
 @param parameters Parameter to be set for the @ref parameters property
 */
-(id)initWithParameters:(NSDictionary*)parameters;
/**
 @brief Generates a popup.
 */
+(id)popup;
/**
 @brief Generates a popup.
 @param parameters Parameter to be set for the @ref parameters property
 */
+(id)popupWithParameters:(NSDictionary*)parameters;
/**
 * @brief Display the receiver.
 * The popup will animate with a bounce animation from the center of the parentView. While the
 * popup is displaying an opaque view will cover the parentView outside of the boundary of
 * the popup.
 */
-(void)show;
/**
 * @brief Dismiss the receiver.
 * The popup will animate out by shrinking toward the center of the parentView.
 */
-(void)dismiss;

/**
 @brief Loads a UIWebView page in a popup asynchronously by using the request given by the aRequest argument.
 @param aRequest NSURLRequest object initialized by the URL to be loaded.
 */
-(void)loadRequest:(NSURLRequest*)aRequest;

/**
 @brief Displays a page by using the specified arguments.
 @param aData Content data of the page.
 @param aMIMEType MIME type of the page.
 @param anEncodingName @c utf-8 or @c utf-16 encoding name defined by IANA.
 @param aBaseURL Base url of the content.
 
 Displays the page by using the UIWebView method having the same name.
 */
-(void)loadData:(NSData*)aData MIMEType:(NSString*)aMIMEType textEncodingName:(NSString*)anEncodingName baseURL:(NSURL*)aBaseURL;

/**
 @brief Displays a page by using the specified arguments.
 @param aString Content data of the page.
 @param aBaseURL Base url of the content.
 
 Displays the page by using the UIWebView method with the same name.
 */
-(void)loadHTMLString:(NSString*)aString baseURL:(NSURL*)aBaseURL;

/**
 @brief Returns the result of running JS.
 @return Result of running JS. If it fails, nil will be returned.
 @param aScript Script to run.
 
 Runs JS by using the UIWebView method with the same name and returns the result.
 */
-(NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)aScript;


/**
 @brief Convenience method for creating attribute value.
 @since 3.2.0
 @return A JSON string suitable for use with GreeRequestServicePopupAttributes.
 @param attributesDictionary An NSDictionery of key-value string pairs.
 */
+(NSString*)jsonEncodeAttributes:(NSDictionary*)attributesDictionary;

@end

/**
 * @brief The GreeInvitePopup interface is used for interacting with the invite service.
 *
 * By using GreeInvitePopup, players can invite their friends to the app.  As a result, it increases number of players and it can help virality.
 * If an invitation is sent to player's friends who has not installed the app, the friend will receive an invitation message.
 *
 * For specifying popup dialog's behavior, this class provides following properties: 
 * 
 * @li @ref message : Specify message which is shown on invites popup dialog.
 * @li @ref callbackURL : Specify callback URL which is used to receive results of the invitation.  This is for webview based application use only.
 * @li @ref toUserIds : Specify default target user.  Please set an array of user id.
 *
 * To receive results of the invitation, please check @ref results property when @ref completeBlock Block is called.
 *
 * For details regarding the invite service, please look at this document:
 * <a href="https://docs.developer.gree.net/en/globaltechnicalspecs/api/inviteservice" target="_blank">https://docs.developer.gree.net/en/globaltechnicalspecs/api/inviteservice</a>
 */
@interface GreeInvitePopup : GreePopup
@property (copy) NSString* message;
@property (retain) NSURL* callbackURL;
@property (retain) NSArray* toUserIds;
@property       (retain) GreeIncentive* incentivePayload;
@end

/**
 * @brief The GreeSharePopup interface is used for interacting with the share service.
 *
 * By using GreeSharePopup, the application can post player's messages or/and image files to the GREE Platform.  The message will be displayed on GREE's SNS timeline.
 * The message will be inspected automatically.
 *
 * For specifying behavior of popup dialogs, this class provides following properties:
 * 
 * - @ref text : Default message that is post.
 * - @ref attachingImage : Able to attach an image file.
 * - @ref imageUrls : URL of the image to be attached to a message that will be posted.  It is assumed that image URLs are specified for this property when an application is implemented with webView.  Specify this property in the following format:
 * @code
 * {"640":"http://example.com/image/640.png","240":"http://example.com/image/240.png","75":"http://example.com/image/75.png"}
 * @endcode
 *
 * To receive the result, please check @ref results property when @ref completeBlock block is called.
 *
 * For the detailed information of share service, please check following docs:
 * <a href="https://docs.developer.gree.net/en/globaltechnicalspecs/api/shareservice" target="_blank">https://docs.developer.gree.net/en/globaltechnicalspecs/api/shareservice</a>
 */
@interface GreeSharePopup : GreePopup
@property (copy) NSString* text;
@property (retain) UIImage* attachingImage;
@property (copy) NSString* imageUrls;
@end

/**
 * @brief The GreeRequestPopup interface is used for interacting with the request service.
 * 
 * By using GreeRequestServicePopup, a player can request other players to do something (invite his friend to an event on the game, send a present to his friend, seek help from his friends, etc.)
 * Developer can know how his request was proceeded.
 *
 * For specifying behaviors of the popup dialog, this class provides following properties. 
 * 
 * - @ref parameters : You can set parameters for the customization. 
 *
 * @ref parameters available key & values:
 * <table>
 * <tr><th>Key</th><th>Detail</th><th>Size</th><th>Remarks</th></tr>
 * <tr><td>@ref GreeRequestServicePopupTitle</td><td>Request Title</td><td>26byte</td><td>Mandatory. Exceeded chars are omitted. URL, HTML will be stripped.</td></tr>
 * <tr><td>@ref GreeRequestServicePopupBody</td><td>Request Body</td><td>100byte</td><td>Mandatory. Exceeded chars are omitted. URL, HTML will be stripped.</td></tr>
 * <tr><td>@ref GreeRequestServicePopupRedirectURL</td><td>Target URL that is opened when receiver opened the request.</td><td></td><td>Optional. Default: http://pf.gree.net/APPID. *It's only for SmartPhone Web application.</td></tr>
 * <tr><td>@ref GreeRequestServicePopupListType</td><td>Type of users to which the request will be sent.</td><td></td><td>Optional. Specify joined, all, or specified. Default: all</td></tr>
 * <tr><td>@ref GreeRequestServicePopupToUserId</td><td>IDs of users to which the request will be sent</td><td>Max 15 users</td><td>Mandatory if @ref GreeRequestServicePopupListType is set as 'specified'. Use NSArray for storing user IDs. If number of users exceedes 15, records after 15th will be ignored.</td></tr>
 * <tr><td>@ref GreeRequestServicePopupExpireTime</td><td>By when requests will be saved</td><td></td><td>Optional. Default: The date after 30 days will be set if nothing is specified for this parameter or more than 30 days after request sending is specified. UTC FORMAT (e.g.: YYYY-MM-DDTHH:DD:SS+09:00)</td></tr>
 * <tr><td>@ref GreeRequestServicePopupAttributes</td><td>Any key & value pair parameters in json format.</td><td></td><td>Optional. e.g. [{"key1":"value1","key2":"value2","key3":"value3"}] </td></tr>
 * </table>
 *
 * @par Constant specified as @ref GreeRequestServicePopupListType
 * <table>
 * <tr><th>Type</th><th>Content</th><th>Notes</th></tr>
 * <tr><td>@ref GreeRequestServicePopupListTypeAll</td><td>All friends</td><td>All friends. This is set by default when no parameter is specified for @ref GreeRequestServicePopupListType .</td></tr>
 * <tr><td>@ref GreeRequestServicePopupListTypeJoined</td><td>Friends who use the application</td><td></td></tr>
 * <tr><td>@ref GreeRequestServicePopupListTypeSpecified</td><td>Arbitrary user ID</td><td>@ref GreeRequestServicePopupToUserId must be specified. An error will be displayed if @ref GreeRequestServicePopupToUserId is not specified.</td></tr>
 * </table>
 *
 * To receive the result, check @ref results property when @ref completeBlock block is called.
 * For details in results, please check <a href="https://docs.developer.gree.net/en/globaltechnicalspecs/api/requestservice/reference" target="_blank">https://docs.developer.gree.net/en/globaltechnicalspecs/api/requestservice/reference</a>.
 *
 * For the detailed information of request service, please check following docs:
 * <a href="https://docs.developer.gree.net/en/globaltechnicalspecs/api/requestservice" target="_blank">https://docs.developer.gree.net/en/globaltechnicalspecs/api/requestservice</a> 
 */
@interface GreeRequestServicePopup : GreePopup
@property       (retain) GreeIncentive* incentivePayload;
@end
