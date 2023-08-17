#import "CPAppBannerViewController.h"
#import "CPLog.h"

@interface CPAppBannerViewController()
@end

@implementation CPAppBannerViewController

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.data == nil) {
        return;
    }

    if ([CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder] != nil && ([[CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder] objectForKey:self.data.id] != nil)) {
        self.voucherCode = [[CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder] objectForKey:self.data.id];
    }

    [self conditionalPresentation];
    [self setOrientation];
    self.popupHeight.constant = [CPUtils frameHeightWithoutSafeArea];
}

#pragma mark - Custom UI Functions
- (void)conditionalPresentation {
    if ([self.data.contentType isEqualToString:@"html"]) {
        [self initWithHTMLBanner:self.data];
        [self setContentVisibility:true];
        [self setDynamicBannerConstraints:NO];
    } else {
        [self initWithBanner:self.data];
        [self delagates];
        [self setContentVisibility:false];
        [self setDynamicBannerConstraints:self.data.marginEnabled];
        [self setDynamicCloseButton:NO];
    }
}

#pragma mark - dynamic hide and shows the layer of the view heirarchy.
- (void)setContentVisibility:(BOOL)isHtml {
    self.cardCollectionView.hidden = isHtml;
    self.backGroundImage.hidden = isHtml;
    self.bannerContainer.hidden = isHtml;
    self.btnClose.hidden = isHtml;
    self.pageControl.hidden = YES;
    self.webView.hidden = !isHtml;
}

#pragma mark - native delegates and registration of the nib.
- (void)delagates {
    NSBundle *bundle = [CPUtils getAssetsBundle];
    if (bundle) {
        [self.cardCollectionView registerNib:[UINib nibWithNibName:@"CPBannerCardContainer" bundle:bundle] forCellWithReuseIdentifier:@"CPBannerCardContainer"];
    }
    self.cardCollectionView.delegate = self;
    self.cardCollectionView.dataSource = self;
}

#pragma mark - setup background image
- (void)setBackground {
    [self.backGroundImage setContentMode:UIViewContentModeScaleAspectFill];

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkImageUrl != nil && ![self.data.background.darkImageUrl isKindOfClass:[NSNull class]]) {
        [self.backGroundImage setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.background.darkColor]];
        return;
    }

    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]] && ![self.data.background.imageUrl isEqualToString:@""]) {
        [self.backGroundImage setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
}

#pragma mark - setting up the popup shadow
- (void)backgroundPopupShadow {
    float shadowSize = 10.0f;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(self.bannerContainer.frame.origin.x - shadowSize / 2, self.bannerContainer.frame.origin.y - shadowSize / 2, self.bannerContainer.frame.size.width + shadowSize, self.bannerContainer.frame.size.height + shadowSize)];
    self.bannerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bannerContainer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.bannerContainer.layer.shadowOpacity = 0.8f;
    self.bannerContainer.layer.shadowPath = shadowPath.CGPath;
}

#pragma mark - set layout orientation
- (void)setOrientation {
    if (self.data.type == CPAppBannerTypeTop) {
        [self bannerPosition:YES bottom:NO center:NO];
    } else if (self.data.type == CPAppBannerTypeCenter) {
        [self bannerPosition:NO bottom:NO center:YES];
    } else if (self.data.type == CPAppBannerTypeBottom) {
        [self bannerPosition:NO bottom:YES center:NO];
    } else {
        [self setBackgroundColor];
        [self bannerPosition:YES bottom:YES center:YES];
    }
}

#pragma mark - set dynamic constraints based on the layout conditional presentation
- (void)setDynamicBannerConstraints:(BOOL)marginEnabled {
    if (self.data.type == CPAppBannerTypeTop || self.data.type == CPAppBannerTypeCenter || self.data.type == CPAppBannerTypeBottom) {
        [self setAppBannerWithMargin];
    } else {
        if (marginEnabled) {
            [self setAppBannerWithMargin];
        } else {
            [self setAppBannerWithoutMargin];
        }
    }
}

#pragma mark - dynamic hide and show top button from top right corner
- (void)setDynamicCloseButton:(BOOL)closeButtonEnabled {
    UIColor *backgroundColor;
    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        backgroundColor = [UIColor colorWithHexString:self.data.background.darkColor];
    } else {
        backgroundColor = [UIColor colorWithHexString:self.data.background.color];
    }
    UIColor *color = [CPUtils readableForegroundColorForBackgroundColor:backgroundColor];

    if (@available(iOS 13.0, *)) {
        [self.btnClose setImage:[UIImage systemImageNamed:@"multiply"] forState:UIControlStateNormal];
        self.btnClose.tintColor = color;
    } else {
        [self.btnClose setTitle:@"X" forState:UIControlStateNormal];
        [self.btnClose setTitleColor:color forState:UIControlStateNormal];
    }

    [self.btnClose.layer setMasksToBounds:false];
    if (closeButtonEnabled) {
        self.btnClose.hidden = NO;
    } else {
        self.btnClose.hidden = YES;
    }
}

