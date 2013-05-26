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
#import "GreePhoneNumberBasedPage.h"
#import "NSBundle+GreeAdditions.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreePhoneNumberBasedSelectCountryView.h"
#import "GreePhoneNumberBasedUpgradeView.h"
#import "UIImage+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreePhoneNumberBasedNoticeView.h"
#import "GreeCountryCodes.h"


NSString* const kGreeDatePickerCell      = @"datePicker";
NSString* const kGreeNormalCell          = @"normal";
NSString* const kGreeKeyboardNormal      = @"normal";
NSString* const kGreeHelveticaNeue       = @"HelveticaNeue";
NSString* const kGreeHelveticaNeueBold   = @"HelveticaNeue-Bold";

static int const kScrollNeedScreenSize      = 600;
static int const kNoticeImageSizeAdjustment = 33;

@interface GreePhoneNumberBasedPage ()<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) GreeJSLoadingIndicatorView* loadingView;
@property (nonatomic) BOOL resetScrollTextFieldEndEditing;
-(NSDate*)defaultDate;
-(NSDate*)minimumDate;
-(NSDate*)maximumDate;
-(BOOL)dismissUserInputBoard;
-(void)onBackButtonPressed;
-(void)clearTextFieldWithErrors:(NSArray*)errors;
-(void)showDatePickerWithSender:(id)sender;
-(BOOL)isDatePickerDismissed;
-(void)dismissDatePicker;
-(void)scrollWithScrollSize:(CGFloat)aSize;
-(void)resetScroll;
-(void)resetScrollWithPoint:(CGPoint)aPoint;
@end

@implementation GreePhoneNumberBasedPage

#pragma mark - Object Lifecycle

-(void)dealloc
{

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (self.datePicker.superview) {
    [self.datePicker removeFromSuperview];
  }

  self.userInfo = nil;
  self.filledCells = nil;
  self.cellInformation = nil;
  self.thisPageCellInformation = nil;

  self.datePicker = nil;
  self.tableView = nil;
  self.scrollView = nil;
  self.noticeBackgroundImage = nil;
  self.noticeLabel = nil;
  self.alertLabel = nil;

  self.countryIndex = nil;
  self.countryCell = nil;
  self.countryLabel = nil;
  self.loadingView = nil;

  self.phoneNumberTextField = nil;
  self.pincodeTextField = nil;
  self.nicknameTextField = nil;
  self.nicknameLabel = nil;
  self.birthdayLabel = nil;
  self.phoneNumberLabel = nil;
  self.pincodeLabel = nil;
  self.birthdayField = nil;
  self.noticeLabel2 = nil;

  [super dealloc];
}

