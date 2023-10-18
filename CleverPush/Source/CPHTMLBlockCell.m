#import "CPHTMLBlockCell.h"
#import "CleverPush.h"

@implementation CPHTMLBlockCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.webConfiguration = [[WKWebViewConfiguration alloc] init];
    self.userController = [[WKUserContentController alloc] init];

    [self.userController addScriptMessageHandler:self name:@"close"];
    [self.userController addScriptMessageHandler:self name:@"closeBanner()"];
    [self.userController addScriptMessageHandler:self name:@"closeBanner();"];
    [self.userController addScriptMessageHandler:self name:@"CleverPush.closeBanner();"];
    [self.userController addScriptMessageHandler:self name:@"CleverPush.closeBanner()"];
    [self.userController addScriptMessageHandler:self name:@"subscribe"];
    [self.userController addScriptMessageHandler:self name:@"unsubscribe"];
    [self.userController addScriptMessageHandler:self name:@"closeBanner"];
    [self.userController addScriptMessageHandler:self name:@"trackEvent"];
    [self.userController addScriptMessageHandler:self name:@"setSubscriptionAttribute"];
    [self.userController addScriptMessageHandler:self name:@"addSubscriptionTag"];
    [self.userController addScriptMessageHandler:self name:@"removeSubscriptionTag"];
    [self.userController addScriptMessageHandler:self name:@"setSubscriptionTopics"];
    [self.userController addScriptMessageHandler:self name:@"addSubscriptionTopic"];
    [self.userController addScriptMessageHandler:self name:@"removeSubscriptionTopic"];
    [self.userController addScriptMessageHandler:self name:@"showTopicsDialog"];
    [self.userController addScriptMessageHandler:self name:@"trackClick"];
    [self.userController addScriptMessageHandler:self name:@"openWebView"];
    self.webConfiguration.userContentController = self.userController;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)composeHTML:(NSString*)content {

    if ([content containsString:@"</body>"]) {
        content = [content stringByReplacingOccurrencesOfString:@"</body>" withString:@""];
    }
    if ([content containsString:@"</html>"]) {
        content = [content stringByReplacingOccurrencesOfString:@"</html>" withString:@""];
    }

    NSString *script = @"\
    <script>\
        /*function onCloseClick() {\
            try {\
                window.webkit.messageHandlers.close.postMessage(null);\
            } catch (error) {\
                console.log('Caught error on closeBTN click', error);\
            }\
        }\
        var closeElements = document.getElementsByTagName(\"*\");\
        for (var i = 0, len = closeElements.length; i < len; i++) {\
            var item = closeElements[i];\
            if (item.id && item.id.indexOf && item.id.indexOf(\"close\") == 0 || item.className && item.className.indexOf && item.className.indexOf(\"close\") == 0) {\
                item.addEventListener('click', onCloseClick);\
            }\
        }*/\
        if (typeof window.CleverPush === 'undefined') {\
            window.CleverPush = {};\
        }\
        window.CleverPush.subscribe = function subscribe() {\
            window.webkit.messageHandlers.subscribe.postMessage(null);\
        };\
        window.CleverPush.unsubscribe = function unsubscribe() {\
            window.webkit.messageHandlers.unsubscribe.postMessage(null);\
        };\
        window.CleverPush.closeBanner = function closeBanner() {\
            window.webkit.messageHandlers.closeBanner.postMessage(null);\
        };\
        window.CleverPush.trackEvent = function trackEvent(ID, properties) {\
            window.webkit.messageHandlers.trackEvent.postMessage({ eventId: ID, properties: properties });\
        };\
        window.CleverPush.setSubscriptionAttribute = function setSubscriptionAttribute(attributeId, value) {\
            window.webkit.messageHandlers.setSubscriptionAttribute.postMessage({ attributeKey: attributeId, attributeValue: value });\
        };\
        window.CleverPush.addSubscriptionTag = function addSubscriptionTag(tagId) {\
            window.webkit.messageHandlers.addSubscriptionTag.postMessage(tagId);\
        };\
        window.CleverPush.removeSubscriptionTag = function removeSubscriptionTag(tagId) {\
            window.webkit.messageHandlers.removeSubscriptionTag.postMessage(tagId);\
        };\
        window.CleverPush.setSubscriptionTopics = function setSubscriptionTopics(topicIds) {\
            window.webkit.messageHandlers.setSubscriptionTopics.postMessage(topicIds);\
        };\
        window.CleverPush.addSubscriptionTopic = function addSubscriptionTopic(topicId) {\
            window.webkit.messageHandlers.addSubscriptionTopic.postMessage(topicId);\
        };\
        window.CleverPush.removeSubscriptionTopic = function removeSubscriptionTopic(topicId) {\
            window.webkit.messageHandlers.removeSubscriptionTopic.postMessage(topicId);\
        };\
        window.CleverPush.showTopicsDialog = function showTopicsDialog() {\
            window.webkit.messageHandlers.showTopicsDialog.postMessage(null);\
        };\
        window.CleverPush.openWebView = function openWebView(url) {\
            window.webkit.messageHandlers.openWebView.postMessage(url);\
        };\
        window.CleverPush.trackClick = function trackClick(ID, properties) {\
            window.webkit.messageHandlers.trackClick.postMessage({ buttonId: ID, properties: properties });\
        };\
    </script>";

    NSString *closingBodyHtmlTag = @"</body></html>";
    NSString *scriptSource = [NSString stringWithFormat: @"%@%@%@", content, script, closingBodyHtmlTag];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *headerString = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>";
        [self.webHTMLBlock loadHTMLString:[headerString stringByAppendingString:scriptSource] baseURL:nil];
    });

    self.webHTMLBlock = [[WKWebView alloc] initWithFrame:CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.frame.size.width, self.contentView.frame.size.height) configuration:self.webConfiguration];
    
    [self.contentView addSubview:self.webHTMLBlock];

}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if (message != nil && message.body != nil && message.name != nil) {
        if ([message.name isEqualToString:@"close"] || ([message.name isEqualToString:@"closeBanner"])) {
            UIViewController *top = [UIApplication sharedApplication].keyWindow.rootViewController;
            [top dismissViewControllerAnimated:YES completion:nil];
        } else if ([message.name isEqualToString:@"subscribe"]) {
            [CleverPush subscribe];
        } else if ([message.name isEqualToString:@"unsubscribe"]) {
            [CleverPush unsubscribe];
        } else if ([message.name isEqualToString:@"trackEvent"]) {
            [CleverPush trackEvent:[message.body objectForKey:@"eventId"] properties:[message.body objectForKey:@"properties"]];
        } else if ([message.name isEqualToString:@"setSubscriptionAttribute"]) {
            [CleverPush setSubscriptionAttribute:[message.body objectForKey:@"attributeKey"] value:[message.body objectForKey:@"attributeValue"]];
        } else if ([message.name isEqualToString:@"addSubscriptionTag"]) {
            [CleverPush addSubscriptionTag:message.body];
        } else if ([message.name isEqualToString:@"removeSubscriptionTag"]) {
            [CleverPush removeSubscriptionTag:message.body];
        } else if ([message.name isEqualToString:@"setSubscriptionTopics"]) {
            [CleverPush setSubscriptionTopics:message.body];
        } else if ([message.name isEqualToString:@"addSubscriptionTopic"]) {
            [CleverPush addSubscriptionTopic:message.body];
        } else if ([message.name isEqualToString:@"removeSubscriptionTopic"]) {
            [CleverPush removeSubscriptionTopic:message.body];
        } else if ([message.name isEqualToString:@"showTopicsDialog"]) {
            [CleverPush showTopicsDialog];
        } else if ([message.name isEqualToString:@"trackClick"]) {
            CPAppBannerAction* action;
            NSMutableDictionary *buttonBlockDic = [[NSMutableDictionary alloc] init];
            buttonBlockDic = [message.body mutableCopy];
            buttonBlockDic[@"bannerAction"] = @"type";
            action = [[CPAppBannerAction alloc] initWithJson:buttonBlockDic];
            [self actionCallback:action];
        } else if ([message.name isEqualToString:@"openWebView"]) {
            NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", message.body]];
            if (webUrl && webUrl.scheme && webUrl.host) {
                [CPUtils openSafari:webUrl dismissViewController:CleverPush.topViewController];
            }
        }
    }
}

#pragma mark - Callback event for tracking clicks
- (void)actionCallback:(CPAppBannerAction*)action{
    self.actionCallback(action);
}


@end
