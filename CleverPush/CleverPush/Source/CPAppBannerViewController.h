#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>
#import "CPAppBanner.h"
#import "CPAppBannerDismissType.h"
#import "CPAppBannerFrequency.h"
#import "CPAppBannerStatus.h"
#import "CPAppBannerStopAtType.h"
#import "CPAppBannerType.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerBlockType.h"
#import "UIColor+HexString.h"
#import "UIImageView+CleverPush.h"
#import "CPAspectKeepImageView.h"
#import "UIControl+CPBlockActions.h"
#import "CPUIBlockButton.h"
#import "CleverPush.h"
#import "CPWKWebKitView.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPUtils.h"
#import "CPAppBannerModule.h"
#import "CPBannerCardContainer.h"
#import "CPAspectKeepImageView.h"

@interface CPAppBannerViewController : UIViewController<UIGestureRecognizerDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UICollectionViewDelegate, UICollectionViewDataSource, HeightDelegate, UIScrollViewDelegate, NavigateNextPage>

#pragma mark - Class Variables
@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, strong) IBOutlet CPAspectKeepImageView *backGroundImage;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, assign) long index;
@property (nonatomic, strong) IBOutlet WKWebView *webBanner;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UICollectionView *cardCollectionView;
@property (weak, nonatomic) IBOutlet UIView *bannerContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *popupHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webBannerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnTopConstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageControllTopConstraint;

#pragma mark - Class Methods
- (void)initWithBanner:(CPAppBanner*)banner;
- (void)initWithHTMLBanner:(CPAppBanner*)banner;
- (void)setActionCallback:(CPAppBannerActionBlock)callback;
- (void)onDismiss;
- (IBAction)tapOutSideBanner:(UIButton *)sender;
- (IBAction)btnClose:(UIButton *)sender;

@end
