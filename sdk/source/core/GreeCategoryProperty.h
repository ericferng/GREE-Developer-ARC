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

// These macros can be used to generate methods required to attach getters and setters
// from a category. You will need to add the usual @property definition to access things
// using the dot notation.

#import <objc/runtime.h>

static objc_AssociationPolicy greeDynamicPolicy(NSString* policies)
{
  BOOL isCopy   = NO;
  BOOL isRetain = NO;
  BOOL isAtomic = YES;
  
  static NSMutableCharacterSet *delim;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    delim = [[NSMutableCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [delim addCharactersInString:@","];
    atexit_b(^{
      [delim release];
    });
  });
  for (NSString* policy in [policies componentsSeparatedByCharactersInSet:delim]) {
    if (policy.length) {
      if ([policy isEqualToString:@"copy"]) isCopy = YES;
      else if ([policy isEqualToString:@"retain"] || [policy isEqualToString:@"strong"]) isRetain = YES;
      else if ([policy isEqualToString:@"nonatomic"]) isAtomic = NO;
    }
  }
  
  objc_AssociationPolicy policy = OBJC_ASSOCIATION_ASSIGN;
  if (isAtomic) {
    if (isCopy) policy = OBJC_ASSOCIATION_COPY;
    else if (isRetain) policy = OBJC_ASSOCIATION_RETAIN;
  } else {
    if (isCopy) policy = OBJC_ASSOCIATION_COPY_NONATOMIC;
    else if (isRetain) policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
  }
  return policy;
}

#if __has_feature(objc_arc)
  #define RETURN_VALUE value
#else
  #define RETURN_VALUE [[value retain] autorelease]
#endif

// Examples of how to use below macros
// GREE_SYNTHESIZE(datasourceArray, setDatasourceArray, NSArray*, assign, atomic)
// GREE_SYNTHESIZE(completionHandler, setCompletionHandler, id, copy)
// GREE_SYNTHESIZE_PRIMITIVE(isCompleted, setCompleted, BOOL)

#define GREE_SYNTHESIZE(getter, setter, type, ...)\
static char getter##ObjectKey;\
-(type)getter {\
  type value = (type)(objc_getAssociatedObject(self, &getter##ObjectKey));\
  return RETURN_VALUE;\
}\
-(void)setter:(type)newValue {\
  id value = objc_getAssociatedObject(self, &getter##ObjectKey);\
  if (value != newValue) {\
    static objc_AssociationPolicy policy;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
      policy = greeDynamicPolicy(@#__VA_ARGS__);\
    });\
    objc_setAssociatedObject(self, &getter##ObjectKey, newValue, policy);\
  }\
}

#define GREE_SYNTHESIZE_PRIMITIVE(getter, setter, type)\
static char getter##ObjectKey;\
-(type)getter {\
  type value;\
  memset(&value, 0, sizeof(type));\
  [objc_getAssociatedObject(self, &getter##ObjectKey) getValue:&value];\
  return value;\
}\
-(void)setter:(type)newValue {\
  type value;\
  [objc_getAssociatedObject(self, &getter##ObjectKey) getValue:&value];\
  if (value != newValue) {\
    NSValue* boxedValue = [NSValue value:&newValue withObjCType:@encode(type)];\
    objc_setAssociatedObject(self, &getter##ObjectKey, boxedValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
  }\
}
