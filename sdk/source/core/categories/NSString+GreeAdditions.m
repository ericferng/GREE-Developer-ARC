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

#import "NSString+GreeAdditions.h"
#import "NSData+GreeAdditions.h"
#import "GreeUtility.h"
#import "Base64Transcoder.h"
#import <CommonCrypto/CommonHMAC.h>

#define IS_SURROGATE_PAIRS_HIGH_SURROGATE(unichar) (0xD800 <= (unichar) && (unichar) <= 0xDBFF)
#define IS_SURROGATE_PAIRS_LOW_SURROGATE(unichar)  (0xDC00 <= (unichar) && (unichar) <= 0xDFFF)
#define IS_REGIONAL_INDICATOR(unichar)             (0xDDE6 <= (unichar) && (unichar) <= 0xDDFF)
#define IS_COMBINING_CHARACTER(unichar)            ((unichar) == 0x20E3)

static const int kSurrogatePairNSStringLength = 2;

@implementation NSString (GreeAdditions)
-(NSString*)formatAsGreeVersion
{
  NSArray* pieces = [self componentsSeparatedByString:@"."];
  NSInteger firstValue = 0;
  NSInteger secondValue = 0;
  NSInteger thirdValue = 0;
  if(pieces.count > 0) {
    firstValue = [[pieces objectAtIndex:0] integerValue];
  }
  if(pieces.count > 1) {
    secondValue = [[pieces objectAtIndex:1] integerValue];
  }
  if(pieces.count > 2) {
    thirdValue = [[pieces objectAtIndex:2] integerValue];
  }
  return [NSString stringWithFormat:@"%04d.%02d.%02d", firstValue, secondValue, thirdValue];
}

-(NSDictionary*)greeHashWithNonceAndKeyPrefix:(NSString*)keyPrefix
{
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  CFStringRef nonce = CFUUIDCreateString(NULL, theUUID);
  [NSMakeCollectable (theUUID)autorelease];
  NSString* nonceObj = [(NSString*)nonce lowercaseString];

  NSString* secretKey = [keyPrefix stringByAppendingString:nonceObj];

  NSData* clearTextData = [self dataUsingEncoding:NSUTF8StringEncoding];
  NSString* hashString = [clearTextData greeHashWithKey:secretKey];

  CFRelease(nonce);

  return [NSDictionary dictionaryWithObjectsAndKeys:
          hashString, @"hash",
          nonceObj, @"nonce",
          nil];
}

