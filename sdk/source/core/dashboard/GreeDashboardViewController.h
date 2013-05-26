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

#import <UIKit/UIKit.h>
#import "GreeMenuNavController.h"
#import "GreeDashboardViewControllerDelegate.h"

@interface GreeDashboardViewController : GreeMenuNavController
  <UINavigationControllerDelegate, GreeMenuNavControllerDelegate>

@property (nonatomic, retain) NSURL* baseURL;
@property (nonatomic, assign) id<GreeDashboardViewControllerDelegate> dashboardDelegate;
@property (nonatomic, retain) id results;

+(NSURL*)dashboardURLWithParameters:(NSDictionary*)parameters;

-(id)initWithPath:(NSString*)path;
-(id)initWithBaseURL:(NSURL*)baseURL;

@end