-(id)initWithUserInfo:(GreePhoneNumberBasedUserInfo*)userInfo
{
  self = [super initWithNibName:nil bundle:[NSBundle greePlatformCoreBundle]];
  if (self) {
    if (userInfo) {
      self.userInfo = userInfo;
    } else {
      self.userInfo = [[[GreePhoneNumberBasedUserInfo alloc] init] autorelease];
    }

    self.filledCells = [NSMutableArray array];
    self.loadingView = [[[GreeJSLoadingIndicatorView alloc]
                         initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];

    self.cellInformation = @{kGreeCountryCodeKey : @[kGreeCountryCodeKey, GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.country"), @"", kGreeNormalCell, kGreeKeyboardNormal]};
  }
  return self;
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  CGFloat buttonHeight = self.navigationController.navigationBar.frame.size.height - 14;
  UIButton* button = [GreePhoneNumberBasedPage decorateButton:[[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, buttonHeight)] autorelease]
                                                 defaultImage:[UIImage greeImageNamed:@"gree.navBar.btn.portrait.default.png"]
                                                 touchedImage:[UIImage greeImageNamed:@"gree.navBar.btn.portrait.highlighted.png"]];
  UIImageView* backArrow = [[[UIImageView alloc] initWithImage:
                             [UIImage greeImageNamed:@"gree.navBar.btn.back_icon.png"]] autorelease];
  backArrow.center = button.center;
  [button addSubview:backArrow];
  [button addTarget:self action:@selector(onBackButtonPressed)forControlEvents:UIControlEventTouchUpInside];
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
  self.navigationItem.hidesBackButton   = YES;

  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage greeImageNamed:@"gree.default.background.png"]];

  [self.tableView reloadData];

  self.tableView.backgroundView   = nil;
  self.tableView.backgroundView   = [[[UIView alloc] init] autorelease];
  self.tableView.backgroundColor  = [UIColor clearColor];

  self.tableView.layer.cornerRadius  = 15;
  self.tableView.separatorColor  = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorTableOutline];

  self.datePicker.datePickerMode = UIDatePickerModeDate;
  self.datePicker.date        = [self defaultDate];
  self.datePicker.minimumDate = [self minimumDate];
  self.datePicker.maximumDate = [self maximumDate];

  self.nicknameTextField.myPlaceholder.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.nickname");
  self.phoneNumberTextField.myPlaceholder.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.phoneNumber");
  self.pincodeTextField.myPlaceholder.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.pincode");
  self.birthdayField.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.birthday");
  self.nicknameLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.nickname");
  self.birthdayLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.birthday");
  self.countryLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.country");
  self.phoneNumberLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.phoneNumber");
  self.pincodeLabel.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.pincode");

  if ([self respondsToSelector:@selector(didChangeFieldValue:)]) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFieldValue:)name:UITextFieldTextDidChangeNotification object:self.nicknameTextField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFieldValue:)name:UITextFieldTextDidChangeNotification object:self.phoneNumberTextField];
  }

#if DEBUG
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"close(dev)" style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)] autorelease] animated:NO];
#endif
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Public Interface

