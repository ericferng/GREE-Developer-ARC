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

#import <UIKit/UIKit.h>
#import "GreePhoneNumberBasedUserInfo.h"
#import "GreePhoneNumberBasedParts.h"

extern NSString* const kGreeDatePickerCell;
extern NSString* const kGreeNormalCell;
extern NSString* const kGreeHelveticaNeue;
extern NSString* const kGreeHelveticaNeueBold;

typedef enum {
  GreePhoneNumberBasedFontNoticeLabel,
  GreePhoneNumberBasedFontFormLabel,
  GreePhoneNumberBasedFontNavigationLabel,
  GreePhoneNumberBasedFontTextFieldPlaceholder,
  GreePhoneNumberBasedFontCellLabel
} GreePhoneNumberBasedFont;

typedef enum {
  GreePhoneNumberBasedColorBackground,          //#f2f4f9 R242 G244 B249
  GreePhoneNumberBasedColorDefault,             //#5b5e61 R91  G94  B97
  GreePhoneNumberBasedColorLink,                //#1ac0ff R26  G192 B255
  GreePhoneNumberBasedColorFormPlaceholder,     //        R171 G171 B185
  GreePhoneNumberBasedColorNotFilledBackground, //#e9f9ff R233 G249 B255
  GreePhoneNumberBasedColorErrorBackground,     //#fde6e6 R253 G230 B230
  GreePhoneNumberBasedColorErrorFont,           //#E60000 R230 G0   B0
  GreePhoneNumberBasedColorBlueButtonFont,      //#ffffff R255 G255 B255
  GreePhoneNumberBasedColorNormalCellBackground, //#ffffff R255 G255 B255
  GreePhoneNumberBasedColorTitleText,           //#ffffff R255 G255 B255
  GreePhoneNumberBasedColorWhiteButtonFont,     //#5b5e61 R91  G94  B97
  GreePhoneNumberBasedColorButtonShadow,        //#5b6775 R91  G103 B117 A0.15
  GreePhoneNumberBasedColorTableOutline,        //        R214 G214 B214
  GreePhoneNumberBasedColorTitleShadow,         //        R77  G181 B230
  GreePhoneNumberBasedColorLabelFont,           //        R76  G86  B108
  GreePhoneNumberBasedColorFormInput,           //black
  GreePhoneNumberBasedColorGrayButtonFont,      //        R76  G86  B108
  GreePhoneNumberBasedColorGrayButtonShadow     //white
} GreePhoneNumberBasedColor;



@interface GreePhoneNumberBasedPage : UIViewController
@property (nonatomic, retain) NSDictionary* cellInformation;
@property (nonatomic, retain) NSDictionary* thisPageCellInformation;

@property (nonatomic, retain) GreePhoneNumberBasedUserInfo* userInfo;
@property (nonatomic, retain) NSMutableArray* filledCells;

@property (retain, nonatomic) IBOutlet UIDatePicker* datePicker;
@property (retain, nonatomic) IBOutlet UITableView* tableView;
@property (retain, nonatomic) IBOutlet UIScrollView* scrollView;

@property (retain, nonatomic) IBOutlet UIImageView* noticeBackgroundImage;
@property (retain, nonatomic) IBOutlet UILabel* noticeLabel;
@property (retain, nonatomic) IBOutlet UILabel* noticeLabel2;
@property (retain, nonatomic) UILabel* alertLabel;

@property (nonatomic, retain) NSIndexPath* countryIndex;
@property (nonatomic, retain) UITableViewCell* countryCell;

@property (retain, nonatomic) IBOutlet GreeUITextField* nicknameTextField;
@property (retain, nonatomic) IBOutlet GreeUITextField* phoneNumberTextField;
@property (retain, nonatomic) IBOutlet GreeUITextField* pincodeTextField;
@property (retain, nonatomic) IBOutlet UILabel* birthdayField;

@property (retain, nonatomic) IBOutlet UILabel* nicknameLabel;
@property (retain, nonatomic) IBOutlet UILabel* birthdayLabel;
@property (retain, nonatomic) IBOutlet UILabel* countryLabel;
@property (retain, nonatomic) IBOutlet UILabel* phoneNumberLabel;
@property (retain, nonatomic) IBOutlet UILabel* pincodeLabel;

-(id)initWithUserInfo:(GreePhoneNumberBasedUserInfo*)userInfo;
-(void)dismiss;
-(void)showLoadingView;
-(void)dismissLoadingView;
-(void)handleError:(NSError*)anError;
-(void)showAlert:(NSString*)anError title:(NSString*)aTitle;
-(NSString*)countryLabelText;
-(NSDictionary*)checkBeforeSubmitWithTargets:(NSArray*)targets;
-(NSDictionary*)validateWithTargets:(NSArray*)targets;
-(void)doAfterSubmit;
-(void)selectDefaultCountry;
-(void)didChangeFieldValue:(id)sender;
-(void)attachKeyImageWithLabel:(UILabel*)aLabel;
-(void)attachKeyImageWithLabel2:(UILabel*)aLabel;
-(void)resizeNoticeImageView:(UIImageView*)anImageView height:(CGFloat)aHeight;
-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;

+(void)fitLabel:(UILabel*)aLabel font:(UIFont*)aFont;
+(void)switchButton:(UIButton*)aButton enable:(BOOL)anEnable;
+(UIView*)decorateBlueButton:(UIButton*)aButton labelText:(NSString*)alabelText;
+(UIView*)decorateWhiteButton:(UIButton*)aButton labelText:(NSString*)alabelText fontSize:(int)aFontSize;
+(UIView*)decorateButton:(UIButton*)aButton text:(NSString*)aText fontSize:(int)aFontSize fontColor:(UIColor*)aFontColor shadowColor:(UIColor*)aShadowColor defaultImage:(UIImage*)aDefaultImage touchedImage:(UIImage*)aTouchedImage;
+(UIButton*)decorateButton:(UIButton*)aButton defaultImage:(UIImage*)aDefaultImage touchedImage:(UIImage*)aTouchedImage;
+(UIImage*)convertResizableImage:(UIImage*)anImage;
+(UIFont*)fontWithType:(GreePhoneNumberBasedFont)aType;
+(UIColor*)colorWithType:(GreePhoneNumberBasedColor)aType;
@end

