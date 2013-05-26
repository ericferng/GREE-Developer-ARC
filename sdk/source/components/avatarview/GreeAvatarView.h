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
 * @file GreeAvatarView.h
 * GreeAvatarView class
 */

#import <UIKit/UIKit.h>
#import "GreeUser.h"

/**
 * @brief The GreeAvatarView interface helps you to create a view which can display animated GIF avatar.
 */
@interface GreeAvatarView : UIImageView

/**
 * @brief Downloads the avatar file from the server, and displays it.
 * @since 3.3.2
 * @param user An user.
 * @param size Size of avatar. The default value is GreeUserThumbnailSizeStandard.
 * @param completion Completion block.
 * @note If it is called during the download, it cancels the current download.
 */
-(void)updateUser:(GreeUser*)user size:(GreeUserThumbnailSize)size completion:(void (^)(NSError*))completionBlock;

/**
 * @brief Returns an avatar view.
 * @since 3.3.2
 * @param frame A frame for a view.
 * @param user An user.
 * @param size Size of avatar. The default value is GreeUserThumbnailSizeStandard.
 * @param completion Completion block.
 */
+(id)avatarViewWithFrame:(CGRect)frame;

/**
 * @brief Returns an avatar view.
 * @since 3.3.2
 * @param frame A frame for a view.
 * @param user An user.
 * @param size Size of avatar. The default value is GreeUserThumbnailSizeStandard.
 * @param completion Completion block.
 */
+(id)avatarViewWithFrame:(CGRect)frame user:(GreeUser*)user size:(GreeUserThumbnailSize)size completion:(void (^)(NSError*))completionBlock;
@end
