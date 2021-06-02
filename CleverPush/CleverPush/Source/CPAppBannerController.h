#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

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

@interface CPAppBannerController : UIViewController<UIGestureRecognizerDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

#pragma mark - Class Variables

@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, strong) IBOutlet UIScrollView *bannerBody;
@property (nonatomic, strong) IBOutlet UIView *bannerBodyContent;
@property (nonatomic, strong) IBOutlet WKWebView *webBanner;
@property (nonatomic, strong) IBOutlet WKWebView *webBlock;
@property (nonatomic, strong) IBOutlet UIView *htmlBannerBody;

#pragma mark - Class Methods
- (id)initWithBanner:(CPAppBanner*)banner;
- (id)initWithHTMLBanner:(CPAppBanner*)banner;
- (void)setActionCallback:(CPAppBannerActionBlock)callback;
- (void)onDismiss;
+ (UIViewController*)topViewController;

@end
