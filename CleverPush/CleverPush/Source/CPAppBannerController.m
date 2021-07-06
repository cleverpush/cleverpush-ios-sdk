#import "CPAppBannerController.h"
#import <WebKit/WebKit.h>

@interface CPAppBannerController()

@end

@implementation CPAppBannerController

typedef NS_ENUM(NSInteger, ParentConstraint) {
    ParentConstraintTop,
    ParentConstraintBottom,
    ParentConstraintNone
};

#pragma mark - Initialise blocks banner
- (id)initWithBanner:(CPAppBanner*)banner
{
    self = [super init];
    if (self) {
        self.data = banner;

        [self setModalPresentationStyle:UIModalPresentationCustom];
        [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

        [self.view setContentMode:UIViewContentModeScaleToFill];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.bannerBody = [[UIScrollView alloc] initWithFrame:CGRectMake(20.5, 248, 373, 400)];
        [self.bannerBody setContentMode:UIViewContentModeScaleToFill];
        [self.bannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.bannerBody setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bannerBody setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
        [self.view addSubview:self.bannerBody];
        
        self.backGroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 373, 400)];
        [self.backGroundImage setContentMode:UIViewContentModeScaleToFill];
        [self.backGroundImage setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.backGroundImage setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.backGroundImage setTranslatesAutoresizingMaskIntoConstraints:NO];

        self.bannerBodyContent = [[UIView alloc] initWithFrame:CGRectMake(15, 15, 343, 370)];
        [self.bannerBodyContent setContentMode:UIViewContentModeScaleToFill];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.bannerBodyContent setTranslatesAutoresizingMaskIntoConstraints:NO];

        if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]]) {
            [self.bannerBody addSubview:self.backGroundImage];
            NSLayoutConstraint *backGroundHeight = [NSLayoutConstraint constraintWithItem:self.backGroundImage attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
            NSLayoutConstraint *backGroundWidth = [NSLayoutConstraint constraintWithItem:self.backGroundImage attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
            [self.bannerBody addConstraint:backGroundHeight];
            [self.bannerBody addConstraint:backGroundWidth];
            [self.backGroundImage setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        } else {
            [self.bannerBodyContent setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
        }
        [self.bannerBody addSubview:self.bannerBodyContent];
        
        NSLayoutConstraint *bannerBodyTop = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeTop multiplier:1 constant:15];
        NSLayoutConstraint *bannerBodyBottom = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
        NSLayoutConstraint *bannerBodyX  = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.bannerBody attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *bannerBodyHeight = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeHeight multiplier:1 constant:400];
        bannerBodyHeight.priority = 250;
        NSLayoutConstraint *bannerBodyWidth = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeWidth multiplier:0.9 constant:0];

        self.bannerBody.bounces = NO;
        [self.bannerBody addConstraint:bannerBodyTop];
        [self.bannerBody addConstraint:bannerBodyX];
        [self.bannerBody addConstraint:bannerBodyBottom];
        [self.bannerBody addConstraint:bannerBodyHeight];
        [self.bannerBody addConstraint:bannerBodyWidth];
        
        NSLayoutConstraint *viewWidth = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0.9 constant:0];
        NSLayoutConstraint *viewCenterX  = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *viewCenterY = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant: 0];
        NSLayoutConstraint *topY = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant: 50];
        NSLayoutConstraint *bottomY = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant: -50];
        NSLayoutConstraint *viewHeight = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
        
        [self.view addConstraint:viewHeight];
        [self.view addConstraint:viewWidth];
        [self.view addConstraint:viewCenterX];

        if (self.data.type == CPAppBannerTypeTop) {
            [self.view addConstraint:topY];
        } else if (self.data.type == CPAppBannerTypeCenter) {
            [self.view addConstraint:viewCenterY];
        } else if (self.data.type == CPAppBannerTypeBottom) {
            [self.view addConstraint:bottomY];
        } else {
            [self.view addConstraint:viewCenterY];
        }

        self.bannerBody.layer.cornerRadius = 15.0;
        self.bannerBody.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);

        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)];
        tapGesture.delegate = self;
        tapGesture.cancelsTouchesInView = true;
        tapGesture.numberOfTapsRequired = 1;

        [self.view addGestureRecognizer:tapGesture];
        self.view.userInteractionEnabled = true;
        self.bannerBody.hidden = true;
        [self composeBanner:self.data.blocks];
    }
    return self;
}

