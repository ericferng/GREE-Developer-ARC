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
#import "GreeJSPhotoViewController.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeJSPhotoView.h"
#import "GreeJSLoadingIndicatorView.h"
#import "UIImage+GreeAdditions.h"
#import "GreeJSWebViewController.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"
#import "JSONKit.h"
#import "GreeSettings.h"
#import "GreeError.h"
#import "GreeSerializer.h"
#import "GreeSerializable.h"
#import "GreeGlobalization.h"
#import "GreeJSDownloadIndicatorView.h"
#import "NSString+GreeAdditions.h"


static NSString* const kParamUserIdKey       = @"user_id";
static NSString* const kParamMoodIdKey       = @"mood_id";
static NSString* const kParamAlbumIdKey      = @"album_id";
static NSString* const kParamPhotoIdKey      = @"photo_id";
static NSString* const kParamTotalNumKey     = @"sequence_count";
static NSString* const kParamCurrentIndexKey = @"sequence_index";
static NSString* const kParamEditable        = @"is_editable";
static NSString* const kParamApiTypeKey      = @"type";
static NSString* const kApiTypeMoodName      = @"mood";
static NSString* const kApiTypeAlbumName     = @"album";

static NSInteger const kMaxPhotoLimitCount   = 30;


@interface GreePhotoInfo ()
-(id)initWithGreeContent:(id<GreeContentDatasource>)content;
@property (nonatomic, assign) BOOL isLike;
@property (nonatomic, assign) NSInteger likeNum;
@property (nonatomic, retain) id<GreeContentDatasource> content;

@end

@implementation GreePhotoInfo

-(void)dealloc
{
  self.content = nil;
  [super dealloc];
}

-(id)initWithGreeContent:(id<GreeContentDatasource>)content
{
  if (!content) {
    return nil;
  }

  self = [super init];
  if (self) {
    self.isLike = [content isLikeUser];
    self.likeNum = [content likeNum];
    self.content = content;
  }
  return self;
}

@end

@interface GreeJSPhotoViewController ()
<GreeJSPhotoViewDelegate, UIActionSheetDelegate>
@property (nonatomic, retain) NSDictionary* params;
@property (nonatomic, assign) id<GreeJSPhotoViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, retain) NSString* serviceType;
@property (nonatomic, retain) GreeJSPhotoView* photoView;
@property (nonatomic, retain) NSMutableDictionary* photoInfos;
@property (nonatomic, retain) GreeJSLoadingIndicatorView* loadingIndicator;
@property (nonatomic, retain) UIButton* likeNumButton;
@property (nonatomic, retain) UIImageView* likeImageView;
@property (nonatomic, retain) UILabel* likeNumLabel;
@property (nonatomic, retain) UIBarButtonItem* likeNumButtonItem;
@property (nonatomic, retain) UIButton* commentNumButton;
@property (nonatomic, retain) UIBarButtonItem* commentNumButtonItem;
@property (nonatomic, retain) UIImageView* commentImageView;
@property (nonatomic, retain) UILabel* commentNumLabel;
@property (nonatomic, retain) UIButton* commentButton;
@property (nonatomic, retain) UIBarButtonItem* commentButtonItem;
@property (nonatomic, retain) UIButton* likeButton;
@property (nonatomic, retain) UIBarButtonItem* likeButtonItem;
@property (nonatomic, retain) UIToolbar* topbar;
@property (nonatomic, retain) UILabel* pageLabel;
@property (nonatomic, retain) UIBarButtonItem* pageButtonItem;
@property (nonatomic, retain) UIBarButtonItem* closeButtonItem;
@property (nonatomic, retain) UIBarButtonItem* actionButtonItem;
@property (nonatomic, retain) UIBarButtonItem* flexibleSpaceButtonItem;
@property (nonatomic, retain) UIBarButtonItem* fixedSpaceButtonItem;
@property (nonatomic, retain) UIView* photoCommentView;
@property (nonatomic, retain) UILabel* titleLabel;
@property (nonatomic, retain) UILabel* messageLabel;
@property (nonatomic, retain) GreeJSDownloadIndicatorView* indicator;
@property (nonatomic, assign) NSInteger totalCount;
@property (nonatomic, assign, getter = isEditable) BOOL editable;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) UIStatusBarStyle beforeStatusBarSytle;
@property (nonatomic, assign) BOOL beforeStatusBarHidden;
@property (nonatomic, assign) NSInteger previousPhotoIndex;

