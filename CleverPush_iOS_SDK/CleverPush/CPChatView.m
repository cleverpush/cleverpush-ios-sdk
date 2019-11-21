#import "CPChatView.h"
#import "CleverPush.h"

@interface CPChatView()

@end

@implementation CPChatView

CPChatURLOpenedCallback urlOpenedCallback;
CPChatSubscribeCallback subscribeCallback;
NSString* headerCodes;

- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.body isEqualToString:@"subscribe"]) {
        if (subscribeCallback != nil) {
            subscribeCallback();
            return;
        }
        
        [CleverPush subscribe:^(NSString* subscriptionId) {
            // wait for ID
            [CleverPush getSubscriptionId];
         
            [self loadChat];
        }];
    }
}

- (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

- (void)lockChat {
    [self loadChatWithSubscriptionId:@"preview"];
}

- (void)loadChat {
    NSString* subscriptionId;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    } else {
        subscriptionId = @"preview";
    }
    
    [self loadChatWithSubscriptionId:subscriptionId];
}

- (void)loadChatWithSubscriptionId:(NSString*)subscriptionId {
    NSString *content;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[CleverPush getChannelConfig]
                                                       options:0
                                                         error:&error];

    if (!jsonData) {
        content = [NSString stringWithFormat:@"Fehler: %@", error];
    } else {
        NSString* subscriptionId;
        if ([CleverPush isSubscribed]) {
            subscriptionId = [CleverPush getSubscriptionId];
        } else {
            subscriptionId = @"preview";
        }
        
        NSString* brandingColor;
        NSString* backgroundColor;
        if ([CleverPush getBrandingColor]) {
            brandingColor = [self hexStringFromColor:[CleverPush getBrandingColor]];
        }
        if ([CleverPush getChatBackgroundColor]) {
            backgroundColor = [self hexStringFromColor:[CleverPush getChatBackgroundColor]];
        }
        
        if (!headerCodes) {
            headerCodes = @"";
        }
        
        NSString *jsonConfig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        content = [NSString stringWithFormat:@"\
        <!DOCTYPE html>\
        <html>\
        <head>\
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>\
        <style>\
        html, body { margin: 0; padding: 0; height: 100%%; } \
        </style>\
        %@\
        </head>\
        <body>\
        <div class='cleverpush-chat-target' style='height: 100%%;'></div>\
        <script>document.documentElement.style.webkitUserSelect='none'; document.documentElement.style.webkitTouchCallout='none';</script>\
        <script>window.cleverpushHandleSubscribe = function() { window.webkit.messageHandlers.chat.postMessage(\"subscribe\") }</script>\
        <script>var cleverpushConfig = %@; var cleverpushSubscriptionId = '%@'; cleverpushConfig.nativeApp = true; cleverpushConfig.brandingColor = '%@'; cleverpushConfig.chatBackgroundColor = '%@';</script>\
        <script src='https://static.cleverpush.com/sdk/cleverpush-chat.js'></script>\
        </body>\
        </html>", headerCodes, jsonConfig, subscriptionId, brandingColor, backgroundColor];
    }
    
    NSLog(@"CleverPush: ChatView content: %@", content);
    
    [_webView loadHTMLString:content baseURL:[[NSBundle mainBundle] resourceURL]];
}

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

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController* userController = [[WKUserContentController alloc] init];

        [userController addScriptMessageHandler:self name:@"chat"];
        configuration.userContentController = userController;
        
        _webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
        _webView.scrollView.scrollEnabled = true;
        _webView.scrollView.bounces = false;
        _webView.allowsBackForwardNavigationGestures = false;
        _webView.contentMode = UIViewContentModeScaleToFill;
        [self loadChat];
        _webView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        _webView.navigationDelegate = self;
        [self addSubview:_webView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock {
    urlOpenedCallback = urlOpenedBlock;
    subscribeCallback = subscribeBlock;

    self = [self initWithFrame:frame];
    return self;
}

- (id)initWithFrame:(CGRect)frame urlOpenedCallback:(CPChatURLOpenedCallback)urlOpenedBlock subscribeCallback:(CPChatSubscribeCallback)subscribeBlock headerCodes:(NSString *)headerHtmlCodes {
    urlOpenedCallback = urlOpenedBlock;
    subscribeCallback = subscribeBlock;
    headerCodes = headerHtmlCodes;

    self = [self initWithFrame:frame urlOpenedCallback:urlOpenedBlock subscribeCallback:subscribeBlock];
    return self;
}

@end
