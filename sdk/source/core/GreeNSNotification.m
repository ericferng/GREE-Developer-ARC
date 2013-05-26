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

#import "GreeNSNotification.h"
#import "GreeNSNotification+Internal.h"

#define MAKESTR(name) NSString* const name = @# name

MAKESTR(GreeNSNotificationKeyUser);
MAKESTR(GreeNSNotificationKeyRequest);

MAKESTR(GreeNSNotificationUserLogin);
MAKESTR(GreeNSNotificationUserInvalidated);
MAKESTR(GreeNSNotificationUserLogout);
MAKESTR(GreeNSNotificationUserLoginError);
MAKESTR(GreeNSNotificationRequestNeedsRevalidation);
MAKESTR(GreeNSNotificationKeyWillOpenNotification);
MAKESTR(GreeNSNotificationKeyDidCloseNotification);
MAKESTR(GreeNSNotificationKeyDidUpdateLocalUserNotification);
MAKESTR(GreeNSNotificationKeyDidAcquireAccessTokenNotification);
MAKESTR(GreeNSNotificationKeyDidAppStartNotification);
