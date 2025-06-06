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

@implementation CPBannerCardContainer
@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    [CPLog debug:@"awakeFromNib - data: %@", self.data];
    [CPLog debug:@"awakeFromNib - traitCollection: %@", self.traitCollection];
    
    self.tblCPBanner.delegate = self;
    self.tblCPBanner.dataSource = self;
    [self.tblCPBanner addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];

    [self backgroundPopupShadow];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(getCurrentAppBannerPageIndex:)
                                              name:@"getCurrentAppBannerPageIndexValue"
                                            object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dynamicHeight:(CGSize)value {
    [self.delegate manageTableHeightDelegate:value];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    CGRect frame = self.tblCPBanner.frame;
    CGFloat maxHeight = [CPUtils frameHeightWithoutSafeArea] - 50;
    CGFloat contentHeight = self.tblCPBanner.contentSize.height;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    BOOL isLandscape = screenWidth > screenHeight;
    
    if (isIPad && isLandscape) {
        NSInteger imageCount = 0;
        NSInteger buttonCount = 0;
        
        for (CPAppBannerBlock *block in self.blocks) {
            if (block.type == CPAppBannerBlockTypeImage) {
                imageCount++;
            } else if (block.type == CPAppBannerBlockTypeButton) {
                buttonCount++;
            }
        }
        
        if (imageCount > 0 && buttonCount > 0) {
            maxHeight = screenHeight * 0.7;
        }
    }
    
    if (contentHeight > maxHeight) {
        frame.size.height = maxHeight - 40;
    } else {
        frame.size.height = contentHeight;
    }
    self.tblCPBanner.frame = frame;
    self.tblCPBannerHeightConstraint.constant = frame.size.height;
    if (self.data.carouselEnabled || self.data.closeButtonEnabled) {
        self.tblCPBannerHeightConstraint.constant = frame.size.height - 20;
        if (self.data.closeButtonPositionStaticEnabled) {
            self.tblCPBannerHeightConstraint.constant = frame.size.height - 40;
        }
    }
    [self updateTableViewContentInset];
}

- (void)updateTableViewContentInset {
    if (![self.data.contentType isEqualToString:@"html"]) {
        CGFloat viewHeight = self.tblCPBanner.frame.size.height;
        CGFloat tableViewContentHeight = self.tblCPBanner.contentSize.height;
        
        // Check if device is iPad and in landscape mode
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
        BOOL isLandscape = screenWidth > screenHeight;

        if (tableViewContentHeight < viewHeight) {
            CGFloat marginHeight = (viewHeight - tableViewContentHeight) / 2.0;
            
            // For iPad in landscape, adjust the content position to show more at the top
            if (isIPad && isLandscape) {
                // Count the number of blocks to determine if we have buttons after images
                NSInteger imageCount = 0;
                NSInteger buttonCount = 0;
                
                for (CPAppBannerBlock *block in self.blocks) {
                    if (block.type == CPAppBannerBlockTypeImage) {
                        imageCount++;
                    } else if (block.type == CPAppBannerBlockTypeButton) {
                        buttonCount++;
                    }
                }
                
                // If we have both images and buttons, position content at the top with less bottom padding
                if (imageCount > 0 && buttonCount > 0) {
                    // Use a smaller top inset to move content up slightly
                    CGFloat topInset = marginHeight * 0.5;
                    CGFloat bottomInset = marginHeight * 1.5;
                    
                    // Apply insets without animation to prevent laggy movement
                    [UIView performWithoutAnimation:^{
                        self.tblCPBanner.contentInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);
                        self.tblCPBanner.contentOffset = CGPointMake(0, -topInset);
                    }];
                    return;
                }
            }
            
            // Apply insets without animation to prevent laggy movement
            [UIView performWithoutAnimation:^{
                self.tblCPBanner.contentInset = UIEdgeInsetsMake(marginHeight, 0, marginHeight, 0);
                self.tblCPBanner.contentOffset = CGPointMake(0, -marginHeight);
            }];
        } else {
            // Apply insets without animation to prevent laggy movement
            [UIView performWithoutAnimation:^{
                self.tblCPBanner.contentInset = UIEdgeInsetsZero;
            }];
        }
    }
}

