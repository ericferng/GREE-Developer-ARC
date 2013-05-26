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

#import "GreeJSLocationNavigationController.h"
#import "GreeJSWebViewController.h"
#import "GreeJSWebViewLocationDelegate.h"
#import "UIImage+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeJSHandler.h"
#import "GreeJSInputViewController.h"
#import "UIViewController+GreeAdditions.h"
#import "UINavigationBar+GreeAdditions.h"
#import <CoreLocation/CoreLocation.h>

const int kLocationUpdateCountMax = 2;

@interface GreeJSLocationNavigationController ()<GreeJSWebViewLocationDelegate, CLLocationManagerDelegate>
@property (nonatomic, assign) GreeJSInputViewController* parent;
@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, copy) NSString* viewName;
@property (nonatomic, readwrite) int locationCounter;
@property (nonatomic, retain) CLLocation* bestAccuracyLocation;

-(void)closeButtonPressed:(UIBarButtonItem*)sender;
-(void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation;
-(void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
-(void)loadRequest;
-(BOOL)isUserNeedSetting;
-(void)loadHelpPage;



@end

@implementation GreeJSLocationNavigationController

#pragma mark - Object Lifecycle

-(id)initWithViewName:(NSString*)viewName parent:(GreeJSInputViewController*)parentViewController
{
  GreeJSWebViewController* viewController = [[[GreeJSWebViewController alloc] init] autorelease];

  self = [super initWithRootViewController:viewController];
  if (self) {
    self.parent = parentViewController;
    viewController.locationDelegate = self;

    [self.navigationBar greeApplyGreeAppearance];
    viewController.navigationItem.titleView = self.navigationItem.titleView;
    viewController.navigationItem.title = GreePlatformString(@"location.spotlist.navigation.title", @"navigation title");

    UIImage* closeButtonImage = [UIImage greeImageNamed:@"navibar-close-def.png"];
    UIImage* closeButtonImageHightlight = [UIImage greeImageNamed:@"navibar-close-press.png"];
    UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, closeButtonImage.size.width, closeButtonImage.size.height);
    [closeButton setImage:closeButtonImage
                 forState:UIControlStateNormal];
    [closeButton setImage:closeButtonImageHightlight
                 forState:UIControlStateHighlighted];
    [closeButton addTarget:self
                    action:@selector(closeButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];

    if (viewName == nil) {
      return self;
    }

    UIBarButtonItem* rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:closeButton] autorelease];
    viewController.navigationItem.rightBarButtonItem = rightBarButtonItem;

    if ([CLLocationManager locationServicesEnabled] && ![self isUserNeedSetting]) {
      self.viewName = viewName;
      self.locationManager = [[[CLLocationManager alloc] init] autorelease];
      self.locationManager.delegate = self;
      [self.locationManager startUpdatingLocation];
      self.locationCounter = 0;
    } else {
      [self loadHelpPage];
    }
  }

  return self;
}

-(void)dealloc
{
  self.locationManager = nil;
  self.viewName = nil;
  self.bestAccuracyLocation = nil;
  [super dealloc];
}


#pragma mark - Internal Methods

-(void)closeButtonPressed:(UIBarButtonItem*)sender
{
  [self greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)spotViewCloseButtonPressed:(GreeJSWebViewController*)webViewController
{
  [self.parent updateLocationInfo:webViewController.params];
  [self greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
  if (!self.bestAccuracyLocation || self.bestAccuracyLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
    self.bestAccuracyLocation = newLocation;
  }
  self.locationCounter++;
  if (self.locationCounter == kLocationUpdateCountMax) {
    [self.locationManager stopUpdatingLocation];
    [self loadRequest];
  }
}

-(void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if ([self isUserNeedSetting]) {
    [self loadHelpPage];
  }
}

-(void)loadRequest
{
  GreeJSWebViewController* viewController = (GreeJSWebViewController*)self.topViewController;
  NSString* baseURL = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns];
  NSString* latLngQuery;
  if (self.bestAccuracyLocation) {
    float lat = self.bestAccuracyLocation.coordinate.latitude;
    float lng = self.bestAccuracyLocation.coordinate.longitude;
    latLngQuery = [NSString stringWithFormat:@"&lat=%f&lng=%f", lat, lng];
  } else {
    latLngQuery = @"";
  }
  NSString* urlString = [NSString stringWithFormat:@"%@/#view=%@%@", baseURL, self.viewName, latLngQuery];
  [viewController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

-(BOOL)isUserNeedSetting
{
  switch ([CLLocationManager authorizationStatus]) {
  case kCLAuthorizationStatusRestricted:
  case kCLAuthorizationStatusDenied:        return YES;
  case kCLAuthorizationStatusNotDetermined:
  case kCLAuthorizationStatusAuthorized:    return NO;
  }
  return YES;
}

// show how to avail location service
-(void)loadHelpPage
{
  self.viewName = @"spot_help_setting";
  [self loadRequest];
}

@end
