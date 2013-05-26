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

#import <QuartzCore/QuartzCore.h>
#import "GreeNotificationTableViewController.h"
#import "GreeNotificationTableViewCell.h"
#import "UIImage+GreeAdditions.h"
#import "GreeNotificationMessage.h"
#import "UIImageView+AFNetworking.h"
#import "GreeNotifications.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeGlobalization.h"
#import "GreeLinkedFriend.h"
#import "GreeMarkasRead.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeJSPullToRefreshHeaderView.h"
#import "GreeNotificationLoader.h"
#import "GreeJSIconPersistentCache.h"
#import "GreeInviteNotificationField.h"
#import "GreeJSDownloadIndicatorView.h"
#import "GreeNotificationFeed.h"

@interface GreeNotificationFieldHeaderView : UIView
@end

@implementation GreeNotificationFieldHeaderView

#pragma mark - UIView Overrides

-(void)drawRect:(CGRect)rect
{
  CGContextRef currentContext = UIGraphicsGetCurrentContext();

  CGGradientRef glossGradient;
  CGColorSpaceRef rgbColorspace;
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = { 235.0f/255.0f, 240.0f/255.0f, 245.0f/255.0f, 1.0,
                            215.0f/255.0f, 220.0f/255.0f, 225.0f/255.0f, 1.0 };

  rgbColorspace = CGColorSpaceCreateDeviceRGB();
  glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);

  CGRect currentBounds = self.bounds;
  CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
  CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), currentBounds.size.height);
  CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, bottomCenter, 0);

  CGGradientRelease(glossGradient);
  CGColorSpaceRelease(rgbColorspace);
}

@end

static NSInteger const kLoadingFeedCellTag = 1001;
static NSInteger const kNothingMoreFeedCellTag = 1002;
static NSInteger const kLoadingMoreFeedIndicatorTag = 1003;

typedef enum  {
  GreePullToRefreshHeaderViewStateHidden,
  GreePullToRefreshHeaderViewStatePullingDown,
  GreePullToRefreshHeaderViewStateOveredThreshold,
  GreePullToRefreshHeaderViewStateStopping,
} GreePullToRefreshHeaderViewState;

@interface GreeNotifycationFeedIconPersistentCache : GreeJSIconPersistentCache
@property (nonatomic, copy) NSString* cacheDirectory;
@end

@implementation GreeNotifycationFeedIconPersistentCache

#pragma mark - Object Lifecycle

-(id)init
{
  if ((self = [super init])) {
    NSArray* pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cacheDirectory = [NSString stringWithFormat:@"%@/notifications", [pathList lastObject]];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return self;
}

@end

@interface GreeInviteTableViewCell : UITableViewCell
-(void)drawContentView:(CGRect)rect;
@property (nonatomic, retain) NSString* countStr;
@property (nonatomic, retain) UIView* mainView;
@property (nonatomic, copy) NSString* text;
@property (nonatomic, assign) int count;
@property (nonatomic, retain) UIFont* textFont;
@property (nonatomic, retain) UIFont* indicatorFont;
@property (nonatomic, retain) UIColor* indicatorColor;
@property (nonatomic, retain) UIColor* indicatorBackgroundColor;
@end

@interface GreeInviteTableViewCellView : UIView
@end

@implementation GreeInviteTableViewCellView

#pragma mark - UIView Overrides

-(void)drawRect:(CGRect)rect
{
  if ([self superview]) {
    [(GreeInviteTableViewCell*)[self superview] drawContentView : rect];
  }
}

@end

@implementation GreeInviteTableViewCell

#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.countStr = nil;
  self.mainView = nil;
  self.text = nil;
  self.textFont = nil;
  self.indicatorFont = nil;
  self.indicatorColor = nil;
  self.indicatorBackgroundColor = nil;

  [super dealloc];
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
  if(!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    return nil;
  }
  self.textFont = [UIFont boldSystemFontOfSize:18];
  self.indicatorFont = [UIFont boldSystemFontOfSize:16];
  self.indicatorColor = [UIColor whiteColor];
  self.indicatorBackgroundColor = [UIColor colorWithRed:140/255.0 green:153/255.0 blue:180/255.0 alpha:1.0];
  self.mainView = [[[GreeInviteTableViewCellView alloc] initWithFrame:CGRectZero] autorelease];
  self.mainView.opaque = YES;
  [self addSubview:self.mainView];
  return self;
}

-(id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString*)reuseIdentifier
{
  return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
}

#pragma mark - UIView Overrides

-(void)layoutSubviews
{
  [super layoutSubviews];

  self.contentView.hidden = YES;
  [self.contentView removeFromSuperview];
  [self setNeedsDisplay];
}

-(void)setFrame:(CGRect)frame
{
  [super setFrame:frame];
  self.mainView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height-1);
  [self.mainView setNeedsDisplay];
}

#pragma mark - UITableViewCell Overrides

-(void)willTransitionToState:(UITableViewCellStateMask)state
{
  [super willTransitionToState:state];
  [self setNeedsDisplay];
}

