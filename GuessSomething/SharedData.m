//
//  SharedData.m
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/16/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import "SharedData.h"

@interface SharedData ()

@end

@implementation SharedData

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    //self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.jsonResults = [[NSMutableDictionary alloc] init];
        self.createOrPlay = [[NSString alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    //[super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    //[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
+(SharedData *) sharedData;
{
    static SharedData* _sharedData;
    if (!_sharedData)
        _sharedData = [[SharedData alloc] init];
    return _sharedData;
}


@end

