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

#import "GreeUniversalMenuViewController.h"
#import "GreeUniversalMenuData.h"
#import "GreeUniversalMenuDataRows.h"
#import "GreeUniversalMenuViewCell.h"
#import "GreeUniversalMenuViewCellSubviewNormal.h"
#import "GreeUniversalMenuViewCellSubviewProfile.h"
#import "GreeUniversalMenuViewCellSubviewExpander.h"
#import "GreeUniversalMenuViewCellSubviewNotSelectable.h"
#import "GreeUniversalMenuViewSectionHeader.h"
#import "GreeUniversalMenuDefinitions.h"
#import "GreeMenuNavController.h"
#import "GreeJSOpenFromMenuCommand.h"
#import "GreeJSLaunchNativeAppCommand.h"
#import "GreeJSLaunchNativeBrowserCommand.h"
#import "GreeJSPopupNeedUpgradeCommand.h"

@interface GreeUniversalMenuViewController ()<GreeUniversalMenuDataDelegate>
@property (nonatomic, retain) GreeUniversalMenuData* data;
@end

@implementation GreeUniversalMenuViewController

#pragma mark - Object lifecycle

-(id)init
{
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.data = [[[GreeUniversalMenuData alloc] initWithDelegate:self] autorelease];
  }
  return self;
}

-(void)dealloc
{
  self.data.delegate = nil;
  self.data = nil;
  [super dealloc];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuListBackground];

  self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,
                                                          0,
                                                          0,
                                                          OPEN_MENU_OFFSET_RIGHT_MARGIN);
  // fast scroll!
  self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal;
}

#pragma mark - Public methods

-(void)universalMenuWillOpen
{
  [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
  [self.tableView flashScrollIndicators];
}

-(void)reload
{
  [self.data request];
}

#pragma mark - UniversalMenu data delegate

-(void)dataDidUpdate
{
  [self.tableView reloadData];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return self.data.numberOfSections;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.data numberOfRowsInSection:section];
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == kGreeUniversalMenuDataSectionIndexProfile) {
    return [self tableView:tableView profileCellForRowAtIndexPath:indexPath];
  } else if ([self.data isExpanderAtIndexPath:indexPath]) {
    return [self tableView:tableView expanderCellForRowAtIndexPath:indexPath];
  } else if ([self.data isNotSelectableCellAtIndexPath:indexPath]) {
    return [self tableView:tableView notSelectableCellForRowAtIndexPath:indexPath];
  }
  return [self tableView:tableView normalCellForRowAtIndexPath:indexPath];
}

#pragma mark - Table view delegate

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
  NSString* text = [[self.data sectionAtIndex:section] objectForKey:@"header"];
  if (text.length == 0) {
    return nil;
  }

  GreeUniversalMenuViewSectionHeader* header =
    [[[GreeUniversalMenuViewSectionHeader alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 32)] autorelease];
  header.title.text = text;
  return header;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
  NSString* text = [[self.data sectionAtIndex:section] objectForKey:@"header"];
  if (text.length == 0) {
    return 0;
  }

  return 32;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == kGreeUniversalMenuDataSectionIndexProfile) {
    return kGreeUniversalMenuProfileHeight;
  } else {
    return kGreeUniversalMenuNormalCellHeight;
  }
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if ([self.data isExpanderAtIndexPath:indexPath]) {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self expandCollapseSection:indexPath.section];
    return;
  }

  NSDictionary* row = [self.data rowAtIndexPath:indexPath];
  NSDictionary* onClick = [row objectForKey:@"on_click"];
  if (!onClick) {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  }

  NSString* command = [onClick objectForKey:@"command"];
  NSDictionary* params = [onClick objectForKey:@"params"];
  if ([command isEqualToString:GreeJSOpenFromMenuCommand.name]) {

    [[[[GreeJSOpenFromMenuCommand alloc] init] autorelease] execute:params];

  } else if ([command isEqualToString:GreeJSLaunchNativeAppCommand.name]) {

    [[[[GreeJSLaunchNativeAppCommand alloc] init] autorelease] execute:params];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

  } else if ([command isEqualToString:GreeJSLaunchNativeBrowserCommand.name]) {

    [[[[GreeJSLaunchNativeBrowserCommand alloc] init] autorelease] execute:params];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

  } else if ([command isEqualToString:GreeJSPopupNeedUpgradeCommand.name]) {

    [[[[GreeJSPopupNeedUpgradeCommand alloc] init] autorelease] execute:params];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

  }
}

