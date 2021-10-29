#import "CPAppBannerViewController.h"

@interface CPAppBannerViewController()
@end

@implementation CPAppBannerViewController

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self conditionalPresentation];
    [self setBackground];
    [self backgroundPopupShadow];
    [self setOrientation];
    [self setUpPageControl];
    if (self.data == nil) {
        return;
    }
}
#pragma mark - Custom UI Functions
- (void)conditionalPresentation {
    if (![self.data carouselEnabled] && [self.data.contentType isEqualToString:@"html"]) {
        [self initWithHTMLBanner:self.data];
        [self contentVisibility:true background:true htmlContent:false];
    } else {
        [self initWithBanner:self.data];
        [self delagates];
        [self contentVisibility:false background:false htmlContent:true];
    }
}

- (void)contentVisibility:(BOOL)collection background:(BOOL)background htmlContent:(BOOL)htmlContent {
    self.cardCollectionView.hidden = collection;
    self.backGroundImage.hidden = background;
    self.webBanner.hidden = htmlContent;
}

- (void)delagates {
    [self.cardCollectionView registerNib:[UINib nibWithNibName:@"CPCardContainer" bundle:nil] forCellWithReuseIdentifier:@"CPCardContainer"];
    self.cardCollectionView.delegate = self;
    self.cardCollectionView.dataSource = self;
}

- (void)setBackground {
    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]]) {
        [self.backGroundImage setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
    } else {
        [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
    }
    [self.bannerContainer.layer setCornerRadius:15.0];
    [self.bannerContainer.layer setMasksToBounds:YES];
    [self.backGroundImage setContentMode:UIViewContentModeScaleAspectFill];
}

- (void)backgroundPopupShadow {
    float shadowSize = 10.0f;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(self.bannerContainer.frame.origin.x - shadowSize / 2, self.bannerContainer.frame.origin.y - shadowSize / 2, self.bannerContainer.frame.size.width + shadowSize, self.bannerContainer.frame.size.height + shadowSize)];
    self.bannerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bannerContainer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.bannerContainer.layer.shadowOpacity = 0.8f;
    self.bannerContainer.layer.shadowPath = shadowPath.CGPath;
}

- (void)setOrientation {
    if (self.data.type == CPAppBannerTypeTop) {
        [self bannerPosition:YES bottom:NO center:NO];
    } else if (self.data.type == CPAppBannerTypeCenter) {
        [self bannerPosition:NO bottom:NO center:YES];
    } else if (self.data.type == CPAppBannerTypeBottom) {
        [self bannerPosition:YES bottom:NO center:NO];
    } else {
        [self bannerPosition:YES bottom:YES center:YES];
    }
}

- (void)bannerPosition:(BOOL)top bottom:(BOOL)bottom center:(BOOL)center {
    self.topConstraint.active = top;
    self.bottomConstraint.active = bottom;
    self.centerYConstraint.active = center;
}

- (void)setUpPageControl {
    [self.pageControl setNumberOfPages:self.data.screens.count];
}

