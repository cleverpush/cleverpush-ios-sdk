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
- (void)setChatBackgroundColor:(UIColor *)color;
- (void)setChatSenderBubbleTextColor:(UIColor *)color;
- (void)setChatSenderBubbleBackgroundColor:(UIColor *)color;
- (void)setChatSendButtonBackgroundColor:(UIColor *)color;
- (void)setChatInputTextColor:(UIColor *)color;
- (void)setChatInputBackgroundColor:(UIColor *)color;
- (void)setChatReceiverBubbleBackgroundColor:(UIColor *)color;
- (void)setChatInputContainerBackgroundColor:(UIColor *)color;
- (void)setChatTimestampTextColor:(UIColor *)color;
- (void)setChatReceiverBubbleTextColor:(UIColor *)color;

- (UIColor*)getChatbackgroundColor;
- (UIColor*)getChatSenderBubbleTextColor;
- (UIColor*)getChatSenderBubbleBackgroundColor;
- (UIColor*)getChatSendButtonBackgroundColor;
- (UIColor*)getChatInputBackgroundColor;
- (UIColor*)getChatInputTextColor;
- (UIColor*)getChatReceiverBubbleBackgroundColor;
- (UIColor*)getChatInputContainerBackgroundColor;
- (UIColor*)getChatTimestampTextColor;
- (UIColor*)getChatReceiverBubbleTextColor;

@end