# pragma mark - Internal Methods (cells)

-(UITableViewCell*)tableView:(UITableView*)tableView profileCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* ProfileCellIdentifier = @"Profile";
  GreeUniversalMenuViewCell* cell = [tableView dequeueReusableCellWithIdentifier:ProfileCellIdentifier];
  GreeUniversalMenuViewCellSubviewProfile* subview;
  if (!cell) {
    cell = [[[GreeUniversalMenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ProfileCellIdentifier] autorelease];

    UIView* backgroundView = [[[UIView alloc] init] autorelease];
    backgroundView.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuTitleBackground];
    cell.backgroundView = backgroundView;

    UIView* selectedBackgroundView = [[[UIView alloc] init] autorelease];
    selectedBackgroundView.backgroundColor = [UIColor greeColorWithHex:kGreeUniversalMenuTitleBackgroundTapped];
    cell.selectedBackgroundView = selectedBackgroundView;

    subview = [[[GreeUniversalMenuViewCellSubviewProfile alloc] initWithFrame:cell.contentView.bounds] autorelease];
    cell.subview = subview;
    [cell.contentView addSubview:subview];
  }
  NSDictionary* profile = self.data.profile;
  subview = (GreeUniversalMenuViewCellSubviewProfile*)cell.subview;
  subview.name.text = [profile objectForKey:@"name"];
  if ([[profile objectForKey:@"nickname"] isKindOfClass:[NSString class]]) {
    subview.nickname.text = [profile objectForKey:@"nickname"];
  }
  NSString* iconUrlString = [[profile objectForKey:@"image"] objectForKey:@"url"];
  if ([iconUrlString isKindOfClass:[NSString class]]) {
    NSURL* iconURL = [NSURL URLWithString:iconUrlString];
    [subview setIconURL:iconURL];
  }
  subview.highlighted = NO;

  return cell;
}

-(UITableViewCell*)tableView:(UITableView*)tableView expanderCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* ExpanderCellIdentifier = @"Expander";
  GreeUniversalMenuViewCell* cell = [tableView dequeueReusableCellWithIdentifier:ExpanderCellIdentifier];
  GreeUniversalMenuViewCellSubviewExpander* subview;
  if (!cell) {
    cell = [[[GreeUniversalMenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ExpanderCellIdentifier] autorelease];
    subview = [[[GreeUniversalMenuViewCellSubviewExpander alloc] initWithFrame:cell.contentView.bounds] autorelease];
    cell.subview = subview;
    [cell.contentView addSubview:subview];
  }
  subview = (GreeUniversalMenuViewCellSubviewExpander*)cell.subview;
  subview.section = indexPath.section;
  GreeUniversalMenuDataRows* rows = [self.data rowsAtSectionIndex:indexPath.section];
  subview.isExpanded = rows.isExpanded;
  subview.drawBorderTop = (indexPath.row != 0);
  subview.drawBorderBottom = (indexPath.row != ([self.data numberOfRowsInSection:indexPath.section] - 1));
  subview.highlighted = NO;
  subview.block =^(GreeUniversalMenuViewCellSubviewExpander* expander) {
    [self expandCollapseSection:expander.section];
  };
  return cell;
}

