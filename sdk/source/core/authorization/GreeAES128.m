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
#import "GreeAES128.h"

#include <stdlib.h>
#include <memory.h>
#include <string.h>

@implementation GreeAES128

#pragma mark - Object Lifecycle
-(void)dealloc
{
  [super dealloc];
}

#pragma mark - Public Interface
-(NSData*)generateKey
{
  char akey[kCCKeySizeAES128];
  srandomdev();
  int i;
  for (i = 0; i < kCCKeySizeAES128; i+=sizeof(long) ) {
    long* p = (long*)(akey + i);
    *p = random();
  }
  return [[[NSData alloc] initWithBytes:akey length:kCCKeySizeAES128] autorelease];
}

-(void)setKey:(const void*)akey
{
  memcpy(key, akey, kCCKeySizeAES128);
}

-(void)setInitializationVector:(const void*)vector
{
  memcpy(iv, vector, kCCKeySizeAES128);
}

-(NSData*)encrypt:(const void*)data length:(int)datasize
{

  int blocks = datasize /(kCCBlockSizeAES128 - 1);
  if (datasize % (kCCBlockSizeAES128 - 1)) {
    blocks++;
  }

  void* encrypted = malloc(kCCBlockSizeAES128 * blocks);
  size_t total_size = 0;
  int offset = 0;
  int remaining = datasize;

  const void* p = data;
  while (--blocks >= 0) {
    size_t size = 0;

    int bytesToEncrypt = (remaining >= kCCBlockSizeAES128) ? (kCCBlockSizeAES128 - 1) : remaining;
    OSStatus ccStatus = CCCrypt(kCCEncrypt,
                                kCCAlgorithmAES128,
                                kCCOptionPKCS7Padding,
                                key,
                                kCCKeySizeAES128,
                                iv,
                                p, bytesToEncrypt,
                                (char*)encrypted + offset, kCCBlockSizeAES128,
                                &size
                                );
    if (ccStatus != kCCSuccess) {
      NSLog(@"CCrypt failed %ld", ccStatus);
      free(encrypted);
      return nil;
    }
    offset += size;
    total_size += size;
    p += bytesToEncrypt;
    remaining -= bytesToEncrypt;
  }
  return [[[NSData alloc] initWithBytesNoCopy:encrypted length:total_size freeWhenDone:YES] autorelease];
}

-(NSData*)decrypt:(const void*)data length:(int)datasize
{
  char* plain;
  size_t total_size = 0;
  int offset = 0;

  plain = malloc(datasize + kCCBlockSizeAES128);
  const void* p = data;
  while ((p - data) < datasize) {
    size_t size = 0;
    OSStatus ccStatus = CCCrypt(kCCDecrypt,
                                kCCAlgorithmAES128,
                                kCCOptionPKCS7Padding,
                                key,
                                kCCKeySizeAES128,
                                iv,
                                p, kCCBlockSizeAES128,
                                plain + offset, kCCBlockSizeAES128,
                                &size
                                );
    if (ccStatus != kCCSuccess) {
      NSLog(@"CCrypt failed %ld", ccStatus);
      free(plain);
      return nil;
    }
    offset += size;
    total_size += size;
    p += kCCBlockSizeAES128;
  }
  return [[[NSData alloc] initWithBytesNoCopy:plain length:total_size freeWhenDone:YES] autorelease];
}

@end
