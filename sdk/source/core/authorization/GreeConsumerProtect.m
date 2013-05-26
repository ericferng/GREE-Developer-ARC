//
// Copyright 2010-2011 GREE, inc.
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

#import <CommonCrypto/CommonCryptor.h>

#import "GreeConsumerProtect.h"
#import "GreeConsumerProtect+Internal.h"
#import "NSData+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeLogger.h"

#define ENCRYPT_ALGORITHM     kCCAlgorithmAES128
#define ENCRYPT_BLOCK_SIZE    kCCBlockSizeAES128
#define ENCRYPT_KEY_SIZE      kCCKeySizeAES256

@implementation GreeConsumerProtect

+(NSString*)encryptedHexString:(NSString*)string keyString:(NSString*)keyString
{
  NSData* data = [self encryptData:[string dataUsingEncoding:NSUTF8StringEncoding]
                               key:[keyString dataUsingEncoding:NSUTF8StringEncoding]
                                iv:nil];
  return [data greeFormatInHex];
}

+(NSString*)decryptedHexString:(NSString*)encryptedHexString keyString:(NSString*)keyString
{
  NSData* encryptedData = [encryptedHexString greeHexStringFormatInBinary];

  NSData* data = [self decryptData:encryptedData
                               key:[keyString dataUsingEncoding:NSUTF8StringEncoding]
                                iv:nil];
  if (data) {
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
  } else {
    return nil;
  }
}

+(NSData*)encryptData:(NSData*)data key:(NSData*)key iv:(NSData*)iv;
{
  if (!data) {
    return nil;
  }
  if (!key || key.length == 0) {
    return data;
  }

  NSData* result = nil;

  // setup key
  unsigned char cKey[ENCRYPT_KEY_SIZE];
  bzero(cKey, sizeof(cKey));
  [key getBytes:cKey length:ENCRYPT_KEY_SIZE];

  // setup iv
  char cIv[ENCRYPT_BLOCK_SIZE];
  bzero(cIv, ENCRYPT_BLOCK_SIZE);
  if (iv) {
    [iv getBytes:cIv length:ENCRYPT_BLOCK_SIZE];
  }

  // setup output buffer
  size_t bufferSize = [data length] + ENCRYPT_BLOCK_SIZE;
  void* buffer = malloc(bufferSize);

  // do encrypt
  size_t encryptedSize = 0;
  CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                        ENCRYPT_ALGORITHM,
                                        kCCOptionPKCS7Padding,
                                        cKey,
                                        ENCRYPT_KEY_SIZE,
                                        cIv,
                                        [data bytes],
                                        [data length],
                                        buffer,
                                        bufferSize,
                                        &encryptedSize);

  if (cryptStatus == kCCSuccess) {
    result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
  } else { // COV_NF_START
    GreeLog(@"failed to encrypt CCCryptoStatus: %d", cryptStatus);
    free(buffer);
  } // COV_NF_END

  return result;
}

+(NSData*)decryptData:(NSData*)data key:(NSData*)key iv:(NSData*)iv;
{
  if (!data) {
    return nil;
  }
  if (!key || key.length == 0) {
    return data;
  }

  NSData* result = nil;

  // setup key
  unsigned char cKey[ENCRYPT_KEY_SIZE];
  bzero(cKey, sizeof(cKey));
  [key getBytes:cKey length:ENCRYPT_KEY_SIZE];

  // setup iv
  char cIv[ENCRYPT_BLOCK_SIZE];
  bzero(cIv, ENCRYPT_BLOCK_SIZE);
  if (iv) {
    [iv getBytes:cIv length:ENCRYPT_BLOCK_SIZE];
  }

  // setup output buffer
  size_t bufferSize = [data length] + ENCRYPT_BLOCK_SIZE;
  void* buffer = malloc(bufferSize);

  // do decrypt
  size_t decryptedSize = 0;
  CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                        ENCRYPT_ALGORITHM,
                                        kCCOptionPKCS7Padding,
                                        cKey,
                                        ENCRYPT_KEY_SIZE,
                                        cIv,
                                        [data bytes],
                                        [data length],
                                        buffer,
                                        bufferSize,
                                        &decryptedSize);

  if (cryptStatus == kCCSuccess) {
    result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
  } else { // COV_NF_START
    GreeLog(@"failed to decrypt CCCryptoStatus: %d", cryptStatus);
    free(buffer);
  } // COV_NF_END

  return result;
}

@end