-(void)dismiss
{
  [self greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)showLoadingView
{
  if (!self.loadingView.superview) {
    self.navigationController.view.userInteractionEnabled = NO;
    self.view.userInteractionEnabled = NO;
    self.loadingView.center = self.view.center;
    [self.view addSubview:self.loadingView];
  }
}

-(void)dismissLoadingView
{
  if (self.loadingView.superview) {
    self.navigationController.view.userInteractionEnabled = YES;
    self.view.userInteractionEnabled = YES;
    [self.loadingView removeFromSuperview];
  }
}

-(void)handleError:(NSError*)anError
{
  [self dismissLoadingView];

  NSString* domain = [anError domain];

  if (![domain isEqualToString:@"net.gree.error"]) {
    [self showAlert:[anError localizedDescription] title:nil];
    return;
  }

  int greeErrorCode           = [[anError userInfo][@"code"] intValue];
  NSString* greeMessage       = [anError userInfo][@"message"];
  NSArray*  greeInvalidFields = [anError userInfo][@"invalid_fields"];

  if (greeErrorCode == 3201) {
    GreePhoneNumberBasedNoticeView* notice = [[[GreePhoneNumberBasedNoticeView alloc] initWithUserInfo:self.userInfo] autorelease];
    [self.navigationController pushViewController:notice animated:YES];
    return;
  }


  if (greeErrorCode  == 3002) {
    NSMutableArray* errs = [NSMutableArray array];
    for (NSString* invalid in greeInvalidFields) {
      if ([invalid isEqualToString:@"birth"]) {
        [errs addObject:kGreeBirthdayKey];
      }
      if ([invalid isEqualToString:@"nick_name"]) {
        [errs addObject:kGreeNicknameKey];
      }
    }
    [self clearTextFieldWithErrors:[NSArray arrayWithArray:errs]];
  }

  if (greeErrorCode == 3003 || greeErrorCode == 3004) {
    [self clearTextFieldWithErrors:@[kGreePhoneNumberKey]];
  }

  if (greeErrorCode >= 3101 && greeErrorCode <= 3108) {
    [self clearTextFieldWithErrors:@[kGreePincodeKey]];
  }

  if ([greeMessage isEqualToString:GreePlatformStringWithKey(@"errorHandling.genericNetwork.message")]) {
    greeMessage = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.networkError");
  }

  [self showAlert:(greeMessage ? greeMessage : [anError localizedDescription]) title:nil];
}

-(void)showAlert:(NSString*)anError title:(NSString*)aTitle
{
  [[[[UIAlertView alloc] initWithTitle:(aTitle ? aTitle : GreePlatformStringWithKey(@"phoneNumberBasedRegistration.alert.title"))
                               message:anError
                              delegate:nil
                     cancelButtonTitle:GreePlatformStringWithKey(@"phoneNumberBasedRegistration.alert.close")
                     otherButtonTitles:nil, nil] autorelease] show];
}

-(NSDictionary*)checkBeforeSubmitWithTargets:(NSArray*)targets
{

  NSDictionary* validationErrors = [self validateWithTargets:targets];
  if (validationErrors) {
    [self clearTextFieldWithErrors:[validationErrors allKeys]];
    [self showAlert:[[validationErrors allValues] componentsJoinedByString:@"\n"] title:nil];
    return validationErrors;
  }

  [self dismissUserInputBoard];
  return nil;
}

-(NSDictionary*)validateWithTargets:(NSArray*)targets
{
  NSDictionary* dic = [self.userInfo validate];

  BOOL validateFlag = YES;
  NSMutableDictionary* mutableDic = [NSMutableDictionary dictionary];

  for (NSString* target in targets) {
    NSString* targetErrMsg = [dic objectForKey:target];
    if (targetErrMsg) {
      validateFlag = NO;
      [mutableDic setObject:targetErrMsg forKey:target];
    }
  }

  return (validateFlag) ? nil : [NSDictionary dictionaryWithDictionary:mutableDic];
}


-(void)doAfterSubmit
{
  [self dismissLoadingView];
}

-(void)selectDefaultCountry
{
  [GreeCountryCodes getCurrentCountryCodeWithBlock:^(NSString* countryCode){
     self.userInfo.countryCode = countryCode;
     UITableViewCell* countryCell = [self.tableView cellForRowAtIndexPath:self.countryIndex];
     countryCell.textLabel.text =  [self countryLabelText];
     countryCell.textLabel.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormInput];

     [self.tableView reloadData];
   }];
}

-(void)didChangeFieldValue:(id)sender
{
  //implement by child class (optional)
}

-(void)attachKeyImageWithLabel:(UILabel*)aLabel
{
  CGSize labelSize = [aLabel.text sizeWithFont:[GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontFormLabel]];
  UIImageView* keyImageView = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"gree.regi.icon.lock.png"]] autorelease];
  keyImageView.frame = CGRectMake(labelSize.width + 5, 1, 12, 16);
  [aLabel addSubview:keyImageView];
}

-(void)attachKeyImageWithLabel2:(UILabel*)aLabel
{
  UIImageView* keyImageView = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"gree.regi.icon.lock.png"]] autorelease];
  keyImageView.frame = CGRectMake(-16, 1, 12, 16);
  [aLabel addSubview:keyImageView];
}

+(void)fitLabel:(UILabel*)aLabel font:(UIFont*)aFont
{
  CGSize size = [aLabel.text sizeWithFont:aFont
                        constrainedToSize:CGSizeMake(aLabel.frame.size.width, 200)
                            lineBreakMode:UILineBreakModeWordWrap];
  aLabel.frame = CGRectMake(aLabel.frame.origin.x, aLabel.frame.origin.y,
                            aLabel.frame.size.width, size.height);
}

+(void)switchButton:(UIButton*)aButton enable:(BOOL)anEnable
{
  aButton.userInteractionEnabled = anEnable;
  aButton.alpha = (anEnable) ? 1 : 0.5;
}

