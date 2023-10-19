#import "CPBannerCardContainer.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPUIBlockButton.h"
#import "CPButtonBlockCell.h"
#import "UIColor+HexString.h"
#import "CPTextBlockCell.h"
#import "CPAppBannerViewController.h"
#import "CPHTMLBlockCell.h"
#import "CPAppBannerCarouselBlock.h"
#import "CPLog.h"
#import "CPInboxDetailContainer.h"

@implementation CPInboxDetailContainer
@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tblCPBanner.delegate = self;
    self.tblCPBanner.dataSource = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self backgroundPopupShadow];
        [self setBackground];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.blocks == nil || self.blocks.count == 0) {
        return 0;
    }
    return self.blocks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeImage) {
        CPImageBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPImageBlockCell" forIndexPath:indexPath];
        CPAppBannerImageBlock *block = (CPAppBannerImageBlock*)self.blocks[indexPath.row];

        if (block.imageWidth > 0 && block.imageHeight > 0) {
            CGFloat aspectRatio = block.imageWidth / block.imageHeight;
            if (isnan(aspectRatio) || aspectRatio == 0.0) {
                aspectRatio = 1.0;
            }
            cell.imgCPBannerHeightConstraint.constant = (cell.contentView.frame.size.width / aspectRatio) * (block.scale / 100.0);
        }

        NSString *imageUrl;
        if ([self.data darkModeEnabled:self.tblCPBanner.traitCollection] && block.darkImageUrl != nil) {
            imageUrl = block.darkImageUrl;
        } else {
            imageUrl = block.imageUrl;
        }

        if (imageUrl != nil && ![imageUrl isKindOfClass:[NSNull class]]) {
            cell.activitydata.transform = CGAffineTransformMakeScale(1, 1);
            [cell.activitydata startAnimating];
            [cell.imgCPBanner setImageWithURL:[NSURL URLWithString:imageUrl]callback:^(BOOL callback) {
                if (callback) {
                    [UIView performWithoutAnimation:^{
                        [cell setNeedsLayout];
                        [cell layoutIfNeeded];
                        [tableView beginUpdates];
                        [tableView endUpdates];
                        [cell.activitydata stopAnimating];
                    }];
                }
            }];
        }
        return  cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeButton) {
        CPButtonBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPButtonBlockCell" forIndexPath:indexPath];

        CPAppBannerButtonBlock *block = (CPAppBannerButtonBlock*)self.blocks[indexPath.row];

        [cell.btnCPBanner setTitle:block.text forState:UIControlStateNormal];

        UIColor *titleColor;
        if ([self.data darkModeEnabled:self.tblCPBanner.traitCollection] && block.darkColor != nil) {
            titleColor = [UIColor colorWithHexString:block.darkColor];
        } else {
            titleColor = [UIColor colorWithHexString:block.color];
        }
        [cell.btnCPBanner setTitleColor:titleColor forState:UIControlStateNormal];

        CGFloat fontSize = (CGFloat)(block.size) * 1.2;
        if ([CPUtils fontFamilyExists:block.family]) {
            [cell.btnCPBanner.titleLabel setFont:[UIFont fontWithName:block.family size:fontSize]];
        } else {
            if (block.family != nil) {
                [CPLog error:@"Font Family not found for button block: %@", block.family];
            }
            [cell.btnCPBanner.titleLabel setFont:[UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold]];
        }

        switch (block.alignment) {
            case CPAppBannerAlignmentRight:
                cell.btnCPBanner.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                break;
            case CPAppBannerAlignmentLeft:
                cell.btnCPBanner.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                break;
            case CPAppBannerAlignmentCenter:
                cell.btnCPBanner.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                break;
        }

        UIColor *backgroundColor;
        if ([self.data darkModeEnabled:self.tblCPBanner.traitCollection] && block.darkBackground != nil) {
            backgroundColor = [UIColor colorWithHexString:block.darkBackground];
        } else {
            backgroundColor = [UIColor colorWithHexString:block.background];
        }
        cell.btnCPBanner.backgroundColor = backgroundColor;

        CGSize maxSize = CGSizeMake(cell.btnCPBanner.frame.size.width - (15.0 * 2), CGFLOAT_MAX);
        CGRect titleRect = [block.text boundingRectWithSize:maxSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: cell.btnCPBanner.titleLabel.font}
                                                     context:nil];
        CGFloat titleHeight = ceil(titleRect.size.height);
        titleHeight = titleHeight + 10;

        cell.btnCPBanner.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0);
        cell.btnCPBanner.translatesAutoresizingMaskIntoConstraints = false;
        cell.btnCPBanner.layer.cornerRadius = (CGFloat)block.radius * 0.6;
        cell.btnCPBanner.adjustsImageWhenHighlighted = YES;
        cell.btnCPBanner.titleLabel.numberOfLines = 0;
        cell.btnCPBanner.titleLabel.textAlignment = NSTextAlignmentCenter;
        cell.btnCPBannerHeightConstraint.constant = titleHeight;
        [cell.btnCPBanner setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

        [cell.btnCPBanner handleControlEvent:UIControlEventTouchUpInside withBlock:^{
            [self actionCallback:block.action from:YES];
        }];
        return cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeText) {
        CPTextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPTextBlockCell" forIndexPath:indexPath];
        CPAppBannerTextBlock *block = (CPAppBannerTextBlock*) self.blocks[indexPath.row];

        cell.txtCPBanner.text = block.text;
        cell.txtCPBanner.numberOfLines = 0;

        UIColor *textColor;
        if ([self.data darkModeEnabled:self.tblCPBanner.traitCollection] && block.darkColor != nil) {
            textColor = [UIColor colorWithHexString:block.darkColor];
        } else {
            textColor = [UIColor colorWithHexString:block.color];
        }
        cell.txtCPBanner.textColor = textColor;

        CGFloat fontSize = (CGFloat)(block.size) * 1.2;
        if ([CPUtils fontFamilyExists:block.family]) {
            [cell.txtCPBanner setFont:[UIFont fontWithName:block.family size:fontSize]];
        } else {
            if (block.family != nil) {
                [CPLog error:@"Font Family not found for text block: %@", block.family];
            }
            [cell.txtCPBanner setFont:[UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold]];
        }

        [cell.txtCPBanner setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        cell.txtCPBanner.translatesAutoresizingMaskIntoConstraints = false;
        switch (block.alignment) {
            case CPAppBannerAlignmentRight:
                cell.txtCPBanner.textAlignment = NSTextAlignmentRight;
                break;
            case CPAppBannerAlignmentLeft:
                cell.txtCPBanner.textAlignment = NSTextAlignmentLeft;
                break;
            case CPAppBannerAlignmentCenter:
                cell.txtCPBanner.textAlignment = NSTextAlignmentCenter;
                break;
        }
        return cell;
    } else {
        CPHTMLBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPHTMLBlockCell" forIndexPath:indexPath];
        CPAppBannerHTMLBlock *block = (CPAppBannerHTMLBlock*)self.blocks[indexPath.row];

        cell.webConfiguration = [[WKWebViewConfiguration alloc] init];
        cell.userController = [[WKUserContentController alloc] init];

        [cell.userController addScriptMessageHandler:self name:@"close"];
        [cell.userController addScriptMessageHandler:self name:@"subscribe"];
        [cell.userController addScriptMessageHandler:self name:@"unsubscribe"];
        [cell.userController addScriptMessageHandler:self name:@"closeBanner"];
        [cell.userController addScriptMessageHandler:self name:@"trackEvent"];
        [cell.userController addScriptMessageHandler:self name:@"setSubscriptionAttribute"];
        [cell.userController addScriptMessageHandler:self name:@"addSubscriptionTag"];
        [cell.userController addScriptMessageHandler:self name:@"removeSubscriptionTag"];
        [cell.userController addScriptMessageHandler:self name:@"setSubscriptionTopics"];
        [cell.userController addScriptMessageHandler:self name:@"addSubscriptionTopic"];
        [cell.userController addScriptMessageHandler:self name:@"removeSubscriptionTopic"];
        [cell.userController addScriptMessageHandler:self name:@"showTopicsDialog"];
        [cell.userController addScriptMessageHandler:self name:@"trackClick"];
        [cell.userController addScriptMessageHandler:self name:@"openWebView"];
        cell.webConfiguration.userContentController = cell.userController;

        if (block.content != nil && ![block.content isKindOfClass:[NSNull class]]) {
            cell.webHTMLBlock.scrollView.scrollEnabled = false;
            cell.webHTMLBlock.scrollView.bounces = false;
            cell.webHTMLBlock.opaque = false;
            cell.webHTMLBlock.backgroundColor = UIColor.clearColor;
            cell.webHTMLBlock.scrollView.backgroundColor = UIColor.clearColor;
            cell.webHTMLBlock.allowsBackForwardNavigationGestures = false;
            cell.webHTMLBlock.contentMode = UIViewContentModeScaleToFill;
            cell.webHTMLBlock.layer.cornerRadius = 15.0;
            cell.webHTMLBlock.navigationDelegate = self;

            if ([block.content containsString:@"</body>"]) {
                block.content = [block.content stringByReplacingOccurrencesOfString:@"</body>" withString:@""];
            }
            if ([block.content containsString:@"</html>"]) {
                block.content = [block.content stringByReplacingOccurrencesOfString:@"</html>" withString:@""];
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
            NSString *scriptSource = [NSString stringWithFormat: @"%@%@%@", block.content, script, closingBodyHtmlTag];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *headerString = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>";
                [cell.webHTMLBlock loadHTMLString:[headerString stringByAppendingString:scriptSource] baseURL:nil];
            });

            cell.webHTMLBlock = [[WKWebView alloc] initWithFrame:CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.frame.size.width, self.contentView.frame.size.height) configuration:cell.webConfiguration];
            [cell.contentView addSubview:cell.webHTMLBlock];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeImage) {
        CPAppBannerImageBlock *block = (CPAppBannerImageBlock*)self.blocks[indexPath.row];
        [self actionCallback:block.action from:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeHTML) {
        CPAppBannerHTMLBlock *block = (CPAppBannerHTMLBlock*)self.blocks[indexPath.row];
        return block.height;
    } else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if (message != nil && message.body != nil && message.name != nil) {
        if ([message.name isEqualToString:@"close"] || ([message.name isEqualToString:@"closeBanner"])) {
            UIViewController* topController = [CleverPush topViewController];
            [topController dismissViewControllerAnimated:YES completion:nil];
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
            [self actionCallback:action from:YES];
        } else if ([message.name isEqualToString:@"openWebView"]) {
            NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", message.body]];
            if (webUrl && webUrl.scheme && webUrl.host) {
                [CPUtils openSafari:webUrl dismissViewController:CleverPush.topViewController];
            }
        }
    }
}

