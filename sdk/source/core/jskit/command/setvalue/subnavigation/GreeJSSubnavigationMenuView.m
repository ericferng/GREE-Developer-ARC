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


#import "GreeJSSubnavigationMenuView.h"
#import "GreeJSSubnavigationIconView.h"
#import "GreeJSIconPersistentCache.h"
#import "UIImage+GreeAdditions.h"
#import "AFNetworking.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeUtility.h"

static NSString* const kButtonNameKey         = @"name";
static NSString* const kButtonIconNormalKey   = @"iconNormal";
static NSString* const kButtonIconSelectedKey = @"iconHighlighted";

static NSString* condensedFont = nil;

@interface GreeJSSubnavigationMenuView ()
+(NSString*)nibNameByItem:(NSDictionary*)item highlighted:(BOOL)highlight;
-(void)resetIcons;
-(void)adjustIconsLabelFont;
-(float)fontSizeWithLimitWidth:(float)limitWidth text:(NSString*)text font:(NSString*)font;
-(NSString*)maxIconLabelWidthTextIfOverLimitWidth:(float)limitWidth;

@property (nonatomic, retain, readwrite) NSMutableArray* icons;
@property (nonatomic, retain) NSOperationQueue* queue;
@end

@implementation GreeJSSubnavigationMenuView

#pragma mark -
#pragma mark Object Lifecycle

/** Designated initializer. */
-(id)init
{
  self = [super init];
  if (self) {

    self.autoresizingMask =
      UIViewAutoresizingFlexibleHeight |
      UIViewAutoresizingFlexibleWidth |
      UIViewAutoresizingFlexibleBottomMargin;
    self.backgroundColor = [UIColor clearColor];

    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    self.queue.maxConcurrentOperationCount = 2;
    [self.queue setSuspended:NO];

    // Instantiate icons.
    self.icons = [NSMutableArray array];

    if (condensedFont == nil) {
      if (GreeDeviceOsVersionIsAtLeast(@"5.0.0")) {
        condensedFont = kSubnavigationIconLabelFontCondensed;
      } else {
        // iOS4 doesn't have HelveticaNeue-CondencedBold
        condensedFont = kSubnavigationIconLabelFont;
      }
    }
  }
  return self;
}
-(void)dealloc
{
  self.icons = nil;
  self.queue = nil;
  [super dealloc];
}


#pragma mark -
#pragma mark - Internal Methods

-(void)resetIcons
{
  for (UIView* icon in self.icons) {
    [icon removeFromSuperview];
  }
  [self.icons removeAllObjects];
}

+(NSString*)nibNameByItem:(NSDictionary*)item highlighted:(BOOL)highlight;
{
  NSString* urlString = (highlight) ? [item objectForKey:kButtonIconSelectedKey] : [item objectForKey:kButtonIconNormalKey];

  // Convert url to file name.
  // For example:
  // h ttp://sns-dev-DEVID.dev.gree-dev.net:3030/img/subnavi/btn_subnavi_mail_inbox_default@2x.png

  // -> [@"h ttp://sns-dev-DEVID.dev.gree-dev.net:3030", @"btn_subnavi_mail_inbox_default@2x.png"]
  NSArray* list = [urlString componentsSeparatedByString:@"/img/subnavi/"];

  if (list.count != 2) {
    return nil;
  }

  // -> btn_subnavi_mail_inbox_default@2x.png
  NSString* fileName = [list objectAtIndex:1];

  // -> btn_subnavi_mail_inbox_default.png
  fileName = [fileName stringByReplacingOccurrencesOfString:@"@2x" withString:@""];

  // -> gree_btn_subnavi_mail_inbox_default.png
  fileName = [@"gree_" stringByAppendingString:fileName];

  return fileName;
}


