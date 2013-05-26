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
#import <QuartzCore/QuartzCore.h>
#import "UIImage+GreeAdditions.h"
#import "GreePhoneNumberBasedNavigationController.h"
#import "GreePhoneNumberBasedPage.h"

@implementation GreePhoneNumberBasedNavigationController

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    UINavigationBar* navigationBar = self.navigationBar;
    UIImage* defaultImage   = [UIImage greeImageNamed:@"gree.navBar.vertical.png"];

    if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
      [navigationBar setBackgroundImage:[GreePhoneNumberBasedPage convertResizableImage:defaultImage] forBarMetrics:UIBarMetricsDefault];
    } else {
      UIImageView* backgroundView     = [[[UIImageView alloc] initWithImage:[GreePhoneNumberBasedPage convertResizableImage:defaultImage]] autorelease];
      backgroundView.frame            = CGRectMake(0, 0, navigationBar.bounds.size.width, navigationBar.bounds.size.height);
      backgroundView.backgroundColor  = [UIColor blackColor];
      backgroundView.layer.zPosition  = -1;
      [navigationBar insertSubview:backgroundView atIndex:0];
    }
  }
  return self;
}

-(BOOL)shouldAutorotate
{
  return NO;
}

@end