#pragma mark - set app banner with margin
- (void)setAppBannerWithMargin {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat topPadding = 0;
    if (@available(iOS 11.0, *)) {
        topPadding = window.safeAreaInsets.top;
        self.topConstraint.constant = topPadding;
    }
    self.bottomConstraint.constant = 34;
    self.leadingConstraint.constant = 25;
    self.trailingConstraint.constant = -25;
    [self.bannerContainer.layer setCornerRadius:15.0];
    [self.bannerContainer.layer setMasksToBounds:YES];
    self.pageControllTopConstraint.constant = - 20;
    self.btnTopConstraints.constant = 0;
}

#pragma mark - set app banner without margin padding from all of the edges will be zero
- (void)setAppBannerWithoutMargin {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    if (@available(iOS 11.0, *)) {
        CGFloat topPadding = window.safeAreaInsets.top;
        CGFloat bottomPadding = window.safeAreaInsets.bottom + 20;
        self.leadingConstraint.constant = 0;
        self.trailingConstraint.constant = 0;
        [self.bannerContainer.layer setCornerRadius:0.0];
        [self.bannerContainer.layer setMasksToBounds:YES];
        self.pageControllTopConstraint.constant = - bottomPadding;
        self.btnTopConstraints.constant = topPadding;
    }
}

#pragma mark - activate and deativate constraints based on the layout type
- (void)bannerPosition:(BOOL)top bottom:(BOOL)bottom center:(BOOL)center {
    self.topConstraint.active = top;
    self.bottomConstraint.active = bottom;
    self.centerYConstraint.active = center;
}

- (void)setUpPageControl {
    if (self.data.carouselEnabled == true) {
        [self.pageControl setNumberOfPages:self.data.screens.count];
        [self.cardCollectionView setScrollEnabled:true];
    } else {
        [self.pageControl setNumberOfPages:0];
        [self.cardCollectionView setScrollEnabled:false];
    }
}

#pragma mark - Set background color
- (void)setBackgroundColor {
    [self.view setBackgroundColor:[UIColor whiteColor]];

    if (self.data.background.color != nil && ![self.data.background.color isKindOfClass:[NSNull class]] && ![self.data.background.color isEqualToString:@""] ) {
        [self.view setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
    }
}

#pragma mark - custom delegate manage tableview constraint size based on it's content size and based on conditional
- (void)manageTableHeightDelegate:(CGSize)value {
    if (value.height > UIScreen.mainScreen.bounds.size.height) {
        self.popupHeight.constant = [CPUtils frameHeightWithoutSafeArea];
    } else {
        self.popupHeight.constant = value.height + 20;
        if (self.data.closeButtonEnabled && self.data.closeButtonPositionStaticEnabled) {
            self.popupHeight.constant = value.height + 60;
        }
        [self.cardCollectionView layoutIfNeeded];
    }
}

#pragma mark - Initialise blocks banner
- (void)initWithBanner:(CPAppBanner*)banner {
    self.data = banner;
}

#pragma mark - Initialise HTML banner
- (void)initWithHTMLBanner:(CPAppBanner*)banner {
    self.data = banner;
    if (self.voucherCode != nil && ![self.voucherCode isKindOfClass:[NSNull class]] && ![self.voucherCode isEqualToString:@""]) {
        [self composeHTML:[CPUtils replaceString:@"{voucherCode}" withReplacement:self.voucherCode inString:self.data.HTMLContent]];

    } else {
        [self composeHTML:self.data.HTMLContent];
    }
}

#pragma mark - Update the UI while the device detects rotation.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.cardCollectionView.collectionViewLayout invalidateLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.cardCollectionView performBatchUpdates:^{
            [self.cardCollectionView reloadData];
        } completion:nil];
    }];
}

