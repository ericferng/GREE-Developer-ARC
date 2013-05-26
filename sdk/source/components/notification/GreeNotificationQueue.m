//
// Copyright 2011 GREE, Inc.
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

#import "GreeNotificationQueue.h"
#import "GreeNotificationContainerView.h"
#import "GreeNotificationView.h"
#import "GreeNotification+Internal.h"
#import "GreeDashboardViewController.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeJSExternalWebViewController.h"
#import "GreeJSWebViewController.h"
#import "UIImage+GreeAdditions.h"
#import "GreeSettings.h"
#import "GreePlatform+Internal.h"
#import "GreeUser.h"
#import "GreeDashboardViewControllerLaunchMode.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "UIView+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeAnalyticsEvent.h"

#define HALF_OF(x) (x / 2.0f)

/**
 * We match a GreeNotificationView to a GreeNotification using the notification's index
 * in the array.  A UIView should not have a tag of 0, however, so we use this macro to
 * make the adjustment.
 */
#define TAG_FROM_INDEX(x) x+1

#define DEGREES_TO_RADIANS(x) M_PI * (x) / 180.0

@interface GreeNotificationQueue ()
@property (nonatomic, readwrite, retain) NSMutableArray* notifications;
@property (nonatomic, readwrite, retain) GreeNotificationContainerView* notificationContainerView;
@property (nonatomic, readwrite, retain) NSTimer* notificationDisplayDurationTimer;
@property (nonatomic, readwrite, assign) BOOL showingNextNotificationView;
@property (nonatomic, readwrite, assign) BOOL removingNotificationContainerView;

-(void)createAndDisplayNotificationContainerView;
-(void)pruneNotificationContainerView;
-(void)addNotificationViewAtIndex:(NSUInteger)anIndex;
-(void)scheduleNotificationChange;
-(void)notificationFinishedDisplaying;
-(void)showNotificationViewAnimated:(BOOL)animated;
-(void)showNextNotificationAnimated:(BOOL)animated;
-(void)removeNotificationViewAnimated:(BOOL)animated;
@end

@interface GreePlatform (GreeNotificationsInternal)
-(id)rawNotificationQueue;
@end

@implementation GreeNotificationQueue

#pragma mark - Object Lifecycle

GREEPLATFORM_AUTOREGISTER_COMPONENT

-(id)initWithSettings:(GreeSettings*)settings
{
  if ((self = [super init])) {
    self.notifications = [NSMutableArray arrayWithCapacity:8];
    self.displayPosition = GreeNotificationDisplayTopPosition;

    self.removingNotificationContainerView = NO;
    self.showingNextNotificationView = NO;

    self.notificationsEnabled = YES;

    if([settings settingHasValue:GreeSettingNotificationPosition]) {
      self.displayPosition = [settings integerValueForSetting:GreeSettingNotificationPosition];
    }

    if([settings settingHasValue:GreeSettingNotificationEnabled]) {
      self.notificationsEnabled = [settings boolValueForSetting:GreeSettingNotificationEnabled];
    }
  }

  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self.notificationDisplayDurationTimer invalidate];
  self.notificationDisplayDurationTimer = nil;

  [self pruneNotificationContainerView];

  self.notifications = nil;

  [super dealloc];
}

#pragma mark - Public Interface

-(void)addNotification:(GreeNotification*)notification
{
  UIViewController* lastPresentedViewController = [UIViewController greeLastPresentedViewController];

  if (!self.notificationsEnabled || ![lastPresentedViewController greeShouldShowGreeNotification]) {
    return;
  }

  __block GreeNotificationQueue* queue = self;

  //will be added when the icon is loaded, errors are currently being ignored
  [notification loadIconWithBlock:^(NSError* error) {
     [queue.notifications addObject:notification];
     if (queue.notifications.count == 1) {
       dispatch_async(dispatch_get_main_queue(), ^{
                        [queue createAndDisplayNotificationContainerView];
                      });
     }
   }];
}

