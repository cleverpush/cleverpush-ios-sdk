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
    [self setDynamicBannerConstraints:self.data.marginEnabled];
    [self setDynamicCloseButton:self.data.closeButtonEnabled];
}

#pragma mark - dynamic hide and shows the layer of the view heirarchy.
- (void)contentVisibility:(BOOL)collection background:(BOOL)background htmlContent:(BOOL)htmlContent {
    self.cardCollectionView.hidden = collection;
    self.backGroundImage.hidden = background;
    self.webBanner.hidden = htmlContent;
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
    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]]) {
        [self.backGroundImage setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
    } else {
        [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
    }
    [self.backGroundImage setContentMode:UIViewContentModeScaleAspectFill];
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
    if (@available(iOS 13.0, *)) {
        [self.btnClose setImage:[UIImage systemImageNamed:@"multiply"] forState:UIControlStateNormal];
        self.btnClose.tintColor = UIColor.whiteColor;
    } else {
        [self.btnClose setTitle:@"X" forState:UIControlStateNormal];
        [self.btnClose setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }

    if (closeButtonEnabled) {
        self.btnClose.hidden = NO;
    } else {
        self.btnClose.hidden = YES;
    }
}

#pragma mark - set app banner with margin
- (void)setAppBannerWithMargin {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    if (@available(iOS 11.0, *)) {
        CGFloat topPadding = window.safeAreaInsets.top;
        self.topConstraint.constant = topPadding;
    }
    self.bottomConstraint.constant = 34;
    self.leadingConstraint.constant = 25;
    self.trailingConstraint.constant = 25;
    [self.bannerContainer.layer setCornerRadius:15.0];
    [self.bannerContainer.layer setMasksToBounds:YES];
    self.pageControllTopConstraint.constant = 3;
    self.btnTopConstraints.constant = 0;
}

#pragma mark - set app banner without margin padding from all of the edges will be zero
- (void)setAppBannerWithoutMargin {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    if (@available(iOS 11.0, *)) {
        CGFloat topPadding = window.safeAreaInsets.top;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        self.topConstraint.constant = 0;
        self.bottomConstraint.constant = 0;
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
    [self.pageControl setNumberOfPages:self.data.screens.count];
}

#pragma mark - custom delegate manage tableview constraint size based on it's content size and based on conditional
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

#pragma mark - CollectionView Delegate and DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.screens.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPBannerCardContainer *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPBannerCardContainer" forIndexPath:indexPath];
    cell.data = self.data;
    [cell setActionCallback:self.actionCallback];
    cell.blocks = self.data.screens[indexPath.item].blocks;
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
    [cell layoutIfNeeded];
    return cell;
}

#pragma mark - custom delegate when tapped on a button and it's action has been set to navigate on a next screen
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

#pragma mark - compose HTML Banner
- (void)composeHTML:(NSString*)content {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    WKUserContentController* userController = [[WKUserContentController alloc]init];
    [userController addScriptMessageHandler:self name:@"close"];
    config.userContentController = userController;
    
    self.webBanner.scrollView.scrollEnabled = true;
    self.webBanner.scrollView.bounces = false;
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

- (IBAction)tapOutSideBanner:(UIButton *)sender {
    [self onDismiss];
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self fadeOut];
        [self jumpOut];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissViewControllerAnimated:NO completion:nil];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.view == touch.view;
}

- (IBAction)btnClose:(UIButton *)sender {
    [self onDismiss];
}

@end