-(UITableViewCell*)tableView:(UITableView*)tableView notSelectableCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* ExpanderCellIdentifier = @"NotSelectable";
  GreeUniversalMenuViewCell* cell = [tableView dequeueReusableCellWithIdentifier:ExpanderCellIdentifier];
  GreeUniversalMenuViewCellSubviewNotSelectable* subview;
  if (!cell) {
    cell = [[[GreeUniversalMenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ExpanderCellIdentifier] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundView = nil;
    subview = [[[GreeUniversalMenuViewCellSubviewNotSelectable alloc] initWithFrame:cell.contentView.bounds] autorelease];
    cell.subview = subview;
    [cell.contentView addSubview:subview];
  }
  subview = (GreeUniversalMenuViewCellSubviewNotSelectable*)cell.subview;
  NSDictionary* row = [self.data rowAtIndexPath:indexPath];
  subview.title.text = [row objectForKey:@"title"];
  return cell;
}

-(UITableViewCell*)tableView:(UITableView*)tableView normalCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* CellIdentifier = @"Cell";
  GreeUniversalMenuViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  GreeUniversalMenuViewCellSubviewNormal* subview;
  if (!cell) {
    cell = [[[GreeUniversalMenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    subview = [[[GreeUniversalMenuViewCellSubviewNormal alloc] initWithFrame:cell.bounds] autorelease];
    cell.subview = subview;
    [cell addSubview:subview];
  }
  NSDictionary* row = [self.data rowAtIndexPath:indexPath];
  subview = (GreeUniversalMenuViewCellSubviewNormal*)cell.subview;
  subview.title.text = [row objectForKey:@"title"];
  subview.badgeValue = [[row objectForKey:@"badge"] unsignedIntegerValue];

  NSDictionary* image = [row objectForKey:@"image"];
  if (image) {
    NSURL* iconURL = [NSURL URLWithString:[image objectForKey:@"url"]];
    BOOL iconCache = [[image objectForKey:@"cache"] boolValue];
    [subview setIconURL:iconURL cache:iconCache];
    subview.iconEnabled = YES;
  } else {
    subview.iconEnabled = NO;
  }

  subview.drawBorderTop = (indexPath.row != 0);
  subview.drawBorderBottom = (indexPath.row != ([self.data numberOfRowsInSection:indexPath.section] - 1));
  subview.highlighted = NO;
  return cell;
}

# pragma mark - Internal Methods (expand & collapse)

-(void)expandCollapseSection:(NSInteger)section
{
  GreeUniversalMenuDataRows* rows = [self.data rowsAtSectionIndex:section];
  if (rows.isExpanded) {
    [self collapseSection:section withRows:rows];
  } else {
    [self expandSection:section withRows:rows];
  }
}

-(void)expandSection:(NSInteger)section withRows:(GreeUniversalMenuDataRows*)rows
{
  int collapsedNum = rows.count;
  rows.isExpanded = YES;
  int expandedNum = rows.count;
  NSArray* indexPaths = [self differenceOfIndexPathsBetweenCollapsed:collapsedNum
                                                            expanded:expandedNum
                                                           atSection:section];

  [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeUniversalMenuSectionWillExpand"
                                                      object:nil
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:section]
                                                                                         forKey:@"section"]];
  [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
}

-(void)collapseSection:(NSInteger)section withRows:(GreeUniversalMenuDataRows*)rows
{
  [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeUniversalMenuSectionWillCollapse"
                                                      object:nil
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:section]
                                                                                         forKey:@"section"]];

  [self performSelector:@selector(collapseAfterDelayWithParams:)
             withObject:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInteger:section], @"section",
               rows, @"rows", nil]
             afterDelay:0.15];

  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.2];
  [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
                        atScrollPosition:UITableViewScrollPositionNone animated:NO];
  [UIView commitAnimations];
}

-(void)collapseAfterDelayWithParams:(NSDictionary*)params
{
  NSInteger section = [[params objectForKey:@"section"] integerValue];
  GreeUniversalMenuDataRows* rows = [params objectForKey:@"rows"];

  int expandedNum = rows.count;
  [rows setIsExpanded:NO];
  int collapsedNum = rows.count;
  NSArray* indexPaths = [self differenceOfIndexPathsBetweenCollapsed:collapsedNum
                                                            expanded:expandedNum
                                                           atSection:section];

  [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

-(NSArray*)differenceOfIndexPathsBetweenCollapsed:(NSInteger)collapsed
                                         expanded:(NSInteger)expanded
                                        atSection:(NSInteger)section
{
  NSMutableArray* indexPaths = [NSMutableArray array];
  for (int i = collapsed; i < expanded; i++) {
    [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
  }
  return indexPaths;
}


@end
