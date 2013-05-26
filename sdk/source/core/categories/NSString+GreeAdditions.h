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

#import <Foundation/Foundation.h>

@interface NSString (GreeAdditions)
/**
 * Will return a version of the string formatted like 0000.00.00
 * Non numbers will be ignored and missing pieces will be filled with zeros
 */
-(NSString*)formatAsGreeVersion;

/**
 * Given a key prefix and a data string, generate a hash in accordance with the Gree platform server
 * A nonce is generated based on the current time
 * This nonce is appended to the key prefix for use as a HMAC-SHA1 key
 * The string is hashed and converted to lowercase hex
 *
 *@param keyPrefix will be added to the nonce, an example would be a user id.
 *@param dataString the value to be hashed, an example would be an achievement id.
 *@return a dictionary with keys "nonce" and "hash"
 */
-(NSDictionary*)greeHashWithNonceAndKeyPrefix:(NSString*)keyPrefix;

-(NSString*)greeURLEncodedString;

-(NSString*)greeURLDecodedString;

-(NSMutableDictionary*)greeDictionaryFromQueryString;

/**
 * @return Full path for the given relative path located within Gree's exclusive ~/Documents folder
 */
+(NSString*)greeDocumentsPathForRelativePath:(NSString*)relativePath;

/**
 * @return Full path for the given relative path located within Gree's exclusive /tmp/ folder
 */
+(NSString*)greeTempPathForRelativePath:(NSString*)relativePath;

/**
 * @return Full path for the given relative path located within Gree's exclusive ~/Library/Caches folder
 */
+(NSString*)greeCachePathForRelativePath:(NSString*)relativePath;

/**
 * @return Full path for the given relative path located within Gree's exclusive ~/Library/Logs folder
 */
+(NSString*)greeLoggingPathForRelativePath:(NSString*)relativePath;

/**
 * @return NSData from HexString
 */
-(NSData*)greeHexStringFormatInBinary;

// For on-demand HTML localization. Assuming the receiver is a string of HTML this will search
// for <!-- localized:KEY --> / <!-- localized --> and replace it with the given localized string.
-(NSString*)greeStringByReplacingHtmlLocalizedStringWithKey:(NSString*)key withString:(NSString*)localizedString;

// count Surrogate Pairs and Emoji as 1 character
-(NSUInteger)greeTextLengthGreeNormalized;

-(NSString*)stringByRemoveHtmlTags;
-(NSString*)stringByDecodingHTMLEntities;

// convert to MD5
-(NSString*)MD5String;

// make a UUID string 32-byte long, lowercase, without hyphens
-(NSString*)greeUUIDString;

// return base64 decoded data
-(NSData*)greeBase64DecodedData;
@end

