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

#import "JSONKit.h"
#import "GreeUniversalMenuData.h"
#import "GreeUniversalMenuDataRows.h"
#import "GreeSNSAPI.h"
#import "NSString+GreeAdditions.h"
#import "GreePlatform+Internal.h"

static const int kRowIndexProfile = 0;
static const int kNumberOfProfileSections = 1;
static const int kNumberOfProfileRows = 1;

@interface GreeUniversalMenuData ()
@property (nonatomic, retain) GreeSNSAPI* snsapi;
@property (nonatomic, retain) NSString* json;
@property (nonatomic, retain) NSMutableArray* sections;
@end

@implementation GreeUniversalMenuData

# pragma mark - Object lifecycle

-(id)initWithDelegate:(id<GreeUniversalMenuDataDelegate>)delegate
{
  self = [super init];
  if (self) {
    self.delegate = delegate;
    self.snsapi = [[[GreeSNSAPI alloc] init] autorelease];
    [self load];
    [self request];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authorizationDidSuccessUpgrade:)
                                                 name:@"GreeAuthorizationDidSuccessUpgrade"
                                               object:nil];
  }
  return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.snsapi = nil;
  self.json = nil;
  [super dealloc];
}

# pragma mark - Public Methods

-(NSInteger)numberOfSections
{
  return self.sections.count + kNumberOfProfileSections;
}

-(NSInteger)numberOfRowsInSection:(NSInteger)section
{
  if (section == kGreeUniversalMenuDataSectionIndexProfile) {
    return kNumberOfProfileRows;
  }

  GreeUniversalMenuDataRows* rows = [self rowsAtSectionIndex:section];
  int num = rows.count;
  if (rows.isExpandable) {
    num += 1;
  }

  return num;
}

-(NSDictionary*)sectionAtIndex:(NSInteger)section
{
  if (section == kGreeUniversalMenuDataSectionIndexProfile) {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"", @"header", nil];
  }

  return [self.sections objectAtIndex:section - kNumberOfProfileSections];
}

-(GreeUniversalMenuDataRows*)rowsAtSectionIndex:(NSInteger)section
{
  return [[self sectionAtIndex:section] objectForKey:@"rows"];
}

-(NSDictionary*)rowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == kGreeUniversalMenuDataSectionIndexProfile) {
    return self.profile;
  }

  return [[self rowsAtSectionIndex:indexPath.section] rowAtIndex:indexPath.row];
}

-(BOOL)isExpanderAtIndexPath:(NSIndexPath*)indexPath
{
  GreeUniversalMenuDataRows* rows = [[self sectionAtIndex:indexPath.section] objectForKey:@"rows"];
  return (rows.isExpandable && indexPath.row == rows.count);
}

-(BOOL)isNotSelectableCellAtIndexPath:(NSIndexPath*)indexPath
{
  return ![[self rowAtIndexPath:indexPath] objectForKey:@"on_click"];
}

-(void)request
{
  NSString* requestData = @"{\
    \"jsonrpc\":\"2.0\",\
    \"method\":\"UniversalMenu.get\",\
    \"id\":1,\
    \"params\":{\
      \"show_game_dashboard\":%@\
    },\
    \"renderer\":\"native\",\
    \"isLoggingSkipped\":false\
  }";
  NSString* showGameDashboard = ([GreePlatform isSnsApp] ? @"false" : @"true");
  requestData = [NSString stringWithFormat:requestData, showGameDashboard];

  [self.snsapi
   postWithRequestData:requestData
               success:^(NSString* responseString) {
     NSDictionary* result = [[responseString greeObjectFromJSONString] objectForKey:@"result"];
     self.json = [result greeJSONString];

     if (!self.json) {
       [self requestFailure];
       return;
     }

     [self updateWithJSON:self.json];
     [self.delegate dataDidUpdate];
     [self save];
   } failure:^(int statusCode, NSError* error, NSString* responseString) {
     [self requestFailure];
   }];
}

#pragma mark - Internal Methods

-(void)save
{
  NSString* path = [NSString greeCachePathForRelativePath:@"greeUniversalMenuCache"];
  NSError* error;
  [self.json writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

-(void)load
{
  NSString* path = [NSString greeCachePathForRelativePath:@"greeUniversalMenuCache"];
  NSError* error;
  self.json = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  if (!error) {
    [self updateWithJSON:self.json];
  }
}

-(void)updateWithJSON:(NSString*)json
{
  NSDictionary* data = [json greeMutableObjectFromJSONString];
  self.profile = [data objectForKey:@"profile"];

  self.sections = [data objectForKey:@"sections"];
  for (int i = 0; i < self.sections.count; i++) {
    NSMutableDictionary* section = [self.sections objectAtIndex:i];
    GreeUniversalMenuDataRows* rows = [[[GreeUniversalMenuDataRows alloc] initWithDictionary:section] autorelease];
    [section setValue:rows forKey:@"rows"];
  }
}

-(void)authorizationDidSuccessUpgrade:(NSNotification*)notification
{
  NSLog(@"Failed UniversalMenuDataLoad");
  [self request];
}

-(void)requestFailure
{
  const static NSTimeInterval RetryInterval = 3.0;
  [NSTimer scheduledTimerWithTimeInterval:RetryInterval target:self selector:@selector(retryRequest:)userInfo:nil repeats:NO];
}

-(void)retryRequest:(NSTimer*)timer
{
  [self request];
}

@end