#pragma mark - Initialise HTML banner
- (id)initWithHTMLBanner:(CPAppBanner*)banner {
    self = [super init];
    if (self) {
        self.data = banner;
        
        [self setModalPresentationStyle:UIModalPresentationCustom];
        [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self.view setContentMode:UIViewContentModeScaleToFill];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.htmlBannerBody = [[UIView alloc] initWithFrame:CGRectMake(20, [[UIScreen mainScreen] bounds].size.width / 2 , [[UIScreen mainScreen] bounds].size.width - 40 , 400)];
        [self.htmlBannerBody setContentMode:UIViewContentModeScaleToFill];
        [self.htmlBannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.htmlBannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.htmlBannerBody setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.htmlBannerBody setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
        [self.view addSubview:self.htmlBannerBody];
        
        self.bannerBodyContent = [[UIView alloc] initWithFrame:CGRectMake(20, 20, [[UIScreen mainScreen] bounds].size.width - 80, 360)];
        [self.bannerBodyContent setContentMode:UIViewContentModeScaleToFill];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.bannerBodyContent setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bannerBodyContent setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
        [self.htmlBannerBody addSubview:self.bannerBodyContent];
        self.htmlBannerBody.layer.cornerRadius = 15.0;
        self.htmlBannerBody.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)];
        tapGesture.delegate = self;
        tapGesture.cancelsTouchesInView = true;
        tapGesture.numberOfTapsRequired = 1;
        
        [self.view addGestureRecognizer:tapGesture];
        self.view.userInteractionEnabled = true;
        
        [self composeHTML:self.data.HTMLContent];
    }
    return self;
}

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.data == nil) {
        return;
    }
}
- (void)viewDidLayoutSubviews{
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.data.contentType isEqualToString:@"block"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.bannerBodyContent.frame.size.height > UIScreen.mainScreen.bounds.size.height) {
                CGFloat height = 00.00;
                if (@available(iOS 11.0, *)) {
                    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
                    CGFloat topPadding = window.safeAreaInsets.top;
                    CGFloat bottomPadding = window.safeAreaInsets.bottom;
                    height = UIScreen.mainScreen.bounds.size.height - (topPadding + bottomPadding);
                    NSLayoutConstraint *viewHeight = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:height - 30];
                    [self.view addConstraint:viewHeight];
                } else {
                    height = UIScreen.mainScreen.bounds.size.height;
                    NSLayoutConstraint *viewHeight = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:height - 30];
                    [self.view addConstraint:viewHeight];
                }
            } else {
                NSLayoutConstraint *viewHeight = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:self.bannerBodyContent.frame.size.height + 30];
                [self.view addConstraint:viewHeight];
            }
            self.bannerBody.hidden = false;
            [self fadeIn];
            [self jumpIn];
        });
    }
}

#pragma mark - composeBanner
- (void)composeBanner:(NSMutableArray<CPAppBannerBlock*>*)blocks {
    NSLog(@"CleverPush: composeBanner");
    UIView *prevView = nil;
    int index = 0;
    for (CPAppBannerBlock* block in blocks) {
        ParentConstraint parentConstraint = ParentConstraintNone;
        
        if (index == 0) {
            parentConstraint = ParentConstraintTop;
        } else if (index == [blocks count] - 1) {
            parentConstraint = ParentConstraintBottom;
        }
        
        if (block.type == CPAppBannerBlockTypeButton) {
            UIView *buttonView = [self composeButtonBlock:(CPAppBannerButtonBlock*)block];
            [self activateItemConstrants:buttonView prevView:prevView parentConstraint:parentConstraint];
            prevView = buttonView;
        } else if (block.type == CPAppBannerBlockTypeText) {
            UILabel *textView = [self composeTextBlock:(CPAppBannerTextBlock*)block];
            [self activateItemConstrants:textView prevView:prevView parentConstraint:parentConstraint];
            prevView = textView;
        } else if (block.type == CPAppBannerBlockTypeImage) {
            UIImageView *imageView = [self composeImageBlock:(CPAppBannerImageBlock*)block];
            [self activateItemConstrants:imageView prevView:prevView parentConstraint:parentConstraint];
            prevView = imageView;
        } else if (block.type == CPAppBannerBlockTypeHTML) {
            WKWebView *blockHtml = [self composeHTMLBlock:(CPAppBannerHTMLBlock*)block];
            [self activateItemConstrants:blockHtml prevView:prevView parentConstraint:parentConstraint];
            prevView = blockHtml;
        }
        index++;
    }
}