- (void)getCurrentAppBannerPageIndex:(NSNotification *)notification {
    NSDictionary *pagevalue = notification.userInfo;
    NSInteger index = [pagevalue[@"currentIndex"] integerValue];
    self.pageControl.currentPage = index;
    self.currentScreenIndex = index;
    CPAppBanner *appBanner = pagevalue[@"appBanner"];
    self.data = appBanner;
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
            CGFloat aspectRatio = block.imageWidth / (CGFloat)block.imageHeight;
            if (isnan(aspectRatio) || aspectRatio == 0.0) {
                aspectRatio = 1.0;
            }

            // Always get the current screen dimensions to ensure we have the latest orientation
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
            
            // Check if device is iPad and in landscape mode
            BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
            BOOL isLandscape = screenWidth > screenHeight;
            
            CGFloat scale = (CGFloat)block.scale / 100.0;
            CGFloat imageViewWidth = screenWidth * scale;
            CGFloat imageViewHeight = imageViewWidth / aspectRatio;
            
            // For iPad in landscape, scale down the entire image
            if (isIPad && isLandscape) {
                // More balanced scale factor for iPad in landscape (60% of original size)
                CGFloat scaleFactor = 0.6;
                
                imageViewWidth = imageViewWidth * scaleFactor;
                imageViewHeight = imageViewHeight * scaleFactor;
                
                // Calculate available height for the banner
                CGFloat availableHeight = screenHeight * 0.8; // 80% of screen height
                
                // If the image is still too tall, scale it down further to fit
                if (imageViewHeight > availableHeight * 0.7) { // Allow 70% of available height for image
                    CGFloat heightScaleFactor = (availableHeight * 0.7) / imageViewHeight;
                    imageViewWidth *= heightScaleFactor;
                    imageViewHeight *= heightScaleFactor;
                }
            } else if (isIPad && !isLandscape) {
                // For iPad in portrait, ensure the image isn't too big
                // Use a more moderate scaling factor
                CGFloat scaleFactor = 0.7; // Slightly reduced from 0.8 to ensure it's not too big
                
                imageViewWidth = imageViewWidth * scaleFactor;
                imageViewHeight = imageViewHeight * scaleFactor;
                
                // Limit maximum width in portrait mode
                CGFloat maxPortraitWidth = screenWidth * 0.85; // 85% of screen width
                if (imageViewWidth > maxPortraitWidth) {
                    CGFloat widthScaleFactor = maxPortraitWidth / imageViewWidth;
                    imageViewWidth = maxPortraitWidth;
                    imageViewHeight *= widthScaleFactor;
                }
                
                // Limit maximum height in portrait mode
                CGFloat maxPortraitHeight = screenHeight * 0.5; // 50% of screen height
                if (imageViewHeight > maxPortraitHeight) {
                    CGFloat heightScaleFactor = maxPortraitHeight / imageViewHeight;
                    imageViewHeight = maxPortraitHeight;
                    imageViewWidth *= heightScaleFactor;
                }
            }
            
            // Set the width and height constraints directly without animation
            [UIView performWithoutAnimation:^{
                cell.imgCPBannerWidthConstraint.constant = imageViewWidth;
                cell.imgCPBannerHeightConstraint.constant = imageViewHeight;
                
                // Force immediate layout to apply the new constraints
                [cell setNeedsLayout];
                [cell layoutIfNeeded];
            }];
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
            if (@available(iOS 13.0, *)) {
                cell.activitydata.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
            } else {
                cell.activitydata.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            }

            // Check cache first
            UIImage *cachedImage = [[CPUtils sharedImageCache] objectForKey:imageUrl];
            if (cachedImage) {
                cell.imgCPBanner.image = cachedImage;
                [cell.activitydata stopAnimating];
                [UIView performWithoutAnimation:^{
                    [cell setNeedsLayout];
                    [cell layoutIfNeeded];
                }];
            } else {
                [cell.imgCPBanner setImageWithURL:[NSURL URLWithString:imageUrl] callback:^(BOOL callback) {
                    if (callback) {
                        [UIView performWithoutAnimation:^{
                            [cell setNeedsLayout];
                            [cell layoutIfNeeded];
                            [cell.activitydata stopAnimating];
                        }];
                    }
                }];
            }
        }
        return cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeButton) {
        CPButtonBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPButtonBlockCell" forIndexPath:indexPath];

        CPAppBannerButtonBlock *block = (CPAppBannerButtonBlock*)self.blocks[indexPath.row];
        NSString *buttonText = block.text;

        [cell.btnCPBanner setTitle:buttonText forState:UIControlStateNormal];
        if (self.voucherCode != nil && ![self.voucherCode isKindOfClass:[NSNull class]] && ![self.voucherCode isEqualToString:@""]) {
            buttonText = [CPUtils replaceString:@"{voucherCode}" withReplacement:self.voucherCode inString:block.text];
            [cell.btnCPBanner setTitle:buttonText forState:UIControlStateNormal];
        }

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
        CGRect titleRect = [buttonText boundingRectWithSize:maxSize
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
            if (self.voucherCode != nil && ![self.voucherCode isKindOfClass:[NSNull class]] && ![self.voucherCode isEqualToString:@""]) {
                block.action.url = [CPUtils replaceAndEncodeURL:block.action.url withReplacement:self.voucherCode];
            }
            BOOL hasActionsArray = block.actions != nil &&
                                   ![block.actions isKindOfClass:[NSNull class]] &&
                                   [block.actions isKindOfClass:[NSArray class]] &&
                                    [(block.actions) count] > 0;

            CPAppBannerCarouselBlock *screen = [[CPAppBannerCarouselBlock alloc] init];

            if (self.data.multipleScreensEnabled && self.data.screens.count > 0) {
                for (CPAppBannerCarouselBlock *screensList in self.data.screens) {
                    if (!screensList.isScreenClicked) {
                        screen = self.data.screens[self.currentScreenIndex];
                        break;
                    }
                }
            }

            if (hasActionsArray) {
                [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:self.data forScreen:screen forButtonBlock:block forImageBlock:nil blockType:@"button"];
                
                [self actionCallback:block.action actions:block.actions from:YES];
            } else {
                [self actionCallback:block.action from:YES];
            }
        }];
        return cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeText) {
        CPTextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPTextBlockCell" forIndexPath:indexPath];
        CPAppBannerTextBlock *block = (CPAppBannerTextBlock*) self.blocks[indexPath.row];

        cell.txtCPBanner.text = block.text;
        cell.txtCPBanner.numberOfLines = 0;
        if (self.voucherCode != nil && ![self.voucherCode isKindOfClass:[NSNull class]] && ![self.voucherCode isEqualToString:@""]) {
            cell.txtCPBanner.text = [CPUtils replaceString:@"{voucherCode}" withReplacement:self.voucherCode inString:block.text];
        }

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

        for (NSString *name in [CPUtils scriptMessageNames]) {
            [cell.userController addScriptMessageHandler:self name:name];
        }

        cell.webConfiguration.userContentController = cell.userController;

        if (block.content != nil && ![block.content isKindOfClass:[NSNull class]]) {
            cell.webHTMLBlock.scrollView.scrollEnabled = false;
            cell.webHTMLBlock.backgroundColor = UIColor.clearColor;
            cell.webHTMLBlock.scrollView.backgroundColor = UIColor.clearColor;
            cell.webHTMLBlock.layer.cornerRadius = 15.0;
            cell.webHTMLBlock.navigationDelegate = self;
            [CPUtils configureWebView:cell.webHTMLBlock];

            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.webHTMLBlock loadHTMLString:[CPUtils generateBannerHTMLStringWithFunctions:block.content] baseURL:nil];
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
        BOOL hasActionsArray = block.actions != nil &&
                               ![block.actions isKindOfClass:[NSNull class]] &&
                               [block.actions isKindOfClass:[NSArray class]] &&
                                [(block.actions) count] > 0;

        CPAppBannerCarouselBlock *screen = [[CPAppBannerCarouselBlock alloc] init];

        if (self.data.multipleScreensEnabled && self.data.screens.count > 0) {
            for (CPAppBannerCarouselBlock *screensList in self.data.screens) {
                if (!screensList.isScreenClicked) {
                    screen = self.data.screens[self.currentScreenIndex];
                    break;
                }
            }
        }
        
        if (hasActionsArray) {
            [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:self.data forScreen:screen forButtonBlock:nil forImageBlock:block blockType:@"image"];
            
            [self actionCallback:block.action actions:block.actions from:NO];
        } else {
            [self actionCallback:block.action from:NO];
        }
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
        [CPUtils userContentController:userContentController didReceiveScriptMessage:message withBanner:self.data];
    }
}