#pragma mark decorate & resize

+(UIView*)decorateBlueButton:(UIButton*)aButton labelText:(NSString*)alabelText
{
  return [GreePhoneNumberBasedPage decorateButton:aButton
                                             text:alabelText
                                         fontSize:16
                                        fontColor:[UIColor whiteColor]
                                      shadowColor:[GreePhoneNumberBasedPage
                       colorWithType:GreePhoneNumberBasedColorButtonShadow]
                                     defaultImage:[UIImage greeImageNamed:@"gree.regi.btn.blue.png"]
                                     touchedImage:[UIImage greeImageNamed:@"gree.regi.btn.blue.tapped.png"]];
}

+(UIView*)decorateWhiteButton:(UIButton*)aButton labelText:(NSString*)alabelText fontSize:(int)aFontSize
{
  return [GreePhoneNumberBasedPage decorateButton:aButton
                                             text:alabelText
                                         fontSize:aFontSize
                                        fontColor:[GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorLabelFont]
                                      shadowColor:nil defaultImage:[UIImage greeImageNamed:@"gree.regi.btn.white.png"]
                                     touchedImage:[UIImage greeImageNamed:@"gree.regi.btn.white.tapped.png"]];
}

+(UIView*)decorateButton:(UIButton*)aButton text:(NSString*)aText fontSize:(int)aFontSize fontColor:(UIColor*)aFontColor shadowColor:(UIColor*)aShadowColor defaultImage:(UIImage*)aDefaultImage touchedImage:(UIImage*)aTouchedImage
{
  aButton = [self decorateButton:aButton defaultImage:aDefaultImage touchedImage:aTouchedImage];
  aButton.titleLabel.font = [UIFont fontWithName:kGreeHelveticaNeueBold size:aFontSize];
  [aButton setTitle:aText forState:UIControlStateNormal];
  [aButton setTitleColor:aFontColor forState:UIControlStateNormal];
  [aButton setTitleColor:aFontColor forState:UIControlStateHighlighted];
  [aButton.titleLabel sizeToFit];
  aButton.clipsToBounds = YES;

  if (aShadowColor) {
    aButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [aButton setTitleShadowColor:aShadowColor forState:UIControlStateNormal];
    [aButton setTitleShadowColor:aShadowColor forState:UIControlStateHighlighted];
  }

  return aButton;
}

+(UIButton*)decorateButton:(UIButton*)aButton defaultImage:(UIImage*)aDefaultImage touchedImage:(UIImage*)aTouchedImage
{
  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    [aButton setBackgroundImage:[GreePhoneNumberBasedPage convertResizableImage:aDefaultImage] forState:UIControlStateNormal];
    [aButton setBackgroundImage:[GreePhoneNumberBasedPage convertResizableImage:aTouchedImage] forState:UIControlStateHighlighted];
  } else {
    UIImageView* backgroundView = [[[UIImageView alloc] initWithImage:[GreePhoneNumberBasedPage convertResizableImage:aDefaultImage]] autorelease];
    backgroundView.frame = CGRectMake(0, 0, aButton.bounds.size.width, aButton.bounds.size.height);
    backgroundView.layer.zPosition = -1;
    [aButton insertSubview:backgroundView atIndex:0];
  }
  return aButton;
}

-(void)resizeNoticeImageView:(UIImageView*)anImageView height:(CGFloat)aHeight
{
  UIImage* noticeImage = [UIImage greeImageNamed:@"gree.notice.module.png"];
  UIImage* resizableImage = [GreePhoneNumberBasedPage convertResizableImage:noticeImage];
  UIImageView* resultImageView = [[[UIImageView alloc] initWithImage:resizableImage] autorelease];
  resultImageView.frame = CGRectMake(anImageView.frame.origin.x, anImageView.frame.origin.y, anImageView.frame.size.width, aHeight + kNoticeImageSizeAdjustment);
  resultImageView.layer.zPosition = -1;

  [anImageView.superview addSubview:resultImageView];

  if (anImageView.superview) {
    [anImageView removeFromSuperview];
  }
}

