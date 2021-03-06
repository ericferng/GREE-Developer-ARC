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
 * @file GreeDashboardViewControllerDelegate.h
 * GreeDashboardViewControllerDelegate Protocol
 */

#import <Foundation/Foundation.h>
@class GreeDashboardViewController;

@protocol GreeDashboardViewControllerDelegate<NSObject>
@optional
/**
 * Called when the close button of the dashboard is tapped.
 * @param dashboardViewController The dashboard view controller whose close button was tapped.
 */
-(void)dashboardCloseButtonPressed:(GreeDashboardViewController*)dashboardViewController;
@end
