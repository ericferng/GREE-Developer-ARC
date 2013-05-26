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


#import "GreeJSCommand.h"
#import "GreeJSCommandEnvironment.h"

@implementation GreeJSCommand

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.result = nil;
  [super dealloc];
}

#pragma mark - Public Interface

+(NSString*)name
{
  NSLog(@"%@:%@ must be overloaded in subclasses.", [self class], NSStringFromSelector(_cmd));
  return nil;
}

-(void)execute:(NSDictionary*)params
{
  NSLog(@"%@:%@ must be overloaded in subclasses.", [self class], NSStringFromSelector(_cmd));
}

-(UIViewController*)viewControllerWithRequiredBaseClass:(Class)baseClass
{
  Class requiredClass = baseClass;

  if (baseClass == nil) {
    requiredClass = [UIViewController class];
  }

  id viewController = [self.environment viewControllerForCommand:self];

  NSAssert2([viewController isKindOfClass:requiredClass],
            @"%@ requires a UIViewController of with a base class of %@",
            NSStringFromClass([self class]),
            NSStringFromClass(requiredClass));

  return viewController;
}

-(BOOL)isAsynchronousCommand
{
  return NO;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

@end
