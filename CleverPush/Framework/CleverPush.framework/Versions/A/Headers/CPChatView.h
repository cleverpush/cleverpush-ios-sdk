#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface CPChatView : UIView <WKNavigationDelegate, WKScriptMessageHandler>

#pragma mark - Class Variables
@property(strong,nonatomic) WKWebView *webView;

typedef void (^CPChatURLOpenedCallback)(NSURL* url);
typedef void (^CPChatSubscribeCallback)(void);

#pragma mark - Class Methods
- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock;
- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock headerCodes:(NSString *)headerHtmlCodes;
- (void)loadChat;
- (void)loadChatWithSubscriptionId:(NSString*)subscriptionId;
- (void)lockChat;

@end
