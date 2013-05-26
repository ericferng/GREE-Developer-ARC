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
#import "GreeNotificationNavigationController.h"
#import "GreeNotificationTableViewController.h"
#import "UINavigationBar+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "NSObject+GreeAdditions.h"
#import "GreeNoticeView.h"

@interface GreeNotificationNavigationController ()<GreeNotificationTableViewControllerDelegate>
@property (nonatomic, retain) GreeNotificationTableViewController* tableViewController;
-(NSString*)notificationsNameWithType:(GreeNotificationBoardType)type;
-(void)titleBarTapped:(id)sender;
@end

@implementation GreeNotificationNavigationController

#pragma mark - Objecdt lifecycle

-(void)dealloc
{
  self.tableViewController.eventDelegate = nil;
  self.topBar = nil;
  self.titleLabel = nil;
  self.tableViewController = nil;
  [super dealloc];
}

-(void)viewDidLoad
{
  self.tableViewController.view.frame = CGRectMake(0.0,
                                                   self.topBar.frame.size.height,
                                                   self.view.frame.size.width,
                                                   self.view.frame.size.height-self.topBar.frame.size.height);
  [self.view addSubview:self.tableViewController.view];
  self.titleLabel.text = [self notificationsNameWithType:self.boardType];

  UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleBarTapped:)];
  gesture.numberOfTapsRequired = 1;
  gesture.numberOfTouchesRequired = 1;
  [self.topBar addGestureRecognizer:gesture];
  [gesture release];

  if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] == NSOrderedAscending) {
    [self.tableViewController viewDidAppear:YES];
  }
}

-(id)initWithNotificationType:(GreeNotificationBoardType)boardType
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.tableViewController = [[[GreeNotificationTableViewController alloc]
                                 initWithNotificationType:boardType
                                                    style:UITableViewStylePlain] autorelease];
    self.tableViewController.eventDelegate = self;
    _boardType = boardType;
  }
  return self;
}

#pragma mark - Public Interface

-(void)setBoardType:(GreeNotificationBoardType)boardType
{
  if (self.boardType == boardType) {
    return;
  }
  _boardType = boardType;
  self.titleLabel.text = [self notificationsNameWithType:self.boardType];
  [self.tableViewController setBoardType:boardType];
}

#pragma mark - Internal Method

-(UINavigationBar*)topBar
{
  if (!_topBar) {
    _topBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0)];
    _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIImage* image = [[UIImage greeImageNamed:@"nb-window-navibar-bg.png"] stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
    if ([_topBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
      [_topBar setBackgroundImage:image
                    forBarMetrics:UIBarMetricsDefault];
      [_topBar setBackgroundImage:image
                    forBarMetrics:UIBarMetricsLandscapePhone];
    } else {
      UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
      imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      CGRect theFrame = _topBar.frame;
      theFrame.size.height += 3.f;
      imageView.frame = theFrame;
      [_topBar insertSubview:imageView atIndex:0];
      [imageView release];
    }
  }
  return _topBar;
}

-(UILabel*)titleLabel
{
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] initWithFrame:self.topBar.frame];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_titleLabel setBackgroundColor:[UIColor clearColor]];
    [_titleLabel setTextAlignment:UITextAlignmentCenter];
    [_titleLabel setTextColor:[UIColor whiteColor]];
    [_titleLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
  }
  return _titleLabel;
}

-(NSString*)notificationsNameWithType:(GreeNotificationBoardType)type
{
  NSString* title = @"";
  if (type == GreeNotificationBoardTypeSns) {
    title = GreePlatformString(@"Notification.Popupboard.Title.SNS", @"Social Notifications");
  } else if (type == GreeNotificationBoardTypeFriend) {
    title = GreePlatformString(@"Notification.Popupboard.Title.Friend", @"Friends' Notifications");
  } else if (type == GreeNotificationBoardTypeGame) {
    title = GreePlatformString(@"Notification.Popupboard.Title.Game", @"App Notifications");
  }
  return title;
}

-(void)titleBarTapped:(id)sender
{
  [self.tableViewController.tableView
   scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
         atScrollPosition:UITableViewRowAnimationTop
                 animated:YES];
}

#pragma mark - GreeNotificationTableViewController delegate method

-(void)greeNotificationTableViewController:(GreeNotificationTableViewController*)controller
                          didSelectFeedUrl:(NSString*)url
                            launchExternal:(BOOL)launchExternal

{
  if ([self.delegate respondsToSelector:@selector(didSelectedFeedUrl:launchExternal:controller:)]) {
    [self.delegate didSelectedFeedUrl:url launchExternal:launchExternal controller:self];
  }
}

-(void)greeNotificationTableViewController:(GreeNotificationTableViewController*)controller didFailResponseWithError:(NSError*)error
{
  if ([error.domain isEqualToString:NSURLErrorDomain]) {
    [GreeNoticeView
     postWithParentView:self.view
              alignment:GreeNoticeViewPositionTop
                message:GreePlatformString(@"errorHandling.noInternetConnection", @"No internet connection")
     positionAdjustment:CGPointMake(0.f, self.topBar.frame.size.height-4.f)];
  }
}

@end
