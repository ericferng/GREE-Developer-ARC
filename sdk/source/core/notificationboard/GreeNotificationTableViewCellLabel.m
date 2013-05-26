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

#import "GreeNotificationTableViewCellLabel.h"
#import "GreePlatform+Internal.h"

static CGFloat const kLineMaxSpacing = 0.0;
static CGFloat const kLineMinSpacing = 0.0;
static CGFloat const kParagraphHeight = 0.0;
static NSString* const kBorderVersion = @"4.3.2";

@interface GreeNotificationTableViewCellLabel ()
@property (retain, nonatomic) NSMutableAttributedString* attrStr;
@property (retain, nonatomic) NSMutableArray* fonts;
@property (retain, nonatomic) NSMutableArray* colors;
@property (retain, nonatomic) NSMutableArray* ranges;
@property (assign, readwrite, nonatomic) CGFloat leading;
-(void)addStringWithAttribute:(NSString*)text font:(UIFont*)font color:(UIColor*)color;
-(CTFrameRef)createCTFrame:(CGRect)rect;
@end

@implementation GreeNotificationTableViewCellLabel

#pragma mark - Object Lifecycle

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }
  self.ranges = [NSMutableArray array];
  self.fonts = [NSMutableArray array];
  self.colors = [NSMutableArray array];

  self.text = @"";
  self.highlightedTextColor = [UIColor whiteColor];
  self.leading = 4;
  return self;
}

-(id)initWithFrame:(CGRect)frame leading:(CGFloat)leading
{
  self = [self initWithFrame:frame];
  self.leading = leading;
  return self;
}

-(void)dealloc
{
  self.attrStr = nil;
  self.ranges = nil;
  self.fonts = nil;
  self.colors = nil;

  [super dealloc];
}

#pragma mark - NSObject Overrides

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

#pragma mark - Public Interface

-(void)addStringWithAttribute:(NSString*)text font:(UIFont*)font color:(UIColor*)color
{
  NSRange range = NSMakeRange(self.text.length, text.length);

  if (!font) {
    font = self.font;
  }

  if (!color) {
    color = self.textColor;
  }

  [self.ranges addObject:[NSValue valueWithRange:range]];
  [self.fonts addObject:font];
  [self.colors addObject:color];

  self.text = [self.text stringByAppendingString:text];
}

-(CGFloat)multiFontHeight:(CGFloat)width
{
  CGFloat height = 0;
  CGRect rect = CGRectMake(0, 0, width, 1000);
  CTFrameRef ctFrame = [self createCTFrame:rect];

  CFArrayRef lines;
  lines = CTFrameGetLines(ctFrame);

  if ([[[UIDevice currentDevice] systemVersion] compare:kBorderVersion options:NSNumericSearch] == NSOrderedAscending) {
    CGPoint* origins;
    origins = malloc(sizeof(CGPoint) * CFArrayGetCount(lines));
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, CFArrayGetCount(lines)), origins);
    CTLineRef line;
    int lastLineIndex = CFArrayGetCount(lines) -1;

    if(lastLineIndex >= 0) {
      line = CFArrayGetValueAtIndex(lines, CFArrayGetCount(lines) -1);

      CGPoint originFirst = origins[0];
      CGPoint originLast = origins[lastLineIndex];
      CGFloat ascent;
      CGFloat descent;
      CGFloat leading;
      CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
      CGFloat adjust = 1.0f;
      height = (rect.size.height - originLast.y) + ascent + descent + adjust;
      height -= (rect.size.height - originFirst.y);
    }
    if (origins) {
      free(origins);
      origins = NULL;
    }

  } else {
    int lineCount = CFArrayGetCount(lines);
    for (int i = 0; i < lineCount; i++) {
      CTLineRef line = CFArrayGetValueAtIndex(lines, i);

      CGFloat ascent;
      CGFloat descent;
      CGFloat leading;
      CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

      height += ascent + descent;
      if (i != 0 && (descent < self.leading)) {
        height += (self.leading - descent);
      }
    }
  }

  if (ctFrame) {
    CFRelease(ctFrame);
    ctFrame = NULL;
  }

  return height;
}

-(void)refreshText
{
  self.text = @"";
  self.ranges = [NSMutableArray array];
  self.fonts = [NSMutableArray array];
  self.colors = [NSMutableArray array];
}

#pragma mark - Internal Methods

