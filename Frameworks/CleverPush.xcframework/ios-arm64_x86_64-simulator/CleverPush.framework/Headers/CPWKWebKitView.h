#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPWKWebKitView : WKWebView
- (void)setHTMLContent:(NSString*)content;

@end

NS_ASSUME_NONNULL_END
