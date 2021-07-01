#import "CPStoriesController.h"
@interface CPStoriesController ()
@end

@implementation CPStoriesController
@synthesize delegate;

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.stories == nil) {
        return;
    }
    [self ConfigureCPCarousel];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.carousel = self.carousel;
}

- (void)dealloc {
    self.carousel.delegate = nil;
    self.carousel.dataSource = nil;
}

#pragma mark - Configure Stories Carousel
- (void)ConfigureCPCarousel {
    self.carousel = [[CleverPushiCarousel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.carousel.pagingEnabled = YES;
    self.carousel.bounces = NO;
    self.carousel.currentItemIndex = self.storyIndex;
    [self.view addSubview:self.carousel];
}

#pragma mark CleverPushiCarousel methods
- (NSInteger)numberOfItemsInCarousel:(CleverPushiCarousel *)carousel {
    return [self.stories count];
}

- (UIView *)carousel:(CleverPushiCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    indicator.color = UIColor.redColor;
    [indicator hidesWhenStopped];
    [indicator startAnimating];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc]init];
    [userController addScriptMessageHandler:self name:@"previous"];
    [userController addScriptMessageHandler:self name:@"next"];
    configuration.userContentController = userController;
    configuration.allowsInlineMediaPlayback = YES;
    
    CPWKWebView *webview = [[CPWKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) configuration:configuration];
    webview.scrollView.scrollEnabled = true;
    webview.scrollView.bounces = false;
    webview.allowsBackForwardNavigationGestures = false;
    webview.contentMode = UIViewContentModeScaleToFill;
    webview.scrollView.backgroundColor = UIColor.blackColor;

    NSString* customURL = [NSString stringWithFormat:@"https://api.cleverpush.com/channel/%@/story/%@/html", self.stories[index].channel, self.stories[index].id];
    
    CGFloat frameHeight;
    frameHeight = [CPUtils frameHeightWithoutSafeArea];
    
    NSString *content = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><script async src=\"https://cdn.ampproject.org/v0.js\"></script><script async custom-element=\"amp-story-player\" src=\"https://cdn.ampproject.org/v0/amp-story-player-0.1.js\"></script></head><body><amp-story-player layout=\"fixed\" width=\"%f\" height=\"%f\"><a href=\"%@\">\"%@\"</a></amp-story-player><script>var player = document.querySelector('amp-story-player');player.addEventListener('noPreviousStory', function (event) {window.webkit.messageHandlers.previous.postMessage(null);});player.addEventListener('noNextStory', function (event) {window.webkit.messageHandlers.next.postMessage(null);});</script></body></html>",UIScreen.mainScreen.bounds.size.width, frameHeight, customURL, self.stories[index].title];
    
    [webview loadHTML:content withCompletionHandler:^(WKWebView *webView, NSError *error){
        if (error) {
            [indicator stopAnimating];
        } else {
            [indicator stopAnimating];
        }
    }];
    view = webview;
    
    UIButton *closeButton = [[UIButton alloc]init];
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        CGFloat topPadding = window.safeAreaInsets.top;
        closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(10, topPadding + 10 , 40, 40))];
    } else {
        closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(10, 10, 40, 40))];
    }
    closeButton.layer.cornerRadius = 20.0;
    closeButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    closeButton.tag = index;
    
    if (@available(iOS 13.0, *)) {
        [closeButton setImage:[UIImage systemImageNamed:@"multiply"] forState:UIControlStateNormal];
        closeButton.tintColor = UIColor.whiteColor;
    } else {
        [closeButton setTitle:@"X" forState:UIControlStateNormal];
        [closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    [closeButton addTarget:self action:@selector(closeTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    [webview addSubview:closeButton];
    indicator.center = webview.center;
    [webview addSubview:indicator];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [webview addGestureRecognizer:swipeDown];
    
    return view;
}

- (void)carouselCurrentItemIndexDidChange:(CleverPushiCarousel *)carousel {
    if (![self.readStories containsObject:self.stories[carousel.currentItemIndex].id]) {
        [self.readStories addObject:self.stories[carousel.currentItemIndex].id];
    }
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.readStories forKey:@"CleverPush_SEEN_STORIES"];
    self.storyIndex = carousel.currentItemIndex;
}

- (CGFloat)carousel:(CleverPushiCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.01;
    }
    return value;
}

- (void)next {
    if (self.storyIndex == self.stories.count - 1)  {
        self.carousel.currentItemIndex = 0;
    } else if (self.storyIndex >= 0) {
        [self.carousel scrollToItemAtIndex:self.storyIndex + 1 animated:YES];
    }
}

- (void)previous {
    if (self.storyIndex == 0)  {
        self.carousel.currentItemIndex = 0;
    } else if (self.storyIndex >= 0) {
        [self.carousel scrollToItemAtIndex:self.storyIndex - 1 animated:YES];
    }
}

#pragma mark Synced JS with Native bridge.
- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.name isEqualToString:@"previous"]){
        [self previous];
    } else {
        [self next];
    }
}

#pragma mark Device orientation
- (BOOL) shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Animations
- (void)didSwipe:(UISwipeGestureRecognizer*)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionDown) {
        [self onDismiss];
    }
}

- (void)onDismiss {
    [delegate reloadReadStories:self.readStories];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - Dismiss by tapping on the X button.
- (void)closeTapped:(UIButton *)button {
    [self onDismiss];
}

@end