-(GreePhotoInfo*)currentPhotoInfo;
-(void)closeButtonPressed:(id)sender;
-(void)actionButtonItemTapped:(id)sender;
-(void)likeNumButtonTapped:(id)sender;
-(void)commentNumButtonTapped:(id)sender;
-(void)commentButtonTapped:(id)sender;
-(void)likeButtonTapped:(id)sender;
-(void)reloadPhotoButtonTapped:(id)sender;
-(void)setLikeNum:(NSUInteger)likeNum;
-(void)setCommentNum:(NSUInteger)commentNum;
-(void)setTitleWithCurrentPage:(NSInteger)page totalNum:(NSInteger)totalNum;
-(void)updateLike:(GreePhotoInfo*)info;
-(NSString*)formatContentCount:(NSInteger)count;
-(void)completeSaveImageIntoPhotoAlbum:(UIImage*)image
              didFinishSavingWithError:(NSError*)error
                           contextInfo:(void*)contextInfo;
-(void)showBars:(BOOL)show animated:(BOOL)animated;
-(void)showIndicator;
-(void)hideIndicator;
-(void)updateUI;
-(void)setCommentWithTitle:(NSString*)title message:(NSString*)message;
-(void)setLikeButtonOn:(BOOL)on;
-(void)saveImageIntoPhotoAlbum;
-(void)loadContentInfoWithSequenceIndex:(NSInteger)index
                                 params:(NSDictionary*)params
                                  block:(void (^)(NSArray* infos, NSError* error))block;
-(void)loadPhotoImageWithRequest:(NSURLRequest*)request
                 targetImageView:(UIImageView*)imageView
                         success:(void (^)(UIImage* image))success
                         failure:(void (^)(NSError* error))failure;
-(void)setLikeOn:(BOOL)on
          userId:(NSInteger)userId
       contentId:(NSInteger)contentId
     contentType:(GreeLikeContentType*)type
    successBlock:(void (^)(void))successBlock
    failureBlock:(void (^)(NSError* error))failureBlock;

@end

@implementation GreeJSPhotoViewController

#pragma mark - Object Lifecycle

-(id)initWithParams:(NSDictionary*)params delegate:(id)delegate
{
  self = [self initWithNibName:nil bundle:nil];
  if (self) {
    self.delegate = delegate;
    self.photoInfos = [NSMutableDictionary dictionaryWithCapacity:0];
    self.params = [NSDictionary dictionaryWithDictionary:params];
    self.userId = [[self.params objectForKey:kParamUserIdKey] intValue];
    self.serviceType = [params objectForKey:kParamApiTypeKey];
    if ([[self.params objectForKey:kParamApiTypeKey] isEqualToString:kApiTypeAlbumName]) {
      self.totalCount = [[params objectForKey:kParamTotalNumKey] integerValue];
      self.currentIndex = [[params objectForKey:kParamCurrentIndexKey] integerValue];
      self.editable = [[params objectForKey:kParamEditable] boolValue];
    } else if ([[self.params objectForKey:kParamApiTypeKey] isEqualToString:kApiTypeMoodName]) {
      self.totalCount = 1;
      self.currentIndex = 0;
    }
  }
  return self;
}

-(void)loadView
{
  [super loadView];
  self.view.frame = [UIScreen mainScreen].bounds;
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  self.beforeStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
  self.beforeStatusBarSytle = [UIApplication sharedApplication].statusBarStyle;

  self.photoView.frame = self.view.frame;
  self.photoView.delegate = self;

  [self.photoView setCurrentPage:self.currentIndex animated:NO];

  [self.view addSubview:self.photoView];
  [self.view addSubview:self.topbar];

  self.fixedSpaceButtonItem.width = 10.0;
  NSArray* items = [NSArray arrayWithObjects:
                    self.likeNumButtonItem,
                    self.commentNumButtonItem,
                    self.flexibleSpaceButtonItem,
                    self.commentButtonItem,
                    self.fixedSpaceButtonItem,
                    self.likeButtonItem,
                    nil];
  [self setToolbarItems:items];
}