#pragma mark - NSObject overrides
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, notification count:%d, displayPosition:%@>",
          NSStringFromClass([self class]),
          self,
          [self.notifications count],
          NSStringFromGreeNotificationDisplayPosition(self.displayPosition)];
}

#pragma mark - Internal Methods
-(void)createAndDisplayNotificationContainerView
{
  NSAssert(self.notificationContainerView == nil, @"Trying to display a new notification view while it is already being displayed");
  NSAssert([self.notifications count] > 0, @"Displaying a notification view without any notifications.");

  self.notificationContainerView = [[[GreeNotificationContainerView alloc] initWithDisplayPosition:self.displayPosition] autorelease];
  self.notificationContainerView.alpha = 0.0f;


  UIViewController* viewController = [UIViewController greeLastPresentedViewController];
  [self.notificationContainerView greeAddRotatingSubviewToViewController:viewController];

  [self addNotificationViewAtIndex:0];
  [self showNotificationViewAnimated:YES];
  [self scheduleNotificationChange];
}

-(void)pruneNotificationContainerView
{
  [self.notificationContainerView greeRemoveRotatingSubviewFromSuperview];
  self.notificationContainerView = nil;
}

-(void)addNotificationViewAtIndex:(NSUInteger)anIndex
{
  NSAssert([self.notifications count] > anIndex, @"The notification index is higher than the number of notifications");

  CGSize containerSize = self.notificationContainerView.contentView.frame.size;

  GreeNotification* notification = [self.notifications objectAtIndex:anIndex];

  GreeNotificationView* notificationView = [[GreeNotificationView alloc]
                                            initWithMessage:notification.message
                                                       icon:notification.iconImage
                                                badgeString:notification.badgeString
                                                      frame:CGRectMake(0.0f, -containerSize.height * anIndex, containerSize.width, containerSize.height)];

  notificationView.tag = TAG_FROM_INDEX(anIndex);
  notificationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;

  if (notification.displayType == GreeNotificationViewDisplayCloseType) {
    notificationView.showsCloseButton = YES;
  }

  UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                  initWithTarget:self
                                                          action:@selector(notificationViewTapped:)
                                                 ];

  tapGestureRecognizer.delegate = self;
  [notificationView addGestureRecognizer:tapGestureRecognizer];
  [tapGestureRecognizer release];

  [notificationView.closeButton
          addTarget:self
             action:@selector(closeButtonPressed:)
   forControlEvents:UIControlEventTouchUpInside];

  [self.notificationContainerView.contentView addSubview:notificationView];
  [notificationView release];
}

-(void)scheduleNotificationChange
{
  NSAssert([self.notifications count] > 0, @"Scheduling a notification queue change with no notifications.");

  GreeNotification* notification = [self.notifications objectAtIndex:0];

  if (notification.duration < GreeNotificationInfiniteDuration) {
    self.notificationDisplayDurationTimer = [NSTimer scheduledTimerWithTimeInterval:notification.duration
                                                                             target:self
                                                                           selector:@selector(notificationFinishedDisplaying)
                                                                           userInfo:nil
                                                                            repeats:NO];
  }
}

-(void)notificationFinishedDisplaying
{
  NSAssert([self.notifications count] > 0, @"Updating notification view with no notifications.");
  self.notificationDisplayDurationTimer = nil;

  if ([self.notifications count] > 1) {
    [self addNotificationViewAtIndex:1];
    [self showNextNotificationAnimated:YES];
  } else {
    [self removeNotificationViewAnimated:YES];
  }
}

-(void)showNotificationViewAnimated:(BOOL)animated
{
  GreeNotificationContainerView* view = self.notificationContainerView;
  void (^viewChanges)(void) =^{
    view.alpha = 1.0f;
  };

  if (animated) {
    [UIView animateWithDuration:0.5f
                     animations:viewChanges];
  } else {
    viewChanges();
  }
}

