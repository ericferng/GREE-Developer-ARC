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

#import "GreeHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonHMAC.h>
#import "GreeAuthorization.h"
#import "GreeError+Internal.h"
#import "GreeGlobalization.h"
#import "AFImageRequestOperation.h"
#import "JSONKit.h"
#import "GreePlatform+Internal.h"
#import "NSString+GreeAdditions.h"
#import "GreeBenchmark.h"

NSString* GreeAFQueryStringFromParametersWithEncoding(NSDictionary* parameters, NSStringEncoding encoding);
typedef NSURLRequest* (^GreeHTTPRedirectResponseBlock)(NSURLConnection* connection, NSURLRequest* request, NSURLResponse* redirectResponse);

//these are some private settings to use for fixing a nonce and timestamp for testing
//use KVC to set the values
//e.g. [client setValue:@"TESTVAL" forKeyPath:@"testNonce"]
@interface GreeHTTPClient ()
@property (nonatomic, retain) NSString* testNonce;
@property (nonatomic, retain) NSString* testTimestamp;

//client application key and secret will be set in init
@property (nonatomic, retain) NSString* clientOAuthKey;
@property (nonatomic, retain) NSString* clientOAuthSecret;
//user key and secret are set with setUserToken:secret:
@property (nonatomic, retain) NSString* userOAuthKey;
@property (nonatomic, retain) NSString* userOAuthSecret;

@property (nonatomic, retain) NSString* clientOAuthCallBack;
@property (nonatomic, retain) NSString* userOAuthVerifier;

@property (nonatomic, copy) GreeHTTPRedirectResponseBlock redirectResponseBlock;

-(NSString*)OAuthTypeURLEncoding:(NSString*)str;
-(NSString*)signClearText:(NSString*)text secret:(NSString*)secret;
-(NSString*)URLWithoutQuery:(NSURL*)url;
-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)parameters;
-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)parameters includeUserAuth:(BOOL)includeUserAuth;
-(NSString*)base64EncodeData:(NSData*)data;
+(NSString*)userAgentString;
+(id)buildHandleForOperation:(GreeAFURLConnectionOperation*)operation;
-(void)method:(NSString*)method
         path:(NSString*)path
   parameters:(NSDictionary*)parameters
      success:(void (^)(GreeAFHTTPRequestOperation* operation, id responseObject))success
      failure:(void (^)(GreeAFHTTPRequestOperation* operation, NSError* error))failure;
-(GreeHTTPFailureBlock)errorHandlingFailureBlockWithUpgradeSuccessBlock:(void (^)(void))success wrappedBlock:(GreeHTTPFailureBlock)wrapped;
@end

@implementation GreeHTTPClient