-(void)dealloc
{
  self.params = nil;
  self.serviceType = nil;
  self.photoView = nil;
  self.photoInfos = nil;
  self.closeButtonItem = nil;
  self.topbar = nil;
  self.pageLabel = nil;
  self.pageButtonItem = nil;
  self.actionButtonItem = nil;
  self.flexibleSpaceButtonItem = nil;
  self.fixedSpaceButtonItem = nil;
  self.loadingIndicator = nil;
  self.photoCommentView = nil;
  self.likeNumButton = nil;
  self.likeImageView = nil;
  self.likeNumLabel = nil;
  self.likeNumButtonItem = nil;
  self.commentNumButton = nil;
  self.commentNumButtonItem = nil;
  self.commentImageView = nil;
  self.commentNumLabel = nil;
  self.commentButton = nil;
  self.commentButtonItem = nil;
  self.likeButtonItem = nil;
  self.likeButton = nil;
  self.titleLabel = nil;
  self.messageLabel = nil;
  self.indicator = nil;

  [super dealloc];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return [self isAbleToAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - UIViewController Overrides

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];

  self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
  self.navigationController.navigationBar.translucent = YES;

  self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
  self.navigationController.toolbar.translucent = YES;

  [self.navigationController setNavigationBarHidden:YES animated:NO];
  [self.navigationController setToolbarHidden:NO animated:NO];

  [self updateUI];
  [self showBars:YES animated:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [[UIApplication sharedApplication] setStatusBarHidden:self.beforeStatusBarHidden withAnimation:UIStatusBarAnimationFade];
  [[UIApplication sharedApplication] setStatusBarStyle:self.beforeStatusBarSytle animated:YES];
}

#pragma mark - GreeJSPhotoViewDelegate Methoads

-(NSInteger)numberOfPhotoImages:(GreeJSPhotoView*)photoView
{
  return self.totalCount;
}

-(UIImage*)photoImage:(GreeJSPhotoView*)photoView
            imageView:(UIImageView*)imageView
         imageAtIndex:(NSUInteger)index
{
  __block UIImage* placeholderImage = nil;
  __block GreePhotoInfo* info = [self.photoInfos objectForKey:[NSString stringWithFormat:@"%d", index]];

  if (![imageView viewWithTag:[imageView hash]]) {
    GreeJSDownloadIndicatorView* indicator = [GreeJSDownloadIndicatorView downloadIndicator];
    indicator.center = imageView.center;
    indicator.tag = [imageView hash];
    [imageView addSubview:indicator];
    [indicator spin];
  }

  if (!info) {
    NSInteger offset = index;
    if (self.previousPhotoIndex > offset && [self.serviceType isEqualToString:kApiTypeAlbumName]) {
      offset = (offset-kMaxPhotoLimitCount < 0) ? 0 : offset-kMaxPhotoLimitCount;
    }
    [self loadContentInfoWithSequenceIndex:offset params:self.params block:^(NSArray* infos, NSError* error) {
       if (error) {
         GreeJSDownloadIndicatorView* indicator
           = (GreeJSDownloadIndicatorView*)[imageView viewWithTag:[imageView hash]];
         [indicator pause];
         indicator.block =^(GreeJSDownloadIndicatorView* view) {
           if (!view.isSpin) {
             [view spin];
             [self photoImage:photoView imageView:imageView imageAtIndex:index];
           }
         };
       } else {
         [self photoImage:photoView imageView:imageView imageAtIndex:index];
       }
     }];
  } else {
    NSURL* url = [NSURL URLWithString:[info.content imageUrlString]];
    NSURLRequest* request = [[[NSURLRequest alloc] initWithURL:url] autorelease];
    [self loadPhotoImageWithRequest:request targetImageView:imageView
                            success:^(UIImage* image) {
       GreeJSDownloadIndicatorView* indicator
         = (GreeJSDownloadIndicatorView*)[imageView viewWithTag:[imageView hash]];
       if (indicator) {
         [indicator removeFromSuperview];
         indicator = nil;
       }
       placeholderImage = image;
     } failure:^(NSError* error) {
       GreeJSDownloadIndicatorView* indicator
         = (GreeJSDownloadIndicatorView*)[imageView viewWithTag:[imageView hash]];
       [indicator pause];
       indicator.block =^(GreeJSDownloadIndicatorView* view) {
         if (!view.isSpin) {
           [view spin];
           [self photoImage:photoView imageView:imageView imageAtIndex:index];
         }
       };
     }];
  }
  self.previousPhotoIndex = index;

  return placeholderImage;
}

-(void)photoScrollViewDidChangeNextPage:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView
{
  [self updateUI];
}

-(void)photoScrollViewDidChangePreviousPage:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView
{
  [self updateUI];
}

-(void)photoScrollViewDidEndDecelerating:(UIScrollView*)scrollView photoView:(GreeJSPhotoView*)photoView
{
  UIImageView* imageView = [photoView currentPhotoImageView];
  GreeJSDownloadIndicatorView* indicator = (GreeJSDownloadIndicatorView*)[imageView viewWithTag:[imageView hash]];
  if (indicator && !indicator.isSpin) {
    [self.photoView reloadPhotos];
  }
  [self updateUI];
}

-(void)didSingleTap:(GreeJSPhotoView*)photoView
{
  BOOL show = self.navigationController.toolbar.alpha ? 0 : 1;
  [self showBars:show animated:YES];
}

#pragma mark - UIActionSheetDelegate Methoads

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if ([actionSheet cancelButtonIndex] == buttonIndex) {
    return;
  }
  if ([[actionSheet buttonTitleAtIndex:buttonIndex]
       isEqualToString:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Save.Title", @"Save")]) {
    [self saveImageIntoPhotoAlbum];
  } else if([[actionSheet buttonTitleAtIndex:buttonIndex]
             isEqualToString:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Edit.Title", @"Edit")]) {

    [self greeDismissViewControllerAnimated:YES completion:^{
       if ([self.delegate respondsToSelector:@selector(photoViewController:didAction:photoInfo:)]) {
         GreePhotoInfo* info = [self.photoInfos valueForKey:
                                [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
         [self.delegate photoViewController:self
                                  didAction:GreePhotoActionShowEdit
                                  photoInfo:info];
       }
     }];
  }
}

#pragma mark - Internal Methods

-(GreeJSPhotoView*)photoView
{
  if (!_photoView) {
    _photoView = [[GreeJSPhotoView alloc] initWithFrame:CGRectZero];
    _photoView.autoresizingMask =
      UIViewAutoresizingFlexibleHeight |
      UIViewAutoresizingFlexibleWidth;
  }
  return _photoView;
}

-(UIView*)photoCommentView
{
  if (!_photoCommentView) {

    _photoCommentView = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                 self.view.frame.size.height-self.navigationController.toolbar.frame.size.height-45.0,
                                                                 self.view.frame.size.width,
                                                                 45.0)];
    _photoCommentView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth |
      UIViewAutoresizingFlexibleTopMargin |
      UIViewAutoresizingFlexibleBottomMargin;
    _photoCommentView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  }
  return _photoCommentView;
}

-(UILabel*)titleLabel
{
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    _titleLabel.numberOfLines = 1;
  }
  return _titleLabel;
}

-(UILabel*)messageLabel
{
  if (!_messageLabel) {
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.autoresizingMask =
      UIViewAutoresizingFlexibleWidth;
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.font = [UIFont systemFontOfSize:14.0];
    _messageLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    _messageLabel.numberOfLines = 1;
  }
  return _messageLabel;
}

-(UIButton*)likeNumButton
{
  if (!_likeNumButton) {
    _likeNumButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _likeNumButton.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _likeNumButton.frame = CGRectMake(0.0, 0.0, 50.0, self.navigationController.toolbar.frame.size.height);
    [_likeNumButton addTarget:self action:@selector(likeNumButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
    [_likeNumButton addSubview:self.likeImageView];
    [_likeNumButton addSubview:self.likeNumLabel];
  }
  return _likeNumButton;
}

-(UIImageView*)likeImageView
{
  if (!_likeImageView) {
    _likeImageView = [[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"like_default.png"]];
    _likeImageView.frame = CGRectMake(0.0, 0.0, 16.0, self.navigationController.toolbar.frame.size.height);
    _likeImageView.contentMode = UIViewContentModeScaleAspectFit;
    _likeImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _likeImageView.backgroundColor = [UIColor clearColor];
  }
  return _likeImageView;
}

-(UILabel*)likeNumLabel
{
  if (!_likeNumLabel) {
    _likeNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0.0, 34.0, self.navigationController.toolbar.frame.size.height)];
    _likeNumLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _likeNumLabel.backgroundColor = [UIColor clearColor];
    _likeNumLabel.textColor = [UIColor whiteColor];
    _likeNumLabel.font = [UIFont boldSystemFontOfSize:14.0];
  }
  return _likeNumLabel;
}

-(UIBarButtonItem*)likeNumButtonItem
{
  if (!_likeNumButtonItem) {
    _likeNumButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.likeNumButton];
  }
  self.likeNumButton.frame = CGRectMake(0.0, 0.0, 50.0, 44.0);
  return _likeNumButtonItem;
}

