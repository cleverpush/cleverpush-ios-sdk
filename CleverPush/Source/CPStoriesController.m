#import "CPStoriesController.h"
#import "CPLog.h"
#import "CPWidgetModule.h"

@interface CPStoriesController ()
@end

@implementation CPStoriesController
@synthesize delegate;

#define IMAGEVIEW_BORDER_LENGTH 50

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.stories == nil) {
        return;
    }

    self.storyStatusMap = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < [self.stories count]; i++) {
        [self.storyStatusMap setObject:@(NO) forKey:@(i)];
    }

    [self configureCloseButton];
    [self ConfigureCPCarousel];
    [self initialisePanGesture];
    [self trackStoryOpened];

}

- (void)viewDidDisappear:(BOOL)animated {
    self.carousel = self.carousel;
}

- (void)dealloc {
    self.carousel.delegate = nil;
    self.carousel.dataSource = nil;
}

#pragma mark - Initialise Pan Gesture for dismiss with animation
- (void)initialisePanGesture {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self.view addGestureRecognizer:panRecognizer];
}

#pragma mark - Gesture action
- (void)panGestureAction:(UIPanGestureRecognizer*)panGesture {
    CGPoint translation = [panGesture translationInView:panGesture.view.superview];
    CGFloat topSideRestrction = CGRectGetMinX(self.view.frame);
    CGFloat viewCurrentOrginYValue = self.view.frame.origin.y;
    
    if (panGesture.state == UIGestureRecognizerStateBegan || panGesture.state == UIGestureRecognizerStateChanged) {
        [self setFrameRect:CGPointMake(0, translation.y)];
        viewCurrentOrginYValue = self.view.frame.origin.y;
        
        if (viewCurrentOrginYValue <= topSideRestrction) {
            [self setInitialOffset];
        }
        
    } else if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [panGesture velocityInView:panGesture.view];
        
        if (velocity.y >= [[UIScreen mainScreen] bounds].size.height * 60 / 100 ) {
            [self dismissWithAnimation];
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                [self setInitialOffset];
            }];
        }
    }
}

#pragma mark - get the frame of origin Y and dismiss
- (void)dismissWithAnimation {
    [UIView animateWithDuration:0.2 animations:^{
        [self setFrameRect:CGPointMake(0, self.view.frame.origin.y)];
    }completion:^(BOOL finished) {
        if (finished) {
            [self onDismiss];
        }
    }];
}

#pragma mark - set the frame based on the transition point
- (void)setFrameRect:(CGPoint)point {
    CGRect rect = self.view.frame;
    rect.origin = point;
    self.view.frame = rect;
}

#pragma mark - set the default frame
- (void)setInitialOffset {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(screenBound.origin.x, screenBound.origin.y, screenBound.size.width, screenBound.size.height);
}

#pragma mark - Configure Stories Carousel
- (void)ConfigureCPCarousel {
    self.carousel = [[CleverPushiCarousel alloc] initWithFrame:self.view.bounds];
    self.carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.carousel.pagingEnabled = YES;
    self.carousel.bounces = NO;
    self.carousel.currentItemIndex = self.storyIndex;
    self.carousel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.carousel];
}

#pragma mark - Tracking when story widget has been opened
- (void)trackStoryOpened {
    [CPWidgetModule trackWidgetOpened:self.widget.id withStories:self.readStories onSuccess:nil onFailure:^(NSError * _Nullable error) {
        [CPLog error:@"Failed to open widgets stories: %@", error];
    }];
}

#pragma mark - Tracking when story widget has been rendered
- (void)trackStoriesShown {
    [CPWidgetModule trackWidgetShown:self.widget.id withStories:self.readStories onSuccess:nil onFailure:^(NSError * _Nullable error) {
        [CPLog error:@"Failed to render story: %@ %@", self.widget.id, error];
    }];
}

#pragma mark CleverPushiCarousel methods
- (NSInteger)numberOfItemsInCarousel:(CleverPushiCarousel *)carousel {
    return [self.stories count];
}

