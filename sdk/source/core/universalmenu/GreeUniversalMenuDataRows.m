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

#import "GreeUniversalMenuDataRows.h"

@interface GreeUniversalMenuDataRows ()
@property (nonatomic, retain) NSArray* rows;
@property (nonatomic, retain) NSArray* rowsMore;
@end

@implementation GreeUniversalMenuDataRows

# pragma mark - Object lifecycle

-(id)initWithDictionary:(NSDictionary*)section
{
  self = [super init];
  if (self) {
    self.isExpanded = NO;
    self.rows = [section objectForKey:@"rows"];
    self.rowsMore = [section objectForKey:@"rows_more"];
  }
  return self;
}

-(void)dealloc
{
  self.rows = nil;
  self.rowsMore = nil;
  [super dealloc];
}

# pragma mark - Public Methods

-(NSDictionary*)rowAtIndex:(NSInteger)row
{
  if (self.isExpanded && row >= self.rows.count) {
    return [self.rowsMore objectAtIndex:(row - self.rows.count)];
  }

  return [self.rows objectAtIndex:row];
}

-(NSInteger)count
{
  if (self.isExpanded) {
    return self.rows.count + self.rowsMore.count;
  }

  return self.rows.count;
}

-(BOOL)isExpandable
{
  return !!self.rowsMore;
}

@end
