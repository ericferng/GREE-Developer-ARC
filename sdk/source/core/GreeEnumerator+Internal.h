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
#import "GreeEnumerator.h"
/*
   Enumerators are generally subclasses of GreeEnumeratorBase, but this detail is not exposed to the public API
   Creation of a new enumerator involves overriding the convertData and httpRequestPath methods
 */

@interface GreeEnumeratorBase : NSObject<GreeEnumerator>

@property (nonatomic, readwrite, assign) NSInteger startIndex;
@property (nonatomic, readwrite, assign) NSInteger enumeratorStartIndex;
@property (nonatomic, readwrite, assign) NSInteger pageSize;
@property (nonatomic, readonly,  assign) NSInteger count;
@property (nonatomic, readwrite, retain) NSString* guid;


//designated initializer
-(id)initWithStartIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize;

//GreeEnumerator protocol
-(void)loadNext:(GreeEnumeratorResponseBlock)block;
-(void)loadPrevious:(GreeEnumeratorResponseBlock)block;




//This must be overridden in a subclass
//The path may contain interpolated components such as a resourceId, such as return [NSString stringWithFormat:@"leaderboards/%@", self.leaderboardId];
-(NSString*)httpRequestPath;
//This must be overridden in a subclass
//It will generally be of the form return [GreeSerializer deserializeArray:input withClass:[RESOURCE_CLASS class]];
-(NSArray*)convertData:(NSArray*)input;
//This can be optionally overridden in a subclass
//The default is to convert neworking errors to Gree error domain (see GreeError)
//A subclass should call [super convertError:input] somewhere inside
-(NSError*)convertError:(NSError*)input;
//This can be optionally overridden in a subclass, there is no need to call super
//The parameters dictionary is passed to this method
-(void)updateParams:(NSMutableDictionary*)params;
//This can be optionally overridden in a subclass, there is no need to call super
//If the server returns a 401 error, then reauthorization will be required.  If that reauthorization requires a service, then implement this method to set it
-(NSString*)retryService;

@end