-(void)downloadImageURL:(NSURL*)url selected:(BOOL)selected forIcon:(GreeJSSubnavigationIconView*)icon
{
  NSURLRequest* request = [NSURLRequest requestWithURL:url];

  GreeAFHTTPRequestOperation* requestOperation = [[[GreeAFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
  [requestOperation setQueuePriority:(selected ? NSOperationQueuePriorityNormal : NSOperationQueuePriorityHigh)];
  [requestOperation setCompletionBlockWithSuccess:
   ^(GreeAFHTTPRequestOperation* operation, id responseObject) {
     NSData* data = [operation responseData];
     UIImage* image = [UIImage imageWithData:data];

     if (image) {
       [[GreeJSIconPersistentCache sharedImageCache]
        cacheImageData:data
                forURL:url
       ];
     }

     if (selected) {
       icon.selectedImage = image;
     } else {
       icon.normalImage = image;
     }
   }
                                          failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
     NSLog(@"icon download failed %@ %@", url, error);
   }
  ];
  [self.queue addOperation:requestOperation];
}

#pragma mark -
#pragma mark - Public Interface

-(BOOL)configureSubnavigationMenuWithParams:(NSDictionary*)params
{
  [self resetIcons];

  NSInteger index = 0;
  NSDictionary* iconConfigurations = [[params objectForKey:@"subNavigation"] objectForKey:@"subNavigation"];
  for (NSDictionary* item in iconConfigurations) {

    // icon key url
    NSURL* normalImageURL      = [NSURL URLWithString:[item objectForKey:kButtonIconNormalKey]];
    NSURL* selectedImageURL    = [NSURL URLWithString:[item objectForKey:kButtonIconSelectedKey]];

    // try to get cache image
    GreeJSIconPersistentCache* cache = [GreeJSIconPersistentCache sharedImageCache];
    UIImage* normalImage    = [cache cachedImageForURL:normalImageURL];
    UIImage* selectedImage  = [cache cachedImageForURL:selectedImageURL];

    // try to get bundle image
    if (normalImage == nil) {
      NSString* bundleIconName = [[self class] nibNameByItem:item highlighted:NO];
      normalImage = [UIImage greeImageNamed:bundleIconName];
    }
    if (selectedImage == nil) {
      NSString* bundleIconName = [[self class] nibNameByItem:item highlighted:YES];
      selectedImage = [UIImage greeImageNamed:bundleIconName];
    }

    GreeJSSubnavigationIconView* icon = [[[GreeJSSubnavigationIconView alloc] initWithNormalImage:normalImage
                                                                                    selectedImage:selectedImage
                                                                                           params:item
                                                                                         delegate:self.delegate] autorelease];
    icon.tag = index++;


    // try to download image
    if (normalImage == nil) {
      [self downloadImageURL:normalImageURL selected:NO forIcon:icon];
    }
    if (selectedImage == nil) {
      [self downloadImageURL:selectedImageURL selected:YES forIcon:icon];
    }

    // show temporal image
    if (normalImage == nil) {
      
    }
    if (selectedImage == nil) {
      
    }

    [self addSubview:icon];
    [self.icons addObject:icon];
  }

  return YES;
}

-(BOOL)visible
{
  return [self.icons count] > 0;
}


#pragma mark -
#pragma mark UIView Overrides

-(void)layoutSubviews
{
  self.backgroundColor = [UIColor colorWithPatternImage:[UIImage greeImageNamed:@"sub_navigation_portfolio_bg.png"]];

  // Parse JSON Data, determine number of buttons.
  NSUInteger numberOfButtons = [self.icons count];

  // layout icons
  float frameWidth = self.frame.size.width;
  float iconRectWidth = numberOfButtons < kSubnavigationIconPerPageLimit ?
                        frameWidth/numberOfButtons :
                        frameWidth/kSubnavigationIconPerPageLimit;

  int iconIndex = 0;
  float lastIconOriginX = 0;
  for (UIView* icon in self.icons) {
    float x = floor(iconIndex * iconRectWidth);
    float width = floor((iconIndex + 1) * iconRectWidth) - lastIconOriginX;
    CGRect iconRect = CGRectMake(x,
                                 self.frame.origin.y,
                                 width,
                                 self.frame.size.height);
    icon.frame = iconRect;
    [icon setNeedsLayout];

    lastIconOriginX += width;
    iconIndex++;
  }

  [self adjustIconsLabelFont];

  [self setNeedsDisplay];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

-(void)adjustIconsLabelFont
{
  if ([self.icons count] <= 0) {
    return;
  }

  float boundsWidth = ((UILabel*)[self.icons objectAtIndex:0]).bounds.size.width;

  if (boundsWidth <= 0) {
    return;
  }

  float limitWidth = boundsWidth - kSubnavigationIconLabelPadding;
  NSString* maxLabelWidthText = [self maxIconLabelWidthTextIfOverLimitWidth:limitWidth];

  if (maxLabelWidthText == nil) {
    return;
  }

  // Set new UIFont.
  float fontSize = [self fontSizeWithLimitWidth:limitWidth text:maxLabelWidthText font:condensedFont];
  UIFont* shrinkFont          = [UIFont fontWithName:kSubnavigationIconLabelFont size:fontSize];
  UIFont* shrinkFontCondensed = [UIFont fontWithName:condensedFont size:fontSize];
  for (GreeJSSubnavigationIconView* icon in self.icons) {
    UILabel* label = icon.label;
    if([label.text sizeWithFont:shrinkFont].width > limitWidth) {
      label.font = shrinkFontCondensed;
    } else {
      label.font = shrinkFont;
    }
  }
}

-(NSString*)maxIconLabelWidthTextIfOverLimitWidth:(float)limitWidth
{
  float maxWidth = 0;
  NSString* maxWidthText = nil;
  UIFont* const defaultFont = [UIFont fontWithName:kSubnavigationIconLabelFont
                                              size:kSubnavigationIconLabelFontSize];
  for (GreeJSSubnavigationIconView* icon in self.icons) {
    NSString* text = icon.label.text;
    CGSize size = [text sizeWithFont:defaultFont];
    float width = size.width;
    if (width > maxWidth) {
      maxWidthText = text;
      maxWidth = width;
    }
  }


  if (maxWidth > limitWidth) {
    return maxWidthText;
  } else {
    return nil;
  }
}

-(float)fontSizeWithLimitWidth:(float)limitWidth text:(NSString*)text font:(NSString*)fontName
{
  const float fontSizeShrinkStep = 0.25f;
  float width = INFINITY;
  float fontSize = kSubnavigationIconLabelFontSize;
  for (; fontSize > kSubnavigationIconLabelFontSizeMinimum && width > limitWidth; fontSize -= fontSizeShrinkStep) {
    UIFont* font = [UIFont fontWithName:fontName size:fontSize];
    CGSize size = [text sizeWithFont:font];
    width = size.width;
  }
  return fontSize;
}


@end