+(UIImage*)convertResizableImage:(UIImage*)anImage
{
  CGFloat h = anImage.size.height/2 - 1;
  CGFloat w = anImage.size.width/2 - 1;

  return [anImage respondsToSelector:@selector(resizableImageWithCapInsets:)] ?
         [anImage resizableImageWithCapInsets:UIEdgeInsetsMake(h, w, h, w)]
         : [anImage stretchableImageWithLeftCapWidth:(NSInteger)w topCapHeight:(NSInteger)h];
}

#pragma mark typeInfo

+(UIFont*)fontWithType:(GreePhoneNumberBasedFont)aType
{
  switch (aType) {
  case GreePhoneNumberBasedFontNoticeLabel :
    return [UIFont fontWithName:kGreeHelveticaNeue size:15];

  case GreePhoneNumberBasedFontFormLabel :
    return [UIFont fontWithName:kGreeHelveticaNeueBold size:14];

  case GreePhoneNumberBasedFontNavigationLabel:
    return [UIFont fontWithName:kGreeHelveticaNeueBold size:18];

  case GreePhoneNumberBasedFontTextFieldPlaceholder:
    return [UIFont fontWithName:kGreeHelveticaNeue size:16];

  case GreePhoneNumberBasedFontCellLabel:
    return [UIFont fontWithName:kGreeHelveticaNeue size:16];

  default:
    return nil;
  }
}

+(UIColor*)colorWithType:(GreePhoneNumberBasedColor)aType
{
  switch (aType) {
  case GreePhoneNumberBasedColorBackground:
    return [UIColor colorWithRed:242/255.0f green:244/255.0f blue:249/255.0f alpha:1];

  case GreePhoneNumberBasedColorDefault:
    return [UIColor colorWithRed:91/255.0f  green:94/255.0f  blue:97/255.0f  alpha:1];

  case GreePhoneNumberBasedColorLink:
    return [UIColor colorWithRed:26/255.0f  green:192/255.0f blue:255/255.0f alpha:1];

  case GreePhoneNumberBasedColorFormPlaceholder:
    return [UIColor colorWithRed:171/255.0f green:171/255.0f blue:185/255.0f alpha:1];

  case GreePhoneNumberBasedColorNotFilledBackground:
    return [UIColor colorWithRed:233/255.0f green:249/255.0f blue:255/255.0f alpha:1];

  case GreePhoneNumberBasedColorErrorBackground:
    return [UIColor colorWithRed:253/255.0f green:230/255.0f blue:230/255.0f alpha:1];

  case GreePhoneNumberBasedColorErrorFont:
    return [UIColor colorWithRed:230/255.0f green:0/255.0f   blue:0/255.0f   alpha:1];

  case GreePhoneNumberBasedColorBlueButtonFont:
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1];

  case GreePhoneNumberBasedColorWhiteButtonFont:
    return [UIColor colorWithRed:91/255.0f  green:94/255.0f  blue:97/255.0f  alpha:1];

  case GreePhoneNumberBasedColorButtonShadow:
    return [UIColor colorWithRed:91/255.0f  green:103/255.0f blue:117/255.0f alpha:0.15];

  case GreePhoneNumberBasedColorNormalCellBackground:
    return [UIColor whiteColor];

  case GreePhoneNumberBasedColorTitleText:
    return [UIColor whiteColor];

  case GreePhoneNumberBasedColorTableOutline:
    return [UIColor colorWithRed:214/255.0f green:214/255.0f blue:214/255.0f alpha:1];

  case GreePhoneNumberBasedColorTitleShadow:
    return [UIColor colorWithRed:77/255.0f  green:181/255.0f blue:230/255.0f alpha:1];

  case GreePhoneNumberBasedColorLabelFont:
    return [UIColor colorWithRed:76/255.0f  green:86/255.0f  blue:108/255.0f alpha:1];

  case GreePhoneNumberBasedColorFormInput:
    return [UIColor blackColor];

  case GreePhoneNumberBasedColorGrayButtonFont:
    return [UIColor colorWithRed:76/255.0f  green:86/255.0f  blue:108/255.0f alpha:1];

  case GreePhoneNumberBasedColorGrayButtonShadow:
    return [UIColor whiteColor];

  default:
    return nil;
  }
}