#pragma mark - CollectionView Delegate and DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.data.screens.count == 0) {
        return 1;
    } else {
        return self.data.screens.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPBannerCardContainer *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPBannerCardContainer" forIndexPath:indexPath];
    cell.data = self.data;
    [cell setActionCallback:self.actionCallback];

    if (self.voucherCode != nil && ![self.voucherCode isKindOfClass:[NSNull class]] && ![self.voucherCode isEqualToString:@""]) {
        cell.voucherCode = self.voucherCode;
    }

    if ((!self.data.carouselEnabled && !self.data.multipleScreensEnabled) || self.data.screens.count == 0) {
        cell.blocks = self.data.blocks;
    } else {
        cell.blocks = self.data.screens[indexPath.item].blocks;
    }
    NSBundle *bundle = [CPUtils getAssetsBundle];
    if (bundle) {
        [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPImageBlockCell" bundle:bundle] forCellReuseIdentifier:@"CPImageBlockCell"];
        [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPTextBlockCell" bundle:bundle] forCellReuseIdentifier:@"CPTextBlockCell"];
        [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPButtonBlockCell" bundle:bundle] forCellReuseIdentifier:@"CPButtonBlockCell"];
        [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPHTMLBlockCell" bundle:bundle] forCellReuseIdentifier:@"CPHTMLBlockCell"];
    }

    cell.delegate = self;
    cell.changePage = self;
    cell.controller = self;
    [cell.tblCPBanner reloadData];
    [cell setDynamicCloseButton:self.data.closeButtonEnabled];
    [cell setUpPageControl];

    cell.topViewBannerConstraint.priority = UILayoutPriorityDefaultLow;
    cell.bottomViewBannerConstraint.priority = UILayoutPriorityDefaultLow;
    cell.centerViewBannerConstraint.priority = UILayoutPriorityDefaultLow;
    if (self.data.type == CPAppBannerTypeTop) {
        cell.topViewBannerConstraint.priority = UILayoutPriorityDefaultHigh;
    } else if (self.data.type == CPAppBannerTypeCenter) {
        cell.centerViewBannerConstraint.priority = UILayoutPriorityDefaultHigh;
    } else if (self.data.type == CPAppBannerTypeBottom) {
        cell.bottomViewBannerConstraint.priority = UILayoutPriorityDefaultHigh;
    } else {
        cell.topViewBannerConstraint.priority = UILayoutPriorityDefaultHigh;
        cell.bottomViewBannerConstraint.priority = UILayoutPriorityDefaultHigh;
    }

    [cell.tblCPBanner layoutIfNeeded];
    [cell.tblCPBanner updateConstraintsIfNeeded];
    [cell layoutIfNeeded];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    [((CPBannerCardContainer *)cell).tblCPBanner reloadData];
    [cell layoutIfNeeded];
}

#pragma mark - custom delegate when tapped on a button and it's action has been set to navigate on a next screen
- (void)navigateToNextPage {
    NSIndexPath *nextItem = [NSIndexPath indexPathForItem:self.index + 1 inSection:0];
    if (nextItem.row < self.data.screens.count) {
        [self.cardCollectionView scrollToItemAtIndexPath:nextItem atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        self.pageControl.currentPage = self.index + 1;
        [self pageControlCurrentIndex: self.index + 1];
    }
}

#pragma mark - custom delegate when tapped on a button and it's action has been set to navigate on a next screen and carousel is disabled.
- (void)navigateToNextPage:(NSString *)value {
    for (int i = 0; i < self.data.screens.count; i++) {
        CPAppBannerCarouselBlock *item = [self.data.screens objectAtIndex:i];
        if ([item.id isEqualToString:value]) {
            NSIndexPath *nextItem = [NSIndexPath indexPathForItem:i inSection:0];
            if (nextItem.row < self.data.screens.count) {
                CGRect rect = [self.cardCollectionView layoutAttributesForItemAtIndexPath:nextItem].frame;
                [self.cardCollectionView scrollRectToVisible:rect animated:NO];
                self.pageControl.currentPage = i;
                [self pageControlCurrentIndex: i];
                break;
            }
        }
    }
}

#pragma mark - Set the value of pageControl from current index
-(void)pageControlCurrentIndex:(NSInteger)value {
    NSDictionary *pagevalue = @{@"currentIndex": @(value)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"getCurrentAppBannerPageIndexValue" object:nil userInfo:pagevalue];
}

#pragma mark - UIScrollViewDelegate for UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.cardCollectionView.frame.size.width;
    float currentPage = self.cardCollectionView.contentOffset.x / pageWidth;
    if (0.0f != fmodf(currentPage, 1.0f)) {
        self.pageControl.currentPage = currentPage + 1;
    } else {
        self.pageControl.currentPage = currentPage;
    }
    self.index = self.pageControl.currentPage;
    [self pageControlCurrentIndex: currentPage];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bannerContainer.frame.size.width, self.bannerContainer.frame.size.height);
}

#pragma mark - compose HTML Banner
- (void)composeHTML:(NSString*)content {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc] init];
    [userController addScriptMessageHandler:self name:@"close"];
    [userController addScriptMessageHandler:self name:@"subscribe"];
    [userController addScriptMessageHandler:self name:@"unsubscribe"];
    [userController addScriptMessageHandler:self name:@"closeBanner"];
    [userController addScriptMessageHandler:self name:@"trackEvent"];
    [userController addScriptMessageHandler:self name:@"setSubscriptionAttribute"];
    [userController addScriptMessageHandler:self name:@"addSubscriptionTag"];
    [userController addScriptMessageHandler:self name:@"removeSubscriptionTag"];
    [userController addScriptMessageHandler:self name:@"setSubscriptionTopics"];
    [userController addScriptMessageHandler:self name:@"addSubscriptionTopic"];
    [userController addScriptMessageHandler:self name:@"removeSubscriptionTopic"];
    [userController addScriptMessageHandler:self name:@"showTopicsDialog"];
    [userController addScriptMessageHandler:self name:@"trackClick"];
    [userController addScriptMessageHandler:self name:@"openWebView"];
    config.userContentController = userController;

    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size.width, [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size.height) configuration:config];
    self.webView.scrollView.scrollEnabled = true;
    self.webView.scrollView.bounces = false;
    self.webView.allowsBackForwardNavigationGestures = false;
    self.webView.contentMode = UIViewContentModeScaleToFill;
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = false;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webBannerHeight.constant = [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size.height;

    if (self.data.closeButtonEnabled) {
        UIColor *backgroundColor;
        UIButton *closeButton = [[UIButton alloc]init];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGRect frame = window.rootViewController.view.frame;
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;
        CGFloat topPadding = 0;

        if (@available(iOS 11.0, *)) {
            topPadding = window.safeAreaInsets.top;
            closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(width - 40, topPadding, 40, 40))];
            if (self.data.closeButtonPositionStaticEnabled) {
                self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, topPadding + 40, width, height) configuration:config];
                closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(width - 40, self.view.safeAreaInsets.top - 40, 40, 40))];
            }
        } else {
            closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(width - 40, 10, 40, 40))];
            if (self.data.closeButtonPositionStaticEnabled) {
                self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 40, width, height) configuration:config];
                closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(width - 40, [UIApplication sharedApplication].statusBarFrame.size.height - 40, 40, 40))];
            }
        }

        if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
            backgroundColor = [UIColor colorWithHexString:self.data.background.darkColor];
        } else {
            backgroundColor = [UIColor colorWithHexString:self.data.background.color];
        }
        UIColor *color = [CPUtils readableForegroundColorForBackgroundColor:backgroundColor];

        if (@available(iOS 13.0, *)) {
            [closeButton setImage:[UIImage systemImageNamed:@"multiply"] forState:UIControlStateNormal];
            closeButton.tintColor = color;
        } else {
            [closeButton setTitle:@"X" forState:UIControlStateNormal];
            [closeButton setTitleColor:color forState:UIControlStateNormal];
        }

        [closeButton.layer setMasksToBounds:false];
        [closeButton addTarget:self action:@selector(onDismiss)
              forControlEvents:UIControlEventTouchUpInside];
        [self.webView addSubview:closeButton];
    }
    [self.view addSubview:self.webView];

    // remove </body> and </html> which will get added later again
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
        [self.webView loadHTMLString:[headerString stringByAppendingString:scriptSource] baseURL:nil];
    });
}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if (message != nil && message.body != nil && message.name != nil) {
        if ([message.name isEqualToString:@"close"] || ([message.name isEqualToString:@"closeBanner"])) {
            [self onDismiss];
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame && !navigationAction.targetFrame.isMainFrame) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    if ([navigationAction.request.URL.absoluteString isEqualToString:@"about:blank"] || [navigationAction.request.URL.absoluteString isEqualToString:@"about:blank%23"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    decisionHandler(WKNavigationActionPolicyCancel);
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
}

#pragma mark - Callback event for tracking clicks
- (void)actionCallback:(CPAppBannerAction*)action{
    self.actionCallback(action);
}

#pragma mark - Animations
- (void)fadeOut {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
    }];
}

- (void)jumpOut {
    [UIView animateWithDuration:0.25 animations:^{
        self.bannerContainer.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
    } completion:nil];
}

- (IBAction)tapOutSideBanner:(UIButton *)sender {
    [self onDismiss];
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self fadeOut];
        [self jumpOut];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissViewControllerAnimated:NO completion:nil];
        [CPAppBannerModule showNextActivePendingBanner:self.data];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.view == touch.view;
}

- (IBAction)btnClose:(UIButton *)sender {
    [self onDismiss];
}

@end
