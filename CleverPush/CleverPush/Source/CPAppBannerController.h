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
@interface CPAppBannerController : UIViewController<UIGestureRecognizerDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, strong) IBOutlet UIView *bannerBody;
@property (nonatomic, strong) IBOutlet UIView *bannerBodyContent;

- (id)initWithBanner:(CPAppBanner*)banner;
- (id)initWithHTMLBanner:(CPAppBanner*)banner;

- (void)onDismiss;
- (void)setActionCallback:(CPAppBannerActionBlock)callback;

+ (UIViewController*)topViewController;

@end