-(void)setNeedsDisplay
{
  [super setNeedsDisplay];
  [self.mainView setNeedsDisplay];
}

#pragma mark - Public Interface

-(void)setText:(NSString*)text
{
  if (_text != text) {
    [_text release];
    _text = [text copy];
  }
  [self setNeedsDisplay];
}

-(void)setCount:(int)count
{
  if(count == _count) {
    return;
  }
  if(count > 99 && _count < 100) {
    self.indicatorFont = [UIFont boldSystemFontOfSize:12.0];
  } else if(count < 100 && _count > 99) {
    self.indicatorFont = [UIFont boldSystemFontOfSize:16.0];
  }
  _count = count;
  self.countStr = [NSString stringWithFormat:@"%d", count];
  [self setNeedsDisplay];
}

-(void)drawContentView:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  UIColor* backgroundColor = (self.selected || self.highlighted) ? [UIColor clearColor] : [UIColor whiteColor];
  UIColor* textColor = (self.selected || self.highlighted) ? [UIColor whiteColor] : [UIColor blackColor];
  [backgroundColor set];
  CGContextFillRect(context, rect);
  CGRect theRect = CGRectInset(rect, 10, 18);
  theRect.size.width -= 45;
  if(self.editing) {
    theRect.origin.x += 30;
  }
  [textColor set];
  [self.text drawInRect:theRect withFont:self.textLabel.font lineBreakMode:UILineBreakModeTailTruncation];

  if(self.count > 0 && !self.editing) {
    [[UIColor colorWithRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
    CGRect rr = CGRectMake(theRect.size.width+ theRect.origin.x, 18, 30, 20);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rrect = CGRectMake(rr.origin.x, rr.origin.y, rr.size.width, rr.size.height);
    CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, 10);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, 10);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, 10);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, 10);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    if(self.count > 99) {
      rr.origin.y += 2;
    }
    [[UIColor whiteColor] set];
    [self.countStr drawInRect:rr withFont:self.indicatorFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
  }
}

@end

@interface GreeNotificationTableViewController ()
@property (nonatomic, retain) NSMutableArray* fieldsList;
@property (nonatomic, retain) GreeNotifications* notifications;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) GreePullToRefreshHeaderViewState pullToRefreshHeaderViewState;
@property (nonatomic, retain) NSOperationQueue* queue;

-(void)setHeaderViewHidden:(BOOL)hidden animated:(BOOL)animated;
-(void)hideEmptySeparators;
-(void)loadAutoPagerizeFeedsWithField:(NSArray*)array offset:(NSInteger)offset limit:(NSInteger)limit;
-(void)loadNewestFeedsWithField:(NSArray*)array offset:(NSInteger)offset limit:(NSInteger)limit cache:(BOOL)cache;

-(NSArray*)loadFieldNames:(BOOL)reload;
-(void)handleDataItems:(NSArray*)dataItems error:(NSError*)error reload:(BOOL)reload;

-(int)rowOfLastCellInSection:(NSInteger)section;
-(NSArray*)feedsInSection:(NSInteger)section;

-(void)updateNotificationCell:(GreeNotificationTableViewCell*)cell
                        field:(GreeNotificationField*)field
                         feed:(GreeNotificationFeed*)feed;
-(void)updateGameNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed;
-(void)updateSNSNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed;
-(void)updateFriendNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed;

-(GreeNotificationTableViewCell*)greeNotificationTableViewCellForAtIndexPath:(NSIndexPath*)indexPath;
-(UITableViewCell*)normalTableViewCellForAtIndexPath:(NSIndexPath*)indexPath;

-(void)updateBadge;
-(void)reload;
-(void)updateMarkasRead;
-(void)pullToRefreshWorkFinished;

+(UIColor*)feedReadColor;
+(UIColor*)feedUnReadColor;
+(UIColor*)feedTapHighlightColor;
@end

@implementation GreeNotificationTableViewController

#pragma mark - Object lifecycle

-(void)viewDidLoad
{
  [super viewDidLoad];

  self.fieldsList = [NSMutableArray arrayWithCapacity:0];
  self.queue = [[[NSOperationQueue alloc] init] autorelease];
  self.queue.maxConcurrentOperationCount = 2;
  [self.queue setSuspended:NO];

  self.tableView.backgroundColor = [UIColor colorWithRed:0xf4/255.0f green:0xf5/255.0f blue:0xf6/255.0f alpha:1.0];
  self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
  self.tableView.showsVerticalScrollIndicator = YES;
  self.view.layer.masksToBounds = YES;
  self.view.layer.cornerRadius = 5.0f;

  self.tableView.tableHeaderView = [[[GreeJSPullToRefreshHeaderView alloc] init] autorelease];
  self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStateHidden;
  [self setHeaderViewHidden:YES animated:NO];

  [self hideEmptySeparators];
}

-(void)dealloc
{
  self.fieldsList = nil;
  self.notifications = nil;
  self.queue = nil;

  [super dealloc];
}

#pragma mark - UIViewController Overrides

