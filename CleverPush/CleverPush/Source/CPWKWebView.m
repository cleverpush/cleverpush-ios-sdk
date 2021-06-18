#import "CPWKWebView.h"

@interface CPWKWebView () <WKNavigationDelegate, WKUIDelegate>
@end

@implementation CPWKWebView

- (void)loadRequest:(NSURLRequest *)request withCompletionHandler:(WebViewFinishLoadBlock)completionHandler
{
    self.navigationDelegate = self;
    self.webViewFinishLoadBlock = completionHandler;
    [self loadRequest:request];
}

#pragma mark WKWebView methods
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (self.webViewFinishLoadBlock) {
            self.webViewFinishLoadBlock(webView, error);
            self.webViewFinishLoadBlock = nil;
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (self.webViewFinishLoadBlock) {
        self.webViewFinishLoadBlock(webView, error);
        self.webViewFinishLoadBlock = nil;
    }
}

@end