- (void)manageTableHeightDelegate:(CGSize)value {
    if (value.height > UIScreen.mainScreen.bounds.size.height) {
        self.popupHeight.constant = [CPUtils frameHeightWithoutSafeArea];
    } else {
        self.popupHeight.constant = value.height + 20;
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
    [self composeHTML:self.data.HTMLContent];
}

#pragma mark - Gesture recongniser when user tapped out side of the popup
- (IBAction)tapGestureAction:(id)sender {
    [self onDismiss];
}

#pragma mark - CollectionView Delegate and DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.screens.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPCardContainer *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPCardContainer" forIndexPath:indexPath];
    cell.data = self.data;
    [cell setActionCallback:self.actionCallback];
    [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPImageBlockCell" bundle:nil] forCellReuseIdentifier:@"CPImageBlockCell"];
    [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPTextBlockCell" bundle:nil] forCellReuseIdentifier:@"CPTextBlockCell"];
    [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPButtonBlockCell" bundle:nil] forCellReuseIdentifier:@"CPButtonBlockCell"];
    [cell.tblCPBanner registerNib:[UINib nibWithNibName:@"CPHTMLBlockCell" bundle:nil] forCellReuseIdentifier:@"CPHTMLBlockCell"];
    
    cell.tblCPBanner.delegate = cell;
    cell.tblCPBanner.dataSource = cell;
    cell.delegate = self;
    cell.changePage = self;
    cell.controller = self;
    [cell.tblCPBanner reloadData];
    return cell;
}

- (void)navigateToNextPage {
    NSIndexPath *nextItem = [NSIndexPath indexPathForItem:self.index + 1 inSection:0];
    if (nextItem.row < self.data.screens.count) {
        [self.cardCollectionView scrollToItemAtIndexPath:nextItem atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        self.pageControl.currentPage = self.index + 1;
    }
}

#pragma mark - UIScrollViewDelegate for UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.cardCollectionView.frame.size.width;
    float currentPage = self.cardCollectionView.contentOffset.x / pageWidth;
    if (0.0f != fmodf(currentPage, 1.0f)){
        self.pageControl.currentPage = currentPage + 1;
    } else {
        self.pageControl.currentPage = currentPage;
    }
    self.index = self.pageControl.currentPage;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bannerContainer.frame.size.width, self.bannerContainer.frame.size.height);
}

+ (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

#pragma mark - Define Root view controller
+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)viewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navContObj = (UINavigationController*)viewController;
        return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
    } else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        UIViewController* presentedViewController = viewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        for (UIView *view in [viewController.view subviews]) {
            id subViewController = [view nextResponder];
            if (subViewController && [subViewController isKindOfClass:[UIViewController class]]) {
                if ([(UIViewController *)subViewController presentedViewController]  && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

#pragma mark - compose HTML Banner
- (void)composeHTML:(NSString*)content {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    WKUserContentController* userController = [[WKUserContentController alloc]init];
    [userController addScriptMessageHandler:self name:@"close"];
    config.userContentController = userController;
    
    self.webBanner.scrollView.scrollEnabled = true;
    self.webBanner.scrollView.bounces = false;
    self.webBanner.configuration.defaultWebpagePreferences.allowsContentJavaScript = true;
    self.webBanner.allowsBackForwardNavigationGestures = false;
    self.webBanner.contentMode = UIViewContentModeScaleToFill;
    self.webBanner.navigationDelegate = self;
    self.webBanner.layer.cornerRadius = 15.0;
    
    if ([content containsString:@"</body></html>"]) {
        content = [content stringByReplacingOccurrencesOfString:@"</body></html>" withString:@""];
    }
    
    NSString *script = @"<script type=\"text/javascript\">var keyword = 'close';function onCloseClick() {try {window.webkit.messageHandlers.close.postMessage(null);} catch (error) {console.log('Caught error on closeBTN click', error);}}var elemsWithId = document.getElementsByTagName(\"*\"), item;for (var i = 0, len = elemsWithId.length; i < len; i++) {item = elemsWithId[i];if (item.id && item.id.indexOf(\"close\") == 0) {item.addEventListener('click', onCloseClick);}}var elemsWithClass = document.getElementsByTagName(\"*\"), item;for (var i = 0, len = elemsWithId.length; i < len; i++) {item = elemsWithId[i];if (item.className && item.className.indexOf(\"close\") == 0) {item.addEventListener('click', onCloseClick);}}</script>";
    NSString *bodyText = @"</body></html>";
    NSString *scriptSource = [NSString stringWithFormat: @"%@%@%@", content, script, bodyText];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *headerString = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>";
        [self.webBanner loadHTMLString:[headerString stringByAppendingString:scriptSource] baseURL:nil];
        
    });
}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.name isEqualToString:@"close"]){
        [self onDismiss];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            CGFloat height = [result floatValue];
            if (webView == self.webBanner) {
                if (height > UIScreen.mainScreen.bounds.size.height) {
                    self.popupHeight.constant = [CPUtils frameHeightWithoutSafeArea];
                    self.webBannerHeight.constant = [CPUtils frameHeightWithoutSafeArea];
                } else {
                    self.popupHeight.constant = height;
                    self.webBannerHeight.constant = height;
                }
            }
        }];
    }];
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

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self fadeOut];
        [self jumpOut];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"CleverPush_APP_BANNER_VISIBLE"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissViewControllerAnimated:NO completion:nil];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.view == touch.view;
}

@end