-(void)viewDidAppear:(BOOL)animated
{
  [self loadNewestFeedsWithField:[self loadFieldNames:YES] offset:0 limit:GreeMaxLoadNotificationFeed cache:YES];
}

#pragma mark - Public Interface

-(id)initWithNotificationType:(GreeNotificationBoardType)type style:(UITableViewStyle)style
{
  if (type != GreeNotificationBoardTypeSns &&
      type != GreeNotificationBoardTypeGame &&
      type != GreeNotificationBoardTypeFriend) {
    return nil;
  }
  self = [self initWithStyle:style];
  if (self) {
    _boardType = type;
  }
  return self;
}

-(void)setBoardType:(GreeNotificationBoardType)boardType
{
  _boardType = boardType;

  self.notifications = nil;
  [self.fieldsList removeAllObjects];
  [self.tableView reloadData];

  self.loading = NO;
  [self loadNewestFeedsWithField:[self loadFieldNames:YES] offset:0 limit:GreeMaxLoadNotificationFeed cache:YES];
}

#pragma mark Internal Methoads

-(void)setHeaderViewHidden:(BOOL)hidden animated:(BOOL)animated
{
  CGFloat topOffset = 0.0;
  if (hidden) {
    topOffset = -self.tableView.tableHeaderView.frame.size.height;
  }
  if (animated) {
    [UIView
     animateWithDuration:0.2
              animations:^{
       self.tableView.contentInset = UIEdgeInsetsMake (topOffset, 0, 0, 0);
     }];
  } else {
    self.tableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
  }
}

-(void)loadAutoPagerizeFeedsWithField:(NSArray*)array offset:(NSInteger)offset limit:(NSInteger)limit
{
  if (self.loading) {
    return;
  }
  self.loading = YES;

  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  [GreeNotifications
   loadFeedsWithFields:array
                 appId:appId
                offset:offset
                 limit:limit
               saveKey:nil
                 block:^(GreeNotifications* notifications, NSError* error) {
     self.loading = NO;
     self.notifications = notifications;
     [self handleDataItems:notifications.fields error:error reload:NO];
     if (!self.pullToRefreshHeaderViewState == GreePullToRefreshHeaderViewStateHidden) {
       [self pullToRefreshWorkFinished];
     }
   }];
}

-(void)loadNewestFeedsWithField:(NSArray*)array offset:(NSInteger)offset limit:(NSInteger)limit cache:(BOOL)cache
{
  if (self.loading) {
    return;
  }

  self.loading = YES;

  __block GreeJSLoadingIndicatorView* indicator = nil;
  if (!self.notifications) {
    indicator = [[GreeJSLoadingIndicatorView alloc] initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypePullToRefresh];
    indicator.center = self.tableView.center;
    [self.tableView addSubview:indicator];
    [indicator release];
  }

  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSString* cacheKey = nil;

  if (self.boardType == GreeNotificationBoardTypeGame) {
    cacheKey = GreeGameNotificationCacheKey;
  } else if (self.boardType == GreeNotificationBoardTypeSns) {
    cacheKey = GreeSNSNotificationCacheKey;
  } else if (self.boardType == GreeNotificationBoardTypeFriend) {
    cacheKey = GreeFriendNotificationCacheKey;
  }
  if (cache) {
    [GreeNotifications
     loadCacheFeedsWithCacheKey:cacheKey
                          block:^(GreeNotifications* notifications, NSError* error) {
       if (indicator) {
         [indicator removeFromSuperview];
         indicator = nil;
       }
       self.loading = NO;
       self.notifications = notifications;
       [self handleDataItems:notifications.fields error:error reload:YES];
       if (!self.notifications) {
         [GreeNotifications
          loadFeedsWithFields:array
                        appId:appId
                       offset:offset
                        limit:limit
                      saveKey:cacheKey
                        block:^(GreeNotifications* notifications, NSError* responseError) {
            if (indicator) {
              [indicator removeFromSuperview];
              indicator = nil;
            }
            if (error || !self.notifications) {
              self.notifications = notifications;
              [self handleDataItems:notifications.fields error:responseError reload:YES];
            } else if (notifications) {
              if (![notifications isEqual:self.notifications]) {
                self.notifications = notifications;
                [self handleDataItems:notifications.fields error:responseError reload:YES];
              }
            }
          }];
       }
       [self updateMarkasRead];
     }];
  } else {
    [GreeNotifications
     loadFeedsWithFields:array
                   appId:appId
                  offset:offset
                   limit:limit
                 saveKey:cacheKey
                   block:^(GreeNotifications* notifications, NSError* error) {
       if (indicator) {
         [indicator removeFromSuperview];
         indicator = nil;
       }
       self.loading = NO;
       self.notifications = notifications;
       [self handleDataItems:notifications.fields error:error reload:YES];
       if (!self.pullToRefreshHeaderViewState == GreePullToRefreshHeaderViewStateHidden) {
         [self pullToRefreshWorkFinished];
       }
       [self updateMarkasRead];
     }];
  }
}

