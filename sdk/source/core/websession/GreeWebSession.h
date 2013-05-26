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

#import <Foundation/Foundation.h>

@interface GreeWebSession : NSObject

// The given block will be invoked whenever the web session is successfully regenerated
// Use the token returned from this method to stop observing session changes.
+(id)observeWebSessionChangesWithBlock:(void (^)(void))block;
// Given a token returned from observeWebSessionChangesWithBlock this method will
// unsubscribe the block represented byt he given token from web session changes.
+(void)stopObservingWebSessionChanges:(id)handle;

+(void)regenerateWebSessionWithBlock:(void (^)(NSError* error))block;
// Return YES if web session already stored in cookie storage.
+(BOOL)hasWebSession;

@end