- (void)performActionCallback:(CPAppBannerAction *)action {
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

- (void)actionCallback:(CPAppBannerAction *)action from:(BOOL)buttonBlock {
    self.actionCallback(action);
    [self performActionCallback:action];
}

- (void)actionCallback:(CPAppBannerAction *)action actions:(NSMutableArray<CPAppBannerAction *> *)actions from:(BOOL)buttonBlock {
    NSMutableArray *urlActions = [NSMutableArray array];
    NSMutableArray *nonUrlActions = [NSMutableArray array];

    for (CPAppBannerAction *actionItem in actions) {
        if ([actionItem.type isEqualToString:@"url"]) {
            [urlActions addObject:actionItem];
        } else {
            [nonUrlActions addObject:actionItem];
        }
    }

    [nonUrlActions addObjectsFromArray:urlActions];
    for (CPAppBannerAction *actionItem in nonUrlActions) {
        [self performActionCallback:actionItem];
    }
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (self.handleBannerClosed) {
            self.handleBannerClosed();
        }
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

#pragma mark - dynamic hide and shows the layer of the view heirarchy.
- (void)setDynamicCloseButton:(BOOL)closeButtonEnabled {
    UIColor *backgroundColor;
    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        backgroundColor = [UIColor colorWithHexString:self.data.background.darkColor];
    } else {
        backgroundColor = [UIColor colorWithHexString:self.data.background.color];
    }

    [self.btnClose setBackgroundColor:UIColor.blackColor];

    if (@available(iOS 13.0, *)) {
        UIImage *multiplyImage = [CPUtils resizedImageNamed:@"multiply" withSize:CGSizeMake(12,12)];
        [self.btnClose setImage:multiplyImage forState:UIControlStateNormal];
        [self.btnClose setTintColor:UIColor.whiteColor];
    } else {
        [self.btnClose setTitle:@"X" forState:UIControlStateNormal];
        [self.btnClose setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }

    self.btnClose.alpha = 0.7;
    self.btnClose.layer.cornerRadius = CGRectGetWidth(self.btnClose.frame) / 2;
    [self.btnClose.layer setMasksToBounds:false];
    [self.btnClose addTarget:self action:@selector(onDismiss) forControlEvents:UIControlEventTouchUpInside];
    if (closeButtonEnabled) {
        self.btnClose.hidden = NO;
    } else {
        self.btnClose.hidden = YES;
    }

    self.tblviewTopBannerConstraint.constant = - 25;
    if (self.data.carouselEnabled || self.data.closeButtonEnabled) {
        self.tblviewTopBannerConstraint.constant = - 15;
        if (self.data.closeButtonEnabled && self.data.closeButtonPositionStaticEnabled) {
            self.tblviewTopBannerConstraint.constant = 25;
        }
    }
}

#pragma mark - setup background image
- (void)setBackgroundInner {
    [self.imgviewBackground setContentMode:UIViewContentModeScaleAspectFill];

    BOOL isDarkMode = [self.data darkModeEnabled:self.traitCollection];

    // First check if we're in a carousel/multi-screen mode and have a screen-specific dark mode setting
    if ((self.data.carouselEnabled || self.data.multipleScreensEnabled) && 
        self.data.screens.count > self.currentScreenIndex) {
        CPAppBannerCarouselBlock *currentScreen = self.data.screens[self.currentScreenIndex];
        if (currentScreen.background != nil && ![currentScreen.background isKindOfClass:[NSNull class]]) {
            if (isDarkMode && currentScreen.background.darkColor != nil && 
                ![currentScreen.background.darkColor isKindOfClass:[NSNull class]]) {
                [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:currentScreen.background.darkColor]];
                return;
            } else if (currentScreen.background.color != nil && 
                      ![currentScreen.background.color isKindOfClass:[NSNull class]] && 
                      ![currentScreen.background.color isEqualToString:@""]) {
                [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:currentScreen.background.color]];
                return;
            }
        }
    }

    // Fall back to banner-level settings
    if (isDarkMode && self.data.background.darkImageUrl != nil && 
        ![self.data.background.darkImageUrl isKindOfClass:[NSNull class]]) {
        NSString *imageUrl = self.data.background.darkImageUrl;
        UIImage *cachedImage = [[CPUtils sharedImageCache] objectForKey:imageUrl];
        if (cachedImage) {
            self.imgviewBackground.image = cachedImage;
        } else {
            [self.imgviewBackground setImageWithURL:[NSURL URLWithString:imageUrl]];
        }
        return;
    }

    if (isDarkMode && self.data.background.darkColor != nil && 
        ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.darkColor]];
        return;
    }

    if (self.data.background.imageUrl != nil && 
        ![self.data.background.imageUrl isKindOfClass:[NSNull class]] && 
        ![self.data.background.imageUrl isEqualToString:@""]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
}