-(NSArray*)loadFieldNames:(BOOL)reload
{
  if (self.boardType == GreeNotificationBoardTypeGame) {
    if (!reload) {
      return [NSArray arrayWithObject:kGreeOtherNotificationField];
    } else {
      return [NSArray arrayWithObjects:kGreeInviteNotificationField, kGreeTargetNotificationField, kGreeOtherNotificationField, nil];
    }
  } else if(self.boardType == GreeNotificationBoardTypeSns) {
    return [NSArray arrayWithObject:kGreeActivityNotificationField];
  } else if(self.boardType == GreeNotificationBoardTypeFriend) {
    return [NSArray arrayWithObject:kGreeFriendNotificationField];
  } else {
    return nil;
  }
}

-(void)handleDataItems:(NSArray*)dataItems error:(NSError*)error reload:(BOOL)reload
{
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  if (error) {
    NSInteger lastSectionIndex = [self.tableView numberOfSections]-1;
    if (lastSectionIndex < 0) {
      lastSectionIndex = 0;
    }
    NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex]-1;
    if (lastRowIndex < 0) {
      lastRowIndex = 0;
    }
    NSIndexPath* lastIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
    UITableViewCell* lastCell = [self.tableView cellForRowAtIndexPath:lastIndexPath];
    GreeJSDownloadIndicatorView* indicator = (GreeJSDownloadIndicatorView*)[lastCell viewWithTag:kLoadingMoreFeedIndicatorTag];
    if (indicator && indicator.isSpin) {
      [indicator pause];
    }

    if ([self.eventDelegate respondsToSelector:@selector(greeNotificationTableViewController:didFailResponseWithError:)]) {
      [self.eventDelegate greeNotificationTableViewController:self didFailResponseWithError:error];
    }
  }
  if (dataItems.count > 0) {
    if (reload) {
      [self.fieldsList removeAllObjects];
      [self.fieldsList addObjectsFromArray:dataItems];
      [self.tableView reloadData];
    } else {
      NSInteger lastSectionIndex = self.fieldsList.count;
      NSInteger lastRowIndex = [[self.fieldsList lastObject] feeds].count;
      if (lastRowIndex == NSNotFound) {
        lastRowIndex = 0;
      }
      //begin upateda
      [self.tableView beginUpdates];

      if (self.fieldsList.count == 0) {
        [self.fieldsList addObjectsFromArray:dataItems];
      } else {
        GreeNotificationField* field = [self.fieldsList lastObject];
        [field addFeedsFromField:[dataItems lastObject]];
      }
      // insert section
      for (int index = lastSectionIndex; index < self.fieldsList.count; index++) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationNone];
      }
      //update row
      NSMutableArray* paths = [NSMutableArray array];
      for (int index = lastRowIndex; index < [self rowOfLastCellInSection:self.fieldsList.count-1]; index++) {
        [paths addObject:[NSIndexPath indexPathForRow:index inSection:self.fieldsList.count-1]];
      }
      [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
      //end  update
      [self.tableView endUpdates];
    }
  }
  [self hideEmptySeparators];
}

-(int)rowOfLastCellInSection:(NSInteger)section
{
  if (section < 0) {
    return 0;
  } else {
    return [self feedsInSection:section].count;
  }
}

-(NSArray*)feedsInSection:(NSInteger)section
{
  return [[self.fieldsList objectAtIndex:section] feeds];
}

-(GreeNotificationTableViewCell*)greeNotificationTableViewCellForAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* CellIdentifier = @"GreeNotificationCell";
  GreeNotificationTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[GreeNotificationTableViewCell alloc] initWidthReuseIdentifier:CellIdentifier] autorelease];
    UIView* backgroundView = [[[UIView alloc] init] autorelease];
    [backgroundView setBackgroundColor:[[self class] feedTapHighlightColor]];
    cell.selectedBackgroundView = backgroundView;
  }
  cell.tag = NSNotFound;
  [cell.mainMessageLabel refreshText];
  cell.iconImageView.image = nil;
  cell.subMessageLabel.text = nil;
  cell.timeMessageLabel.text = nil;
  cell.imageView.image = nil;
  cell.textLabel.text = nil;
  cell.detailTextLabel.text = nil;
  cell.accessoryView = nil;
  cell.textLabel.textAlignment = UITextAlignmentLeft;
  cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
  cell.backgroundColor = [[self class] feedReadColor];
  return cell;
}

-(UITableViewCell*)normalTableViewCellForAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* CellIdentifier = @"NormalCell";
  UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc]
               initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:CellIdentifier] autorelease];
    UIView* backgroundView = [[[UIView alloc] init] autorelease];
    [backgroundView setBackgroundColor:[[self class] feedTapHighlightColor]];
    cell.selectedBackgroundView = backgroundView;
  }
  cell.accessoryView = nil;
  cell.textLabel.font = [UIFont systemFontOfSize:14.0];
  cell.textLabel.textColor = [UIColor blackColor];
  cell.textLabel.text = nil;
  cell.textLabel.textAlignment = UITextAlignmentLeft;
  cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
  cell.detailTextLabel.text = nil;
  cell.imageView.image = nil;
  return cell;
}

