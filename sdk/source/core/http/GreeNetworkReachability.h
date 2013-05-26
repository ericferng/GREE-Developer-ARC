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

/**
 * @file GreeNetworkReachability.h
 * GreeNetworkReachability Interface
 */

#import <Foundation/Foundation.h>

/**
 * @brief Enumeration for various network reachability statuses.
 */
typedef enum {
/**
 * @brief Reachability of host is not determined.
 */
  GreeNetworkReachabilityUnknown,
/**
 * @brief Host is reachable via WiFi network.
 */
  GreeNetworkReachabilityConnectedViaWiFi,
/**
 * @brief Host is reachable via carrier network.
 */
  GreeNetworkReachabilityConnectedViaCarrier,
/**
 * @brief Host is not reachable.
 */
  GreeNetworkReachabilityNotConnected,
} GreeNetworkReachabilityStatus;

/**
 * An NSString representation of a given GreeNetworkReachabilityStatus.
 */
NSString* NSStringFromGreeNetworkReachabilityStatus(GreeNetworkReachabilityStatus status);

/**
 * Determines if a GreeNetworkReachabilityStatus represents connectivity or not.
 * @return @c YES if the given status represents connectivity, @c NO if not.
 */
BOOL GreeNetworkReachabilityStatusIsConnected(GreeNetworkReachabilityStatus status);

typedef void (^GreeNetworkReachabilityChangedBlock)(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current);

/**
 * GreeNetworkReachability is a class that wraps the SCNetworkReachability of the
 * SystemConfiguration framework in order to determine if a connection is available
 * to any given host.
 *
 * This determination is made asynchronously and communicated to through the use of
 * observer blocks. 
 */
@interface GreeNetworkReachability : NSObject

@property (nonatomic, readonly, retain) NSString* host;
@property (nonatomic, readonly, assign) GreeNetworkReachabilityStatus status;

/**
 * Initialize the receiver with a given host. Asynchronous reachability check
 * will commence immediately.
 * @note Designated initializer
 */
-(id)initWithHost:(NSString*)host;

/**
 * Register a block to be invoked upon reachability status changes in the receiver.
 * @return A token useful for removing this observer block.
 */
-(id)addObserverBlock:(GreeNetworkReachabilityChangedBlock)observer;

/**
 * Deregisters the observer block identified by a given token.
 * @param handle Token returned from -addObserverBlock:
 */
-(void)removeObserverBlock:(id)handle;

/**
 * @return @c YES if the host is reachable, @c NO if not.
 */
-(BOOL)isConnectedToInternet;

@end