-(NSString*)greeURLEncodedString
{
  NSString* anEncodedString = (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
  [anEncodedString autorelease];
  return anEncodedString;
}

-(NSString*)greeURLDecodedString
{
  NSString* aDecodedString = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
  [aDecodedString autorelease];
  return aDecodedString;
}

-(NSMutableDictionary*)greeDictionaryFromQueryString
{
  id pairs = [self componentsSeparatedByString:@"&"];
  id params = [NSMutableDictionary dictionaryWithCapacity:[pairs count]];
  for (NSString* aPair in pairs) {
    id keyAndValue = [aPair componentsSeparatedByString:@"="];
    if ([keyAndValue count] == 2) {
      [params setObject:[(NSString*)[keyAndValue objectAtIndex:1] greeURLDecodedString]
                 forKey:[(NSString*)[keyAndValue objectAtIndex:0] greeURLDecodedString]];
    }
  }
  return params;
}

+(NSString*)greeDocumentsPathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+(NSString*)greeTempPathForRelativePath:(NSString*)relativePath
{
  NSString* basePath = [NSTemporaryDirectory () stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+(NSString*)greeCachePathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+(NSString*)greeLoggingPathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:@"Logs"];
  basePath = [basePath stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

-(NSData*)greeHexStringFormatInBinary
{
  NSData* obj = [self dataUsingEncoding:NSASCIIStringEncoding];
  if (!obj) {
    return nil;
  }
  int length = [obj length];
  const char* hex = [obj bytes];
  if ( length % 2) {
    return nil;
  }
  char* buffer = (char*)malloc((length / 2) + 1);

  char* p = buffer;
  const char* q = hex;

  int i = 0;
  while (i < length) {
    int n;
    int m = sscanf(q, "%02hhx%n", p, &n);
    if ( m != 1 ) {
      break;
    }
    q += n;
    i += n;
    ++p;
  }
  return [[[NSData alloc] initWithBytesNoCopy:buffer length:p - buffer freeWhenDone:YES] autorelease];
}

-(NSString*)greeStringByReplacingHtmlLocalizedStringWithKey:(NSString*)key withString:(NSString*)localizedString
{
  NSString* replaced = nil;

  NSRange localizedRange = [self rangeOfString:[NSString stringWithFormat:@"<!-- localized:%@ -->", key]];
  if (localizedRange.location != NSNotFound) {
    NSUInteger newStartLocation = localizedRange.location + localizedRange.length;
    NSRange closingTagRange = [self rangeOfString:@"<!-- localized -->" options:0x0 range:NSMakeRange(newStartLocation, [self length] - newStartLocation)];
    if (closingTagRange.location != NSNotFound) {
      NSUInteger replacementLength = (closingTagRange.location + closingTagRange.length) - localizedRange.location;
      replaced = [self stringByReplacingCharactersInRange:NSMakeRange(localizedRange.location, replacementLength) withString:localizedString];
    }
  }

  if (!replaced) {
    // we can't end up with nothing
    replaced = [[self copy] autorelease];
  }

  return replaced;
}

-(NSUInteger)greeTextLengthGreeNormalized
{
  int nsStringLength = self.length;
  int textLength = 0;
  for (int i = 0; i < nsStringLength; i++) {
    unichar c = [self characterAtIndex:i];
    if (!(IS_SURROGATE_PAIRS_HIGH_SURROGATE(c) || IS_COMBINING_CHARACTER(c))) {
      textLength++;
      if (IS_REGIONAL_INDICATOR(c) && kSurrogatePairNSStringLength + i <= nsStringLength) {
        i += kSurrogatePairNSStringLength;
      }
    }
  }
  return textLength;
}

-(NSString*)stringByRemoveHtmlTags
{
  NSRange r;
  NSString* s = [[self copy] autorelease];
  while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
    s = [s stringByReplacingCharactersInRange:r withString:@""];
  }
  return s;
}

-(NSString*)stringByDecodingHTMLEntities
{
  NSUInteger myLength = [self length];
  NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;

  // Short-circuit if there are no ampersands.
  if (ampIndex == NSNotFound) {
    return self;
  }
  // Make result string with some extra capacity.
  NSMutableString* result = [NSMutableString stringWithCapacity:(myLength * 1.25)];

  // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
  NSScanner* scanner = [NSScanner scannerWithString:self];
  do {
    // Scan up to the next entity or the end of the string.
    NSString* nonEntityString;
    if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
      [result appendString:nonEntityString];
    }
    if ([scanner isAtEnd]) {
      goto finish;
    }
    // Scan either a HTML or numeric character entity reference.
    if ([scanner scanString:@"&amp;" intoString:NULL]) {
      [result appendString:@"&"];
    } else if ([scanner scanString:@"&apos;" intoString:NULL]) {
      [result appendString:@"'"];
    } else if ([scanner scanString:@"&quot;" intoString:NULL]) {
      [result appendString:@"\""];
    } else if ([scanner scanString:@"&lt;" intoString:NULL]) {
      [result appendString:@"<"];
    } else if ([scanner scanString:@"&gt;" intoString:NULL]) {
      [result appendString:@">"];
    } else if ([scanner scanString:@"&#" intoString:NULL]) {
      BOOL gotNumber;
      unsigned charCode;
      NSString* xForHex = @"";

      // Is it hex or decimal?
      if ([scanner scanString:@"x" intoString:&xForHex]) {
        gotNumber = [scanner scanHexInt:&charCode];
      } else {
        gotNumber = [scanner scanInt:(int*)&charCode];
      }
      if (gotNumber) {
        [result appendFormat:@"%u", charCode];
      } else {
        NSString* unknownEntity = @"";
        [scanner scanUpToString:@";" intoString:&unknownEntity];
        [result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
      }
      [scanner scanString:@";" intoString:NULL];
    } else {
      NSString* unknownEntity = @"";
      [scanner scanUpToString:@";" intoString:&unknownEntity];
      NSString* semicolon = @"";
      [scanner scanString:@";" intoString:&semicolon];
      [result appendFormat:@"%@%@", unknownEntity, semicolon];
    }
  }
  while (![scanner isAtEnd]);

finish:
  return result;
}

-(NSString*)MD5String
{
  // implementation form SDURLCache
  const char* str = [self UTF8String];
  unsigned char r[CC_MD5_DIGEST_LENGTH];

  CC_MD5(str, strlen(str), r);

  return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

-(NSString*)greeUUIDString
{
  return [[[self stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:32] lowercaseString];
}

-(NSData*)greeBase64DecodedData
{
  const char* encData = [self UTF8String];
  size_t length = [self length];
  size_t decodedSize = GreeEstimateBase64DecodedDataSize(length);
  NSMutableData* decodedData = [NSMutableData dataWithLength:decodedSize];

  GreeBase64DecodeData((void*)encData, length, decodedData.mutableBytes, &decodedSize);
  decodedData.length = decodedSize;
  return decodedData;
}

@end
