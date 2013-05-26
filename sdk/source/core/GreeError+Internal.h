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

#import "GreeError.h"

enum {
  GreeErrorCodeWebSessionResponseUnrecognized = GreeErrorCodeReservedBase+1,
  GreeErrorCodeWebSessionNeedReAuthorize = GreeErrorCodeReservedBase+2,

  // Triggered by some RPC wrappers. userInfo will contain an array of parameter names, named "names".
  GreeErrorCodeParameterMissing = GreeErrorCodeReservedBase+3,
};

@interface GreeError : NSObject
+(NSError*)convertToGreeError:(NSError*)input;

//userInfo will only have the localized description
+(NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode;
//the localized description will be added to any other values passed in
+(NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode userInfo:(NSDictionary*)userInfo;
@end
