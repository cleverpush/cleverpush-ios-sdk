#import "CPChatView.h"
#import "CleverPush.h"
#import "CPUtils.h"
#import "CPLog.h"

@interface CPChatView()

@end

@implementation CPChatView

CPChatURLOpenedCallback urlOpenedCallback;
CPChatSubscribeCallback subscribeCallback;
NSString* headerCodes;
NSString* lastSubscriptionId;
UIColor* chatBackgroundColor;
UIColor* chatSenderBubbleTextColor;
UIColor* chatSenderBubbleBackgroundColor;
UIColor* chatSendButtonBackgroundColor;
UIColor* chatInputTextColor;
UIColor* chatInputBackgroundColor;
UIColor* chatReceiverBubbleBackgroundColor;
UIColor* chatInputContainerBackgroundColor;
UIColor* chatTimestampTextColor;
UIColor* chatReceiverBubbleTextColor;

#pragma mark - Load chat with subscription id
- (void)loadChat {
    BOOL isSubscriptionChanged = [CleverPush getSubscriptionChanged];
    BOOL isSubscribed = [CleverPush isSubscribed];
    if (isSubscriptionChanged || !isSubscribed) {
        [CleverPush setSubscriptionChanged:false];
        [self clearWKWebViewCache];
    }

    NSString* subscriptionId;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    } else {
        subscriptionId = @"preview";
    }
    [self loadChatWithSubscriptionId:subscriptionId];
}

#pragma mark - Initialise the chat with WKWebView frame
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [CleverPush addChatView:self];

        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController* userController = [[WKUserContentController alloc] init];

        [userController addScriptMessageHandler:self name:@"chat"];
        configuration.userContentController = userController;

        _webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
        _webView.scrollView.scrollEnabled = true;
        [CPUtils configureWebView:_webView];
        [self loadChat];
        _webView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        _webView.navigationDelegate = self;
        [self addSubview:_webView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _webView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

#pragma mark - Initialise with frame
- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock {
    urlOpenedCallback = urlOpenedBlock;
    subscribeCallback = subscribeBlock;

    self = [self initWithFrame:frame];
    return self;
}

#pragma mark - Initialise with frame along with callbacks ("urlOpenedCallback", "subscribeCallback")
- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock headerCodes:(NSString *)headerHtmlCodes {
    urlOpenedCallback = urlOpenedBlock;
    subscribeCallback = subscribeBlock;
    headerCodes = headerHtmlCodes;

    self = [self initWithFrame:frame urlOpenedCallback:urlOpenedBlock subscribeCallback:subscribeBlock];
    return self;
}

#pragma mark - load chat with subscription id "preview" (lock chat)
- (void)lockChat {
    [self loadChatWithSubscriptionId:@"preview"];
}

#pragma mark - load chat with subscription id along with custom javascript
- (void)loadChatWithSubscriptionId:(NSString*)subscriptionId {
    [CPLog info:@"CPChatView: loadChatWithSubscriptionId: %@", subscriptionId];

    lastSubscriptionId = subscriptionId;

    [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
        NSString *content;
        NSError *error;
        NSData* jsonData;
        NSString* jsonConfig = @"null";

        if (channelConfig != nil) {
            jsonData = [NSJSONSerialization dataWithJSONObject:channelConfig options:0 error:&error];

            if (jsonData != nil) {
                jsonConfig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
        
        NSString* brandingColor = @"";
        NSString* backgroundColor = @"";
        NSString* chatInputContainerBackgroundColor = @"";
        NSString* chatInputBackgroundColor = @"";
        NSString* chatInputTextColor = @"";
        NSString* chatSenderBubbleTextColor = @"";
        NSString* chatReceiverBubbleBackgroundColor = @"";
        NSString* chatReceiverBubbleTextColor = @"";
        NSString* chatSendButtonBackgroundColor = @"";
        NSString* chatTimestampTextColor = @"";
        NSString* chatSenderBubbleBackgroundColor = @"";
        
        if ([CleverPush getBrandingColor]) {
            brandingColor = [CPUtils hexStringFromColor:[CleverPush getBrandingColor]];
        }
        if ([self getChatBackgroundColor]) {
            backgroundColor = [CPUtils hexStringFromColor:[self getChatBackgroundColor]];
        }
        if ([self getChatSenderBubbleTextColor]) {
            chatSenderBubbleTextColor = [CPUtils hexStringFromColor:[self getChatSenderBubbleTextColor]];
        }
        if ([self getChatSendButtonBackgroundColor]) {
            chatSendButtonBackgroundColor = [CPUtils hexStringFromColor:[self getChatSendButtonBackgroundColor]];
        }
        if ([self getChatInputBackgroundColor]) {
            chatInputBackgroundColor = [CPUtils hexStringFromColor:[self getChatInputBackgroundColor]];
        }
        if ([self getChatInputTextColor]) {
            chatInputTextColor = [CPUtils hexStringFromColor:[self getChatInputTextColor]];
        }
        if ([self getChatReceiverBubbleBackgroundColor]) {
            chatReceiverBubbleBackgroundColor = [CPUtils hexStringFromColor:[self getChatReceiverBubbleBackgroundColor]];
        }
        if ([self getChatInputContainerBackgroundColor]) {
            chatInputContainerBackgroundColor = [CPUtils hexStringFromColor:[self getChatInputContainerBackgroundColor]];
        }
        if ([self getChatTimestampTextColor]) {
            chatTimestampTextColor = [CPUtils hexStringFromColor:[self getChatTimestampTextColor]];
        }
        if ([self getChatReceiverBubbleTextColor]) {
            chatReceiverBubbleTextColor = [CPUtils hexStringFromColor:[self getChatReceiverBubbleTextColor]];
        }
        if ([self getChatSenderBubbleBackgroundColor]) {
            chatSenderBubbleBackgroundColor = [CPUtils hexStringFromColor:[self getChatSenderBubbleBackgroundColor]];
        }
        if (!headerCodes) {
            headerCodes = @"";
        }

        NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"CPChatViewHtmlContent" ofType:@"html"];
        NSString *htmlTemplate = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            [CPLog debug:@"Error loading HTML file: %@", error.localizedDescription];
            return;
        }

        content = [htmlTemplate stringByReplacingOccurrencesOfString:@"{{headerCodes}}" withString:headerCodes];
        content = [content stringByReplacingOccurrencesOfString:@"{{jsonConfig}}" withString:jsonConfig];
        content = [content stringByReplacingOccurrencesOfString:@"{{subscriptionId}}" withString:subscriptionId];
        content = [content stringByReplacingOccurrencesOfString:@"{{brandingColor}}" withString:brandingColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{backgroundColor}}" withString:backgroundColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatSenderBubbleTextColor}}" withString:chatSenderBubbleTextColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatSendButtonBackgroundColor}}" withString:chatSendButtonBackgroundColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatInputBackgroundColor}}" withString:chatInputBackgroundColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatInputTextColor}}" withString:chatInputTextColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatReceiverBubbleBackgroundColor}}" withString:chatReceiverBubbleBackgroundColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatInputContainerBackgroundColor}}" withString:chatInputContainerBackgroundColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatTimestampTextColor}}" withString:chatTimestampTextColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatReceiverBubbleTextColor}}" withString:chatReceiverBubbleTextColor];
        content = [content stringByReplacingOccurrencesOfString:@"{{chatSenderBubbleBackgroundColor}}" withString:chatSenderBubbleBackgroundColor];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView loadHTMLString:content baseURL:[[NSBundle mainBundle] resourceURL]];
        });
    }];
}

