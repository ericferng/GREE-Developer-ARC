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

#define GreeBenchmarkPosition(point) [NSString stringWithFormat : @"%@:%s:%d", point, __FUNCTION__, __LINE__]

#import <Foundation/Foundation.h>
#import "GreeNetworkReachability.h"
#import "GreeBenchmarkMapping.h"
#import "GreeBenchmarkProfile.h"

extern NSString* const kGreeBenchmarkFlowName;
extern NSString* const kGreeBenchmarkPointName;
extern NSString* const kGreeBenchmarkLogin;
extern NSString* const kGreeBenchmarkInvite;
extern NSString* const kGreeBenchmarkShare;
extern NSString* const kGreeBenchmarkRequest;
extern NSString* const kGreeBenchmarkPayment;
extern NSString* const kGreeBenchmarkPaymentDeposit;
extern NSString* const kGreeBenchmarkPaymentHistory;
extern NSString* const kGreeBenchmarkUpgrade;
extern NSString* const kGreeBenchmarkLogout;
extern NSString* const kGreeBenchmarkDashboard;
extern NSString* const kGreeBenchmarkDashboardUm;
extern NSString* const kGreeBenchmarkNotificationBoard;
extern NSString* const kGreeBenchmarkOs;
extern NSString* const kGreeBenchmarkOpen;
extern NSString* const kGreeBenchmarkPaymentApi;
extern NSString* const kGreeBenchmarkAuthorization;
extern NSString* const kGreeBenchmarkPopupStart;
extern NSString* const kGreeBenchmarkUrlLoadStart;
extern NSString* const kGreeBenchmarkUrlLoadError;
extern NSString* const kGreeBenchmarkUrlLoadEnd;
extern NSString* const kGreeBenchmarkPostStart;
extern NSString* const kGreeBenchmarkDismiss;
extern NSString* const kGreeBenchmarkCancel;
extern NSString* const kGreeBenchmarkLaunchNativeApp;
extern NSString* const kGreeBenchmarkApiUsage;
extern NSString* const kGreeBenchmarkEtc;
extern NSString* const kGreeBenchmarkStart;
extern NSString* const kGreeBenchmarkEnd;
extern NSString* const kGreeBenchmarkError;
extern NSString* const kGreeBenchmarkHttpProtocolGet;
extern NSString* const kGreeBenchmarkHttpProtocolPost;
extern NSString* const kGreeBenchmarkHttpProtocolPut;
extern NSString* const kGreeBenchmarkHttpProtocolDelete;

typedef enum {
  GreeBenchmarkPointRoleNone,
  GreeBenchmarkPointRoleStart,
  GreeBenchmarkPointRoleEnd
} GreeBenchmarkPointRole;


@interface GreeBenchmark : NSObject
@property (nonatomic, retain) NSMutableDictionary* allResult;


+(id)benchmark;
-(void)registerWithKey:(NSString*)keyName position:(NSString*)position;
-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointTime:(CFAbsoluteTime)pointTime;
-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole;
-(void)registerWithKey:(NSString*)keyName position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole pointTime:(CFAbsoluteTime)pointTime;

-(void)finish;
-(void)finishWithKey:(NSString*)keyName;
-(void)nextWithKey:(NSString*)keyName;
+(NSString*)pointNamePrefix:(NSString*)path;
-(void)benchmarkWithParameters:(NSString*)method path:(NSString*)path position:(NSString*)position pointRole:(GreeBenchmarkPointRole)pointRole;
@end
