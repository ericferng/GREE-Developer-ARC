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

#import <Foundation/Foundation.h>
#import "GreeUniversalMenuDataDelegate.h"

@class GreeUniversalMenuDataRows;

static const int kGreeUniversalMenuDataSectionIndexProfile = 0;

@interface GreeUniversalMenuData : NSObject
@property (nonatomic, assign) id<GreeUniversalMenuDataDelegate> delegate;
@property (nonatomic, retain) NSDictionary* profile;
-(id)initWithDelegate:(id<GreeUniversalMenuDataDelegate>)delegate;
-(NSInteger)numberOfSections;
-(NSInteger)numberOfRowsInSection:(NSInteger)section;
-(NSDictionary*)sectionAtIndex:(NSInteger)section;
-(NSDictionary*)rowAtIndexPath:(NSIndexPath*)indexPath;
-(BOOL)isExpanderAtIndexPath:(NSIndexPath*)indexPath;
-(BOOL)isNotSelectableCellAtIndexPath:(NSIndexPath*)indexPath;
-(GreeUniversalMenuDataRows*)rowsAtSectionIndex:(NSInteger)section;
-(void)request;
@end
