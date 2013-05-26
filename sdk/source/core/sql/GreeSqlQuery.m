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

#import "GreeSqlQuery.h"
#import "GreeError.h"
#import <sqlite3.h>

#define ASSERT_SQLITE_OK(result) \
  NSAssert( \
    result == SQLITE_OK || result == SQLITE_ROW || result == SQLITE_DONE, \
    @"SQLite error: %s", \
    sqlite3_errmsg(self.database));

@interface GreeSqlQuery ()
@property (nonatomic, assign, readwrite) GreeDatabaseHandle database;
@property (nonatomic, copy, readwrite) NSString* statement;
@property (nonatomic, assign, readwrite) sqlite3_stmt* compiledStatement;
@property (nonatomic, retain, readwrite) NSArray* columnNames;
@property (nonatomic, retain, readwrite) NSArray* bindParameterNames;
@property (nonatomic, assign, readwrite) int lastStepResult;
@property (nonatomic, retain, readwrite) NSMutableArray* fastEnumerationRows;
@end

@implementation GreeSqlQuery

#pragma mark - Object Lifecycle

+(id)queryWithDatabase:(GreeDatabaseHandle)database statement:(NSString*)statement
{
  return [[[self alloc] initWithDatabase:database statement:statement] autorelease];
}

-(id)initWithDatabase:(GreeDatabaseHandle)database statement:(NSString*)statement
{
  self = [super init];
  if (self != nil && database != NULL) {
    self.database = database;
    self.statement = statement;
    self.lastStepResult = SQLITE_OK;

    int result = sqlite3_prepare_v2(self.database, [self.statement UTF8String], [self.statement length], &_compiledStatement, NULL);
    if (result == SQLITE_OK) {
      int columnCount = sqlite3_column_count(self.compiledStatement);
      NSMutableArray* mutableColumnNames = [[NSMutableArray alloc] initWithCapacity:columnCount];
      for (int i = 0; i < columnCount; ++i) {
        [mutableColumnNames addObject:[NSString stringWithUTF8String:sqlite3_column_name(self.compiledStatement, i)]];
      }
      self.columnNames = [NSArray arrayWithArray:mutableColumnNames];
      [mutableColumnNames release];

      int bindParameterCount = sqlite3_bind_parameter_count(self.compiledStatement);
      NSMutableArray* mutableBindParameterNames = [[NSMutableArray alloc] initWithCapacity:bindParameterCount];
      for (int i = 1; i <= bindParameterCount; ++i) {
        // skip the :, $, ?, etc.
        char const* parameterName = ((char const*)sqlite3_bind_parameter_name(self.compiledStatement, i)) + 1;
        [mutableBindParameterNames addObject:[NSString stringWithUTF8String:parameterName]];
      }
      self.bindParameterNames = [NSArray arrayWithArray:mutableBindParameterNames];
      [mutableBindParameterNames release];
    }

    if (self.compiledStatement == NULL && [self.columnNames count] == 0) {
      [self release];
      self = nil;
    }
  } else if (!database) {
    [self release];
    self = nil;
  }

  return self;
}

-(void)dealloc
{
  if (self.compiledStatement != NULL) {
    sqlite3_finalize(self.compiledStatement);
  }
  self.statement = nil;
  self.columnNames = nil;
  self.bindParameterNames = nil;
  self.fastEnumerationRows = nil;
  [super dealloc];
}

#pragma mark - Public Interface

#pragma mark Database Connection

+(GreeDatabaseHandle)openDatabaseAtPath:(NSString*)databasePath
{
  GreeDatabaseHandle dbHandle = NULL;
  int result = sqlite3_open([databasePath UTF8String], &dbHandle);
  if (result != SQLITE_OK) {
    [self closeDatabase:&dbHandle];
  }
  sqlite3_busy_timeout(dbHandle, 250);
  return dbHandle;
}

+(void)closeDatabase:(GreeDatabaseHandle*)database
{
  if (database != NULL && (*database) != NULL) {
    int result = sqlite3_close((*database));
    if (result == SQLITE_OK) {
      (*database) = NULL;
    }
  }
}

#pragma mark Bind Parameters

-(void)bindBool:(BOOL)boolValue named:(NSString*)name
{
  int result = sqlite3_bind_int(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, (int)boolValue);
  ASSERT_SQLITE_OK(result);
}

-(void)bindString:(NSString*)stringValue named:(NSString*)name
{
  int result = sqlite3_bind_text(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, [stringValue UTF8String], -1, SQLITE_TRANSIENT);
  ASSERT_SQLITE_OK(result);
}

-(void)bindData:(NSData*)dataValue named:(NSString*)name
{
  int result = sqlite3_bind_blob(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, [dataValue bytes], [dataValue length], SQLITE_TRANSIENT);
  ASSERT_SQLITE_OK(result);
}

-(void)bindInt:(NSInteger)integerValue named:(NSString*)name
{
  int result = sqlite3_bind_int(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, (int)integerValue);
  ASSERT_SQLITE_OK(result);
}

