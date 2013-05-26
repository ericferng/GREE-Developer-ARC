//
//  AppDelegate.m
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/15/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"2-blue-menu-bar.png"] forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"2-blue-back-button.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    
    
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys: GreeDevelopmentModeSandbox, GreeSettingDevelopmentMode, nil];
    
    //NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys: GreeDevelopmentModeProduction, GreeSettingDevelopmentMode, nil];
    [GreePlatform initializeWithApplicationId:@"xxx" consumerKey:@"xxx"
                                consumerSecret:@"xxx" settings:settings delegate:self];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [GreePlatform shutdown];
}

-(void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [GreePlatform postDeviceToken:deviceToken block:^(NSError* error) {
        if (error) {
            NSLog(@"Error uploading User Token:%@", error);
        } else {
            NSLog(@"Succeeded to upload device token!");
        }
    }];
}

-(void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Error registering for remote notifications:%@", error);
}

-(void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    [GreePlatform handleRemoteNotification:userInfo application:application];
}

-(BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    return [GreePlatform handleOpenURL:url application:application];
}

#pragma mark - GreePlatformDelegate Protocol

-(void)greePlatformWillShowModalView:(GreePlatform*)platform
{
    NSLog(@"%s", __FUNCTION__);
}

-(void)greePlatformDidDismissModalView:(GreePlatform*)platform
{
    NSLog(@"%s", __FUNCTION__);
}

-(void)greePlatform:(GreePlatform*)platform didLoginUser:(GreeUser*)localUser
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"Local User: %@", localUser);
    self.canUpdateProfile = YES;
}

-(void)greePlatform:(GreePlatform*)platform didLogoutUser:(GreeUser*)localUser
{
    NSLog(@"%s", __FUNCTION__);
    self.canUpdateProfile = YES;
    //[self.rootController loadUser];
}

-(void)greePlatformParamsReceived:(NSDictionary*)params
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"params: %@", params.description);
    
    NSDictionary* requestParams = [params objectForKey:@"params"];
    // Show result in UIAlertVIew
    NSString* aMessage = [NSString stringWithFormat:@"%@", params];
    
     
}

-(void)greePlatform:(GreePlatform*)platform didUpdateLocalUser:(GreeUser*)localUser
{
   
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"Local User: %@", localUser);
    NSLog(@"User id: %@",localUser.userId);
    

    if (localUser != nil && self.canUpdateProfile) {
        //[self.rootController loadUser];
        self.canUpdateProfile = NO;
    }
}




@end
