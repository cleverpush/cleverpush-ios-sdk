#import <WebKit/WebKit.h>
#import "CPUtils.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^ __nullable WebViewFinishLoadBlock)(WKWebView *, NSError *);

@interface CPWKWebView : WKWebView

@property(nonatomic, copy) WebViewFinishLoadBlock webViewFinishLoadBlock;

- (void)loadRequest:(NSURLRequest *)request withCompletionHandler:(WebViewFinishLoadBlock)completionHandler;
- (void)loadHTML:(NSString *)request withCompletionHandler:(WebViewFinishLoadBlock)completionHandler;

@end
NS_ASSUME_NONNULL_END