-(void)bindInt64:(int64_t)int64Value named:(NSString*)name
{
  int result = sqlite3_bind_int64(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, (sqlite3_int64)int64Value);
  ASSERT_SQLITE_OK(result);
}

-(void)bindDouble:(double)doubleValue named:(NSString*)name
{
  int result = sqlite3_bind_double(self.compiledStatement, [self.bindParameterNames indexOfObject:name]+1, doubleValue);
  ASSERT_SQLITE_OK(result);
}

#pragma mark Column Accessors

-(BOOL)boolValueAtColumnNamed:(NSString*)column
{
  BOOL boolValue = sqlite3_column_int(self.compiledStatement, [self.columnNames indexOfObject:column]) == 1;
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);
  return boolValue;
}

-(NSString*)stringValueAtColumnNamed:(NSString*)column
{
  const char* text = (const char*)sqlite3_column_text(self.compiledStatement, [self.columnNames indexOfObject:column]);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);
  return [NSString stringWithUTF8String:text];
}

-(NSData*)dataValueAtColumnNamed:(NSString*)column
{
  const int columnIndex = [self.columnNames indexOfObject:column];
  const void* data = sqlite3_column_blob(self.compiledStatement, columnIndex);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);

  NSData* response = nil;
  int dataLength = sqlite3_column_bytes(self.compiledStatement, columnIndex);
  if (data != NULL && dataLength > 0) {
    response = [NSData dataWithBytes:data length:dataLength];
  }
  return response;
}

-(NSInteger)integerValueAtColumnNamed:(NSString*)column
{
  NSInteger integerValue = (NSInteger)sqlite3_column_int(self.compiledStatement, [self.columnNames indexOfObject:column]);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);
  return integerValue;
}

-(int64_t)int64ValueAtColumnNamed:(NSString*)column
{
  int64_t int64Value = (int64_t)sqlite3_column_int64(self.compiledStatement, [self.columnNames indexOfObject:column]);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);
  return int64Value;
}

-(double)doubleValueAtColumnNamed:(NSString*)column
{
  double doubleValue = sqlite3_column_double(self.compiledStatement, [self.columnNames indexOfObject:column]);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);
  return doubleValue;
}

-(id)valueAtColumnNamed:(NSString*)column
{
  int type = sqlite3_column_type(self.compiledStatement, [self.columnNames indexOfObject:column]);
  int result = sqlite3_errcode(self.database);
  ASSERT_SQLITE_OK(result);

  id value = nil;
  switch (type) {
  case SQLITE_INTEGER:
    value = [NSNumber numberWithLongLong:(long long)[self int64ValueAtColumnNamed:column]];
    break;

  case SQLITE_FLOAT:
    value = [NSNumber numberWithDouble:[self doubleValueAtColumnNamed:column]];
    break;

  case SQLITE_BLOB:
    value = [self dataValueAtColumnNamed:column];
    break;

  case SQLITE_TEXT:
    value = [self stringValueAtColumnNamed:column];
    break;

  case SQLITE_NULL:
    value = [NSNull null];
    break;

  default:
    NSAssert(NO, @"Unrecognized SQLITE value type!");
    break;
  };

  return value;
}

#pragma mark Query State

-(BOOL)step
{
  BOOL stepped = NO;

  if (self.lastStepResult == SQLITE_ROW || self.lastStepResult == SQLITE_OK) {
    self.lastStepResult = sqlite3_step(self.compiledStatement);
    ASSERT_SQLITE_OK(self.lastStepResult);
    stepped = YES;
  }

  return stepped;
}

-(void)reset
{
  sqlite3_reset(self.compiledStatement);
  self.lastStepResult = SQLITE_OK;
  [self.fastEnumerationRows removeAllObjects];
}

-(BOOL)hasRowData
{
  return self.lastStepResult == SQLITE_ROW;
}

#pragma mark - NSFastEnumeration Protocol

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id*)stackbuf count:(NSUInteger)len
{
  // if we're at the beginning let's be kind, rewind.
  if (state->state == 0) {
    [self reset];
  }

  // lazily allocate our row storage
  if (!self.fastEnumerationRows) {
    self.fastEnumerationRows = [NSMutableArray arrayWithCapacity:len];
  }

  // gather row data into fastEnumerationRows... this is the expensive part
  int numItems = 0;
  while (numItems < len && [self step] && [self hasRowData]) {
    NSDictionary* row = [[NSMutableDictionary alloc] initWithCapacity:[self.columnNames count]];
    for (NSString* columnName in self.columnNames) {
      [row setValue:[self valueAtColumnNamed:columnName] forKey:columnName];
    }
    stackbuf[numItems++] = row;
    [self.fastEnumerationRows addObject:row];
    [row release];
  }

  state->state += (unsigned long)numItems;
  state->itemsPtr = stackbuf;
  state->mutationsPtr = (unsigned long*)self;

  return numItems;
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p, database:%p, statement:%@>",
          NSStringFromClass([self class]),
          self,
          self.database,
          self.statement];
}

@end
