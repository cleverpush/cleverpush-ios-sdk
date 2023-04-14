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
@property (nonatomic, assign) UIColor* chatInputContainerBackgroundColor;
@property (nonatomic, assign) UIColor* chatInputBackgroundColor;
@property (nonatomic, assign) UIColor* chatInputTextColor;
@property (nonatomic, assign) UIColor* chatSenderBubbleTextColor;
@property (nonatomic, assign) UIColor* chatReceiverBubbleBackgroundColor;
@property (nonatomic, assign) UIColor* chatReceiverBubbleTextColor;
@property (nonatomic, assign) UIColor* chatSendButtonBackgroundColor;
@property (nonatomic, assign) UIColor* chatTimestampTextColor;


@end