-(UIImageView*)commentImageView
{
  if (!_commentImageView) {
    _commentImageView = [[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"comment_default.png"]];
    _commentImageView.frame = CGRectMake(0.0, 0.0, 16.0, self.navigationController.toolbar.frame.size.height);
    _commentImageView.contentMode = UIViewContentModeScaleAspectFit;
    _commentImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _commentImageView.backgroundColor = [UIColor clearColor];
  }
  return _commentImageView;
}

-(UILabel*)commentNumLabel
{
  if (!_commentNumLabel) {
    _commentNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0.0, 34.0, self.navigationController.toolbar.frame.size.height)];
    _commentNumLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _commentNumLabel.backgroundColor = [UIColor clearColor];
    _commentNumLabel.textColor = [UIColor whiteColor];
    _commentNumLabel.font = [UIFont boldSystemFontOfSize:14.0];
  }
  return _commentNumLabel;
}

-(UIButton*)commentNumButton
{
  if (!_commentNumButton) {
    _commentNumButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _commentNumButton.frame = CGRectMake(0.0, 0.0, 50.0, self.navigationController.toolbar.frame.size.height);
    _commentImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [_commentNumButton setBackgroundColor:[UIColor clearColor]];
    [_commentNumButton addTarget:self action:@selector(commentNumButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
    [_commentNumButton addSubview:self.commentImageView];
    [_commentNumButton addSubview:self.commentNumLabel];
  }
  return _commentNumButton;
}

-(UIBarButtonItem*)commentNumButtonItem
{
  if (!_commentNumButtonItem) {
    _commentNumButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.commentNumButton];
  }
  return _commentNumButtonItem;
}

-(UIButton*)commentButton
{
  if (!_commentButton) {
    UIImage* defaultImage = [UIImage greeImageNamed:@"btn_comment_default.png"];
    UIImage* highlightImage = [UIImage greeImageNamed:@"btn_comment_highlight.png"];
    CGSize size = defaultImage.size;
    _commentButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _commentButton.frame = CGRectMake(0, 0, size.width, size.height);
    [_commentButton setBackgroundImage:defaultImage
                              forState:UIControlStateNormal];
    [_commentButton setBackgroundImage:highlightImage
                              forState:UIControlStateHighlighted];
    [_commentButton addTarget:self action:@selector(commentButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
  }
  return _commentButton;
}

-(UIBarButtonItem*)commentButtonItem
{
  if (!_commentButtonItem) {
    _commentButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.commentButton];
  }
  return _commentButtonItem;
}

-(UIButton*)likeButton
{
  if (!_likeButton) {
    _likeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [_likeButton addTarget:self action:@selector(likeButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
    UIImage* defaultImage = [UIImage greeImageNamed:@"btn_like_default.png"];
    UIImage* highlightImage = [UIImage greeImageNamed:@"btn_like_highlight.png"];
    _likeButton.frame = CGRectMake(0.0, 0.0, defaultImage.size.width, defaultImage.size.height);
    [_likeButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    [_likeButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
  }
  return _likeButton;
}

-(UIBarButtonItem*)likeButtonItem
{
  if (!_likeButtonItem) {
    _likeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.likeButton];
  }
  return _likeButtonItem;
}

-(UIToolbar*)topbar
{
  if (!_topbar) {
    _topbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    _topbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topbar.barStyle = UIBarStyleBlackTranslucent;
    _topbar.translucent = YES;
    NSArray* items = [NSArray arrayWithObjects:self.actionButtonItem,
                      self.flexibleSpaceButtonItem,
                      self.pageButtonItem,
                      self.flexibleSpaceButtonItem,
                      self.closeButtonItem,
                      nil];
    [_topbar setItems:items];
  }
  return _topbar;
}

-(UILabel*)pageLabel
{
  if (!_pageLabel) {
    _pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0,
                                                           0.0,
                                                           self.topbar.bounds.size.width/3,
                                                           self.topbar.bounds.size.height)];
    _pageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _pageLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _pageLabel.textColor = [UIColor whiteColor];
    _pageLabel.textAlignment = UITextAlignmentCenter;
    _pageLabel.adjustsFontSizeToFitWidth = YES;
    _pageLabel.backgroundColor = [UIColor clearColor];
  }
  return _pageLabel;
}

-(UIBarButtonItem*)pageButtonItem
{
  if (!_pageButtonItem) {
    _pageButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.pageLabel];
  }
  return _pageButtonItem;
}


-(UIBarButtonItem*)closeButtonItem
{
  if (!_closeButtonItem) {
    UIImage* closeButtonImage = [UIImage greeImageNamed:@"btn_close_default.png"];
    UIImage* closeButtonImageHighlight = [UIImage greeImageNamed:@"btn_close_highlight.png"];
    UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0.0,
                                   0.0,
                                   closeButtonImage.size.width,
                                   self.topbar.frame.size.height);
    [closeButton addTarget:self action:@selector(closeButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:closeButtonImage forState:UIControlStateNormal];
    [closeButton setImage:closeButtonImageHighlight forState:UIControlStateHighlighted];
    closeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
  }
  return _closeButtonItem;
}

-(UIBarButtonItem*)actionButtonItem
{
  if (!_actionButtonItem) {
    _actionButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                      target:self
                                                                      action:@selector(actionButtonItemTapped:)];
    _actionButtonItem.style = UIBarButtonItemStylePlain;
  }
  return _actionButtonItem;
}

-(UIBarButtonItem*)flexibleSpaceButtonItem
{
  if (!_flexibleSpaceButtonItem) {
    _flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil];
  }
  return _flexibleSpaceButtonItem;
}