- (UIView *)carousel:(CleverPushiCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    [view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    view = nil;

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc]init];
    [userController removeScriptMessageHandlerForName:@"previous"];
    [userController removeScriptMessageHandlerForName:@"next"];
    [userController removeScriptMessageHandlerForName:@"storyNavigation"];
    [userController addScriptMessageHandler:self name:@"previous"];
    [userController addScriptMessageHandler:self name:@"next"];
    [userController addScriptMessageHandler:self name:@"storyNavigation"];
    configuration.userContentController = userController;
    configuration.allowsInlineMediaPlayback = YES;
    [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];

    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    containerView.backgroundColor = UIColor.clearColor;

    CPWKWebView *webview = [[CPWKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webview.scrollView.scrollEnabled = true;
    webview.scrollView.bounces = false;
    webview.allowsBackForwardNavigationGestures = false;
    webview.contentMode = UIViewContentModeScaleToFill;
    webview.scrollView.backgroundColor = UIColor.blackColor;
    webview.scrollView.hidden = YES;
    webview.backgroundColor = [UIColor whiteColor];
    webview.scrollView.backgroundColor = [UIColor whiteColor];
    webview.opaque = false;
    [containerView addSubview:webview];

    if (@available(iOS 11.0, *)) {
        webview.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [webview.topAnchor constraintEqualToAnchor:containerView.safeAreaLayoutGuide.topAnchor],
            [webview.bottomAnchor constraintEqualToAnchor:containerView.safeAreaLayoutGuide.bottomAnchor],
            [webview.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [webview.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor]
        ]];
    } else {
        webview.frame = containerView.bounds;
    }

    NSString *storyID = self.stories[index].id;
    NSMutableDictionary *storyInfo = [[[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_SUB_STORY_POSITION_KEY] mutableCopy];
    NSInteger lastWatchedIndex = 0;

    if (storyInfo != nil && [storyInfo objectForKey:storyID] != nil) {
        lastWatchedIndex = [storyInfo[storyID] integerValue] + 1;
    }

    NSString* customURL = [NSString stringWithFormat:@"https://api.cleverpush.com/channel/%@/story/%@/html#page=page-%ld&ignoreLocalStorageHistory=true", self.stories[index].channel, storyID, (long)lastWatchedIndex];

    if (!self.storyWidgetShareButtonVisibility) {
        customURL = [NSString stringWithFormat:@"https://api.cleverpush.com/channel/%@/story/%@/html?hideStoryShareButton=true&#page=page-%ld&ignoreLocalStorageHistory=true", self.stories[index].channel, storyID, (long)lastWatchedIndex];
    }
    NSString *currentIndex = [NSString stringWithFormat:@"%ld", (long)index];
    CGFloat frameHeight = [CPUtils frameHeightWithoutSafeArea];

    NSString *content = [NSString stringWithFormat:@"\
                         <!DOCTYPE html>\
                         <html>\
                         <head>\
                         <script src=\"https://cdn.ampproject.org/amp-story-player-v0.js\"></script>\
                         <link rel=\"stylesheet\" href=\"https://cdn.ampproject.org/amp-story-player-v0.css\">\
                         <style>\
                         body {\
                             margin: 0;\
                             padding: 0;\
                         }\
                         amp-story-player {\
                             display: block;\
                             margin: 0;\
                             padding: 0;\
                             width: 100%%;\
                             height: %f;\
                         }\
                         </style>\
                         </head>\
                         <body>\
                         <amp-story-player style=\"width: 100%%; height: %f;\">\
                         <a href=\"%@\">\"%@\"\
                         </a>\
                         </amp-story-player>\
                         <script>\
                         var playerEl = document.querySelector('amp-story-player');\
                         var player = new AmpStoryPlayer(window, playerEl);\
                         playerEl.addEventListener('noPreviousStory', function (event) {window.webkit.messageHandlers.previous.postMessage(%@);});\
                         playerEl.addEventListener('noNextStory', function (event) {window.webkit.messageHandlers.next.postMessage(%@);});\
                         player.addEventListener('storyNavigation', function(event) {\
                             console.log('storyNavigation event triggered');\
                             var subStoryIndex = Number(event.detail.pageId?.split('-')?.[1] || 111);\
                             window.webkit.messageHandlers.storyNavigation.postMessage({\
                                position: %@,\
                                 subStoryIndex: subStoryIndex\
                             });\
                         });\
                         player.go(%@);\
                         </script>\
                         </body>\
                         </html>", frameHeight, frameHeight, customURL, self.stories[index].title, currentIndex, currentIndex, currentIndex,currentIndex];

    view = containerView;
    [webview loadHTML:content withCompletionHandler:^(WKWebView *webView, NSError *error) {
        if (error) {
            webview.scrollView.hidden = NO;
        } else {
            NSNumber *currentValue = [self.storyStatusMap objectForKey:@(index)];
            if (self.storyIndex == index && [currentValue boolValue] == NO) {
                [self.storyStatusMap setObject:@(YES) forKey:@(index)];
                [self trackStoriesShown];
            }

            [self.carousel addSubview:self.closeButton];
            webview.scrollView.hidden = NO;
        }
    }];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [webview addGestureRecognizer:swipeDown];
    
    if (self.openedCallback) {
        [webview setUrlOpenedCallback:self.openedCallback];
    }
    return view;
}

- (void)carouselCurrentItemIndexDidChange:(CleverPushiCarousel *)carousel {
    if (![self.readStories containsObject:self.stories[carousel.currentItemIndex].id]) {
        [self.readStories addObject:self.stories[carousel.currentItemIndex].id];
        self.stories[carousel.currentItemIndex].opened = YES;
    }
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.readStories forKey:CLEVERPUSH_SEEN_STORIES_KEY];
    self.storyIndex = carousel.currentItemIndex;
    [self.storyStatusMap setObject:@(NO) forKey:@(self.storyIndex)];
    [self trackStoryOpened];
    [self.carousel reloadItemAtIndex:carousel.currentItemIndex animated:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.carousel scrollToItemAtIndex:carousel.currentItemIndex animated:YES];
    });
}