#pragma mark - Internal Methods

-(NSDate*)defaultDate
{
  return [[NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy-MM-dd"] dateFromString:@"1980-06-15"];
}

-(NSDate*)minimumDate
{
  return [[NSDateFormatter greeUTCDateFormatterWithFormat:@"yyyy-MM-dd"] dateFromString:@"1900-01-01"];
}

-(NSDate*)maximumDate
{
  return [NSDate date];
}

-(NSString*)countryLabelText
{
  return (self.userInfo.countryName.length > 0) ?
         [NSString stringWithFormat:@"%@ (%@)", self.userInfo.countryName, self.userInfo.countryPhoneNumber]
         : GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.country");
}

-(BOOL)dismissUserInputBoard
{
  [self dismissDatePicker];
  [self.view endEditing:YES];
  return NO;
}

-(void)onBackButtonPressed
{
  [self.navigationController popViewControllerAnimated:YES];
}

-(void)clearTextFieldWithErrors:(NSArray*)errors
{
  for (NSString* result in errors) {
    if ([result isEqualToString:kGreeNicknameKey]) {
      self.userInfo.nickname = @"";
      self.nicknameTextField.text = @"";
      [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.nicknameTextField];
    }
    if ([result isEqualToString:kGreePincodeKey]) {
      self.userInfo.pincode = @"";
      self.pincodeTextField.text = @"";
      [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.pincodeTextField];
    }
    if ([result isEqualToString:kGreeBirthdayKey]) {
      self.userInfo.birthday = @"";
      self.birthdayField.text = @"";
      [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.birthdayField];
    }
    if ([result isEqualToString:kGreePhoneNumberKey]) {
      self.userInfo.phoneNumber = @"";
      self.phoneNumberTextField.text = @"";
      [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.phoneNumberTextField];
    }
  }
}

#pragma mark datePicker

-(IBAction)touchBirthdayField:(id)sender
{
  self.resetScrollTextFieldEndEditing = NO;

  if (![[self.birthdayField.text substringWithRange:NSMakeRange(4, 1)] isEqualToString:@"/"]) {
    self.birthdayField.text = @"";
  }

  [self dismissUserInputBoard];
  [self showDatePickerWithSender:sender];
}

-(IBAction)changedDatePicker:(id)sender
{
  self.userInfo.birthdayDate = self.datePicker.date;
  self.birthdayField.text = [self.userInfo.birthday stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
  self.birthdayField.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormInput];
  [self didChangeFieldValue:self.birthdayField];
}

-(void)showDatePickerWithSender:(id)sender
{
  if (self.datePicker.superview) {
    return;
  }

  [self.view addSubview:self.datePicker];
  CGRect appFrame      = [UIScreen mainScreen].applicationFrame;
  CGSize pickerSize    = [self.datePicker sizeThatFits:CGSizeZero];

  CGRect closePosition = CGRectMake(appFrame.size.width/2 - pickerSize.width/2, appFrame.size.height, pickerSize.width, pickerSize.height);
  CGRect openPosition  = CGRectMake(appFrame.size.width/2 - pickerSize.width/2, appFrame.origin.y + appFrame.size.height - pickerSize.height,
                                    pickerSize.width, pickerSize.height);

  self.datePicker.frame = closePosition;
  [UIView animateWithDuration:0.3
                   animations:^{
     self.datePicker.frame = openPosition;
   }];

  CGFloat scrollSize = [sender convertPoint:((UIView*)sender).bounds.origin toView:self.view].y - 30;
  [self scrollWithScrollSize:scrollSize];
}

-(BOOL)isDatePickerDismissed
{
  return (self.datePicker.frame.origin.y == 0 ||
          self.datePicker.frame.origin.y >= [UIScreen mainScreen].applicationFrame.size.height);
}

-(void)dismissDatePicker
{
  if ([self isDatePickerDismissed]) {
    return;
  }

  if (self.birthdayField.text.length == 0) {
    self.birthdayField.text = GreePlatformStringWithKey(@"phoneNumberBasedRegistration.form.placeholder.birthday");
  }

  CGRect appFrame      = [UIScreen mainScreen].applicationFrame;
  CGSize pickerSize    = [self.datePicker sizeThatFits:CGSizeZero];
  CGRect closePosition = CGRectMake(appFrame.size.width/2 - pickerSize.width/2, appFrame.size.height,
                                    pickerSize.width, pickerSize.height);
  [UIView animateWithDuration:0.3
                   animations:^{
     self.datePicker.frame = closePosition;
   }
                   completion:^(BOOL finished) {
     [self.datePicker removeFromSuperview];
   }];

  [self resetScroll];
}

#pragma mark scroll

-(void)scrollWithScrollSize:(CGFloat)aSize
{
  if (self.scrollView.frame.size.height <= kScrollNeedScreenSize && aSize > 10) {
    CGFloat scrollSize = self.scrollView.contentOffset.y + aSize;
    [self.scrollView setContentOffset:CGPointMake(0, scrollSize) animated:YES];
  }
}

-(void)resetScroll
{
  [self resetScrollWithPoint:CGPointZero];
}

-(void)resetScrollWithPoint:(CGPoint)aPoint
{
  [self.scrollView setContentOffset:aPoint animated:YES];
}

#pragma mark - UIResponder Overrides

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self dismissUserInputBoard];
}