-(UIBarButtonItem*)fixedSpaceButtonItem
{
  if (!_fixedSpaceButtonItem) {
    _fixedSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                          action:nil];
    _fixedSpaceButtonItem.width = 10.0f;
  }
  return _fixedSpaceButtonItem;
}

-(GreePhotoInfo*)currentPhotoInfo
{
  return [self.photoInfos objectForKey:[NSString stringWithFormat:@"%d", self.photoView.currentPage]];
}

-(void)showBars:(BOOL)show animated:(BOOL)animated
{
  CGFloat alpha = show ? 1.0 : 0.0;
  CGFloat animationDuration = show ? 0.1 : 0.5;
  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
  }
  self.topbar.alpha = alpha;
  self.navigationController.toolbar.alpha = alpha;

  if (animated) {
    [UIView commitAnimations];
  }
}

-(void)showIndicator
{
  if (!self.loadingIndicator) {
    self.loadingIndicator = [[[GreeJSLoadingIndicatorView alloc]
                              initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];
  }
  self.loadingIndicator.center = self.view.center;
  if (!self.loadingIndicator.superview) {
    [self.view addSubview:self.loadingIndicator];
  }
}

-(void)hideIndicator
{
  [self.loadingIndicator removeFromSuperview];
  self.loadingIndicator = nil;
}

-(void)setTitleWithCurrentPage:(NSInteger)page totalNum:(NSInteger)totalNum
{
  if (totalNum > 1) {
    self.pageLabel.text = [NSString stringWithFormat:@"%d/%d",
                           page,
                           self.totalCount];
  } else {
    self.pageLabel.text = nil;
  }
}

-(void)setCommentWithTitle:(NSString*)title message:(NSString*)message
{
  [self.titleLabel removeFromSuperview];
  self.titleLabel = nil;
  [self.messageLabel removeFromSuperview];
  self.messageLabel = nil;
  if (title.length == 0 && message.length == 0) {
    return;
  }

  CGRect titleRect = CGRectZero;
  CGRect messageRect = CGRectZero;

  if (title.length > 0 && message.length == 0) {
    self.titleLabel.numberOfLines = 2;
    titleRect = CGRectMake(0,
                           0,
                           self.photoCommentView.frame.size.width,
                           self.photoCommentView.frame.size.height);
  } else if (title.length == 0 && message.length > 0) {
    self.messageLabel.numberOfLines = 2;
    messageRect = CGRectMake(0,
                             0,
                             self.photoCommentView.frame.size.width,
                             self.photoCommentView.frame.size.height);
  } else {
    self.titleLabel.numberOfLines = 1;
    self.messageLabel.numberOfLines = 1;
    titleRect = CGRectMake(0,
                           0,
                           self.photoCommentView.frame.size.width,
                           self.photoCommentView.frame.size.height/2);
    messageRect = CGRectMake(0,
                             self.photoCommentView.frame.size.height/2,
                             self.photoCommentView.frame.size.width,
                             self.photoCommentView.frame.size.height/2);
  }
  if (title.length > 0) {
    self.titleLabel.frame = CGRectInset(titleRect, 10.0, 4.0);
    self.titleLabel.text = [[title stringByDecodingHTMLEntities] stringByRemoveHtmlTags];
    [self.photoCommentView addSubview:self.titleLabel];
  }
  if (message.length > 0) {
    self.messageLabel.frame = CGRectInset(messageRect, 10.0, 4.0);
    self.messageLabel.text = [[message stringByDecodingHTMLEntities] stringByRemoveHtmlTags];
    [self.photoCommentView addSubview:self.messageLabel];
  }

  BOOL show = self.navigationController.toolbar.alpha == 1 ? YES : NO;
  [self showBars:show animated:NO];
}

-(void)setLikeNum:(NSUInteger)likeNum
{
  NSString* title = [self formatContentCount:likeNum];
  self.likeNumLabel.text =  title;
}

-(void)setCommentNum:(NSUInteger)commentNum
{
  NSString* title = [self formatContentCount:commentNum];
  self.commentNumLabel.text = title;
}

-(void)setLikeButtonOn:(BOOL)on
{
  UIImage* defaultImage = nil;
  UIImage* highlightImage = nil;
  if (on) {
    defaultImage = [UIImage greeImageNamed:@"btn_like_on_default.png"];
    highlightImage = [UIImage greeImageNamed:@"btn_like_on_highlight.png"];
  } else {
    defaultImage = [UIImage greeImageNamed:@"btn_like_default.png"];
    highlightImage = [UIImage greeImageNamed:@"btn_like_highlight.png"];
  }
  [self.likeButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
  [self.likeButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
  CGRect newFrame = self.likeButton.frame;
  newFrame.size = CGSizeMake(defaultImage.size.width, defaultImage.size.height);
  self.likeButton.frame = newFrame;
}

-(void)updateLike:(GreePhotoInfo*)info
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

  // 1. update like button image
  [self setLikeButtonOn:!info.isLike];

  // 2. update like num button title
  info.isLike ? info.likeNum-- : info.likeNum++;
  [self setLikeNum:info.likeNum];

  // 3. call like api
  [self setLikeOn:!info.isLike
           userId:[info.content userId]
        contentId:[info.content contentId]
      contentType:[info.content contentType]
     successBlock:^{
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
   }
     failureBlock:^(NSError* error) {
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
   }];

  info.isLike = !info.isLike;
}

-(NSString*)formatContentCount:(NSInteger)count
{
  if (count > 999) {
    return @"999+";
  } else if (count <= 0) {
    return @"";
  } else {
    return [NSString stringWithFormat:@"%d", count];
  }
}

-(void)saveImageIntoPhotoAlbum
{
  [self showIndicator];
  UIImage* image = [self.photoView currentPhotoImageView].image;
  if (!image) {
    return;
  }
  UIImageWriteToSavedPhotosAlbum(image,
                                 self,
                                 @selector(completeSaveImageIntoPhotoAlbum:didFinishSavingWithError:contextInfo:),
                                 image);
}

-(void)completeSaveImageIntoPhotoAlbum:(UIImage*)image
              didFinishSavingWithError:(NSError*)error
                           contextInfo:(void*)contextInfo
{
  [self hideIndicator];

  if (error != nil) {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:nil
                                                 message:GreePlatformString(@"GreeJS.PhotoViewController.SavePhoto.Failure.Alert.Message",
                                                  @"Failed to save the photo. Please try again.")
                                                delegate:nil
                                       cancelButtonTitle:GreePlatformString(@"GreeJS.ShowModalViewCommand.CloseButton.Title", @"Close")
                                       otherButtonTitles:nil];
    [av show];
    [av release];
  } else {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:nil
                                                 message:GreePlatformString(@"GreeJS.PhotoViewController.SavePhoto.Success.Alert.Message",
                                                  @"Your photo has been saved.")
                                                delegate:nil
                                       cancelButtonTitle:GreePlatformString(@"GreeJS.ShowModalViewCommand.CloseButton.Title", @"Close")
                                       otherButtonTitles:nil];
    [av show];
    [av release];
  }
}