-(void)showNextNotificationAnimated:(BOOL)animated
{
  if (self.showingNextNotificationView) {
    return;
  }

  NSAssert([self.notifications count] > 1, @"Switching notifications without two notifications in the queue");

  self.showingNextNotificationView = YES;

  GreeNotificationView* currentView = (GreeNotificationView*)[self.notificationContainerView viewWithTag:TAG_FROM_INDEX(0)];
  GreeNotificationView* nextView = (GreeNotificationView*)[self.notificationContainerView viewWithTag:TAG_FROM_INDEX(1)];

  void (^viewChanges)(void) =^{
    currentView.frame = CGRectMake(
      0.0f,
      currentView.bounds.size.height,
      currentView.bounds.size.width,
      currentView.bounds.size.height
      );
    nextView.frame = CGRectMake(
      0.0f,
      0.0f,
      nextView.bounds.size.width,
      nextView.bounds.size.height
      );
  };

  void (^completionHandler)(BOOL) =^(BOOL finished) {
    [currentView removeFromSuperview];
    nextView.tag = TAG_FROM_INDEX(0);
    [self.notifications removeObjectAtIndex:0];
    [self scheduleNotificationChange];
    self.showingNextNotificationView = NO;
  };

  if (animated) {
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:0
                     animations:viewChanges
                     completion:completionHandler];
  } else {
    viewChanges();
    completionHandler(YES);
  }
}

-(void)removeNotificationViewAnimated:(BOOL)animated
{
  if (self.removingNotificationContainerView) {
    return;
  }

  NSAssert([self.notifications count] > 0, @"Removing the notification container without having displayed the last notification");

  self.removingNotificationContainerView = YES;

  GreeNotificationContainerView* view = self.notificationContainerView;
  void (^viewChanges)(void) =^{
    view.alpha = 0.0f;
  };

  void (^completionHandler)(BOOL) =^(BOOL finished) {
    [self pruneNotificationContainerView];
    [self.notifications removeObjectAtIndex:0];

    if ([self.notifications count] > 0) {
      [self createAndDisplayNotificationContainerView];
    }

    self.removingNotificationContainerView = NO;
  };

  if (animated) {
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:0
                     animations:viewChanges
                     completion:completionHandler
    ];
  } else {
    viewChanges();
    completionHandler(YES);
  }
}



