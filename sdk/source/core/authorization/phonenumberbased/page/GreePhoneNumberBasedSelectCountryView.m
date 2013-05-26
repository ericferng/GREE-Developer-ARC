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

#import "GreePhoneNumberBasedSelectCountryView.h"
#import "GreePlatform+Internal.h"
#import "GreeCountryCodes.h"
#import "GreePhoneNumberBasedController.h"
#import "GreeGlobalization.h"

@interface GreePhoneNumberBasedSelectCountryView ()
@property (nonatomic, retain) NSArray* sortedCountryKeys;
@property (nonatomic, retain) NSArray* sortedCountryValues;

@end

@implementation GreePhoneNumberBasedSelectCountryView

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.sortedCountryKeys = nil;
  self.sortedCountryValues = nil;

  [super dealloc];
}

-(id)initWithUserInfo:(GreePhoneNumberBasedUserInfo*)userInfo
{
  self = [super initWithUserInfo:userInfo];
  if (self) {
    NSMutableDictionary* countryDictionary = [NSMutableDictionary dictionary];
    [[GreeCountryCodes phoneNumberPrefixes].allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
       [countryDictionary setObject:[GreeCountryCodes localizedNameForCountryCode:obj] forKey:obj];
     }];

    self.sortedCountryKeys = [countryDictionary keysSortedByValueUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.sortedCountryValues = [[countryDictionary allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  }
  return self;
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView = [GreePhoneNumberBasedController navigationLabelWithText:
                                   GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.country")];
}

#pragma mark - UITableViewDataSource Methods

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* key = @"cell";

  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:key];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:key] autorelease];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.font = [GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontCellLabel];
  }
  NSString* countryPhoneNumber = [[GreeCountryCodes phoneNumberPrefixes] objectForKey:[self.sortedCountryKeys objectAtIndex:(NSUInteger)indexPath.row]];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [self.sortedCountryValues objectAtIndex:(NSUInteger)indexPath.row], countryPhoneNumber];
  return cell;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.sortedCountryKeys count];
}

#pragma mark - UITableViewDelegate Methods

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  self.userInfo.countryCode = [self.sortedCountryKeys objectAtIndex:(NSUInteger)indexPath.row];
  [self.navigationController popViewControllerAnimated:YES];
}


@end