-(void)closeButtonPressed:(id)sender
{
  [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)updateUI
{
  GreePhotoInfo* info = [self.photoInfos valueForKey:
                         [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
  if (!info) {
    self.likeNumButton.enabled    = NO;
    self.commentNumButton.enabled = NO;
    self.commentButton.enabled    = NO;
    self.likeButton.enabled       = NO;
    self.actionButtonItem.enabled = NO;
  } else {
    self.likeNumButton.enabled    = YES;
    self.commentNumButton.enabled = YES;
    self.commentButton.enabled    = YES;
    self.likeButton.enabled       = YES;
    self.actionButtonItem.enabled = YES;

    [self setLikeNum:info.likeNum];
    [self setCommentNum:[info.content commentNum]];
    [self setLikeButtonOn:info.isLike];
  }
  [self setTitleWithCurrentPage:self.photoView.currentPage+1 totalNum:self.totalCount];
}

-(void)actionButtonItemTapped:(id)sender
{
  GreePhotoInfo* info = [self currentPhotoInfo];
  if (info) {
    if ([[info.content contentType] isEqualToString:GreeContentTypeMood]) {
      UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                         delegate:self
                                                cancelButtonTitle:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Cancel.Title", @"Cancel")
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Save.Title", @"Save"),
                              nil];
      sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
      [sheet showInView:self.view];
      [sheet release];
    } else if ([[info.content contentType] isEqualToString:GreeContentTypePhoto]) {
      UIActionSheet* sheet = nil;

      if (self.editable) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Cancel.Title", @"Cancel")
                              destructiveButtonTitle:nil
                                   otherButtonTitles:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Save.Title", @"Save"),
                 GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Edit.Title", @"Edit"),
                 nil];
      } else {
        sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Cancel.Title", @"Cancel")
                              destructiveButtonTitle:nil
                                   otherButtonTitles:GreePlatformString(@"GreeJS.PhotoViewController.Menu.ActionSheet.Save.Title", @"Save"),
                 nil];
      }
      sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
      [sheet showInView:self.view];
      [sheet release];
    }
  }
}

