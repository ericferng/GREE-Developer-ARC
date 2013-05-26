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

#import "GreeFriendCodes.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "AFHTTPRequestOperation.h"
#import "GreeError+Internal.h"
#import "GreeEnumerator+Internal.h"
#import "GreeBenchmark.h"

@interface GreeFriendCodes ()
@end

@interface GreeFriendCodeEnumerator : GreeEnumeratorBase
@end



@implementation GreeFriendCodes

#pragma mark - Object Lifecycle

#pragma mark - Public Interface
+(void)requestCodeWithBlock:(void (^)(NSString* code, NSError* error))block
{
  [GreeFriendCodes requestCodeWithExpirationDate:nil block:block];
}

+(void)requestCodeWithExpirationDate:(NSDate*)expirationDate block:(void (^)(NSString* code, NSError* error))block
{
  NSDictionary* params = [NSMutableDictionary dictionary];
  if(expirationDate) {
    NSDateFormatter* formatter = [NSDateFormatter greeDateAndZoneFormatter];
    [params setValue:[formatter stringFromDate:expirationDate] forKey:@"expire_time"];
  }
  NSString* path = @"api/rest/friendcode/@me";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient postPath:path parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     if(block) {
       NSDictionary* entry = [responseObject objectForKey:@"entry"];
       NSString* code = [entry objectForKey:@"code"];
       NSError* err = nil;
       if(!code) {
         err = [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound];
       }
       block(code, err);
       if ([GreePlatform sharedInstance].benchmark) {
         [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
       }
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(block) {
       if(operation.response.statusCode == 400) {
         error = [GreeError localizedGreeErrorWithCode:GreeFriendCodeAlreadyRegistered];
       } else {
         error = [GreeError convertToGreeError:error];
       }
       if ([GreePlatform sharedInstance].benchmark) {
         [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
       }
       block(nil, error);
     }
   }];
}

+(void)verifyCode:(NSString*)code withBlock:(void (^)(NSError* error))block
{
  if(!block) return;
  NSString* path = [NSString stringWithFormat:@"api/rest/friendcode/@me/%@", code];
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  NSDictionary* params = [NSMutableDictionary dictionary];
  [[GreePlatform sharedInstance].httpClient postPath:path parameters:params success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     block(operation.response.statusCode == 200 ? nil : [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(operation.response.statusCode == 400) {
       block([GreeError localizedGreeErrorWithCode:GreeFriendCodeAlreadyEntered]);
     } else if(operation.response.statusCode == 404) {
       block([GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     } else {
       block([GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolPost path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

+(void)loadCodeWithBlock:(void (^)(NSString* code, NSDate* expiration, NSError* error))block
{
  if(!block) return;
  NSString* path = @"api/rest/friendcode/@me/@self";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient getPath:path parameters:nil success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSDictionary* entry = [responseObject objectForKey:@"entry"];
     NSString* code = [entry objectForKey:@"code"];
     NSDateFormatter* formatter = [NSDateFormatter greeDateAndZoneFormatter];
     NSDate* expiration = [formatter dateFromString:[entry objectForKey:@"expire_time"]];
     NSError* returnError = code ? nil : [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound];
     block(code, expiration, returnError);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(operation.response.statusCode == 404) {
       block(nil, nil, [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     } else {
       block(nil, nil, [GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

//getting friends with codes is an enumeration
+(id<GreeEnumerator>)loadFriendsWithBlock:(void (^)(NSArray* friends, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeFriendCodeEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

+(void)loadCodeOwner:(void (^)(NSString* userId, NSError* error))block
{
  if(!block) return;
  NSString* path = @"api/rest/friendcode/@me/@owner";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient getPath:path parameters:nil success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSNumber* userIdNumber = [[responseObject objectForKey:@"entry"] objectForKey:@"id"];
     NSString* userId = nil;
     NSError* returnError = nil;
     if(!userIdNumber) {
       returnError = [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound];
     } else {
       userId = [NSString stringWithFormat:@"%lld", userIdNumber.longLongValue];
     }
     block(userId, returnError);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(operation.response.statusCode == 404) {
       block(nil, [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     } else {
       block(nil, [GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolGet path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

+(void)deleteCodeWithBlock:(void (^)(NSError* error))block
{
  NSString* path = @"api/rest/friendcode/@me";
  if ([GreePlatform sharedInstance].benchmark) {
    [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkStart pointRole:GreeBenchmarkPointRoleStart];
  }
  [[GreePlatform sharedInstance].httpClient deletePath:@"api/rest/friendcode/@me" parameters:nil success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     block(operation.response.statusCode == 202 ? nil : [GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkEnd pointRole:GreeBenchmarkPointRoleEnd];
     }
   } failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     if(operation.response.statusCode == 404) {
       block([GreeError localizedGreeErrorWithCode:GreeFriendCodeNotFound]);
     } else {
       block([GreeError convertToGreeError:error]);
     }
     if ([GreePlatform sharedInstance].benchmark) {
       [[GreePlatform sharedInstance].benchmark benchmarkWithParameters:kGreeBenchmarkHttpProtocolDelete path:path position:kGreeBenchmarkError pointRole:GreeBenchmarkPointRoleEnd];
     }
   }];
}

#pragma mark - Internal Methods

@end

@implementation GreeFriendCodeEnumerator
#pragma mark - GreeEnumerator Overrides
-(NSString*)httpRequestPath
{
  return @"api/rest/friendcode/@me/@friends";
}

-(NSArray*)convertData:(NSArray*)input
{
  //hmmm.... incoming is an array of dictionaries "id"=>value, we want just the value
  NSMutableArray* output =[NSMutableArray arrayWithCapacity:input.count];
  [input enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
     NSNumber* userIdNumber = [obj objectForKey:@"id"];
     [output addObject:[NSString stringWithFormat:@"%lld", userIdNumber.longLongValue]];
   }];
  return output;  //TBD
}

@end


