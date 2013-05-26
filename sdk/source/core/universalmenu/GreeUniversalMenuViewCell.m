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

#import "GreeUniversalMenuViewCell.h"
#import "GreeUniversalMenuDefinitions.h"
#import "GreeUniversalMenuViewCellSubviewNormal.h"

@implementation GreeUniversalMenuViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    UIView* bgColorView = [[UIView alloc] init];
    [bgColorView setBackgroundColor:[UIColor greeColorWithHex:kGreeUniversalMenuListBackgroundTapped]];
    [self setSelectedBackgroundView:bgColorView];
    [bgColorView release];
  }
  return self;
}

-(void)dealloc
{
  self.subview = nil;
  [super dealloc];
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [self.subview setHighlighted:selected];
  [self.subview setNeedsDisplay];
  [super setSelected:selected animated:animated];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
  [self.subview setHighlighted:highlighted];
  [self.subview setNeedsDisplay];
  [super setHighlighted:highlighted animated:animated];
}

@end