#pragma mark - Object Lifecycle
-(id)initWithBaseURL:(NSURL*)url key:(NSString*)key secret:(NSString*)secret;
{
  self = [super initWithBaseURL:url];
  if(self) {

    [self registerHTTPOperationClass:[GreeAFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [[self valueForKey:@"defaultHeaders"] setObject:[GreeHTTPClient userAgentString] forKey:@"User-Agent"];
    //More headers expected later
    self.parameterEncoding = GreeAFJSONParameterEncoding;  //according to the Gree docs, all POST/DELETE parameters are sent as JSON
    self.useCryptographicSigning = YES;
    self.clientOAuthKey = key;
    self.clientOAuthSecret = secret;

    self.redirectResponseBlock =^NSURLRequest*(NSURLConnection* connection, NSURLRequest* request, NSURLResponse* redirectResponse) {
      // Some API calls redirect to applications. We handle the case like Mobile Safari does.
      NSURL* url = request.URL;
      NSString* scheme = url.scheme;
      if (![scheme isEqualToString:@"http"] &&
          ![scheme isEqualToString:@"https"] &&
          [[UIApplication sharedApplication] canOpenURL:url]) {

        dispatch_async(dispatch_get_main_queue(), ^{
                         [[UIApplication sharedApplication] openURL:request.URL];
                       });

        // returning nil here might fail because the current status code is
        // out of the accepted range, so we redirect to about:blank to get a
        // HTTP 200 response.
        return [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
      }
      return request;
    };
  }
  return self;
}

-(void)dealloc
{
  self.clientOAuthKey = nil;
  self.clientOAuthSecret = nil;
  self.userOAuthKey = nil;
  self.userOAuthSecret = nil;

  self.testNonce = nil;
  self.testTimestamp = nil;

  self.clientOAuthCallBack = nil;
  self.userOAuthVerifier = nil;

  self.redirectResponseBlock = nil;

  [super dealloc];
}

#pragma mark - Public Interface
-(GreeAFHTTPRequestOperation*)HTTPRequestOperationWithRequest:(NSURLRequest*)urlRequest
                                                      success:(void (^)(GreeAFHTTPRequestOperation* operation, id responseObject))success
                                                      failure:(void (^)(GreeAFHTTPRequestOperation* operation, NSError* error))failure
{
  GreeAFHTTPRequestOperation* operation = [super HTTPRequestOperationWithRequest:urlRequest success:success failure:failure];
  [operation setRedirectResponseBlock:self.redirectResponseBlock];
  return operation;
}

-(void)setMaxConcurrentOperations:(NSInteger)count
{
  [self.operationQueue setMaxConcurrentOperationCount:count];
}

-(NSInteger)activeRequestCount
{
  NSInteger count = 0;
  for(NSOperation* op in self.operationQueue.operations) {
    if(op.isExecuting) {
      ++count;
    }
  }
  return count;
}

-(void)setOAuthCallback:(NSString*)urlString
{
  self.clientOAuthCallBack = urlString;
}

-(void)setOAuthVerifier:(NSString*)verifier
{
  self.userOAuthVerifier = verifier;
}

-(void)performRequest:(NSMutableURLRequest*)request
           parameters:(NSDictionary*)params
              success:(GreeHTTPSuccessBlock)success
              failure:(GreeHTTPFailureBlock)failure
{
  if (self.denyRequestWithoutAuthorization && ![[GreeAuthorization sharedInstance] isAuthorized]) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     failure(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeNotAuthorized]);
                   });
  } else {
    [self signRequest:request parameters:params];

    GreeHTTPFailureBlock failureBlockWithHandlingError =
      [self errorHandlingFailureBlockWithUpgradeSuccessBlock:^{
         [self performRequest:request parameters:params success:success failure:failure];
       }
                                                wrappedBlock:failure];

    GreeAFHTTPRequestOperation* op = [self HTTPRequestOperationWithRequest:request success:success failure:failureBlockWithHandlingError];
    [self enqueueHTTPRequestOperation:op];
  }
}

-(void)setUserToken:(NSString*)key secret:(NSString*)secret
{
  self.userOAuthKey = key;
  self.userOAuthSecret = secret;
}

-(void)performTwoLeggedRequestWithMethod:(NSString*)method
                                    path:(NSString*)path
                              parameters:(NSDictionary*)parameters
                                 success:(GreeHTTPSuccessBlock)success
                                 failure:(GreeHTTPFailureBlock)failure
{
  GreeHTTPFailureBlock failureBlockWithHandlingError =
    [self errorHandlingFailureBlockWithUpgradeSuccessBlock:^{
       [self performTwoLeggedRequestWithMethod:method path:path parameters:parameters success:success failure:failure];
     }
                                              wrappedBlock:failure];

  NSMutableURLRequest* request = [super requestWithMethod:method path:path parameters:parameters];
  [self signRequest:request parameters:([method isEqualToString:@"GET"] ? parameters : nil) includeUserAuth:NO];
  GreeAFHTTPRequestOperation* operation = [self HTTPRequestOperationWithRequest:request success:success failure:failureBlockWithHandlingError];
  [self enqueueHTTPRequestOperation:operation];
}

