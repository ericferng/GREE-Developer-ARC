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

#import "GreeDashboardURLGenerator.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeDashboardViewControllerLaunchMode.h"
#import "GreeLogger.h"

static BOOL isPresent(NSString* str)
{
  return (str && str.length != 0);
}

static BOOL isBlank(NSString* str)
{
  return (!str || str.length == 0);
}

@interface NSString (GreeDashboardURLGenerator)
-(NSString*)stringByAppendingURLParameterKey:(NSString*)key value:(NSString*)value;
@end

@implementation NSString (GreeDashboardURLGenerator)
-(NSString*)stringByAppendingURLParameterKey:(NSString*)key value:(NSString*)value
{
  NSString* appendingFormat = ([self rangeOfString:@"?"].location == NSNotFound) ? @"?%@=%@" : @"&%@=%@";
  return [self stringByAppendingFormat:appendingFormat, key, value];
}
@end

@interface GreeDashboardURLGenerator ()
@property (nonatomic, assign) NSDictionary* parameters;
@property (nonatomic, assign) NSString* path;
@property (nonatomic, assign) NSString* appId;
@property (nonatomic, assign) NSString* userId;

-(NSURL*)dashboardURLWithParameters:(NSDictionary*)parameters_;
-(NSString*)dashboardURLString;
-(NSString*)URLStringModeUsersInvites;
-(NSString*)URLStringModeRankingDetails;
-(NSString*)URLStringModeAppSetting;
-(NSString*)URLStringModeCommunity;
-(NSString*)URLStringModeUserProfile;
-(NSString*)URLStringModeGameNotice;
-(NSString*)prependBaseURLApps:(NSString*)pathString;
-(NSString*)prependBaseURLPf:(NSString*)pathString;
-(NSString*)prependBaseURLDomain:(NSString*)pathString;
-(NSString*)prependBaseURLSns:(NSString*)pathString;
-(NSString*)prependBaseURLNotice:(NSString*)pathString;
-(NSString*)dashboardPathString:(NSString*)pathString;
@end

@implementation GreeDashboardURLGenerator

-(id)init
{
  self = [super init];
  return self;
}

-(void)dealloc
{
  [super dealloc];
}

+(NSURL*)dashboardURLWithParameters:(NSDictionary*)parameters
{
  GreeDashboardURLGenerator* urlGenerator = [[GreeDashboardURLGenerator alloc] init];
  NSURL* returnValue = [urlGenerator dashboardURLWithParameters:parameters];
  [urlGenerator release];
  return returnValue;
}

-(NSURL*)dashboardURLWithParameters:(NSDictionary*)parameters_
{
  self.parameters = parameters_;
  return [NSURL URLWithString:[self dashboardURLString]];
}

-(NSString*)dashboardURLString
{
  if(!self.parameters) {
    return [self prependBaseURLApps:GreeDashboardModeTop];
  }

  self.path   = [self.parameters objectForKey:GreeDashboardMode];
  self.appId  = [self.parameters objectForKey:GreeDashboardAppId];
  self.userId = [self.parameters objectForKey:GreeDashboardUserId];

  if (isBlank(self.path)) {
    return [self prependBaseURLApps:[self dashboardPathString:GreeDashboardModeTop]];
  }

  if ([self.path isEqualToString:GreeDashboardModeUsersInvites]) {
    return [self URLStringModeUsersInvites];
  }

  if ([self.path isEqualToString:GreeDashboardModeUsersList]) {
    self.userId = nil;
    return [self prependBaseURLApps:[self dashboardPathString:self.path]];
  }

  if ([self.path isEqualToString:GreeDashboardModeTop] ||
      [self.path isEqualToString:GreeDashboardModeRankingList] ||
      [self.path isEqualToString:GreeDashboardModeAchievementList] ) {
    return [self prependBaseURLApps:[self dashboardPathString:self.path]];
  }

  if ([self.path isEqualToString:GreeDashboardModeRankingDetails]) {
    return [self URLStringModeRankingDetails];
  }

  if ([self.path isEqualToString:GreeDashboardModeAppSetting]) {
    return [self URLStringModeAppSetting];
  }

  if ([self.path isEqualToString:GreeDashboardModeCommunity]) {
    return [self URLStringModeCommunity];
  }

  if ([self.path isEqualToString:GreeDashboardModeUserProfile]) {
    return [self URLStringModeUserProfile];
  }

  if ([self.path isEqualToString:GreeDashboardModeGameNotice]) {
    return [self URLStringModeGameNotice];
  }

  return self.path;
}