#pragma mark - creating a blocks of a Button
- (UIView*)composeButtonBlock:(CPAppBannerButtonBlock*)block {
    NSLog(@"CleverPush: composeButtonBlock");
    CPUIBlockButton *button = [CPUIBlockButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:block.text forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:block.color] forState:UIControlStateNormal];
    
    if (block.family && [block.family length] > 0 && [CPUtils fontFamilyExists:block.family]) {
        [button.titleLabel setFont:[UIFont fontWithName:block.family size:(CGFloat)(block.size * 1.2)]];
    } else {
        [button.titleLabel setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightSemibold]];
    }
    
    switch (block.alignment) {
        case CPAppBannerAlignmentRight:
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            break;
        case CPAppBannerAlignmentLeft:
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            break;
        case CPAppBannerAlignmentCenter:
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            break;
    }
    
    button.backgroundColor = [UIColor colorWithHexString:block.background];
    button.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0);
    button.translatesAutoresizingMaskIntoConstraints = false;
    button.layer.cornerRadius = (CGFloat)block.radius;
    button.adjustsImageWhenHighlighted = YES;
    [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [button handleControlEvent:UIControlEventTouchUpInside withBlock:^{
        self.actionCallback(block.action);

        if (block.action.dismiss) {
            [self onDismiss];
        }
    }];
    
    [self.bannerBodyContent addSubview:button];
    return button;
}

#pragma mark - creating a blocks of a Text
- (UILabel*)composeTextBlock:(CPAppBannerTextBlock*)block {
    NSLog(@"CleverPush: composeTextBlock");
    
    UILabel *label = [[UILabel alloc] init];
    
    label.text = block.text;
    label.numberOfLines = 0;
    label.textColor = [UIColor colorWithHexString:block.color];
    
    if (block.family && [block.family length] > 0 && [CPUtils fontFamilyExists:block.family]) {
        [label setFont:[UIFont fontWithName:block.family size:(CGFloat)(block.size * 1.2)]];
    } else {
        [label setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightSemibold]];
    }
    
    [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    label.translatesAutoresizingMaskIntoConstraints = false;
    switch (block.alignment) {
        case CPAppBannerAlignmentRight:
            label.textAlignment = NSTextAlignmentRight;
            break;
        case CPAppBannerAlignmentLeft:
            label.textAlignment = NSTextAlignmentLeft;
            break;
        case CPAppBannerAlignmentCenter:
            label.textAlignment = NSTextAlignmentCenter;
            break;
    }
    [self.bannerBodyContent addSubview:label];
    return label;
}

#pragma mark - creating a blocks of a Image
- (UIImageView*)composeImageBlock:(CPAppBannerImageBlock*)block {
    NSLog(@"CleverPush: composeImageBlock");
    
    UIImageView *imageView = [[CPAspectKeepImageView alloc] init];
    if (block.imageUrl != nil && ![block.imageUrl isKindOfClass:[NSNull class]]) {
        [imageView setImageWithURL:[NSURL URLWithString:block.imageUrl]];
    }
    
    CGFloat AspectRatio = block.scale > 0 ? (CGFloat)block.scale / 100 : 100.0f;
    
    NSLayoutConstraint *imageWidthConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeWidth multiplier:AspectRatio constant:0];
    imageWidthConstraint.priority = UILayoutPriorityRequired;
    
    NSLayoutConstraint *imageHeightConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeWidth multiplier:AspectRatio constant:0];
    imageHeightConstraint.priority = UILayoutPriorityDefaultLow;
    
    NSLayoutConstraint *imageWidthCenterConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    
    imageWidthCenterConstraint.priority = UILayoutPriorityRequired;
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bannerBodyContent addSubview:imageView];
    [self.bannerBodyContent addConstraint:imageWidthConstraint];
    [self.bannerBodyContent addConstraint:imageHeightConstraint];
    [self.bannerBodyContent addConstraint:imageWidthCenterConstraint];
    
    return imageView;
}

#pragma mark - creating a blocks of a HTML
- (WKWebView*)composeHTMLBlock:(CPAppBannerHTMLBlock*)block
{
    NSLog(@"CleverPush: composeHTMLBlock");
    
    WKWebView *webView  = [[WKWebView alloc] init];
    if (block.url != nil && ![block.url isKindOfClass:[NSNull class]]) {
        webView.scrollView.scrollEnabled = true;
        webView.scrollView.bounces = false;
        webView.allowsBackForwardNavigationGestures = false;
        webView.contentMode = UIViewContentModeScaleToFill;
        webView.navigationDelegate = self;
        webView.layer.cornerRadius = 15.0;
        NSURL *url = [NSURL URLWithString:block.url];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }
    
    NSLayoutConstraint *imageWidthConstraint = [NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    imageWidthConstraint.priority = UILayoutPriorityRequired;
    
    NSLayoutConstraint *imageHeightConstraint = [NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:block.height];
    
    imageHeightConstraint.priority = UILayoutPriorityDefaultLow;
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bannerBodyContent addSubview:webView];
    [self.bannerBodyContent addConstraint:imageWidthConstraint];
    [self.bannerBodyContent addConstraint:imageHeightConstraint];
    
    return webView;
}