-(void)updateGameNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed
{
  UIImage* image;
  if (feed.unread) {
    image = [UIImage greeImageNamed:@"status_blue.png"];
  } else {
    image = [UIImage greeImageNamed:@"arrow_gray.png"];
  }
  cell.iconImageView.image = [UIImage greeImageNamed:@"game_36.png"];
  cell.accessoryView = [[[UIImageView alloc] initWithImage:image] autorelease];
}

-(void)updateSNSNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed
{
  UIImage* image;
  if (feed.unread) {
    image = [UIImage greeImageNamed:@"status_blue.png"];
  } else {
    image = [UIImage greeImageNamed:@"arrow_gray.png"];
  }
  cell.iconImageView.image = [UIImage greeImageNamed:@"user_36.png"];
  cell.accessoryView = [[[UIImageView alloc] initWithImage:image] autorelease];
}

-(void)updateFriendNotificationCell:(GreeNotificationTableViewCell*)cell feed:(GreeNotificationFeed*)feed
{
  UIButton* accesoryButtonView  = nil;
  UIImage* defaultImage         = nil;
  if ([feed.nameSpace isEqualToString:GreeNotificationFeedFriendTypeLinkPending]) {
    defaultImage = [UIImage greeImageNamed:@"btn_fr_add.png"];
  } else if ([feed.nameSpace isEqualToString:GreeNotificationFeedFriendTypeRegistration]) {
    defaultImage = [UIImage greeImageNamed:@"btn_fr_permit.png"];
  } else {
    cell.accessoryView = nil;
    return;
  }
  cell.iconImageView.image = [UIImage greeImageNamed:@"user_36.png"];
  accesoryButtonView = [UIButton buttonWithType:UIButtonTypeCustom];
  accesoryButtonView.adjustsImageWhenHighlighted = NO;
  [accesoryButtonView
          addTarget:self
             action:@selector(friendRequestButtonTapped:withEvent:)
   forControlEvents:UIControlEventTouchUpInside];
  accesoryButtonView.frame = CGRectMake(0.0, 0.0, defaultImage.size.width, defaultImage.size.height);
  [accesoryButtonView setImage:defaultImage forState:UIControlStateNormal];
  cell.accessoryView = accesoryButtonView;
}

