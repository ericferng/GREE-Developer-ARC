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

#import "GreePlatform.h"
#import "GreeNetworkReachability.h"
#import "GreeAuthorization.h"
#import "GreeJSPopupNeedUpgradeCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeNotificationBoardViewController.h"


#define kGreeJSPopupNeedUpgradeCommand @"callback"


@interface GreeJSPopupNeedUpgradeCommand ()
@property (nonatomic, assign) BOOL haveBeenDismissed;
@property (assign, getter = isValid) BOOL valid;
-(void)succeeded:(NSDictionary*)parameters;
-(void)failed:(NSDictionary*)parameters;
-(void)greePopupDidDismissNotification:(NSNotification*)aNotification;
-(void)needUpgradeCallback:(NSDictionary*)parameters;
@end


@implementation GreeJSPopupNeedUpgradeCommand

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super init];
  if (self) {
    self.haveBeenDismissed = NO;
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(greePopupDidDismissNotification:)
            name:GreePopupDidDismissNotification
          object:nil];
  }

  return self;
}

-(void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.valid = NO;

  [super dealloc];
}


#pragma mark - GreeJSCommand Overrides

+(NSString*)name
{
  return @"need_upgrade";
}

-(void)execute:(NSDictionary*)params
{
  if (![[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    [[GreePlatform sharedInstance] showNoConnectionModelessAlert];
    [self failed:params];
    return;
  }

  [self retain];
  self.valid = YES;

  [[GreeAuthorization sharedInstance]
   upgradeWithParams:params
        successBlock:^{
     if (self.isValid) {
       //Without delaytime, get request is sent instead of post when reloading post request.
       [self performSelector:@selector(succeeded:) withObject:params afterDelay:0.5f];
     }
   }
        failureBlock:^{
     if (self.isValid) {
       [self performSelector:@selector(failed:) withObject:params afterDelay:0.f];
     }
   }];
}


#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, environment:%@>",
          NSStringFromClass([self class]), self, self.environment];
}


#pragma mark - Internal Methods

-(void)succeeded:(NSDictionary*)parameters
{
  if ([parameters objectForKey:kGreeJSPopupNeedUpgradeCommand]) {
    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [results setObject:@"success" forKey:@"result"];
    [self needUpgradeCallback:results];
  } else {
    [[self.environment webviewForCommand:self] reload];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self name:GreePopupDidDismissNotification object:nil];
  [self callback];
  [self release];
}

-(void)failed:(NSDictionary*)parameters
{
  if ([parameters objectForKey:kGreeJSPopupNeedUpgradeCommand]) {
    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [results setObject:@"fail" forKey:@"result"];
    [self needUpgradeCallback:results];
  } else {
    UIViewController* aViewController = [self.environment viewControllerForCommand:self];
    if ([aViewController isKindOfClass:[GreePopup class]]) {
      GreePopup* aPopup = (GreePopup*)aViewController;

      if (!self.haveBeenDismissed &&
          [aPopup.popupView.delegate respondsToSelector:@selector(popupViewDidCancel)]) {
        [aPopup.popupView.delegate popupViewDidCancel];
      }
    } else if ([aViewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                       [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
                     });
    } else {
      // no thing for dashboard
    }
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self name:GreePopupDidDismissNotification object:nil];
  [self callback];
  [self release];
}

-(void)greePopupDidDismissNotification:(NSNotification*)aNotification
{
  id aSender = [aNotification.userInfo objectForKey:@"sender"];
  if (aSender == [self.environment viewControllerForCommand:self]) {
    self.haveBeenDismissed = YES;
  }
}

-(void)needUpgradeCallback:(NSDictionary*)parameters
{
  [[self.environment handler] callback:[parameters objectForKey:kGreeJSPopupNeedUpgradeCommand] params:parameters];
}
@end