-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)parameters
{
  [self signRequest:request parameters:parameters includeUserAuth:YES];
}
-(void)performTwoLeggedDownloadWithMethod:(NSString*)method
  path:(NSString*)path
  parameters:(NSDictionary*)parameters
  savePath:(NSString*)savePath
  success:(GreeHTTPSuccessBlock)success
  failure:(GreeHTTPFailureBlock)failure
{
  [[NSFileManager defaultManager] createDirectoryAtPath:[savePath stringByDeletingLastPathComponent]
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];

  NSMutableURLRequest* request = [super requestWithMethod:method path:path parameters:parameters];
  [self signRequest:request parameters:([method isEqualToString:@"GET"] ? parameters : nil) includeUserAuth:NO];
  GreeAFHTTPRequestOperation* operation = [[[GreeAFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
  [operation setCompletionBlockWithSuccess:success failure:failure];
  operation.outputStream = [NSOutputStream outputStreamToFileAtPath:savePath append:NO];

  [self enqueueHTTPRequestOperation:operation];
}

-(void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary*)parameters includeUserAuth:(BOOL)includeUserAuth
{
  if (!self.clientOAuthKey) {
    // No clientOAuthKey means no OAuth
    return;
  }

  NSMutableDictionary* additionalParameters = [NSMutableDictionary dictionaryWithDictionary:[request.URL.query greeDictionaryFromQueryString]];

  NSString* timestamp = [NSString stringWithFormat:@"%ld", time(NULL)];

  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  CFStringRef nonce = CFUUIDCreateString(NULL, theUUID);
  [NSMakeCollectable (theUUID)autorelease];
  NSString* nonceObj = (NSString*)nonce;

  if(self.testNonce) nonceObj = self.testNonce;
  if(self.testTimestamp) timestamp = self.testTimestamp;

  //add the new oauth parameters to the list
  [additionalParameters setObject:self.clientOAuthKey forKey:@"oauth_consumer_key"];
  [additionalParameters setObject:self.useCryptographicSigning ? @"HMAC-SHA1": @"PLAINTEXT" forKey:@"oauth_signature_method"];
  [additionalParameters setObject:timestamp forKey:@"oauth_timestamp"];
  [additionalParameters setObject:nonceObj forKey:@"oauth_nonce"];
  [additionalParameters setObject:@"1.0" forKey:@"oauth_version"];
  if(includeUserAuth && self.userOAuthKey) {
    [additionalParameters setObject:self.userOAuthKey forKey:@"oauth_token"];
  }
  if (self.clientOAuthCallBack) {
    [additionalParameters setObject:self.clientOAuthCallBack forKey:@"oauth_callback"];
  }
  if (self.userOAuthVerifier) {
    [additionalParameters setObject:self.userOAuthVerifier forKey:@"oauth_verifier"];
  }
  NSMutableDictionary* allParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [allParameters addEntriesFromDictionary:additionalParameters];

  //this involves adding the Authorization header and several new parameters
  NSMutableArray* outStringArray = [NSMutableArray array];
  [[[allParameters allKeys] sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
     [outStringArray addObject:[NSString stringWithFormat:@"%@=%@", [self OAuthTypeURLEncoding:obj], [self OAuthTypeURLEncoding:[allParameters objectForKey:obj]]]];
   }];
  NSString* signatureString = [NSString stringWithFormat:@"%@&%@&%@",
                               request.HTTPMethod,
                               [self OAuthTypeURLEncoding:[self URLWithoutQuery:request.URL]],
                               [self OAuthTypeURLEncoding:[outStringArray componentsJoinedByString:@"&"]]
                              ];

  //next phase, take that string and sign with secret built from clientKey&userKey
  NSString* signingKey = [NSString stringWithFormat:@"%@&%@", self.clientOAuthSecret, (includeUserAuth && self.userOAuthSecret) ? self.userOAuthSecret : @""];
  NSString* signedValue = [self signClearText:signatureString secret:signingKey];
  NSString* oauthHeader = [NSString stringWithFormat                                                                                                                :@"OAuth realm=\"\", oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", %@%@oauth_version=\"1.0\"",
                           [self OAuthTypeURLEncoding:self.clientOAuthKey],
                           includeUserAuth && self.userOAuthKey ? [NSString stringWithFormat:@"oauth_token=\"%@\", ", [self OAuthTypeURLEncoding:self.userOAuthKey]]: @"",
                           [additionalParameters objectForKey:@"oauth_signature_method"],
                           [self OAuthTypeURLEncoding:signedValue],
                           timestamp,
                           nonceObj,
                           self.clientOAuthCallBack ? [NSString stringWithFormat:@"oauth_callback=\"%@\", ", [self OAuthTypeURLEncoding:self.clientOAuthCallBack]]: @"",
                           self.userOAuthVerifier ? [NSString stringWithFormat:@"oauth_verifier=\"%@\", ", self.userOAuthVerifier]: @""];
  [request addValue:oauthHeader forHTTPHeaderField:@"Authorization"];
  CFRelease(nonce);
}

-(BOOL)hasUserToken
{
  return self.userOAuthKey ? YES : NO;
}


-(void)rawRequestWithMethod:(NSString*)method
                       path:(NSString*)path
                 parameters:(NSDictionary*)parameters
                    success:(GreeHTTPSuccessBlock)success
                    failure:(GreeHTTPFailureBlock)failure
{
  NSMutableURLRequest* request = [self requestWithMethod:method path:path parameters:parameters];
  [request setValue:@"text/text" forHTTPHeaderField:@"Accept"];
  GreeAFHTTPRequestOperation* op = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
  [self enqueueHTTPRequestOperation:op];
}

-(void)encodedDeletePath:(NSString*)path
              parameters:(NSDictionary*)parameters
                 success:(GreeHTTPSuccessBlock)success
                 failure:(GreeHTTPFailureBlock)failure
{
  NSMutableURLRequest* request = [self requestWithMethod:@"DELETE" path:path parameters:nil];
  NSString* oldURLString = [request.URL absoluteString];
  NSString* parameterEncoding = GreeAFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
  NSString* newURLString = [oldURLString stringByAppendingFormat:@"?%@", parameterEncoding];
  request.URL = [NSURL URLWithString:newURLString];
  [self performRequest:request parameters:parameters success:success failure:failure];
}


-(id)downloadImageAtUrl:(NSURL*)url withBlock:(void (^)(UIImage* image, NSError* error))block
{
  if (!block) {
    return nil;
  }

  [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOs position:GreeBenchmarkPosition(@"imageGetStart") pointRole:GreeBenchmarkPointRoleStart];
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
  GreeAFImageRequestOperation* op = [GreeAFImageRequestOperation
                                     imageRequestOperationWithRequest:request
                                                 imageProcessingBlock:nil
                                                              success:^(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image) {
                                       [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOs position:GreeBenchmarkPosition(@"imageGetEnd") pointRole:GreeBenchmarkPointRoleEnd];
                                       block(image, nil);
                                     }
                                                              failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) {
                                       [[GreePlatform sharedInstance].benchmark registerWithKey:kGreeBenchmarkOs position:GreeBenchmarkPosition(@"imageGetError") pointRole:GreeBenchmarkPointRoleEnd];
                                       block(nil, [GreeError convertToGreeError:error]);
                                     }];
  [self enqueueHTTPRequestOperation:op];
  return [GreeHTTPClient buildHandleForOperation:op];
}

-(void)cancelWithHandle:(id)handle
{
  //look for the operation inside the queue
  NSArray* handleData = (NSArray*)handle;
  id operationLocation = [[handleData objectAtIndex:0] nonretainedObjectValue];
  NSArray* existingOperations = self.operationQueue.operations;  //which makes a copy, in case it changes before we can cancel
  NSUInteger location = [existingOperations indexOfObjectIdenticalTo:operationLocation];
  if(location != NSNotFound) {
    GreeAFURLConnectionOperation* foundOperation = [existingOperations objectAtIndex:location];
    if(foundOperation.request.URL == [handleData objectAtIndex:1]) {
      [foundOperation cancel];
    }
  }
}

-(void)reAuthorize
{
  [[GreeAuthorization sharedInstance] reAuthorize];
}

#pragma mark - AFHTTPClient overloads
-(void)getPath:(NSString*)path
    parameters:(NSDictionary*)parameters
       success:(GreeHTTPSuccessBlock)success
       failure:(GreeHTTPFailureBlock)failure
{
  [self method:@"GET" path:path parameters:parameters success:success failure:failure];
}

-(void)postPath:(NSString*)path
     parameters:(NSDictionary*)parameters
        success:(GreeHTTPSuccessBlock)success
        failure:(GreeHTTPFailureBlock)failure
{
  [self method:@"POST" path:path parameters:parameters success:success failure:failure];
}

-(void)putPath:(NSString*)path
    parameters:(NSDictionary*)parameters
       success:(GreeHTTPSuccessBlock)success
       failure:(GreeHTTPFailureBlock)failure
{
  [self method:@"PUT" path:path parameters:parameters success:success failure:failure];
}

-(void)deletePath:(NSString*)path
       parameters:(NSDictionary*)parameters
          success:(GreeHTTPSuccessBlock)success
          failure:(GreeHTTPFailureBlock)failure
{
  [self method:@"DELETE" path:path parameters:parameters success:success failure:failure];
}

-(NSMutableURLRequest*)requestWithMethod:(NSString*)method path:(NSString*)path parameters:(NSDictionary*)parameters
{
  NSMutableURLRequest* request = [super requestWithMethod:method path:path parameters:parameters];

  if ([method isEqualToString:@"GET"]) {
    [self signRequest:request parameters:parameters];
  } else {
    [self signRequest:request parameters:nil];
  }

  return request;
}

-(void)enqueueHTTPRequestOperation:(GreeAFHTTPRequestOperation*)operation
{
  if ([operation.request isKindOfClass:[NSMutableURLRequest class]]) {
    // set the "User-Agent" header for except the OS domain
    NSMutableURLRequest* aRequest = (NSMutableURLRequest*)operation.request;
    [aRequest setValue:[GreeHTTPClient userAgentString] forHTTPHeaderField:@"User-Agent"];
  }

  [super enqueueHTTPRequestOperation:operation];
}

#pragma mark - Private Methods
-(void)method:(NSString*)method
         path:(NSString*)path
   parameters:(NSDictionary*)parameters
      success:(GreeHTTPSuccessBlock)success
      failure:(GreeHTTPFailureBlock)failure
{
  void (^successBlock)(GreeAFHTTPRequestOperation*, id) = nil;
  void (^failureBlock)(GreeAFHTTPRequestOperation*, NSError*) = nil;

  if (self.denyRequestWithoutAuthorization && ![[GreeAuthorization sharedInstance] isAuthorized]) {
    dispatch_async(dispatch_get_main_queue(), ^{
                     failure(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeNotAuthorized]);
                   });
  } else {

    GreeHTTPFailureBlock failureBlockWithHandlingError =
      [self errorHandlingFailureBlockWithUpgradeSuccessBlock:^{
         [self method:method path:path parameters:parameters success:success failure:failure];
       }
                                                wrappedBlock:failure];

    successBlock =^(GreeAFHTTPRequestOperation* operation, id responseObject){
      success(operation, responseObject);
    };
    failureBlock =^(GreeAFHTTPRequestOperation* operation, NSError* error){
      failureBlockWithHandlingError(operation, error);
    };

    if ([method isEqualToString:@"GET"]) {
      [super getPath:path parameters:parameters success:successBlock failure:failureBlock];
    } else if ([method isEqualToString:@"POST"]) {
      [super postPath:path parameters:parameters success:successBlock failure:failureBlock];
    } else if ([method isEqualToString:@"PUT"]) {
      [super putPath:path parameters:parameters success:successBlock failure:failureBlock];
    } else if ([method isEqualToString:@"DELETE"]) {
      [super deletePath:path parameters:parameters success:successBlock failure:failureBlock];
    }
  }
}

-(GreeHTTPFailureBlock)errorHandlingFailureBlockWithUpgradeSuccessBlock:(void (^)(void))success wrappedBlock:(GreeHTTPFailureBlock)wrapped
{
  return [[^(GreeAFHTTPRequestOperation* operation, NSError* error){
             id response = [[operation responseString] greeMutableObjectFromJSONString];
             if ([response isKindOfClass:[NSDictionary class]]) {
               NSDictionary* dict = (NSDictionary*)response;
               if ([dict objectForKey:@"message"]) {
                 NSMutableDictionary* newInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                 [newInfo setObject:[dict objectForKey:@"message"] forKey:GreeHTTPResponseMessageKey];
                 error = [NSError errorWithDomain:error.domain code:error.code userInfo:newInfo];
               }

               if ([[dict objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:1002]]) {
                 NSArray* errAray = [dict objectForKey:@"__error"];
                 if ([[errAray objectAtIndex:0] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                   [[GreeAuthorization sharedInstance] reAuthorize];
                 }
               } else if ([[dict objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:1003]]) {
                 NSArray* errAray = [dict objectForKey:@"__error"];
                 if ([[errAray objectAtIndex:0] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                   NSString* target_grade = [[errAray objectAtIndex:1] stringValue];
                   NSDictionary* param = [NSDictionary dictionaryWithObject:target_grade forKey:@"target_grade"];
                   [[GreeAuthorization sharedInstance] upgradeWithParams:param
                                                            successBlock:success
                                                            failureBlock:^{
                      if (wrapped)
                        wrapped(operation, error);
                    }
                   ];
                   return;
                 }
               }
             }
             if (wrapped)
               wrapped(operation, error);
           } copy] autorelease];
}

-(NSString*)OAuthTypeURLEncoding:(NSString*)str
{
  NSString* result = (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (CFStringRef)str,
                                                                        NULL,
                                                                        CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                        kCFStringEncodingUTF8);
  [result autorelease];
  return result;
}


-(NSString*)signClearText:(NSString*)text secret:(NSString*)secret
{
  if(self.useCryptographicSigning) {
    //SHA1 HMAC
    NSData* secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData* clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);

    //then Base64
    return [self base64EncodeData:[NSData dataWithBytes:result length:20]];
  }
  return secret;
}

-(NSString*)URLWithoutQuery:(NSURL*)url
{
  return [[[url absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
}

-(NSString*)base64EncodeData:(NSData*)data
{
  NSUInteger length = [data length];
  NSMutableData* mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

  uint8_t* input = (uint8_t*)[data bytes];
  uint8_t* output = (uint8_t*)[mutableData mutableBytes];

  for (NSUInteger i = 0; i < length; i += 3) {
    NSUInteger value = 0;
    for (NSUInteger j = i; j < (i + 3); j++) {
      value <<= 8;
      if (j < length) {
        value |= (0xFF & input[j]);
      }
    }

    static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    NSUInteger idx = (i / 3) * 4;
    output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
    output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
    output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
    output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
  }

  return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

//Mozilla/5.0 (iPhone Simulator; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Mobile/9A334
static NSString* GREE_AGENT_DICT_KEY = @"greesdk_user_agent";
static NSString* DEVICE_MODEL_KEY = @"model";
static NSString* DEVICE_VERSTION_KEY = @"version";
static NSString* AGENT_STRING_KEY = @"user_agent_string";
+(NSString*)userAgentString
{
  static dispatch_once_t onceToken;
  static NSString* userAgentStr = nil;
  dispatch_once(&onceToken, ^{
                  UIDevice* device = [UIDevice currentDevice];
                  NSString* newModel = [device model];
                  NSString* newVersion = [device systemVersion];

                  BOOL needUpdateCache = YES;
                  NSUserDefaults* defaults= [NSUserDefaults standardUserDefaults];
                  NSDictionary* userAgentDict = [defaults objectForKey:GREE_AGENT_DICT_KEY];
                  if ([newModel isEqualToString:[userAgentDict objectForKey:DEVICE_MODEL_KEY]] &&
                      [newVersion isEqualToString:[userAgentDict objectForKey:DEVICE_VERSTION_KEY]]) {
                    needUpdateCache = NO;
                    userAgentStr = [userAgentDict objectForKey:AGENT_STRING_KEY];
                  }

                  if (needUpdateCache) {
                    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                    userAgentStr= [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                    [webView release];

                    userAgentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                     newModel, DEVICE_MODEL_KEY,
                                     newVersion, DEVICE_VERSTION_KEY,
                                     userAgentStr, AGENT_STRING_KEY, nil];
                    [defaults setObject:userAgentDict forKey:GREE_AGENT_DICT_KEY];
                  }

                  atexit_b (^{
                              [userAgentStr release], userAgentStr = nil;
                            });
                });

  return userAgentStr;
}

+(id)buildHandleForOperation:(GreeAFURLConnectionOperation*)operation
{
  //NOTE: The array is being used because we may want to add other items in the future.
  //For instance, if we were to record the URL, we could use that to determine if the request hasn't been replaced out from under us.
  //It is vital that the objects inside here don't contain cycles, so don't use anything that contains a block
  NSArray* handleData = [NSArray arrayWithObjects:[NSValue valueWithNonretainedObject:operation], operation.request.URL, nil];
  return handleData;
}

@end