-(void)updateNotificationCell:(GreeNotificationTableViewCell*)cell
                        field:(GreeNotificationField*)field
                         feed:(GreeNotificationFeed*)feed
{
  if (feed.unread) {
    cell.backgroundColor = [[self class] feedUnReadColor];
  }
  if ([field.fieldName isEqualToString:kGreeActivityNotificationField]) {
    [self updateSNSNotificationCell:cell feed:feed];
  } else if ([field.fieldName isEqualToString:kGreeFriendNotificationField]) {
    [self updateFriendNotificationCell:cell feed:feed];
  } else if ([field.fieldName isEqualToString:kGreeTargetNotificationField] ||
             [field.fieldName isEqualToString:kGreeOtherNotificationField]) {
    [self updateGameNotificationCell:cell feed:feed];
  }
  [cell.mainMessageLabel refreshText];
  [GreeNotificationMessage decorateMessage:feed.message data:feed.messageDatas label:cell.mainMessageLabel];
  cell.subMessageLabel.text = feed.appName;
  NSString* dateString = [GreeNotificationMessage createTimeMessage:feed.date];
  cell.timeMessageLabel.text = dateString;

  if ([feed.thumbnailPath length] == 0) return;

  NSURL* url = [NSURL URLWithString:feed.thumbnailPath];
  GreeNotifycationFeedIconPersistentCache* cache = [GreeNotifycationFeedIconPersistentCache sharedImageCache];
  UIImage* cacheImage = [cache cachedImageForURL:url];
  if (cacheImage) {
    cell.iconImageView.image = cacheImage;
  } else {
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    GreeAFHTTPRequestOperation* requestOperation = [[[GreeAFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [requestOperation setQueuePriority:NSOperationQueuePriorityHigh];
    [requestOperation setCompletionBlockWithSuccess:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
       UIImage* image = [[UIImage alloc] initWithData:[operation responseData]];
       if (image) {
         dispatch_queue_t q_global = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
         dispatch_async (q_global, ^{
                           CALayer* imageLayer = [CALayer layer];
                           imageLayer.frame = CGRectMake (0, 0, 50.0f, 50.0f);
                           imageLayer.contents = (id)image.CGImage;
                           imageLayer.masksToBounds = YES;
                           imageLayer.cornerRadius = 10.0f;

                           UIGraphicsBeginImageContext (imageLayer.frame.size);
                           [imageLayer renderInContext:UIGraphicsGetCurrentContext ()];
                           UIImage* roundedImage = UIGraphicsGetImageFromCurrentImageContext ();
                           UIGraphicsEndImageContext ();
                           dispatch_async (dispatch_get_main_queue (), ^{
                                             cell.iconImageView.image = roundedImage;
                                           });
                           NSData* imageData = UIImagePNGRepresentation (roundedImage);
                           if (imageData) {
                             [[GreeNotifycationFeedIconPersistentCache sharedImageCache]
                              cacheImageData:imageData
                                      forURL:url];
                           }
                           [image release];
                         });
       }
     }
                                            failure:nil];
    [self.queue addOperation:requestOperation];
  }
}

-(void)updateCell:(GreeNotificationTableViewCell*)cell indexPath:(NSIndexPath*)indexPath
{
  GreeJSDownloadIndicatorView* indicator =  (GreeJSDownloadIndicatorView*)[cell viewWithTag:kLoadingMoreFeedIndicatorTag];
  [indicator removeFromSuperview];

  GreeNotificationField* field = [self.fieldsList objectAtIndex:indexPath.section];
  NSArray* feeds = field.feeds;
  if ([field.fieldName isEqualToString:kGreeInviteNotificationField]) {
    return;
  } else {
    if (feeds.count == 0) {
      cell.textLabel.font = [UIFont systemFontOfSize:14.0];
      cell.textLabel.textColor = [UIColor colorWithRed:119.0/255.0 green:136.0/255.0 blue:153.0/255.0 alpha:1.0];
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.text = GreePlatformString(@"Notification.Popupboard.Nothingfeed.Cell.Title", @"No notifications.");
    } else if([field.fieldName isEqualToString:kGreeTargetNotificationField]) {
      if (indexPath.row == 3) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.textLabel.text = GreePlatformString(@"Notification.Popupboard.Show.All.Feed.Cell.Title", @"See all notifications");
      } else {
        GreeNotificationFeed* feed = [feeds objectAtIndex:indexPath.row];
        [self updateNotificationCell:(GreeNotificationTableViewCell*)cell field:[self.fieldsList objectAtIndex:indexPath.section] feed:feed];
      }
    } else {
      if (indexPath.row >= 0 && indexPath.row < [feeds count]) {
        GreeNotificationFeed* feed = [feeds objectAtIndex:indexPath.row];
        [self updateNotificationCell:(GreeNotificationTableViewCell*)cell field:[self.fieldsList objectAtIndex:indexPath.section] feed:feed];
      } else if (indexPath.row >= feeds.count) {
        if (field.hasMore) {
          indicator = [GreeJSDownloadIndicatorView downloadIndicator];
          indicator.tag = kLoadingMoreFeedIndicatorTag;
          indicator.center = CGPointMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds));
          indicator.block =^(GreeJSDownloadIndicatorView* view) {
            if (!view.isSpin) {
              [view spin];
              [self loadAutoPagerizeFeedsWithField:[self loadFieldNames:NO]
                                            offset:field.offset+field.limit
                                             limit:GreeMaxLoadNotificationFeed];
            }
          };
          [cell addSubview:indicator];
          cell.tag = kLoadingFeedCellTag;
        } else {
          cell.tag = kNothingMoreFeedCellTag;
        }
      }
    }
  }
}