-(CTFrameRef)createCTFrame:(CGRect)rect
{
  self.attrStr = [[[NSMutableAttributedString alloc] initWithString:self.text] autorelease];

  CTFrameRef ctFrame;
  int length;
  length = [self.attrStr length];

  for(int i = 0; i < [self.ranges count]; i++) {
    NSValue* value = (NSValue*)[self.ranges objectAtIndex:i];
    NSRange range =  [value rangeValue];

    if (NSMaxRange(range) <= length) {
      UIFont* font = (UIFont*)[self.fonts objectAtIndex:i];
      CTFontRef ctFont = CTFontCreateWithName(
        (CFStringRef)font.fontName,
        font.pointSize,
        NULL);
      [self.attrStr
       addAttribute:(NSString*)kCTFontAttributeName
              value:(id)ctFont
              range:range];
      CFRelease(ctFont);
      UIColor* bodyForegroundColor;
      if (self.highlighted) {
        bodyForegroundColor = self.highlightedTextColor;
      } else {
        UIColor* color = (UIColor*)[self.colors objectAtIndex:i];
        bodyForegroundColor = color;
      }

      [self.attrStr
       addAttribute:(NSString*)kCTForegroundColorAttributeName
              value:(id)bodyForegroundColor.CGColor
              range:range];

      CGFloat maxLineHeight = font.pointSize;
      CGFloat minLineHeight = font.pointSize;

      CTLineBreakMode lbm = kCTLineBreakByCharWrapping;
      CTParagraphStyleSetting settings[6];

      settings[0].spec = kCTParagraphStyleSpecifierLineBreakMode;
      settings[0].valueSize = sizeof(CTLineBreakMode);
      settings[0].value = &lbm;
      settings[1].spec = kCTParagraphStyleSpecifierMaximumLineSpacing;
      settings[1].valueSize = sizeof(CGFloat);
      settings[1].value = &kLineMaxSpacing;
      settings[2].spec = kCTParagraphStyleSpecifierMinimumLineSpacing;
      settings[2].valueSize = sizeof(CGFloat);
      settings[2].value = &kLineMinSpacing;
      settings[3].spec = kCTParagraphStyleSpecifierMaximumLineHeight;
      settings[3].valueSize = sizeof(CGFloat);
      settings[3].value = &maxLineHeight;
      settings[4].spec = kCTParagraphStyleSpecifierMinimumLineHeight;
      settings[4].valueSize = sizeof(CGFloat);
      settings[4].value = &minLineHeight;
      settings[5].spec = kCTParagraphStyleSpecifierParagraphSpacing;
      settings[5].valueSize = sizeof(CGFloat);
      settings[5].value = &kParagraphHeight;

      CTParagraphStyleRef param = CTParagraphStyleCreate(settings, 6);

      [self.attrStr
       addAttribute:(id)kCTParagraphStyleAttributeName
              value:(id)param
              range:range];

      CFRelease(param);
    }
  }

  CGMutablePathRef path;
  CTFramesetterRef framesetter;
  path = CGPathCreateMutable();
  CGPathAddRect(path, NULL, rect);
  framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)self.attrStr);
  ctFrame = CTFramesetterCreateFrame(
    framesetter,
    CFRangeMake(0, length),
    path,
    NULL);

  CGPathRelease(path);
  CFRelease(framesetter);

  return ctFrame;
}


-(void)drawRect:(CGRect)rect
{
  CTFrameRef ctFrame = [self createCTFrame:rect];
  CGContextRef context;
  context = UIGraphicsGetCurrentContext();

  CGRect bounds;
  bounds = self.bounds;
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, 0, CGRectGetHeight(bounds));
  CGContextScaleCTM(context, 1.0f, -1.0f);
  CFArrayRef lines;
  lines = CTFrameGetLines(ctFrame);

  int lineCount = CFArrayGetCount(lines);
  CGPoint currentPosition = CGPointMake(bounds.origin.x, bounds.size.height);

  CGFloat preDescent = 0;
  CGFloat preLeading = 0;
  for (int i = 0; i < lineCount; i++) {
    CTLineRef line = CFArrayGetValueAtIndex(lines, i);
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    currentPosition.y -= (ascent);

    if ([[[UIDevice currentDevice] systemVersion] compare:kBorderVersion options:NSNumericSearch] == NSOrderedAscending) {
      if (i != 0) {
        if (preDescent < preLeading) {
          currentPosition.y -= preLeading;
        } else {
          currentPosition.y -= preDescent;
        }
      }
    } else {
      if (i != 0) {
        if (preDescent < self.leading) {
          currentPosition.y -= self.leading;
        } else {
          currentPosition.y -= preDescent;
        }
      }
    }
    CGContextSetTextPosition(context, bounds.origin.x, currentPosition.y);
    CTLineDraw(line, context);
    preDescent = descent;
    preLeading = leading;
  }

  CGContextRestoreGState(context);

  if (ctFrame) {
    CFRelease(ctFrame);
    ctFrame = NULL;
  }
}

@end
