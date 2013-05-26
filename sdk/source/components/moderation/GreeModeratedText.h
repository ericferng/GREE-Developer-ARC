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
 * @file GreeModeratedText.h
 * GreeModeratedText class
 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GreeSerializable.h"


/**
 * Enumeration of possible moderation statuses used to determine
 * if the text is appropriate for end user display.
 */
typedef enum {
/**
 * Text is being inspected, and as such, is not safe for end user display.
 */
  GreeModerationStatusBeingChecked,
/**
 * Text is approved and safe for end user display.
 */
  GreeModerationStatusResultApproved,
/**
 * Text has been deleted.
 */
  GreeModerationStatusDeleted,
/**
 * Text has been rejected and is not safe for end user display.
 */
  GreeModerationStatusResultRejected
} GreeModerationStatus;

/**
 * Broadcasted when the hard currency store data has been updated.
 */
extern NSString* const GreeModeratedTextUpdatedNotification;

/**
 * @brief A class to create, load, update, and delete moderated text objects.
 *
 * Moderated text objects are typically user-generated strings that should be
 * inspected for inappropriate language before being displayed to other users.
 */
@interface GreeModeratedText : NSObject<GreeSerializable>

/**
 * Unique identifier for this moderated text.
 */
@property (nonatomic, retain, readonly) NSString* textId;
/**
 * Unique identifier for the application which created this moderated text.
 * This is typically your application.
 */
@property (nonatomic, retain, readonly) NSString* appId;
/**
 * UserID of the text's author. This is typically the logged in user.
 */
@property (nonatomic, retain, readonly) NSString* authorId;
/**
 * The content of this moderated text. 
 */
@property (nonatomic, retain, readonly) NSString* content;

/**
 * Current status of this moderated text.
 * @see GreeModerationStatus
 */
@property (nonatomic, assign, readonly) GreeModerationStatus status;

/**
 * @brief Create a new moderated text with a given content string.
 *
 * Attempts to register the text with the server and submit it for
 * inspection.
 *
 * @param string The content of the new moderated text.
 * @param block Invoked after attempting to register with the server.
 *
 * @note The text is not created until your block is invoked without error.
 */
+(void)createWithString:(NSString*)string block:(void (^)(GreeModeratedText* createdUserText, NSError* error))block;

/**
 * @brief Loads one or more GreeModeratedText objects by their id.
 * @param ids An array of NSString ids of moderated texts.
 * @param block Invoked when loading is complete.
 */
+(void)loadFromIds:(NSArray*)ids block:(void (^)(NSArray* userTexts, NSError* error))block;

/**
 * @brief Updates the content string for a moderated text.
 * @param updatedString A new string to replace the existing value on the server.
 * @param block Invoked when updating is complete.
 */
-(void)updateWithString:(NSString*)updatedString block:(void (^)(NSError* error))block;

/**
 * @brief Deletes the moderated text.
 * @param block Invoked when deletion completes.
 */
-(void)deleteWithBlock:(void (^)(NSError* error))block;

/**
 * @brief Asks to be notified when the server updates the status.  
 */
-(void)beginNotification;

/**
 * @brief Will no longer receive status updates from the server.
 */
-(void)endNotification;

/**
 * @brief Returns the list of moderated texts that are currently being checked with the server.
 * @since 3.2.0
 */
+(NSArray*)currentList;
@end
