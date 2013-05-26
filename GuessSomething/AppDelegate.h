//
//  AppDelegate.h
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/15/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "GreePlatform.h"
#import "GreePlatformSettings.h"
#import "SharedData.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, GreePlatformDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign) BOOL canUpdateProfile;
@end
