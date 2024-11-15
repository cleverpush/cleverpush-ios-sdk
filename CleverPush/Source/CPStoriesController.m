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
    [self initialisePanGesture];
    [self trackStoryOpened];
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
        
        if (velocity.y >= [[UIScreen mainScreen] bounds].size.height * 60 / 100) {
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

#pragma mark - Configure the story view
- (void)loadContentWithCompletion:(void (^)(void))completion {
    WKUserContentController* userController = [[WKUserContentController alloc] init];
    [userController removeScriptMessageHandlerForName:@"previous"];
    [userController removeScriptMessageHandlerForName:@"next"];
    [userController removeScriptMessageHandlerForName:@"navigation"];
    [userController removeScriptMessageHandlerForName:@"storyNavigation"];
    [userController removeScriptMessageHandlerForName:@"storyButtonCallbackUrl"];
    [userController removeScriptMessageHandlerForName:@"storyReady"];
    [userController addScriptMessageHandler:self name:@"previous"];
    [userController addScriptMessageHandler:self name:@"next"];
    [userController addScriptMessageHandler:self name:@"navigation"];
    [userController addScriptMessageHandler:self name:@"storyNavigation"];
    [userController addScriptMessageHandler:self name:@"storyButtonCallbackUrl"];
    [userController addScriptMessageHandler:self name:@"storyReady"];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userController;
    configuration.allowsInlineMediaPlayback = YES;
    [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    [configuration setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    configuration.userContentController = userController;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;

    self.webview = [[CPWKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    self.webview.scrollView.scrollEnabled = YES;
    self.webview.scrollView.bounces = NO;
    self.webview.allowsBackForwardNavigationGestures = NO;
    self.webview.contentMode = UIViewContentModeScaleToFill;
    self.webview.backgroundColor = [UIColor whiteColor];
    self.webview.scrollView.backgroundColor = [UIColor whiteColor];
    self.webview.scrollView.hidden = NO;
    self.webview.backgroundColor = [UIColor whiteColor];
    self.webview.opaque = NO;
    self.webview.navigationDelegate = self;

    self.contentLoadedCompletion = completion;

    NSMutableArray *storyURLs = [NSMutableArray array];
    for (NSInteger i = 0; i < self.stories.count; i++) {
        NSString *storyId = self.stories[i].id;
        NSInteger subStoryIndex = [self getSubStoryPosition:i];
        BOOL hasMultiplePages = (self.stories[i].content.pages != nil && self.stories[i].content.pages.count > 1);

        NSString *customURL = [NSString stringWithFormat:@"https://api.cleverpush.com/channel/%@/story/%@/html?hideStoryShareButton=%@&widgetId=%@%@",
                               self.stories[i].channel,
                               storyId,
                               self.storyWidgetShareButtonVisibility ? @"false" : @"true",
                               self.widget.id,
                               hasMultiplePages ? [NSString stringWithFormat:@"&#page=page-%ld", (long)subStoryIndex] : @""];

        [storyURLs addObject:customURL];
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:storyURLs options:0 error:nil];
    NSString *storyURLsJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"storyPlayerContent" ofType:@"html"];
    NSString *htmlTemplate = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        [CPLog debug:@"Error loading HTML file: %@", error.localizedDescription];
        if (self.contentLoadedCompletion) {
            self.contentLoadedCompletion();
        }
    } else {
        NSString *frameHeightString = [NSString stringWithFormat:@"%fpx", [CPUtils frameHeightWithoutSafeArea]];
        NSString *html = [htmlTemplate stringByReplacingOccurrencesOfString:@"{{frameHeight}}" withString:frameHeightString];
        html = [html stringByReplacingOccurrencesOfString:@"{{storyIndex}}" withString:[@(self.storyIndex) stringValue]];
        html = [html stringByReplacingOccurrencesOfString:@"{{storyURLs}}" withString:storyURLsJsonString];

        if (@available(iOS 16.4, *)) {
            [self.webview setInspectable:YES];
        }

        [self.webview loadHTML:html withCompletionHandler:^(WKWebView *webView, NSError *error) {
            if (error) {
                self.webview.scrollView.hidden = NO;
            } else {
                [self.webview addSubview:self.closeButton];
                self.webview.scrollView.hidden = NO;
            }
        }];

        UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
        swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
        [self.webview addGestureRecognizer:swipeDown];

        if (self.openedCallback) {
            [self.webview setUrlOpenedCallback:self.openedCallback];
        }

        [self.view addSubview:self.webview];
    }
}

#pragma mark - Tracking when story widget has been opened
- (void)trackStoryOpened {
    if (self.widget != nil) {
        NSMutableArray<NSString *> *readStoryIdArray = [NSMutableArray new];
        for (NSString *storyId in self.readStories) {
            if (![CPUtils isNullOrEmpty:storyId]) {
                if (self.widget.groupStoryCategories) {
                    NSArray *currentStoryIds = [storyId componentsSeparatedByString:@","];
                    for (NSString *storyId in currentStoryIds) {
                        [readStoryIdArray addObject:storyId];
                    }
                } else {
                    [readStoryIdArray addObject:storyId];
                }
            }
        }

        [CPWidgetModule trackWidgetOpened:self.widget.id withStories:readStoryIdArray onSuccess:nil onFailure:^(NSError * _Nullable error) {
            [CPLog error:@"Failed to open widgets stories: %@ %@", self.widget.id, error];
        }];
    }
}

#pragma mark - Synced JS with Native bridge.
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"navigation"]) {
        self.storyIndex = [message.body[@"index"] integerValue];
        [self currentItemIndexDidChange:self.storyIndex];
    } else if ([message.name isEqualToString:@"storyNavigation"]) {
        NSInteger subStoryIndex = [message.body[@"subStoryIndex"] integerValue];
        [self onStoryNavigation:self.storyIndex subStoryPosition:subStoryIndex];
    } else if ([message.name isEqualToString:@"storyButtonCallbackUrl"]) {
		[self.webview evaluateJavaScript:@"player.pause();" completionHandler:nil];
        if (message.body != nil && ![message.body isKindOfClass:[NSNull class]] && [message.body isKindOfClass:[NSDictionary class]]) {
            NSDictionary *bodyDict = (NSDictionary *)message.body;
            if (bodyDict && bodyDict.count > 0) {
                NSString *callbackURLString = bodyDict[@"callbackUrl"];
                if (![CPUtils isNullOrEmpty:callbackURLString]) {
                    NSURL *storyElementCallBackURL = [NSURL URLWithString:callbackURLString];
                    if ([CPUtils isValidURL:storyElementCallBackURL]) {
                        __weak typeof(self) weakSelf = self;
                        if (self.openedCallback) {
                            self.finishedCallback = ^() {
                                [weakSelf.webview evaluateJavaScript:@"player.play();" completionHandler:nil];
                            };
                            self.openedCallback(storyElementCallBackURL, self.finishedCallback);
                        } else {
                            [CPUtils openSafari:storyElementCallBackURL];
                        }

                        NSString *requestURLString = bodyDict[@"url"];
                        if (![CPUtils isNullOrEmpty:requestURLString]) {
                            if ([CPUtils isValidURL:[NSURL URLWithString:requestURLString]]) {
                                NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:requestURLString];
                                [CleverPush enqueueRequest:request onSuccess:nil onFailure:nil];
                            }
                        }
                    }
                }
            }
        }
    } else if ([message.name isEqualToString:@"next"]) {
        [self onDismiss];
    } else if ([message.name isEqualToString:@"storyReady"]) {
        if (self.contentLoadedCompletion) {
            self.contentLoadedCompletion();
        }
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.webview evaluateJavaScript:@"player.play();" completionHandler:nil];
}

