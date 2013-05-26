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
 * @file GreePlatform+GreeMiddlewareAdditions.h
 * GreePlatform category. Use only by middleware.
 */

#import "GreePlatform.h"

/**
  This key is used to set a middleware name to cookie. Use only by middleware.
  @see GreePlatform(GreeMiddlewareAdditions)::setOriginalCookie:key:
 */
extern NSString* const GreeCookieKeyMiddlewareName;
/**
  This key is used to set a middleware version to cookie. Use only by middleware.
  @see GreePlatform(GreeMiddlewareAdditions)::setOriginalCookie:key:
 */
extern NSString* const GreeCookieKeyMiddlewareVersion;

/**
 * GreeMiddlewareAdditions is category of GreePlatform. Use only by middleware.
 */
@interface GreePlatform (GreeMiddlewareAdditions)

/**
 * This method is used only by middleware.
 * Set original cookie.
 * @param value for key
 * @param key name
 * @since 3.2.0
 */
-(void)setOriginalCookie:(NSString*)value key:(NSString*)key;

@end