- (void)setUpPageControl {
    if (self.data.carouselEnabled == true) {
        [self.pageControl setNumberOfPages:self.data.screens.count];
        self.pageControl.hidden = NO;
        self.pageControlHeightConstraint.constant = 30;
        self.tblviewBottomBannerConstraint.constant = 25;
        
        // Set page control colors for dark mode
        if ([self.data darkModeEnabled:self.traitCollection]) {
            self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
            self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
        } else {
            self.pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
            self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        }
    } else {
        [self.pageControl setNumberOfPages:0];
        self.pageControl.hidden = YES;
        self.pageControlHeightConstraint.constant = 0;
        self.tblviewBottomBannerConstraint.constant = 10;
    }
}

#pragma mark - setup background color
- (void)setBackgroundOuter {
    [self.contentView setBackgroundColor:[UIColor clearColor]];

    if (self.data.type == CPAppBannerTypeFull) {
        BOOL isDarkMode = [self.data darkModeEnabled:self.traitCollection];
        
        if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
            if (self.data.screens[self.currentScreenIndex].background != nil && 
                ![self.data.screens[self.currentScreenIndex].background isKindOfClass:[NSNull class]]) {
                
                if (isDarkMode && self.data.screens[self.currentScreenIndex].background.darkColor != nil && 
                    ![self.data.screens[self.currentScreenIndex].background.darkColor isKindOfClass:[NSNull class]]) {
                    [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.screens[self.currentScreenIndex].background.darkColor]];
                } else if (self.data.screens[self.currentScreenIndex].background.color != nil && 
                         ![self.data.screens[self.currentScreenIndex].background.color isKindOfClass:[NSNull class]] && 
                         ![self.data.screens[self.currentScreenIndex].background.color isEqualToString:@""]) {
                    [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.screens[self.currentScreenIndex].background.color]];
                } else {
                    [self.contentView setBackgroundColor:[UIColor whiteColor]];
                }
            } else {
                [self.contentView setBackgroundColor:[UIColor whiteColor]];
            }
        } else {
            if (isDarkMode && self.data.background.darkColor != nil && 
                ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
                [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.background.darkColor]];
            } else if (self.data.background.color != nil && 
                     ![self.data.background.color isKindOfClass:[NSNull class]] && 
                     ![self.data.background.color isEqualToString:@""]) {
                [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
            } else {
                [self.contentView setBackgroundColor:[UIColor whiteColor]];
            }
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // Handle both dark mode changes and orientation changes
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [UIView performWithoutAnimation:^{
                [self setBackgroundInner];
                [self setBackgroundOuter];
            }];
        }
    }
    
    // Check if orientation has changed
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(currentOrientation) || UIDeviceOrientationIsPortrait(currentOrientation)) {
        // Use the optimized method for orientation changes
        [self updateForOrientationChange];
    }
}

// Method to handle orientation changes and update the view accordingly
- (void)updateForOrientationChange {
    // Disable animations during updates to prevent lags
    [UIView performWithoutAnimation:^{
        // Force a complete reload of the table view to recalculate image sizes
        [self.tblCPBanner reloadData];
        
        // Update table view content inset
        [self updateTableViewContentInset];
        
        // Force layout update
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        // Update backgrounds
        [self setBackgroundInner];
        [self setBackgroundOuter];
    }];
}

- (void)setData:(CPAppBanner *)data {
    _data = data;
    if (data != nil) {
        [self setBackgroundInner];
        [self setBackgroundOuter];
    }
}

@end