#pragma mark - WKWebView Delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = navigationAction.request;
    if ([[[request URL] scheme] isEqualToString:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    if (urlOpenedCallback != nil) {
        urlOpenedCallback([request URL]);
    }

    decisionHandler(WKNavigationActionPolicyCancel);
}

#pragma mark -  WKScriptMessageHandler
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {

    if ([message.body isEqualToString:@"subscribe"]) {
        if (subscribeCallback != nil) {
            subscribeCallback();
            return;
        }

        [CleverPush subscribe:^(NSString* subscriptionId) {
            // wait for ID
            [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
                if (subscriptionId == nil) {
                    [CPLog debug:@"CPChatView: didReceiveScriptMessage: There is no subscription for CleverPush SDK."];
                }
                [self loadChat];
            }];
        }];
    } else if ([message.body isEqualToString:@"reload"]) {
        if (lastSubscriptionId != nil) {
            [self loadChatWithSubscriptionId:lastSubscriptionId];
        } else {
            [self loadChat];
        }
    }
}

#pragma mark - Clear webview cache memory
- (void)clearWKWebViewCache {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        NSSet *commonDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]];
        NSSet *websiteDataTypes;

        if (@available(iOS 11.3, *)) {
            websiteDataTypes = [commonDataTypes setByAddingObjectsFromArray:@[WKWebsiteDataTypeFetchCache, WKWebsiteDataTypeServiceWorkerRegistrations]];
        } else {
            websiteDataTypes = commonDataTypes;
        }

        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{}];
    });
}

#pragma mark - Chatview color get and set methods.
- (void)setChatBackgroundColor:(UIColor *)color {
    chatBackgroundColor = color;
}

- (void)setChatSendButtonBackgroundColor:(UIColor *)color {
    chatSendButtonBackgroundColor = color;
}

- (void)setChatSenderBubbleTextColor:(UIColor *)color {
    chatSenderBubbleTextColor = color;
}

- (void)setChatInputTextColor:(UIColor *)color {
    chatInputTextColor = color;
}

- (void)setChatInputBackgroundColor:(UIColor *)color {
    chatInputBackgroundColor = color;
}

- (void)setChatReceiverBubbleBackgroundColor:(UIColor *)color {
    chatReceiverBubbleBackgroundColor = color;
}

- (void)setChatInputContainerBackgroundColor:(UIColor *)color {
    chatInputContainerBackgroundColor = color;
}

- (void)setChatTimestampTextColor:(UIColor *)color {
    chatTimestampTextColor = color;
}

- (void)setChatReceiverBubbleTextColor:(UIColor *)color {
    chatReceiverBubbleTextColor = color;
}

- (void)setChatSenderBubbleBackgroundColor:(UIColor *)color {
    chatSenderBubbleBackgroundColor = color;
}

- (UIColor*)getChatBackgroundColor {
    return chatBackgroundColor;
}

- (UIColor*)getChatSenderBubbleTextColor {
    return chatSenderBubbleTextColor;
}

- (UIColor*)getChatSendButtonBackgroundColor {
    return chatSendButtonBackgroundColor;
}

- (UIColor*)getChatInputTextColor {
    return chatInputTextColor;
}

- (UIColor*)getChatInputBackgroundColor {
    return chatInputBackgroundColor;
}

- (UIColor*)getChatReceiverBubbleBackgroundColor {
    return chatReceiverBubbleBackgroundColor;
}

- (UIColor*)getChatInputContainerBackgroundColor {
    return chatInputContainerBackgroundColor;
}

- (UIColor*)getChatTimestampTextColor {
    return chatTimestampTextColor;
}

- (UIColor*)getChatReceiverBubbleTextColor {
    return chatReceiverBubbleTextColor;
}

- (UIColor*)getChatSenderBubbleBackgroundColor {
    return chatSenderBubbleBackgroundColor;
}

@end
