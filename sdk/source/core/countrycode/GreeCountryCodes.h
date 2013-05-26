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
#import <Foundation/Foundation.h>

typedef void (^GreeCountryCodesBlock)(NSString* countryCode);

@interface GreeCountryCodes : NSObject

// Returns a list of all the country codes supported by the OS
+(NSArray*)allCountryCodes;

// Return the name of a country according to the current locale
+(NSString*)localizedNameForCountryCode:(NSString*)countryCode;

// Return a dictionary where keys are NSString objects representing
// country codes and values are NSNumber objects representing the
// corresponding phone number prefix (e.g. 1 for "US").
+(NSDictionary*)phoneNumberPrefixes;

// Detect the user's country code.
// If the device has a SIM card it will use it, otherwise it will
// fall back to using the user's location or his regional settings.
+(void)getCurrentCountryCodeWithBlock:(GreeCountryCodesBlock)block;

@end