#pragma mark - creating a banner with HTML
- (WKWebView*)composeHTML:(NSString*)content {
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    WKUserContentController* userController = [[WKUserContentController alloc]init];
    [userController addScriptMessageHandler:self name:@"close"];
    config.userContentController = userController;
    
    _webBanner = [[WKWebView alloc] initWithFrame:self.bannerBodyContent.bounds configuration:config];
    _webBanner.scrollView.scrollEnabled = true;
    _webBanner.scrollView.bounces = false;
    _webBanner.allowsBackForwardNavigationGestures = false;
    _webBanner.contentMode = UIViewContentModeScaleToFill;
    _webBanner.navigationDelegate = self;
    _webBanner.layer.cornerRadius = 15.0;
    [self.bannerBodyContent addSubview:_webBanner];
    
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
    return _webBanner;
}

#pragma mark - UIWebView Delgate Method
- (void)userContentController:(WKUserContentController*)userContentController
      didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.name isEqualToString:@"close"]) {
        [self onDismiss];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            CGFloat height = [result floatValue];
            if (webView == self.webBanner) {
                if (height > UIScreen.mainScreen.bounds.size.height) {
                    self.htmlBannerBody.frame = CGRectMake(20, 70 , self.htmlBannerBody.frame.size.width, UIScreen.mainScreen.bounds.size.height - 140);
                    self.bannerBodyContent.frame = CGRectMake(20, 20, self.bannerBodyContent.frame.size.width, self.htmlBannerBody.frame.size.height - 40);
                    webView.frame = CGRectMake(0, 0, self.bannerBodyContent.frame.size.width, self.bannerBodyContent.frame.size.height);
                } else {
                    CGFloat ScreenHeight = UIScreen.mainScreen.bounds.size.height;
                    CGFloat popupY = (ScreenHeight - height) / 2;
                    self.htmlBannerBody.frame = CGRectMake(20, popupY , self.htmlBannerBody.frame.size.width, height + 40);
                    self.bannerBodyContent.frame = CGRectMake(20, 20, self.bannerBodyContent.frame.size.width, self.htmlBannerBody.frame.size.height - 40);
                    webView.frame = CGRectMake(0, 0, self.bannerBodyContent.frame.size.width, self.bannerBodyContent.frame.size.height);
                }
            }
        }];
    }];
}

#pragma mark - Managed Layout constraints
- (void)activateItemConstrants:(UIView*)view prevView:(UIView*)prevView parentConstraint:(ParentConstraint )parentConstraint {
    if (self.bannerBodyContent == nil) {
        return;
    }
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    rightConstraint.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    leftConstraint.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *topParentConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    topParentConstraint.priority = UILayoutPriorityRequired;
    
    NSLayoutConstraint *bottomParentConstraint = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    bottomParentConstraint.priority = UILayoutPriorityRequired;
    
    [self.bannerBodyContent addConstraint:leftConstraint];
    [self.bannerBodyContent addConstraint:rightConstraint];

    if (parentConstraint == ParentConstraintTop) {
        [self.bannerBodyContent addConstraint:topParentConstraint];
    } else if (parentConstraint == ParentConstraintBottom && prevView) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevView attribute:NSLayoutAttributeBottom multiplier:1 constant:8];
        topConstraint.priority = UILayoutPriorityRequired;
        
        [self.bannerBodyContent addConstraint:topConstraint];
        [self.bannerBodyContent addConstraint:bottomParentConstraint];
    } else if (prevView) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevView attribute:NSLayoutAttributeBottom multiplier:1 constant:8];
        topConstraint.priority = UILayoutPriorityRequired;
        
        [self.bannerBodyContent addConstraint:topConstraint];
    }
    
    CGRect contentRect = CGRectZero;
    
    for (UIView *view in self.bannerBody.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.bannerBody.contentSize = contentRect.size;
}

#pragma mark - Animations
- (void)fadeIn {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
    }];
}

- (void)fadeOut {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
    }];
}

- (void)jumpIn {
    [UIView animateWithDuration:0.25 animations:^{
        self.bannerBody.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:nil];
}

- (void)jumpOut {
    [UIView animateWithDuration:0.25 animations:^{
        self.bannerBody.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
    } completion:nil];
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
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
