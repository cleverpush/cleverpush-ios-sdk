#import "CPInboxDetailView.h"
#import "CPInboxDetailContainer.h"
#import "CPLog.h"

@interface CPInboxDetailView()
@end

@implementation CPInboxDetailView

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.data == nil) {
        return;
    }

    [self conditionalPresentation];
    [self setUpPageControl];
    [self setDynamicCloseButton:NO];
}

#pragma mark - Custom UI Functions
- (void)conditionalPresentation {
    if ([self.data.contentType isEqualToString:@"html"]) {
        [self initWithHTMLBanner:self.data];
        [self setContentVisibility:true];
    } else {
        [self initWithBanner:self.data];
        [self delagates];
        [self setContentVisibility:false];
    }
}

#pragma mark - dynamic hide and shows the layer of the view heirarchy.
- (void)setContentVisibility:(BOOL)isHtml {
    self.cardCollectionView.hidden = isHtml;
    self.backGroundImage.hidden = isHtml;
    self.pageControl.hidden = isHtml;
    self.webView.hidden = !isHtml;
}

#pragma mark - native delegates and registration of the nib.
- (void)delagates {
    NSBundle *bundle = [CPUtils getAssetsBundle];
    if (bundle) {
        [self.cardCollectionView registerNib:[UINib nibWithNibName:@"CPInboxDetailContainer" bundle:bundle] forCellWithReuseIdentifier:@"CPInboxDetailContainer"];
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

    if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
        if (self.data.screens[self.index].background != nil && ![self.data.screens[self.index].background isKindOfClass:[NSNull class]] && self.data.screens[self.index].background.color != nil && ![self.data.screens[self.index].background.color isKindOfClass:[NSNull class]] && ![self.data.screens[self.index].background.color isEqualToString:@""]) {
            [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.screens[self.index].background.color]];
        } else {
            [self.backGroundImage setBackgroundColor:[UIColor whiteColor]];
        }
    } else {
        [self.backGroundImage setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
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
    self.btnClose.hidden = NO;
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
    if (self.data.screens.count == 0) {
        return 1;
    } else {
        return self.data.screens.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPInboxDetailContainer *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPInboxDetailContainer" forIndexPath:indexPath];
    cell.data = self.data;
    [cell setActionCallback:self.actionCallback];

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
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    [((CPInboxDetailContainer *)cell).tblCPBanner reloadData];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
}

#pragma mark - custom delegate when tapped on a button and it's action has been set to navigate on a next screen
- (void)navigateToNextPage {
    NSIndexPath *nextItem = [NSIndexPath indexPathForItem:self.index + 1 inSection:0];
    if (nextItem.row < self.data.screens.count) {
        [self.cardCollectionView scrollToItemAtIndexPath:nextItem atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        self.pageControl.currentPage = self.index + 1;
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
                break;
            }
        }
    }
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
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bannerContainer.frame.size.width, self.bannerContainer.frame.size.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAt:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
    CPAppBannerImageBlock *block = (CPAppBannerImageBlock*)self.data.blocks[indexPath.row];

    if (block.imageWidth > 0 && block.imageHeight > 0) {
        CGFloat imageViewWidth = flowLayout.itemSize.width;
        CGFloat imageViewHeight = imageViewWidth * block.scale / 100;
        return CGSizeMake(flowLayout.itemSize.width, imageViewHeight);
    }
    return flowLayout.itemSize;
}

#pragma mark - compose HTML Banner
- (void)composeHTML:(NSString*)content {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc] init];

    for (NSString *name in [CPUtils scriptMessageNames]) {
        [userController addScriptMessageHandler:self name:name];
    }

    config.userContentController = userController;

    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, self.webView.frame.origin.y, [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size.width, self.webView.frame.size.height) configuration:config];
    self.webView.scrollView.scrollEnabled = true;
    self.webView.navigationDelegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [CPUtils configureWebView:self.webView];

    [self.view addSubview:self.webView];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView loadHTMLString:[CPUtils generateBannerHTMLStringWithFunctions:content] baseURL:nil];
    });
}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if (message != nil && message.body != nil && message.name != nil) {
        [CPUtils userContentController:userContentController didReceiveScriptMessage:message withBanner:self.data];
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
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
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
        
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.view == touch.view;
}

- (IBAction)btnClose:(UIButton *)sender {
    [self onDismiss];
}

@end
