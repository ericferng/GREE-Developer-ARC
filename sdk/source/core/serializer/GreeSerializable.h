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

/**
 * @file GreeSerializable.h
 * GreeSerializable Protocol
 */

#import <Foundation/Foundation.h>

@class GreeSerializer;

/**
 * @brief Adopting this protocol allows a given class to be serialized via GreeSerializer.
 */
@protocol GreeSerializable<NSObject>
@required

/**
 * Initialize the receiver using the data in a GreeSerializer using the xxxForKey: methods.
 */
-(id)initWithGreeSerializer:(GreeSerializer*)serializer;

/**
 * Serialize the receiver's data to a GreeSerializer using the serializeXxx:forKey: methods.
 */
-(void)serializeWithGreeSerializer:(GreeSerializer*)serializer;

@end
