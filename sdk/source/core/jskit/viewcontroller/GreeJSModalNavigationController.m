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


#import "GreeJSModalNavigationController.h"
#import "GreePlatform+Internal.h"
#import "UIViewController+GreeAdditions.h"

@implementation GreeJSModalNavigationController

#pragma mark - Object Lifecycle

-(id)init
{
  self = [super initWithNibName:nil bundle:nil];
  if (self != nil) {
  }
  return self;
}

-(void)dealloc
{
  self.block = nil;
  [super dealloc];
}

#pragma mark - UIViewController Overrides

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

-(void)loadView
{
  [super loadView];

  UIView* myView = self.view;
  myView.frame = [UIScreen mainScreen].applicationFrame;
  myView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  myView.autoresizesSubviews = YES;
}

-(void)viewDidLoad
{
  self.wantsFullScreenLayout = NO;
}

@end