#pragma mark - Unread count story navigation methods.
- (void)onStoryNavigation:(NSInteger)position subStoryPosition:(NSInteger)subStoryPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (self.widget.groupStoryCategories) {
        NSMutableArray *storyIdArray = [self.stories[position].id componentsSeparatedByString:@","].mutableCopy;

        NSString *storyUnreadCountString = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
        NSArray *readStoryIdArray = storyUnreadCountString.length > 0 ? [storyUnreadCountString componentsSeparatedByString:@","] : @[];

        NSString *subStoryId = @"";
        if (subStoryPosition >= 0 && subStoryPosition < storyIdArray.count) {
            subStoryId = storyIdArray[subStoryPosition];
        }

        if (storyUnreadCountString.length == 0) {
            storyUnreadCountString = subStoryId;
        } else {
            storyUnreadCountString = [storyUnreadCountString stringByAppendingFormat:@",%@", subStoryId];
        }

        readStoryIdArray = [storyUnreadCountString componentsSeparatedByString:@","];
        NSInteger readCount = 0;

        for (NSString *idString in storyIdArray) {
            if ([readStoryIdArray containsObject:idString]) {
                readCount++;
            }
        }

        NSInteger unreadCount = storyIdArray.count - readCount;

        self.stories[position].unreadCount = unreadCount;
        self.stories[position].opened = YES;

        [defaults setObject:storyUnreadCountString forKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
        [defaults synchronize];

    } else {
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
}

- (NSInteger)getSubStoryPosition:(NSInteger)selectedPosition {
    NSInteger subStoryIndex = 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (self.widget != nil && self.widget.groupStoryCategories) {
        NSArray *storyIdArray = [self.stories[selectedPosition].id componentsSeparatedByString:@","];
        NSString *storyUnreadCountString = [defaults stringForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
        NSArray *readStoryIdArray = [storyUnreadCountString componentsSeparatedByString:@","];

        for (NSString *subStoryID in storyIdArray) {
            if ([readStoryIdArray containsObject:subStoryID]) {
                subStoryIndex++;
            } else {
                break;
            }
        }

        if (storyIdArray.count == subStoryIndex) {
            subStoryIndex = 0;
        }
    } else {
        NSMutableDictionary *storyInfo = [[[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_SUB_STORY_POSITION_KEY] mutableCopy];

        if (storyInfo != nil && storyInfo[self.stories[selectedPosition].id] != nil) {
            subStoryIndex = [storyInfo[self.stories[selectedPosition].id] integerValue] + 1;
        }
    }

    return subStoryIndex;
}

- (void)currentItemIndexDidChange:(NSInteger)index {
    if (![self.readStories containsObject:self.stories[index].id]) {
        [self.readStories addObject:self.stories[index].id];
        self.stories[index].opened = YES;
    }
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.readStories forKey:CLEVERPUSH_SEEN_STORIES_KEY];
    [self.storyStatusMap setObject:@(NO) forKey:@(self.storyIndex)];
    [self trackStoryOpened];
}

#pragma mark - Device orientation
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
            self.webview.frame = self.view.bounds;
            [self.webview layoutIfNeeded];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            [UIView animateWithDuration:0.1 animations:^{
                overlayView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [overlayView removeFromSuperview];
            }];
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
