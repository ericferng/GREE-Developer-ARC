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
 * @file GreeEnumerator.h
 * GreeEnumerator protocol
 */

#import <Foundation/Foundation.h>

/**
 * Type of blocks required by loadNext and loadPrevious. 
 * @param items An NSArray containing one page of items or nil if there isn't any data.
 * @param error Returns any errors that may have occurred.
 */
typedef void (^GreeEnumeratorResponseBlock)(NSArray* items, NSError* error);

/**
 * @brief Generic protocol for enumerating collections of server-side resources.
 *
 * Objects conforming to the GreeEnumerator protocol are created by the component class APIs to page
 * over a (potentially) large set of data. In most cases you can expect id<GreeEnumerator> objects
 * to be returned from the various API class methods beginning with load.
 *
 * The typical API usage pattern looks something like this:
 * @code
 *  [GreeScore loadTopScoresForLeaderboard:leaderboard_id timePeriod:GreeScoreTimePeriodAlltime block:^(NSArray* scores, NSError* error) {
 *     // process top page of scores
 *  }];
 * @endcode
 * 
 * with enumerators, however, you can retrieve more than the first page of data:
 *
 * @code
 *  id<GreeEnumerator> allScoreEnumerator = [GreeScore loadTopScoresForLeaderboard:@"" timePeriod:GreeScoreTimePeriodAlltime block:^(NSArray* scores, NSError* error) {
 *     // process top page of scores
 *  }];
 *  // some time later... after user presses "next", etc.
 *  [allScoreEnumerator loadNext:^(NSArray* scores, NSError* error) {
 *     // process second page of scores
 *  }];
 * @endcode
 *
 * When you have exhausted the data set your returned items will be nil.
 */
@protocol GreeEnumerator<NSObject>

/**
 * @brief Starting index for your next page request.
 * loadPrevious attempts to load the 'pageSize' items before 'startIndex'
 * loadNext attempts to load the next 'pageSize' items after and including 'startIndex' 
 */
-(NSInteger)startIndex;

/**
 * @brief How many entries, at maximum, each page will contain.
 * @note This is merely a suggestion; the server is free to cap this value if the page size is too large.
 */
-(NSInteger)pageSize;

/**
 * @brief @c YES if there are items before the most recently loaded page, @c NO otherwise.
 */
-(BOOL)canLoadPrevious;

/**
 * @brief @c YES if there may be more data to load, @c NO if the data set is known to be exhaused.
 */
-(BOOL)canLoadNext;

/**
 * Loads the next page of data. A page is defined as pageSize items starting with startIndex.
 * @param block The GreeEnumeratorResponseBlock which will receive the items.
 */
-(void)loadNext:(GreeEnumeratorResponseBlock)block;

/**
 * Loads the page previoud to the most recent page, or the first page if startIndex is too low.
 * @param block The GreeEnumeratorResponseBlock which will receive the items.
 */
-(void)loadPrevious:(GreeEnumeratorResponseBlock)block;

/**
 * @brief Change the start index to a specified value.  Values < 1 will be set to 1.
 * @note Advanced API call, use with caution.
 */
-(void)setStartIndex:(NSInteger)startIndex;

/**
 * @brief Set a desired page size for your next load request.
 * It is not guaranteed that the server will accept this value.  Once a page is loaded,
 * this will be set to the page size from the server.  Changing this value after load
 * will interfere with paging backwards.
 * @note Advanced API call, use with caution.
 */
-(void)setPageSize:(NSInteger)pageSize;

/**
 * @brief Sets the enumerator to use a specific user context.
 * @note Not all enumerators respect or support this notion.
 * @note Passing in nil will default to the current user.
 * @note Advanced API call, use with caution.
 */
-(void)setGuid:(NSString*)guid;

@end

/**
 * @brief Countable protocol for enumerating collections of server-side resources.
 */
@protocol GreeCountableEnumerator<GreeEnumerator>

/**
 * @brief Returns the count of all elements contained in the requested resource.
 */
-(NSInteger)count;

@end