-(void)friendRequestButtonTapped:(id)sender withEvent:(UIEvent*)event
{
  UIButton* button = (UIButton*)sender;
  NSIndexPath* indexPath = [self.tableView
                            indexPathForRowAtPoint:[[[event touchesForView: button] anyObject]
                                                    locationInView: self.tableView]];
  if (indexPath == nil) {
    return;
  }
  GreeNotificationField* field = [self.fieldsList objectAtIndex:indexPath.section];
  NSMutableArray* feeds = (NSMutableArray*)field.feeds;
  if (indexPath.row >= 0 && indexPath.row < [feeds count]) {
    UIView* accessoryView = [self.tableView cellForRowAtIndexPath:indexPath].accessoryView;
    GreeJSLoadingIndicatorView* processing = [[GreeJSLoadingIndicatorView alloc]
                                              initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypePullToRefresh];
    processing.frame = accessoryView.bounds;
    [accessoryView addSubview:processing];
    [processing release];

    GreeNotificationFeed* feed = [feeds objectAtIndex:indexPath.row];
    [GreeLinkedFriend
     linkFriendWithKey:feed.feedKey
          successBlock:^(void) {
       [self.tableView beginUpdates];
       [feeds removeObjectAtIndex:indexPath.row];
       [self.tableView
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
       [self.tableView endUpdates];

       [self updateBadge];
       [GreeNotifications
        deleteCacheFeedFriendWithFeedKey:feed.feedKey
                                cacheKey:GreeFriendNotificationCacheKey];
     } failureBlock:^(NSError* error) {
       [processing removeFromSuperview];
       if (error) {
         if ([self.eventDelegate
              respondsToSelector:@selector(greeNotificationTableViewController:didFailResponseWithError:)]) {
           [self.eventDelegate
            greeNotificationTableViewController:self didFailResponseWithError:error];
         }
       }
     }];
  }
}

-(void)updateBadge
{
  [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:nil];
}

-(void)reload
{
  self.loading = NO;
  [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:^(GreeBadgeValues* badgeValues) {
     [self loadNewestFeedsWithField:[self loadFieldNames:YES] offset:0 limit:GreeMaxLoadNotificationFeed cache:NO];
   }];
}

-(UITableViewCell*)inviteCellForRowAtIndexPath:(NSIndexPath*)indexPath fileld:(GreeInviteNotificationField*)field
{
  static NSString* CellIdentifier = @"InviteCell";
  GreeInviteTableViewCell* cell = (GreeInviteTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if(cell == nil) {
    cell = [[[GreeInviteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
    cell.textLabel.text = field.message;
    cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"arrow_gray.png"]] autorelease];
    UIView* backgroundView = [[[UIView alloc] init] autorelease];
    [backgroundView setBackgroundColor:[[self class] feedTapHighlightColor]];
    cell.selectedBackgroundView = backgroundView;
  }
  cell.backgroundColor = [[self class] feedReadColor];
  cell.text = field.message;
  cell.count = field.unreadInvite;
  return cell;
}

-(void)hideEmptySeparators
{
  UIView* v = [[UIView alloc] initWithFrame:CGRectZero];
  v.backgroundColor = [UIColor clearColor];
  [self.tableView setTableFooterView:v];
  [v release];
}

-(void)updateMarkasRead
{
  NSString* readType = nil;
  NSString* appId = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSString* cacheKey = nil;
  GreeBadgeValues* badgeValues = [GreePlatform sharedInstance].badgeValues;
  if (self.boardType == GreeNotificationBoardTypeGame) {
    if (badgeValues.applicationBadgeCount == 0) {
      return;
    }
    readType = GreeMarkasReadTypeGame;
    cacheKey = GreeGameNotificationCacheKey;
  } else if (self.boardType == GreeNotificationBoardTypeSns) {
    if (badgeValues.snsBadgeCount == 0) {
      return;
    }
    readType = GreeMarkasReadTypeActivity;
    cacheKey = GreeSNSNotificationCacheKey;
  } else if (self.boardType == GreeNotificationBoardTypeFriend) {
    if (badgeValues.friendBadgeCount == 0) {
      return;
    }
    readType = GreeMarkasReadTypeFriend;
    cacheKey = GreeFriendNotificationCacheKey;
  }
  [GreeMarkasRead
   markasReadWithType:readType
               endkey:nil
                appId:[appId intValue]
         successBlock:^{
     [self updateBadge];
     [GreeNotifications
      updateCacheFeedMarkReadWithType:readType
                             cacheKey:cacheKey];
   }
         failureBlock:nil];
}

-(void)pullToRefreshWorkFinished
{
  self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStateHidden;
  [(GreeJSPullToRefreshHeaderView*)self.tableView.tableHeaderView updateTimeOfRefreshed];
  [(GreeJSPullToRefreshHeaderView*)self.tableView.tableHeaderView nowLoading : NO];
  [self setHeaderViewHidden:YES animated:YES];
}

+(UIColor*)feedReadColor
{
  return [UIColor
          colorWithRed:0xf4/255.0f
                 green:0xf5/255.0f
                  blue:0xf6/255.0f
                 alpha:1.0];
}

+(UIColor*)feedUnReadColor
{
  return [UIColor whiteColor];
}

+(UIColor*)feedTapHighlightColor
{
  return [UIColor colorWithRed:0.f/255.f green:160.f/255.f blue:220.f/255.f alpha:1.f];
}

#pragma mark - Table view data source

-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  GreeNotificationField* field = [self.fieldsList objectAtIndex:section];
  if ([field.fieldName isEqualToString:kGreeInviteNotificationField]) {
    return GreePlatformString(@"Notification.Popupboard.Section.Header.Title.Invite", @"App Invites");
  } else if ([field.fieldName isEqualToString:kGreeTargetNotificationField]) {
    return self.notifications.appName;
  } else if ([field.fieldName isEqualToString:kGreeOtherNotificationField]) {
    return GreePlatformString(@"Notification.Popupboard.Section.Header.Title.Other", @"Other Apps");
  }
  return nil;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return self.fieldsList.count;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  GreeNotificationField* field = [self.fieldsList objectAtIndex:section];
  NSInteger rows = field.feeds.count;
  if ([field.fieldName isEqualToString:kGreeInviteNotificationField]) {
    return 1;
  } else if ([field.fieldName isEqualToString:kGreeTargetNotificationField]) {
    if (rows > 3) {
      return 4;  // feeds cell and show all feeds cell
    } else if (rows == 0) {
      return 1;
    } else {
      return rows;
    }
  }
  return rows+1;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  GreeNotificationField* field = [self.fieldsList objectAtIndex:indexPath.section];
  if ([field.fieldName isEqualToString:kGreeInviteNotificationField]) {
    return [self inviteCellForRowAtIndexPath:indexPath fileld:(GreeInviteNotificationField*)field];
  } else {
    GreeNotificationTableViewCell* cell = [self greeNotificationTableViewCellForAtIndexPath:indexPath];
    [self updateCell:cell indexPath:indexPath];
    return cell;
  }
}

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
  GreeNotificationField* field = [self.fieldsList objectAtIndex:section];
  if ([field.fieldName isEqualToString:kGreeFriendNotificationField] ||
      [field.fieldName isEqualToString:kGreeActivityNotificationField]) {
    return 0.0f;
  }
  return 24.0f;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
    return;
  }

  NSString* feedUrl = nil;
  BOOL launchExternal = NO;
  GreeNotificationField* field = [self.fieldsList objectAtIndex:indexPath.section];
  if (field.feeds.count < indexPath.row+1) {
    feedUrl = field.url;
  } else if ([field.fieldName isEqualToString:kGreeTargetNotificationField]
             && indexPath.row == 3) {
    feedUrl = field.url;
  } else {
    GreeNotificationFeed* feed = [field.feeds objectAtIndex:indexPath.row];
    feedUrl = feed.url;
    launchExternal = feed.launchExternal;
  }
  if ([self.eventDelegate respondsToSelector:@selector(greeNotificationTableViewController:didSelectFeedUrl:launchExternal:)]) {
    [self.eventDelegate greeNotificationTableViewController:self didSelectFeedUrl:feedUrl launchExternal:launchExternal];
  }
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  GreeNotificationTableViewCell* cell =
    (GreeNotificationTableViewCell*)[self tableView:self.tableView cellForRowAtIndexPath:indexPath];
  if (cell.tag == kNothingMoreFeedCellTag) {
    return 0.0;
  } else if (cell.tag == kLoadingFeedCellTag) {
    return 56.0;
  }
  if ([cell respondsToSelector:@selector(cellHeight:)]) {
    return [cell cellHeight:self.tableView.bounds.size.width];
  }
  return 56.0;
}

