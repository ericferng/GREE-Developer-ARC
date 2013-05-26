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

#import "NSObject+GreeAdditions.h"

@implementation NSObject (GreeAdditions)
-(void)executeBlock__:(void (^)(void))block
{
  block();
}

-(void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
  void (^tempBlock)(void) = [block copy];
  [self performSelector:@selector(executeBlock__:)
             withObject:tempBlock
             afterDelay:delay];
  [tempBlock release];
}

@end
