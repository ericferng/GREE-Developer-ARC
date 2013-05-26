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

extern NSString* const GreeDeviceIdentifierKeyUUID;
extern NSString* const GreeDeviceIdentifierKeySecureUDID;

@interface GreeDeviceIdentifier : NSObject

//provide mac address
+(NSString*)macAddress;

//provide json web token
+(NSString*)deviceContextIdWithSecret:(NSString*)secret greeUUID:(NSString*)greeUUID keys:(NSArray*)keys;

// provide OF access token for OF migration
+(NSString*)ofAccessToken;

// provide OF user id for OF migration
+(NSString*)ofUserId;

// provide OF application id for OF migration
+(NSString*)ofApplicationId;

// remove OF access token for OF migration
+(void)removeOfAccessToken;

// remove OF user id for OF migration
+(void)removeOfUserId;

// remove OF application id for OF migration
+(void)removeOfApplicationId;

@end
