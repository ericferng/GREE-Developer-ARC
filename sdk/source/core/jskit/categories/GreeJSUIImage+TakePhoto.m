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

#import "GreeJSUIImage+TakePhoto.h"
#include "Base64Transcoder.h"

@implementation UIImage (GreeJSUIImageTakePhotoAdditions)

+(UIImage*)greeImageWithBase64:(NSString*)base64
{
  if (!base64 || [base64 length] == 0) {
    return nil;
  }

  const char* data = [base64 UTF8String];
  size_t length = [base64 length];
  size_t decodedSize = GreeEstimateBase64DecodedDataSize(length);
  NSMutableData* decodedData = [NSMutableData dataWithLength:decodedSize];

  GreeBase64DecodeData(data, length, decodedData.mutableBytes, &decodedSize);
  decodedData.length = decodedSize;
  return [UIImage imageWithData:decodedData];
}

@end
