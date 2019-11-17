#import "CPChatView.h"
#import "CleverPush.h"

@interface CPChatView()

@end

@implementation CPChatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSString *content;
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[CleverPush getChannelConfig]
                                                           options:0
                                                             error:&error];

        if (!jsonData) {
            content = [NSString stringWithFormat:@"Fehler: %@", error];
        } else {
            NSString *jsonConfig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            content = [NSString stringWithFormat:@"\
            <!DOCTYPE html>\
            <html>\
            <head>\
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>\
            <style>\
            html, body { margin: 0; padding: 0; height: 100%%; } \
            </style>\
            </head>\
            <body>\
            <div class='cleverpush-chat-target' style='height: 100%%;'></div>\
            <script>document.documentElement.style.webkitUserSelect='none'; document.documentElement.style.webkitTouchCallout='none';</script>\
            <script>var cleverpushConfig = %@; var cleverpushSubscriptionId = '%@'; cleverpushConfig.nativeApp = true;</script>\
            <script src='https://static.cleverpush.com/sdk/cleverpush-chat.js?v=2'></script>\
            </body>\
            </html>", jsonConfig, [CleverPush getSubscriptionId]];
        }
        
        NSLog(@"CleverPush: WebView content: %@", content);
        
        _webView = [[WKWebView alloc] initWithFrame:frame];
        _webView.scrollView.scrollEnabled = true;
        _webView.scrollView.bounces = false;
        _webView.allowsBackForwardNavigationGestures = false;
        _webView.contentMode = UIViewContentModeScaleToFill;
        [_webView loadHTMLString:content baseURL:[[NSBundle mainBundle] resourceURL]];
        _webView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        [self addSubview:_webView];
    }
    return self;
}

@end
