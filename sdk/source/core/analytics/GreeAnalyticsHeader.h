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
#import "GreeSerializable.h"
#import "GreeSerializer.h"

@interface GreeAnalyticsHeader : NSObject<GreeSerializable>

@property (nonatomic, retain) NSString* hardwareVersion;
@property (nonatomic, retain) NSString* bundleVersion;
@property (nonatomic, retain) NSString* sdkVersion;
@property (nonatomic, retain) NSString* osVersion;
@property (nonatomic, retain) NSString* localeCountryCode;

+(id)header;

-(id)initWithHardwareVersion:(NSString*)hardwareVersion
               bundleVersion:(NSString*)bundleVersion
                  sdkVersion:(NSString*)sdkVersion
                   osVersion:(NSString*)osVersion
            localCountryCode:(NSString*)localeCountryCode;

@end