#pragma mark - UIGestureRecognizer target method
-(void)notificationViewTapped:(UIGestureRecognizer*)gestureRecognizer
{
  NSAssert([self.notifications count] > 0, @"Notification tapped but notification does not exist");
  NSDictionary* info = [[self.notifications objectAtIndex:0] infoDictionary];
  NSString* type = [info objectForKey:@"type"];
  gestureRecognizer.enabled = NO;
  NSString* analyticsEventName = nil;
  NSDictionary* analyticsEventParameters = nil;

  if([type isEqualToString:@"dash"]) {
    int subType = [[info objectForKey:@"subtype"] intValue];
    NSDictionary* parameters = nil;

    switch (subType) {
    case GreeNotificationSourceMyLogin:
    {
      if ([GreePlatform isSnsApp]) {
        break;
      }
      UIViewController* viewController = [[[[UIApplication sharedApplication]
                                            keyWindow] rootViewController] greeLastPresentedViewController];
      NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                  GreeDashboardModeGameNotice, GreeDashboardMode,
                                  nil];
      [viewController presentGreeDashboardWithParameters:parameters animated:YES];

      NSURL* url = [GreeDashboardViewController dashboardURLWithParameters:parameters];
      analyticsEventName = [url absoluteString];
      break;
    }
    case GreeNotificationSourceFriendLogin:
    {
      NSString* urlString = [NSString stringWithFormat:@"%@%@&user_id=%@", [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlSns], [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingFriendLoginNotificationPath], [info objectForKey:@"actor_id"]];
      NSURL* url = [NSURL URLWithString:urlString];
      UIViewController* viewController = [[[[UIApplication sharedApplication]
                                            keyWindow] rootViewController] greeLastPresentedViewController];
      [viewController
       presentGreeDashboardWithBaseURL:url
                              delegate:viewController
                              animated:YES
                            completion:nil];

      analyticsEventName = [[[url query] greeDictionaryFromQueryString] objectForKey:@"view"];
      analyticsEventParameters = [NSDictionary dictionaryWithObject:[info objectForKey:@"actor_id"] forKey:@"user_id"];
      break;
    }
    case GreeNotificationSourceMyAchievementUnlocked:
    {
      parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                    GreeDashboardModeAchievementList, GreeDashboardMode,
                    nil];
      [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
      break;
    }
    case GreeNotificationSourceFriendAchievementUnlocked:
    {
      parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                    GreeDashboardModeAchievementList, GreeDashboardMode,
                    [info objectForKey:@"actor_id"], GreeDashboardUserId,
                    nil];
      [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
      break;
    }
    case GreeNotificationSourceMyHighScore:
    {
      parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                    GreeDashboardModeRankingDetails, GreeDashboardMode,
                    [info objectForKey:@"cid"], GreeDashboardLeaderboardId,
                    nil];
      [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
      break;
    }
    case GreeNotificationSourceFriendHighScore:
    {
      parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                    GreeDashboardModeRankingDetails, GreeDashboardMode,
                    [info objectForKey:@"actor_id"], GreeDashboardUserId,
                    [info objectForKey:@"cid"], GreeDashboardLeaderboardId,
                    nil];
      [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
      break;
    }
    default:
      break;
    }
  } else if([type isEqualToString:@"message"] ||
            [type isEqualToString:@"request"]) {
    UIViewController* viewController = [[[[UIApplication sharedApplication]
                                          keyWindow] rootViewController] greeLastPresentedViewController];

    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                GreeDashboardModeGameNotice, GreeDashboardMode,
                                nil];
    [viewController presentGreeDashboardWithParameters:parameters animated:YES];

    NSURL* url = [GreeDashboardViewController dashboardURLWithParameters:parameters];
    analyticsEventName = [url absoluteString];
  }

  if (analyticsEventName) {
    [[GreePlatform sharedInstance] addAnalyticsEvent:
     [GreeAnalyticsEvent eventWithType:@"pg"
                                  name:analyticsEventName
                                  from:@"in_game_notification"
                            parameters:analyticsEventParameters]];
  }
}

#pragma mark - UIGestureRecognizer delegate method
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
  GreeNotificationView* currentView = (GreeNotificationView*)[self.notificationContainerView viewWithTag:TAG_FROM_INDEX(0)];

  if ([touch.view isDescendantOfView:currentView.closeButton]) {
    return NO;
  }

  return YES;
}

-(void)closeButtonPressed:(id)sender
{
  [self.notificationDisplayDurationTimer invalidate];
  self.notificationDisplayDurationTimer = nil;

  if ([self.notifications count] > 0) {
    [self notificationFinishedDisplaying];
  }
}

#pragma mark - GreeComponent Protocol

+(id)componentWithSettings:(GreeSettings*)settings
{
  id<GreePlatformComponent> obj = [[[[self class] alloc] initWithSettings:settings] autorelease];

  return obj;
}

-(void)userLoggedIn:(GreeUser*)user
{
  dispatch_after
  (
    dispatch_time(DISPATCH_TIME_NOW, 2.0f * NSEC_PER_SEC),
    dispatch_get_current_queue(),
    ^{
      dispatch_async
      (
        dispatch_get_main_queue(),
        ^{[self addNotification:[GreeNotification notificationForLoginWithUsername:user.nickname]]; }
      );
    }
  );
}

-(void)handleRemoteNotification:(NSDictionary*)notificationDictionary
{
  GreeNotification* notification = [GreeNotification notificationWithAPSDictionary:notificationDictionary];

  if(notification)
    [self addNotification:notification];
}

@end

@implementation GreePlatform (GreeNotifications)
-(GreeNotificationQueue*)notificationQueue
{
  return (GreeNotificationQueue*)[self rawNotificationQueue];  //rather circular, isn't it?
}
@end


