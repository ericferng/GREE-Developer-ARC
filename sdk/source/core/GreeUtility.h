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

/**
 * @return A UUID string that is unique to this application's installation
 * @note This UUID is not consistent across installs of the same application.
 */
NSString* GreeApplicationUuid(void);

/**
 * All GreePlatform local storage must be relative to this relative path, regardless
 * of which root directory it lives in: documents, temp, caches.
 *
 * @return The relative path for all local storage in Gree SDK.
 */
NSString* GreeSdkRelativePath(void);

/**
 * @param minimumVersion Minimum iOS version to test for (i.e. @"4.1")
 * @return YES if the current device iOS version meets or exceeds the given minimum
 */
BOOL GreeDeviceOsVersionIsAtLeast(NSString* minimumVersion);
void GreeRetry(NSInteger maxTryCount, void(^retryBlock)(NSInteger, double, void(^)(BOOL, double)));
