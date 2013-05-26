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


#import "GreeAPI.h"


@interface GreeAPIEnumeratorBase : NSObject<GreeAPIEnumerator, GreeAPIDefaultParameters>
@property (nonatomic, readwrite, assign) NSInteger startIndex;
@property (nonatomic, readwrite, assign) NSInteger pageSize;
@property (nonatomic, readwrite, assign) BOOL hasMore;
@property (nonatomic, readwrite, retain) NSMutableDictionary* requestParameters;
@property (nonatomic, readwrite, retain) NSMutableArray* userIds;

//This must be overridden in a subclass
// http://api.gree.net/{user_id list}/{resource specifier}
//                                    ^^^^^^^^^^^^^^^^^^^^
-(NSString*)httpRequestResourceSpecifier;

// This must be overridden in a subclass
// It will generally be of the form return [GreeSerializer deserializeArray:input withClass:[RESOURCE_CLASS class]];
-(NSArray*)convertData:(NSArray*)input;

//This can be optionally overridden in a subclass
//The default is to convert neworking errors to Gree error domain (see GreeError)
//A subclass should call [super convertError:input] somewhere inside
-(NSError*)convertError:(NSError*)input;

//Default: NO
//If subclass convert response json manually, this method should return YES.
-(BOOL)shouldConvertManually;

//If shouldConvertManually returns YES, this class calls this method.
-(id)convertDataManually:(id)input;

@end