-(void)  tableView:(UITableView*)tableView
   willDisplayCell:(UITableViewCell*)cell
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (cell.tag == kLoadingFeedCellTag) {
    GreeJSDownloadIndicatorView* indicator = (GreeJSDownloadIndicatorView*)[cell viewWithTag:kLoadingMoreFeedIndicatorTag];
    if (indicator && !indicator.isSpin) {
      [indicator spin];
    }
    GreeNotificationField* field = [self.fieldsList objectAtIndex:indexPath.section];
    [self loadAutoPagerizeFeedsWithField:[self loadFieldNames:NO] offset:field.offset+field.limit limit:GreeMaxLoadNotificationFeed];
  }
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
  GreeNotificationField* field = [self.fieldsList objectAtIndex:section];
  if ([field.fieldName isEqualToString:kGreeFriendNotificationField]
      || [field.fieldName isEqualToString:kGreeActivityNotificationField]) {
    return nil;
  }
  UIView* header = [[[GreeNotificationFieldHeaderView alloc]
                     initWithFrame:CGRectMake(0.0,
                                              0.0,
                                              self.tableView.frame.size.width,
                                              24.0)] autorelease];
  UILabel* label = [[[UILabel alloc] initWithFrame:CGRectInset(header.frame, 10.0, 0)] autorelease];
  label.backgroundColor = [UIColor clearColor];
  label.textColor = [UIColor colorWithRed:119.0/255.0 green:136.0/255.0 blue:153.0/255.0 alpha:1.0];
  label.layer.shadowColor = [UIColor colorWithRed:235.0/255.0 green:240.0/255.0 blue:245.0/255.0 alpha:1.0].CGColor;
  label.layer.shadowOffset = CGSizeMake(0.0, -1.0);
  label.textAlignment = UITextAlignmentLeft;
  label.font = [UIFont boldSystemFontOfSize:14.0];
  label.text = [self tableView:tableView titleForHeaderInSection:section];
  [header addSubview:label];
  return header;
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView*)scrollView
{
  if (self.pullToRefreshHeaderViewState == GreePullToRefreshHeaderViewStateStopping) {
    return;
  }
  CGFloat threshold = self.tableView.tableHeaderView.frame.size.height;
  GreeJSPullToRefreshHeaderView* pullToRefView = (GreeJSPullToRefreshHeaderView*)self.tableView.tableHeaderView;

  [UIView beginAnimations:nil context:NULL];
  if (kGreeJSRefreshHeaderMargin <= scrollView.contentOffset.y &&
      scrollView.contentOffset.y < threshold) {
    self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStatePullingDown;
    pullToRefView.refreshLabel.text = pullToRefView.textPullToRefresh;
    [pullToRefView.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
  } else if (scrollView.contentOffset.y < kGreeJSRefreshHeaderMargin) {
    pullToRefView.refreshLabel.text = pullToRefView.textReleaseToRefresh;
    [pullToRefView.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
    self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStateOveredThreshold;
  } else {
    self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStateHidden;
  }
  [UIView commitAnimations];
}

-(void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
  if (self.pullToRefreshHeaderViewState == GreePullToRefreshHeaderViewStateOveredThreshold) {
    self.pullToRefreshHeaderViewState = GreePullToRefreshHeaderViewStateStopping;
    [self setHeaderViewHidden:NO animated:YES];
    [(GreeJSPullToRefreshHeaderView*)self.tableView.tableHeaderView nowLoading : YES];
    [self reload];
  }
}

@end
