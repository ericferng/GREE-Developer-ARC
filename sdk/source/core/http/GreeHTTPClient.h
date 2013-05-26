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

#import "AFHTTPClient.h"
#import <UIKit/UIKit.h>
/*
   There are several types of requests that can be made using this class
   Most requests will be sent to the Gree server, these must be signed with OAuth
   Most of the time, you will use one of the following to make a JSON request:
   getPath:parameters:success:failure,
   postPath:parameters:success:failure,
   putPath:parameters:success:failure,
   deletePath:parameters:success:failure

   Non-JSON requests:
    rawRequestWithMethod:path:parameters:success:failure

   The rest of these are not expected to be used very often.
   To make a request without queuing it, there are two possibilities:
   For JSON:
    requestWithMethod:path:parameters:
   for non-JSON:
    use [NSMutableURLRequest requestWithURL:], base the URL from self.baseURL

   To sign and queue the request:
    performRequest:parameters:success:failure:


   You can also work with requests sent to servers other than the Gree server.
   To sign any request with Gree credentials:
    signRequest:parameters:

   To submit the request to the Gree queue:
    HTTPRequestOperationWithRequest:success:failure:
    enqueueHTTPRequestOperation
 */


typedef void (^GreeHTTPSuccessBlock)(GreeAFHTTPRequestOperation*, id);
typedef void (^GreeHTTPFailureBlock)(GreeAFHTTPRequestOperation*, NSError*);


@interface GreeHTTPClient : GreeAFHTTPClient
//designated initializer
-(id)initWithBaseURL:(NSURL*)url key:(NSString*)key secret:(NSString*)secret;
-(void)setMaxConcurrentOperations:(NSInteger)count;
-(NSInteger)activeRequestCount;
-(void)setOAuthCallback:(NSString*)urlString;
-(void)setOAuthVerifier:(NSString*)verifier;

// Explicitly two legged.
-(void)performTwoLeggedRequestWithMethod:(NSString*)method
                                    path:(NSString*)path
                              parameters:(NSDictionary*)parameters
                                 success:(GreeHTTPSuccessBlock)success
                                 failure:(GreeHTTPFailureBlock)failure;

//OAuth authenticated values
//By default, all requests made through the GreeHTTPClient are signed using client and user token
//Those methods that only require two legged authentication should still work with the extra signing

//This will sign any request with the current client and user key.  The parameters must match those inside the request.
-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)parameters;


//this can be used to send any request with OAuth signing.  Any parameters used in creation of the request must be passed to this method as well.
-(void)performRequest:(NSMutableURLRequest*)request
           parameters:(NSDictionary*)params
              success:(GreeHTTPSuccessBlock)success
              failure:(GreeHTTPFailureBlock)failure;

//use this to create a request which is signed but does not necessarily expect JSON data.  The responseObject will be the raw data

-(void)rawRequestWithMethod:(NSString*)method
                       path:(NSString*)path
                 parameters:(NSDictionary*)parameters
                    success:(GreeHTTPSuccessBlock)success
                    failure:(GreeHTTPFailureBlock)failure;

//this version of delete path won't JSON encode the parameters, which is AFNetworking's behavior
-(void)encodedDeletePath:(NSString*)path parameters:(NSDictionary*)parameters success:(GreeHTTPSuccessBlock)success failure:(GreeHTTPFailureBlock)failure;

-(void)performTwoLeggedDownloadWithMethod:(NSString*)method path:(NSString*)path parameters:(NSDictionary*)parameters savePath:(NSString*)savePath success:(GreeHTTPSuccessBlock)success failure:(GreeHTTPFailureBlock)failure;

//download image with block
-(id)downloadImageAtUrl:(NSURL*)url withBlock:(void (^)(UIImage* image, NSError* error))block;

//cancel with handle
-(void)cancelWithHandle:(id)handle;

//used primarily for testing, defaults to YES
//this will be removed when we switch from the OAuth sandbox to using our own servers
@property (nonatomic, assign) BOOL useCryptographicSigning;

//use for "not authorized" response
@property (nonatomic, assign) BOOL denyRequestWithoutAuthorization;

-(BOOL)hasUserToken;

//set user key and secret (token) from the login process
-(void)setUserToken:(NSString*)key secret:(NSString*)secret;

//when you get a 401 error, you should make a call to show top page
//see GreeEnumerator for an example
-(void)reAuthorize;
@end
