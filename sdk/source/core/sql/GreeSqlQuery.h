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

typedef struct sqlite3* GreeDatabaseHandle;

@interface GreeSqlQuery : NSObject<NSFastEnumeration>

// Attempts to open a database at databasePath for reading & writing, creating
// an empty database if none exists.
+(GreeDatabaseHandle)openDatabaseAtPath:(NSString*)databasePath;
// Closes an open database. The given database parameter will be NULLed.
+(void)closeDatabase:(GreeDatabaseHandle*)database;

+(id)queryWithDatabase:(GreeDatabaseHandle)database statement:(NSString*)statement;
// designated initializer
-(id)initWithDatabase:(GreeDatabaseHandle)database statement:(NSString*)statement;

// Use these methods to bind data to named statement parameters
-(void)bindBool:(BOOL)boolValue named:(NSString*)name;
-(void)bindString:(NSString*)stringValue named:(NSString*)name;
-(void)bindData:(NSData*)dataValue named:(NSString*)name;
-(void)bindInt:(NSInteger)integerValue named:(NSString*)name;
-(void)bindInt64:(int64_t)int64Value named:(NSString*)name;
-(void)bindDouble:(double)doubleValue named:(NSString*)name;

// Use these methods to access column data for the current row
-(BOOL)boolValueAtColumnNamed:(NSString*)column;
-(NSString*)stringValueAtColumnNamed:(NSString*)column;
-(NSData*)dataValueAtColumnNamed:(NSString*)column;
-(NSInteger)integerValueAtColumnNamed:(NSString*)column;
-(int64_t)int64ValueAtColumnNamed:(NSString*)column;
-(double)doubleValueAtColumnNamed:(NSString*)column;

// Begins or continues query execution. Returns YES if the query was stepped.
-(BOOL)step;
// Resets the query for re-execution
-(void)reset;
// Returns YES if there is row data available or not.
-(BOOL)hasRowData;

@end
