#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface CPChatView : UIView

@property(strong,nonatomic) WKWebView *webView;

typedef void (^CPChatURLOpenedCallback)(NSURL* url);
typedef void (^CPChatSubscribeCallback)();

- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock;
- (void)loadChat;

@end