#pragma mark - UITextFieldDelegate Methods

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
  CGFloat scrollSize = [textField convertPoint:textField.bounds.origin toView:self.view].y - 35;
  [self scrollWithScrollSize:scrollSize];
  self.resetScrollTextFieldEndEditing = YES;

  return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
  if (self.resetScrollTextFieldEndEditing) {
    [self resetScroll];
  }

  return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [self dismissUserInputBoard];
  return YES;
}

#pragma mark - UITableViewDataSource Methods

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSArray* cellInfo = [self.thisPageCellInformation objectForKey:indexPath];
  NSString* cellKey         = [cellInfo objectAtIndex:0];

  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellKey];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellKey] autorelease];
    cell.backgroundColor = [UIColor whiteColor];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [GreePhoneNumberBasedPage fontWithType:GreePhoneNumberBasedFontCellLabel];
    cell.textLabel.textColor = [GreePhoneNumberBasedPage colorWithType:GreePhoneNumberBasedColorFormPlaceholder];
  }

  return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.thisPageCellInformation count];
}

#pragma mark - UITableViewDelegate Methods

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [self dismissUserInputBoard];
  NSArray* cellInfo = [self.thisPageCellInformation objectForKey:indexPath];
  NSString* cellType = [cellInfo objectAtIndex:3];

  if ([cellType isEqualToString:kGreeNormalCell]) {
    GreePhoneNumberBasedSelectCountryView* countrySelect = [[[GreePhoneNumberBasedSelectCountryView alloc] initWithUserInfo:self.userInfo] autorelease];
    [self.navigationController pushViewController:countrySelect animated:YES];
  } else if ([cellType isEqualToString:kGreeDatePickerCell]) {
    [self showDatePickerWithSender:[tableView cellForRowAtIndexPath:indexPath]];
  }
}


@end