- (CGFloat)carousel:(CleverPushiCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.0;
    }
    return value;
}

- (void)next {
    if (self.storyIndex == self.stories.count - 1) {
        [self onDismiss];
    } else if (self.storyIndex >= 0) {
        [self.carousel reloadItemAtIndex:self.storyIndex + 1 animated:NO];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.carousel scrollToItemAtIndex:self.storyIndex + 1 animated:YES];
        });
    }
}

- (void)previous {
    if (self.storyIndex == 0)  {
        self.carousel.currentItemIndex = 0;
    } else if (self.storyIndex >= 0) {
        [self.carousel reloadItemAtIndex:self.storyIndex - 1 animated:NO];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.carousel scrollToItemAtIndex:self.storyIndex - 1 animated:YES];
        });
    }
}

#pragma mark Synced JS with Native bridge.
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *currentIndex = [NSString stringWithFormat:@"%ld", self.storyIndex];
    if ([message.name isEqualToString:@"previous"] || [message.name isEqualToString:@"next"]) {
        NSString *scriptMessageIndex = [NSString stringWithFormat:@"%@", message.body];
        if (![currentIndex isEqualToString:scriptMessageIndex]) {
            return;
        }

        if ([message.name isEqualToString:@"previous"]) {
            [self previous];
        } else {
            [self next];
        }
    } else if ([message.name isEqualToString:@"storyNavigation"]) {
        NSInteger position = [message.body[@"position"] integerValue];
        NSInteger subStoryIndex = [message.body[@"subStoryIndex"] integerValue];
        if (position == [currentIndex integerValue]) {
            [self onStoryNavigation:position subStoryPosition:subStoryIndex];
        }
    }
}

- (void)onStoryNavigation:(NSInteger)position subStoryPosition:(NSInteger)subStoryPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *storyUnreadCountDict = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];
    NSDictionary *subStoryPositionDict = [defaults objectForKey:CLEVERPUSH_SUB_STORY_POSITION_KEY];

    NSMutableDictionary *updatedStoryUnreadCountDict = [storyUnreadCountDict mutableCopy] ?: [NSMutableDictionary dictionary];
    NSMutableDictionary *updatedSubStoryPositionDict = [subStoryPositionDict mutableCopy] ?: [NSMutableDictionary dictionary];

    if (position < 0 || position >= self.stories.count) {
        return;
    }

    CPStory *story = self.stories[position];
    NSString *storyId = story.id;
    NSInteger subStoryCount = story.content.pages.count;
    NSInteger unreadCount = subStoryCount - (subStoryPosition + 1);
    NSNumber *existingUnreadCount = updatedStoryUnreadCountDict[storyId];
    NSNumber *existingSubStoryPosition = updatedSubStoryPositionDict[storyId];

    BOOL shouldUpdate = NO;

    if (!existingUnreadCount || !existingSubStoryPosition) {
        updatedStoryUnreadCountDict[storyId] = @(unreadCount);
        updatedSubStoryPositionDict[storyId] = @(subStoryPosition);
        story.unreadCount = unreadCount;
        story.opened = YES;
        shouldUpdate = YES;
    } else {
        NSInteger preferencesSubStoryPosition = [existingSubStoryPosition integerValue];
        if (subStoryPosition > preferencesSubStoryPosition) {
            updatedStoryUnreadCountDict[storyId] = @(unreadCount);
            updatedSubStoryPositionDict[storyId] = @(subStoryPosition);
            story.unreadCount = unreadCount;
            story.opened = YES;
            shouldUpdate = YES;
        }
    }

    if (shouldUpdate) {
        [defaults setObject:updatedStoryUnreadCountDict forKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];
        [defaults setObject:updatedSubStoryPositionDict forKey:CLEVERPUSH_SUB_STORY_POSITION_KEY];
        [defaults synchronize];
    }
}