-(void)closeButtonTapped:(id)sender
{
  [self greeDismissViewControllerAnimated:YES completion:nil];
}

-(void)likeNumButtonTapped:(id)sender
{
  [self greeDismissViewControllerAnimated:YES completion:^{
     if ([self.delegate respondsToSelector:@selector(photoViewController:didAction:photoInfo:)]) {
       GreePhotoInfo* info = [self.photoInfos valueForKey:
                              [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
       [self.delegate photoViewController:self
                                didAction:GreePhotoActionShowDetail
                                photoInfo:info];
     }
   }];
}

-(void)commentNumButtonTapped:(id)sender
{
  [self greeDismissViewControllerAnimated:YES completion:^{
     if ([self.delegate respondsToSelector:@selector(photoViewController:didAction:photoInfo:)]) {
       GreePhotoInfo* info = [self.photoInfos valueForKey:
                              [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
       [self.delegate photoViewController:self
                                didAction:GreePhotoActionShowDetail
                                photoInfo:info];
     }
   }];
}

-(void)commentButtonTapped:(id)sender
{
  [self greeDismissViewControllerAnimated:YES completion:^{
     if ([self.delegate respondsToSelector:@selector(photoViewController:didAction:photoInfo:)]) {
       GreePhotoInfo* info = [self.photoInfos valueForKey:
                              [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
       [self.delegate photoViewController:self
                                didAction:GreePhotoActionShowDetail
                                photoInfo:info];
     }
   }];
}

-(void)likeButtonTapped:(id)sender
{
  GreePhotoInfo* info = [self.photoInfos valueForKey:
                         [NSString stringWithFormat:@"%d", self.photoView.currentPage]];
  if (info) {
    [self updateLike:info];
  }
}

-(void)reloadPhotoButtonTapped:(id)sender
{
  [self.photoView reloadPhotos];
}

-(void)loadContentInfoWithSequenceIndex:(NSInteger)index
                                 params:(NSDictionary*)params
                                  block:(void (^)(NSArray* infos, NSError* error))block
{
  NSString* type = [params objectForKey:kParamApiTypeKey];
  if ([type isEqualToString:kApiTypeMoodName]) {
    NSInteger moodId = [[params objectForKey:kParamMoodIdKey] integerValue];
    NSInteger userId = [[params objectForKey:kParamUserIdKey] integerValue];
    [GreeMood loadMoodId:moodId userId:userId block:^(GreeMood* mood, NSError* error) {
       NSArray* returnArray = nil;
       if (!error) {
         GreePhotoInfo* photoInfo = [[GreePhotoInfo alloc] initWithGreeContent:mood];
         if (photoInfo) {
           @synchronized(self) {
             [self.photoInfos setObject:photoInfo forKey:[NSString stringWithFormat:@"%d", index]];
             returnArray = [NSArray arrayWithObject:photoInfo];
           }
           [photoInfo release];
         }
       }
       if (block) {
         block(returnArray, error);
       }
       [self updateUI];
     }];
  } else if ([type isEqualToString:kApiTypeAlbumName]) {
    NSInteger userId = [[params objectForKey:kParamUserIdKey] integerValue];
    NSInteger albumId = [[params objectForKey:kParamAlbumIdKey] integerValue];
    [GreePhoto loadPhotosWithAlbumId:albumId
                              userId:userId
                              offset:index
                               limit:kMaxPhotoLimitCount
                               block:^(NSArray* items, NSError* error) {
       NSArray* returnArray = nil;
       if (items.count > 0) {
         returnArray = [NSMutableArray arrayWithCapacity:items.count];
         for (int i = 0; i < items.count; i++) {
           GreePhotoInfo* info = [[GreePhotoInfo alloc] initWithGreeContent:[items objectAtIndex:i]];
           @synchronized(self) {
             [self.photoInfos setObject:info forKey:[NSString stringWithFormat:@"%d", index+i]];
             [(NSMutableArray*) returnArray addObject:info];
           }
           [info release];
         }
       }
       if (block) {
         block(returnArray, error);
       }
       [self updateUI];
     }];
  }
}

-(void)loadPhotoImageWithRequest:(NSURLRequest*)request
                 targetImageView:(UIImageView*)imageView
                         success:(void (^)(UIImage* image))success
                         failure:(void (^)(NSError* error))failure
{
  if (!imageView) {
    return;
  }
  [imageView setImageWithURLRequest:request
                   placeholderImage:nil
                            success:^(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image) {
     success(image);
   }
                            failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) {
     failure(error);
   }];
}


-(void)setLikeOn:(BOOL)on
          userId:(NSInteger)userId
       contentId:(NSInteger)contentId
     contentType:(GreeLikeContentType*)type
    successBlock:(void (^)(void))successBlock
    failureBlock:(void (^)(NSError* error))failureBlock
{
  if (on) {
    [GreeLike postLikeWithUserId:userId
                       contentId:contentId
                     contentType:type
                    successBlock:^{
       if (successBlock) {
         successBlock();
       }
     }
                    failureBlock:^(NSError* error){
       if (failureBlock) {
         failureBlock(error);
       }
     }];
  } else {
    [GreeLike removeLikeWithUserId:userId
                         contentId:contentId
                       contentType:type
                      successBlock:^{
       if (successBlock) {
         successBlock();
       }
     }
                      failureBlock:^(NSError* error){
       if (failureBlock) {
         failureBlock(error);
       }
     }];
  }
}


@end
