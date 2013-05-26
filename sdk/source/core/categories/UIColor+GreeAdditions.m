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

#import "UIColor+GreeAdditions.h"

@implementation UIColor (GreeAdditions)
+(UIColor*)greeColorWithHex:(UInt32)hex
{
  CGFloat red, green, blue, alpha;

  red = (hex >> 24) & 0xFF;
  green = (hex >> 16) & 0xFF;
  blue = (hex >> 8) & 0xFF;
  alpha = hex & 0xFF;

  return [UIColor
          colorWithRed: red / 255.0f
                 green: green / 255.0f
                  blue: blue / 255.0f
                 alpha: alpha / 255.0f];
}
@end