-(NSString*)URLStringModeUsersInvites
{
  NSString* applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  return [self prependBaseURLPf:[NSString stringWithFormat:@"%@%@", GreeDashboardModeUsersInvites, applicationIdString]];
}

-(NSString*)URLStringModeRankingDetails
{
  NSString* strLeaderboarderId = [self.parameters objectForKey:GreeDashboardLeaderboardId];

  if (isPresent(strLeaderboarderId)) {
    NSString* pathString = [self dashboardPathString:self.path];
    pathString = [pathString stringByAppendingURLParameterKey:GreeDashboardLeaderboardId value:strLeaderboarderId];
    return [self prependBaseURLApps:pathString];
  } else {
    GreeLogWarn(@"Cannot launch the selected dashboard without '%@'", GreeDashboardLeaderboardId);
    return [self prependBaseURLApps:[self dashboardPathString:GreeDashboardModeTop]];
  }
}

-(NSString*)URLStringModeAppSetting
{
  NSString* applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSString* pathString = [NSString stringWithFormat:@"%@%@", GreeDashboardModeAppSetting, applicationIdString];
  return [self prependBaseURLApps:pathString];
}

-(NSString*)URLStringModeCommunity
{
  NSString* commmunityId = [self.parameters objectForKey:GreeDashboardCommunityId];
  NSString* threadId     = [self.parameters objectForKey:GreeDashboardThreadId];

  if (isPresent(commmunityId)) {
    NSMutableString* parametersUrlString = [NSMutableString stringWithFormat:@"/%@/%@", GreeDashboardModeCommunity, commmunityId];
    if (isPresent(threadId)) {
      [parametersUrlString appendFormat:@"/%@", threadId];
    }
    return [self prependBaseURLDomain:parametersUrlString];
  } else {
    return [self prependBaseURLSns:@"/#view=community_updated_list"];
  }
}

-(NSString*)URLStringModeUserProfile
{
  NSString* pathString = [@"/#view=profile_info&user_id=" stringByAppendingString:self.userId];
  return [self prependBaseURLSns:pathString];
}

-(NSString*)URLStringModeGameNotice
{
  NSString* pathString = @"/?action=ggp_timeline&filter=game&header=off";
  return [self prependBaseURLNotice:pathString];
}

-(NSString*)prependBaseURLApps:(NSString*)pathString
{
  return [NSString stringWithFormat:@"%@%@",
          [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlApps],
          pathString];
}

-(NSString*)prependBaseURLPf:(NSString*)pathString
{
  return [NSString stringWithFormat:@"%@%@",
          [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlPf],
          pathString];
}

-(NSString*)prependBaseURLDomain:(NSString*)pathString
{
  return [NSString stringWithFormat:@"http://%@%@",
          [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain],
          pathString];
}

-(NSString*)prependBaseURLSns:(NSString*)pathString
{
  return [NSString stringWithFormat:@"%@%@",
          [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns],
          pathString];
}

-(NSString*)prependBaseURLNotice:(NSString*)pathString
{
  return [NSString stringWithFormat:@"%@%@",
          [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlNotice],
          pathString];
}

-(NSString*)dashboardPathString:(NSString*)pathString
{
  NSString* strPath = [NSString stringWithFormat:@"%@", pathString];

  if (isPresent(self.appId)) {
    strPath = [strPath stringByAppendingURLParameterKey:GreeDashboardAppId value:self.appId];
  }
  if (isPresent(self.userId)) {
    strPath = [strPath stringByAppendingURLParameterKey:GreeDashboardUserId value:self.userId];
  }

  return strPath;
}

@end
