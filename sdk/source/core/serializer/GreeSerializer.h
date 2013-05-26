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

// GreeSerializer handles marshalling and unmarshalling GreeSerializable
// objects to/from standard Foundation objects. Supported object types:
//  * NSString
//  * NSNumber
//  * NSNull
//  * NSArray
//  * NSDictionary
//
// Given that this serialization is explicit there are few restrictions
// regarding container types (NSArray, NSDictionary):
//  * NSArray/NSDictionary of GreeSerializable objects cannot contain other NSDictionary objects
//    (there is no possible distinction between a serialized object (as NSDictionary) and a
//    dictionary containing serialized objects)
//  * All serializable objects contained in NSDictionary or NSArray must be of the same
//    type. (no type information is serialized along with the objects thus we can only know
//    the type of contained objects explicitly at the serialize/deserialize call-site.)
@interface GreeSerializer : NSObject

// Creates an empty GreeSerializer for new serialization.
+(id)serializer;
// Creates a GreeSerializer with a dictionary that has been previously serialized for deserialization.
+(id)deserializerWithDictionary:(NSDictionary*)dictionary;
// For deserializing an array of serializable class objects, this creates the deserializer internally
+(NSArray*)deserializeArray:(NSArray*)array withClass:(Class)klass;

// Designated initializer.
-(id)initWithSerializedDictionary:(NSDictionary*)dictionary;

@property (nonatomic, assign) BOOL deserialzeIntoMutableContainers;

// Access the root dictionary. That is, the top-level serialized container.
-(NSDictionary*)rootDictionary;

// Methods used to deserialize data. Note that containers of serialized objects must
// be deserialized explicitly.
-(id)objectForKey:(NSString*)key;
-(id)objectOfClass:(Class)klass forKey:(NSString*)key;
-(NSDate*)UTCDateForKey:(NSString*)key;
-(NSDate*)dateForKey:(NSString*)key;
-(NSInteger)integerForKey:(NSString*)key;
-(int64_t)int64ForKey:(NSString*)key;
-(double)doubleForKey:(NSString*)key;
-(BOOL)boolForKey:(NSString*)key;
-(NSURL*)urlForKey:(NSString*)key;
-(NSArray*)arrayOfSerializableObjectsWithClass:(Class)klass forKey:(NSString*)key;
-(NSDictionary*)dictionaryOfSerializableObjectsWithClass:(Class)klass forKey:(NSString*)key;

// Methods used to serialize data. Note that containers of GreeSerializable objects
// must be serialzed explicitly.
-(void)serializeObject:(id)objectToSerialize forKey:(NSString*)key;
-(void)serializeDate:(NSDate*)dateToSerialize forKey:(NSString*)key;
-(void)serializeUTCDate:(NSDate*)dateToSerialize forKey:(NSString*)key;
-(void)serializeInteger:(NSInteger)integerToSerialize forKey:(NSString*)key;
-(void)serializeInt64:(int64_t)int64ToSerialize forKey:(NSString*)key;
-(void)serializeDouble:(double)doubleToSerialize forKey:(NSString*)key;
-(void)serializeBool:(BOOL)boolToSerialize forKey:(NSString*)key;
-(void)serializeUrl:(NSURL*)urlToSerialize forKey:(NSString*)key;
-(void)serializeArrayOfSerializableObjects:(NSArray*)arrayToSerialize ofClass:(Class)klass forKey:(NSString*)key;
-(void)serializeDictionaryOfSerializableObjects:(NSDictionary*)dictionaryToSerialize ofClass:(Class)klass forKey:(NSString*)key;

@end
