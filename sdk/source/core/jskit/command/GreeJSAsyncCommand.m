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


#import "GreeJSAsyncCommand.h"

@interface GreeJSAsyncCommand ()
-(void)cleanup;
@end

@implementation GreeJSAsyncCommand

#pragma mark - Object Lifecycle
-(void)dealloc
{
  [self cleanup];
  [super dealloc];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}

#pragma mark - Public Interface
-(void)callback
{
  [[self.environment handler] onCommandCompleted:self];
}

-(void)abort
{
  [self cleanup];
}

#pragma mark - GreeJSCommand Overrides
-(BOOL)isAsynchronousCommand
{
  return YES;
}

#pragma mark - Internal Methods
-(void)cleanup
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
