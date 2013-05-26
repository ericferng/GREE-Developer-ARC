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


#import "GreeJSFormViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeJSInputViewToolbar.h"


static CGFloat kMargin = 8.0f;


@interface GreeJSFormViewController ()
@property (nonatomic, retain) UITextField* titleField;
@property (nonatomic, retain) UILabel* titleLabel;
@property (nonatomic, retain) UILabel* label;

-(BOOL)validateTitleField;
@end


@implementation GreeJSFormViewController


#pragma mark - UIViewController Overrides

-(void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.textView resignFirstResponder];
  [self.titleField becomeFirstResponder];

  CGRect viewFrame = self.view.frame;
  CGFloat y = viewFrame.size.height;
  self.toolbar.frame = CGRectMake(0, y - 44, viewFrame.size.width, 44);
}


#pragma mark - GreeJSInputViewController Overrides

-(NSDictionary*)data
{
  NSMutableDictionary* data = [NSMutableDictionary dictionary];

  [data setValue:self.titleField.text forKey:@"title"];
  [data setValue:self.textView.text forKey:@"text"];
  if (self.toolbar) {
    for (int i = 0; i < self.images.count; i++) {
      UIImage* image = [self.images objectAtIndex:i];
      if (image && ![image isEqual:[NSNull null]]) {
        [data setValue:[self base64WithImage:image]
                forKey:[NSString stringWithFormat:@"image%d", i]];
      }
    }
  }

  return data;
}

-(NSDictionary*)callbackParams
{
  return self.params;
}

-(void)createCallbackParams:(NSDictionary*)params
{
  NSMutableDictionary* p = [[params mutableCopy] autorelease];
  [p removeObjectForKey:@"type"];
  [p removeObjectForKey:@"title"];
  [p removeObjectForKey:@"button"];
  [p removeObjectForKey:@"titlelabel"];
  [p removeObjectForKey:@"titleplaceholder"];
  [p removeObjectForKey:@"placeholder"];
  [p removeObjectForKey:@"titlevalue"];
  [p removeObjectForKey:@"value"];
  [p removeObjectForKey:@"usePhoto"];
  [p removeObjectForKey:@"photoCount"];
  [p removeObjectForKey:@"callback"];
  self.params = p;
}

-(void)buildTextViews:(NSDictionary*)params
{
  CGRect screen = [[UIScreen mainScreen] bounds];

  UIView* titleView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 44)] autorelease];
  titleView.backgroundColor = [UIColor clearColor];
  titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  titleView.layer.borderColor = [[UIColor whiteColor] CGColor];
  titleView.layer.borderWidth = 1.0f;

  self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(kMargin, 0, 0, 0)] autorelease];
  NSString* titleLabelValue = [params valueForKey:@"titlelabel"];
  titleLabelValue = titleLabelValue ? titleLabelValue : @"Title";
  self.titleLabel.text = [NSString stringWithFormat:@"%@ : ", titleLabelValue];
  self.titleLabel.font = [UIFont systemFontOfSize:16.0f];
  self.titleLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                              green:0x88 / 255.0f
                                               blue:0x88 / 255.0f
                                              alpha:1.0f];
  self.titleLabel.backgroundColor = [UIColor clearColor];
  [self.titleLabel sizeToFit];

  self.titleField =
    [[[UITextField alloc] initWithFrame:CGRectMake(self.titleLabel.frame.size.width + kMargin,
                                                   0,
                                                   titleView.frame.size.width - self.titleLabel.frame.size.width - (kMargin * 2),
                                                   32)] autorelease];
  NSString* titleValue = [params valueForKey:@"titlevalue"];
  self.titleField.text = titleValue ? titleValue : @"";
  self.titleField.textColor = [UIColor colorWithRed:0x44 / 255.0f
                                              green:0x44 / 255.0f
                                               blue:0x44 / 255.0f
                                              alpha:1.0f];
  self.titleField.font = [UIFont systemFontOfSize:16.0f];
  self.titleField.borderStyle = UITextBorderStyleNone;
  self.titleField.backgroundColor = [UIColor clearColor];
  self.titleField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.titleField.delegate = self;

  CGFloat topMargin = (titleView.frame.size.height - self.titleLabel.frame.size.height) / 2;
  self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x,
                                     topMargin,
                                     self.titleLabel.frame.size.width,
                                     self.titleLabel.frame.size.height);
  self.titleField.frame = CGRectMake(self.titleField.frame.origin.x,
                                     topMargin,
                                     self.titleField.frame.size.width,
                                     self.titleField.frame.size.height);

  [titleView addSubview:self.titleLabel];
  [titleView addSubview:self.titleField];

  self.textView = [[[UITextView alloc] initWithFrame:CGRectMake(0,
                                                                titleView.frame.origin.y + titleView.frame.size.height,
                                                                screen.size.width,
                                                                100)] autorelease];
  NSString* value = [params valueForKey:@"value"];
  self.textView.text = value ? value : @"";

  self.textView.editable = YES;
  self.textView.font = [UIFont systemFontOfSize:14.0f];
  self.textView.textColor = [UIColor colorWithRed:0x66 / 255.0f
                                            green:0x66 / 255.0f
                                             blue:0x66 / 255.0f
                                            alpha:1.0f];
  self.textView.backgroundColor = [UIColor clearColor];
  self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.textView.delegate = self;

  [self.view addSubview:titleView];
  [self.view addSubview:self.textView];

  //NSString *placeholder = [params valueForKey:@"placeholder"];
  //[self setPlaceholder:placeholder color:[UIColor lightGrayColor]];
}

-(void)buildToolbarViews:(NSDictionary*)params
{
  [super buildToolbarViews:params];
}

-(void)updateTextCounter
{
  self.toolbar.textCounterLabel.text = @"";
  self.toolbar.textLimitLabel.text = @"";
}

-(void)onUIKeyboardDidShowNotification:(NSNotification*)notification
{
//  [super onUIKeyboardDidShowNotification:notification];
  CGRect textFrame = self.textView.frame;
  self.textView.frame = CGRectMake(textFrame.origin.x, textFrame.origin.y,
                                   textFrame.size.width,
                                   textFrame.size.height - self.titleLabel.superview.frame.size.height);
}

#pragma mark - UITextFieldDelegate Methods

-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  [self validateEmpty];
  return YES;
}

#pragma mark - Internal Methods

-(BOOL)validateTitleField
{
  if (self.titleField.text.length <= 0) {
    return NO;
  }
  return YES;
}


@end
