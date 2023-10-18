#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPAppBannerBlock.h"
#import "CPAppBanner.h"

@interface CPHTMLBlockCell : UITableViewCell <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webHTMLContentHeight;
@property (strong, nonatomic) IBOutlet WKWebView *webHTMLBlock;
@property (strong, nonatomic) WKWebViewConfiguration *webConfiguration; 
@property (strong, nonatomic) WKUserContentController *userController;

@end