- (void)actionCallback:(CPAppBannerAction*)action from:(BOOL)buttonBlock {
    self.actionCallback(action);
    if (action.openInWebview) {
        if (action.dismiss) {
            [CPUtils openSafari:action.url dismissViewController:self.controller];
        } else {
            [CPUtils openSafari:action.url];
        }
    } else if (![action.screen isEqualToString:@""] && action.screen != nil) {
        if (self.data.multipleScreensEnabled) {
            [self.changePage navigateToNextPage:action.screen];
        } else {
            [self onDismiss];
        }
    } else if (action.dismiss) {
        [self onDismiss];
        [CPAppBannerModule showNextActivePendingBanner:self.data];
    } else {
        if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
            [self.changePage navigateToNextPage];
        }
    }
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.controller dismissViewControllerAnimated:NO completion:nil];
    });
}

#pragma mark - setting up the popup shadow
- (void)backgroundPopupShadow {
    if (self.data.type != CPAppBannerTypeFull) {
        float shadowSize = 10.0f;
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(self.viewBannerCardContainer.frame.origin.x - shadowSize / 2, self.viewBannerCardContainer.frame.origin.y - shadowSize / 2, self.viewBannerCardContainer.frame.size.width + shadowSize, self.viewBannerCardContainer.frame.size.height + shadowSize)];
        self.viewBannerCardContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.viewBannerCardContainer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.viewBannerCardContainer.layer.shadowOpacity = 0.8f;
        self.viewBannerCardContainer.layer.shadowPath = shadowPath.CGPath;
        [self.viewBannerCardContainer.layer setCornerRadius:15.0];
        [self.viewBannerCardContainer.layer setMasksToBounds:YES];
    }
}

#pragma mark - setup background image
- (void)setBackground {
    [self.imgviewBackground setContentMode:UIViewContentModeScaleAspectFill];

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkImageUrl != nil && ![self.data.background.darkImageUrl isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.darkColor]];
        return;
    }

    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]] && ![self.data.background.imageUrl isEqualToString:@""]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
}

@end
