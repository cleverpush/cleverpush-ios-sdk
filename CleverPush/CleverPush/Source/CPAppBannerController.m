#import "CPAppBannerController.h"

@interface CPAppBannerController()

@end

@implementation CPAppBannerController

typedef NS_ENUM(NSInteger, ParentConstraint) {
    ParentConstraintTop,
    ParentConstraintBottom,
    ParentConstraintNone
};

- (id)initWithBanner:(CPAppBanner*)banner {
    self = [super init];
    if (self) {
        self.data = banner;
        
        [self setModalPresentationStyle:UIModalPresentationCustom];
        [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        
        [self.view setContentMode:UIViewContentModeScaleToFill];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, 414, 896);
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.bannerBody = [[UIView alloc] initWithFrame:CGRectMake(20.5, 248, 373, 400)];
        [self.bannerBody setContentMode:UIViewContentModeScaleToFill];
        [self.bannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bannerBody setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.bannerBody setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bannerBody setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];

        [self.view addSubview:self.bannerBody];
        
        self.bannerBodyContent = [[UIView alloc] initWithFrame:CGRectMake(15, 15, 343, 370)];
        [self.bannerBodyContent setContentMode:UIViewContentModeScaleToFill];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bannerBodyContent setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.bannerBodyContent setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bannerBodyContent setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
        [self.bannerBody addSubview:self.bannerBodyContent];
        
        NSLayoutConstraint *bannerBodyConstraint1 = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeLeading multiplier:1 constant:15];
        NSLayoutConstraint *bannerBodyConstraint2 = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeHeight multiplier:1 constant:400];
        bannerBodyConstraint2.priority = 250;
        NSLayoutConstraint *bannerBodyConstraint3 = [NSLayoutConstraint constraintWithItem:self.bannerBodyContent attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.bannerBody attribute:NSLayoutAttributeTop multiplier:1 constant:15];
        NSLayoutConstraint *bannerBodyConstraint4 = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
        NSLayoutConstraint *bannerBodyConstraint5 = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.bannerBodyContent attribute:NSLayoutAttributeTrailing multiplier:1 constant:15];
        [self.bannerBody addConstraint:bannerBodyConstraint1];
        [self.bannerBody addConstraint:bannerBodyConstraint2];
        [self.bannerBody addConstraint:bannerBodyConstraint3];
        [self.bannerBody addConstraint:bannerBodyConstraint4];
        [self.bannerBody addConstraint:bannerBodyConstraint5];
        
        NSLayoutConstraint *viewConstraint1 = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0.9 constant:0];
        NSLayoutConstraint *viewConstraint2 = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *viewConstraint3 = [NSLayoutConstraint constraintWithItem:self.bannerBody attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [self.view addConstraint:viewConstraint1];
        [self.view addConstraint:viewConstraint2];
        [self.view addConstraint:viewConstraint3];
        
        self.bannerBody.layer.cornerRadius = 15.0;
        self.bannerBody.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
        
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)];
        tapGesture.delegate = self;
        tapGesture.cancelsTouchesInView = true;
        tapGesture.numberOfTapsRequired = 1;
        
        [self.view addGestureRecognizer:tapGesture];
        self.view.userInteractionEnabled = true;
        
        [self composeBanner:self.data.blocks];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.data == nil) {
        return;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self fadeIn];
    [self jumpIn];
}

+ (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

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
        }
        
        index++;
    }
}

- (UIView*)composeButtonBlock:(CPAppBannerButtonBlock*)block {
    NSLog(@"CleverPush: composeButtonBlock");
    CPUIBlockButton *button = [CPUIBlockButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:block.text forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:block.color] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightSemibold]];
    
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

- (UILabel*)composeTextBlock:(CPAppBannerTextBlock*)block {
    UILabel *label = [[UILabel alloc] init];
    
    label.text = block.text;
    label.textColor = [UIColor colorWithHexString:block.color];
    [label setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightRegular]];
    
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

- (UIImageView*)composeImageBlock:(CPAppBannerImageBlock*)block {
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
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevView attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
        topConstraint.priority = UILayoutPriorityRequired;
        
        [self.bannerBodyContent addConstraint:topConstraint];
        [self.bannerBodyContent addConstraint:bottomParentConstraint];
    } else if (prevView) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevView attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
        topConstraint.priority = UILayoutPriorityRequired;
        
        [self.bannerBodyContent addConstraint:topConstraint];
    }
}

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
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self fadeOut];
        [self jumpOut];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.view == touch.view;
}

@end