#pragma mark Device orientation
- (BOOL) shouldAutorotate {
    return self.allowAutoRotation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.allowAutoRotation) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return (UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown);
    }

}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.allowAutoRotation) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

        UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
        overlayView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:overlayView];

        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            overlayView.frame = self.view.bounds;

            [self updateCloseButtonPositionForSize:size];
            self.carousel.frame = CGRectMake(0, 0, size.width, size.height);
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [UIView animateWithDuration:0.1 animations:^{
                overlayView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [overlayView removeFromSuperview];
            }];

            [self.carousel reloadData];
        }];
    }
}

#pragma mark - Animations
- (void)didSwipe:(UISwipeGestureRecognizer*)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionDown) {
        [self onDismiss];
    }
}

#pragma mark - Dismiss by tapping on the X button.
- (void)onDismiss {
    self.carousel = self.carousel;
    self.carousel.delegate = nil;
    self.carousel.dataSource = nil;
    [delegate reloadReadStories:self.readStories];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - Close Button Handling
- (void)closeTapped:(UIButton *)button {
    [self onDismiss];
}

#pragma mark - Configure close buttton
- (void)configureCloseButton {
    self.buttonWidth = 30.0;
    self.buttonHeight = 30.0;
    self.buttonXPosition = 10.0;

    if (@available(iOS 11.0, *)) {
        self.window = UIApplication.sharedApplication.windows.firstObject;
        self.topPadding = self.window.safeAreaInsets.top;
        self.closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(10, self.topPadding + 10, 40, 40))];

        if (self.closeButtonPosition == CPStoryWidgetCloseButtonPositionRightSide) {
            self.buttonXPosition = self.window.frame.size.width - self.buttonWidth - 10.0;
        } else {
            self.buttonXPosition = 10.0;
        }

        self.closeButton.frame = CGRectMake(self.buttonXPosition, self.topPadding + 15, self.buttonWidth, self.buttonHeight);
    } else {
        self.closeButton = [[UIButton alloc]initWithFrame:(CGRectMake(10, 10, 40, 40))];

        if (self.closeButtonPosition == CPStoryWidgetCloseButtonPositionRightSide) {
            self.buttonXPosition = UIApplication.sharedApplication.windows.firstObject.frame.size.width - self.buttonWidth - 10.0;
        } else {
            self.buttonXPosition = 10.0;
        }

        self.closeButton.frame = CGRectMake(self.buttonXPosition, 10.0, self.buttonWidth, self.buttonHeight);
    }
    self.closeButton.layer.cornerRadius = 15.0;
    self.closeButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];

    if (@available(iOS 13.0, *)) {
        [self.closeButton setImage:[UIImage systemImageNamed:@"multiply"] forState:UIControlStateNormal];
        self.closeButton.tintColor = UIColor.whiteColor;
    } else {
        [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
        [self.closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    [self.closeButton addTarget:self action:@selector(closeTapped:)
               forControlEvents:UIControlEventTouchUpInside];

}

- (void)updateCloseButtonPositionForSize:(CGSize)size {
    if (@available(iOS 11.0, *)) {
        CGFloat topPadding = self.window.safeAreaInsets.top;

        if (self.closeButtonPosition == CPStoryWidgetCloseButtonPositionRightSide) {
            self.buttonXPosition = size.width - self.buttonWidth - 10.0;
        } else {
            self.buttonXPosition = 10.0;
        }

        self.closeButton.frame = CGRectMake(self.buttonXPosition, topPadding + 15, self.buttonWidth, self.buttonHeight);
    } else {
        if (self.closeButtonPosition == CPStoryWidgetCloseButtonPositionRightSide) {
            self.buttonXPosition = size.width - self.buttonWidth - 10.0;
        } else {
            self.buttonXPosition = 10.0;
        }

        self.closeButton.frame = CGRectMake(self.buttonXPosition, 10.0, self.buttonWidth, self.buttonHeight);
    }
}

@end
