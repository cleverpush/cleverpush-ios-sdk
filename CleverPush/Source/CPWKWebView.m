#import "CPWKWebView.h"

@interface CPWKWebView () <WKNavigationDelegate, WKUIDelegate>
@end

@implementation CPWKWebView

CPStoryViewOpenedBlock urlOpenedListener;

- (void)loadRequest:(NSURLRequest *)request withCompletionHandler:(WebViewFinishLoadBlock)completionHandler
{
    self.navigationDelegate = self;
    self.webViewFinishLoadBlock = completionHandler;
    [self loadRequest:request];
}

- (void)loadHTML:(NSString *)request withCompletionHandler:(WebViewFinishLoadBlock)completionHandler
{
    self.navigationDelegate = self;
    self.webViewFinishLoadBlock = completionHandler;
    NSString *headerString = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>";
    [self loadHTMLString:[headerString stringByAppendingString:request] baseURL:nil];
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (navigationAction.request.URL) {
            if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
                if (urlOpenedListener != nil) {
                    urlOpenedListener(navigationAction.request.URL,nil);
                } else {
                    [CPUtils openSafari:navigationAction.request.URL];
                }
                decisionHandler(WKNavigationActionPolicyCancel);
            } else {
                decisionHandler(WKNavigationActionPolicyAllow);
            }
        }
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - Track the storyview callback listener
- (void)setUrlOpenedCallback:(CPStoryViewOpenedBlock)urlOpenedBlock {
    urlOpenedListener = urlOpenedBlock;
}

@end
