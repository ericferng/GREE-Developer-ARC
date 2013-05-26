//
//  ViewController.m
//  GuessSomething
//
//  Created by pulkit.kathuria on 5/15/13.
//  Copyright (c) 2013 pulkit.kathuria. All rights reserved.
//

#import "ViewController.h"
#import "GreePlatform.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    sharedData = [SharedData sharedData];
    
    
    if (IS_IPHONE_4){
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"copyright-back.png"]];
    } else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"copyright-back@5g.png"]];
    }

    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)greeLogin{
    [GreePlatform directAuthorizeWithDesiredGrade:GreeUserGradeStandard block:^(GreeUser *localUser, NSError *error) {
        NSLog(@"User loddef");
        NSLog(@"My Local User %@",[localUser profileUrl]);
        
 
        
        NSLog(@"%@",[localUser loadFriendsWithBlock:^(NSArray *friends, NSError *error) {
            NSLog(@"%@",friends);
        }]);
        
    }];

}
-(IBAction)onStart:(id)sender
{

    //[GreePlatform directAuthorizeWithDesiredGrade:GreeUserGradeStandard block:nil];
    [self greeLogin];
       
}

- (IBAction)onLogout:(id)sender{
    [GreePlatform revokeAuthorizationWithBlock:^(NSError* error) { if (error) {
        NSLog(@"Revoke failed: %@", [error localizedDescription]);
        return; }
        NSLog(@"Revoke succeeded, user already logged out."); }];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}



- (void)viewDidUnload {
    [self setButtonEnterOut:nil];
    [self setButtonLogoutOut:nil];
    [super viewDidUnload];
}
@end
