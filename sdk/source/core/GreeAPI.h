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


// This block uses any situations for api.gree.net
typedef void (^GreeAPIResponseBlock)(id object, NSError* error);


// New paging apis for api.gree.net
@protocol GreeAPIEnumerator<NSObject>

-(NSInteger)startIndex;                           // offset, start from 0
-(void)setStartIndex:(NSInteger)startIndex;
-(NSInteger)pageSize;                             // limit
-(void)setPageSize:(NSInteger)pageSize;
-(BOOL)canLoadNext;                               // has_more
-(BOOL)canLoadPrevious;

-(void)loadNext:(GreeAPIResponseBlock)block;
-(void)loadPrevious:(GreeAPIResponseBlock)block;

@end

// New additional parameters for api.gree.net
@protocol GreeAPIDefaultParameters<NSObject>
-(NSDictionary*)parameters;
-(void)setParameters:(NSDictionary*)parameters;
@optional
-(NSString*)languageCode;
-(void)setLanguageCode:(NSString*)languageCode;
@end

// New REST apis for api.gree.net
@protocol GreeAPI<NSObject>
@optional
// for HTTP GET
+(id<GreeAPIEnumerator>)getWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block;
// for HTTP POST
+(void)postWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block;
// for HTTP PUT
+(void)putWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block;
// for HTTP DELETE
+(void)deleteWithParameters:(NSDictionary*)parameters responseBlock:(GreeAPIResponseBlock)block;
@end

// Provide default implementations for GreeAPI Protocol
@interface GreeAPIBase : NSObject<GreeAPI>
@end

extern NSString* const GreeAPIParameterKeyStartIndex;
extern NSString* const GreeAPIParameterKeyPageSize;
extern NSString* const GreeAPIParameterKeyHasMore;
extern NSString* const GreeAPIParameterKeyThumbnail;
extern NSString* const GreeAPIParameterKeyLanguageCode;
extern NSString* const GreeAPIParameterKeyUserIds;


