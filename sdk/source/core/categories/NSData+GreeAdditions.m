//
// Copyright 2010-2012 GREE, inc.
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

#import "NSData+GreeAdditions.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSData (GreeAdditions)

-(NSString*)greeFormatInHex
{
  NSString* hex = @"";
  unsigned char* p = (unsigned char*)[self bytes];
  int i;
  for (i = 0; i < [self length]; i++) {
    hex = [hex stringByAppendingFormat:@"%02x", *p];
    p++;
  }
  return hex;
}

-(NSString*)greeBase64EncodedString
{
  NSUInteger length = [self length];
  NSMutableData* mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

  uint8_t* input = (uint8_t*)[self bytes];
  uint8_t* output = (uint8_t*)[mutableData mutableBytes];

  for (NSUInteger i = 0; i < length; i += 3) {
    NSUInteger value = 0;
    for (NSUInteger j = i; j < (i + 3); j++) {
      value <<= 8;
      if (j < length) {
        value |= (0xFF & input[j]);
      }
    }

    static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    NSUInteger idx = (i / 3) * 4;
    output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
    output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
    output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
    output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
  }

  return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

-(NSString*)greeHashWithKey:(NSString*)key
{
  if ([key length] == 0) {
    return nil;
  }

  NSData* keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

  unsigned char result[20];
  CCHmac(kCCHmacAlgSHA1, [keyData bytes], [keyData length], [self bytes], [self length], result);

  //convert to lowercase hexdigits
  NSMutableString* mutableHash = [[NSMutableString alloc] initWithCapacity:20];
  for (int i = 0; i < 20; ++i) {
    [mutableHash appendFormat:@"%02x", result[i]];
  }

  NSString* hash = [[mutableHash copy] autorelease];
  [mutableHash release];

  return hash;
}

@end

