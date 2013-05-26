//
// Copyright 2010-2012 GREE, inc.
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
#import "GreeCountryCodes.h"
#import "GreeGlobalization.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreLocation/CoreLocation.h>
#import <TargetConditionals.h>

@interface LocationBasedCountryCodeGetter : NSObject<CLLocationManagerDelegate>
@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, copy) GreeCountryCodesBlock block;

+(void)getWithBlock:(GreeCountryCodesBlock)block;
-(id)initWithBlock:(GreeCountryCodesBlock)block;
-(void)start;
-(void)stop;
-(void)cancel;
@end

@implementation LocationBasedCountryCodeGetter

-(id)initWithBlock:(GreeCountryCodesBlock)block
{
  self = [super init];
  if (self) {
    self.block = block;
  }
  return self;
}

-(void)dealloc
{
  [self stop];
  self.block = nil;
  [super dealloc];
}

+(void)getWithBlock:(GreeCountryCodesBlock)block
{
  __block LocationBasedCountryCodeGetter* instance = nil;
  GreeCountryCodesBlock tmpBlock =^(NSString* countryCode) {
    block([countryCode uppercaseString]);
    [instance release];
    instance = nil;
  };
  instance = [[LocationBasedCountryCodeGetter alloc] initWithBlock:tmpBlock];
  atexit_b(^{
    [instance release];
    instance = nil;
  });
  [instance start];
}

-(void)start
{
  if (self.locationManager) {
    return;
  }

  self.locationManager = [[[CLLocationManager alloc] init] autorelease];
  self.locationManager.delegate = self;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
  self.locationManager.purpose = GreePlatformString(@"GreeCountryCodes#locationRequired", @"We need to know which country you live in.");
  [self.locationManager startUpdatingLocation];
}

-(void)stop
{
  if (!self.locationManager) {
    return;
  }

  self.locationManager.delegate = nil;
  [self.locationManager stopUpdatingLocation];

  
  [self.locationManager stopUpdatingHeading];
  [self.locationManager stopMonitoringSignificantLocationChanges];

  self.locationManager = nil;
}

-(void)cancel
{
  [self stop];
  self.block([[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]);
}

-(void)useLocation:(CLLocation*)location
{
  [self stop];

  CLGeocoder* geocoder = [[[CLGeocoder alloc] init] autorelease];
  [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error) {
     NSString* countryCode = nil;
#ifdef TARGET_IPHONE_SIMULATOR
     // The simulator doesn't support CLGeocoder and Japan is so far down
     // in the countries list...^^
     countryCode = @"JP";
#else
     if (!error && placemarks.count) {
       CLPlacemark* placemark = [placemarks objectAtIndex:0];
       countryCode = placemark.ISOcountryCode;
     }
#endif

     if (!countryCode) {
       countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
     }
     self.block(countryCode);
   }];
}

-(void)locationManager:(CLLocationManager*)manager
   didUpdateToLocation:(CLLocation*)newLocation
          fromLocation:(CLLocation*)oldLocation
{
  if (newLocation) {
    [self useLocation:newLocation];
  }
}

-(void)locationManager:(CLLocationManager*)manager
      didFailWithError:(NSError*)error
{
  [self cancel];
}

-(void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusRestricted ||
      status == kCLAuthorizationStatusDenied) {
    [self cancel];
  }
}

@end

@implementation GreeCountryCodes

+(NSArray*)allCountryCodes
{
  return [NSLocale ISOCountryCodes];
}

+(NSString*)localizedNameForCountryCode:(NSString*)countryCode
{
  return [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
}

+(NSDictionary*)phoneNumberPrefixes
{
  NSString* plist = [[NSBundle greePlatformCoreBundle] pathForResource:@"GreeCountryCodes.plist" ofType:nil];
  NSDictionary* data = [NSDictionary dictionaryWithContentsOfFile:plist];
  return [data objectForKey:@"phoneNumberPrefixes"];
}

+(void)getCurrentCountryCodeWithBlock:(void (^)(NSString* countryCode))block
{
  // We first attempt to get the country code using the SIM information
  // since it will provide the best result
  CTTelephonyNetworkInfo* netInfo = [[CTTelephonyNetworkInfo alloc] init];
  CTCarrier* carrier = [netInfo subscriberCellularProvider];
  NSString* isoCountryCode = [carrier isoCountryCode];
  [netInfo release];

  if (isoCountryCode) {
    block([isoCountryCode uppercaseString]);
    return;
  }

  // We don't have a SIM apparently, which means the device might not
  // be a phone.
  if (NSClassFromString(@"CLGeocoder")) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     [LocationBasedCountryCodeGetter getWithBlock:block];
                   });
    return;
  }

  // No reverse geocoder... :-(
  block([[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]);
}

@end
