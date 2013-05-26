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
#import "GreeNetworkReachability.h"

@interface GreeBenchmarkProfile : NSObject
@property (nonatomic, retain) NSString* keyName;
@property (nonatomic, retain) NSString* flowName;
@property (nonatomic, assign) CFAbsoluteTime pointTime;
@property (nonatomic, assign) GreeNetworkReachabilityStatus reachabilityStatus;
@property (nonatomic, retain) NSString* formatTime;
@property (nonatomic, retain) NSString* position;
@property (nonatomic, retain) NSString* pointName;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) CFAbsoluteTime diffTime;
@property (nonatomic, assign) CFAbsoluteTime totalTime;
@property (nonatomic, assign) NSUInteger memoryUsage;
@end
