//
//  ViewController.h
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/15/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharedData.h"


@interface ViewController : UIViewController {
    SharedData *sharedData;
}

- (IBAction)onStart:(id)sender;

- (IBAction)onLogout:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonEnterOut;

@property (weak, nonatomic) IBOutlet UIButton *buttonLogoutOut;

@end
