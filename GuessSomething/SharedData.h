//
//  SharedData.h
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/16/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>


#define IS_IPHONE_4 ( [[[UIDevice currentDevice] model] isEqualToString:@"iPhone"] )
#define IS_IPOD   ( [[[UIDevice currentDevice ] model] isEqualToString:@"iPod touch"] )
#define IS_HEIGHT_GTE_568 [[UIScreen mainScreen ] bounds].size.height >= 568.0f
#define IS_IPHONE_5 (IS_HEIGHT_GTE_568 )
#define RGBConvert (float) 255


#define DEVICEID [[UIDevice currentDevice] uniqueIdentifier]
#define SLATE [UIColor colorWithPatternImage:[UIImage imageNamed:@"ipad-BG-pattern.png"]]


@interface SharedData : NSObject


+(SharedData *) sharedData;
@property (strong, nonatomic) NSMutableDictionary * jsonResults;
@property (strong, nonatomic) NSString *createOrPlay;



@end
