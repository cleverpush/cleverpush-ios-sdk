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
    self.tblCPBanner.delegate = self;
    self.tblCPBanner.dataSource = self;
    [self.tblCPBanner addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self backgroundPopupShadow];
        [self setBackground];
        [self setBackgroundColor];
    });
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
    frame.size.height = [CPUtils frameHeightWithoutSafeArea] - 50;
    if (self.tblCPBanner.contentSize.height > [CPUtils frameHeightWithoutSafeArea]) {
        self.tblCPBanner.frame = frame;
    } else {
        if (self.data.type != CPAppBannerTypeFull) {
            frame.size = self.tblCPBanner.contentSize;
        }
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

        if (tableViewContentHeight < viewHeight) {
            CGFloat marginHeight = (viewHeight - tableViewContentHeight) / 2.0;
            self.tblCPBanner.contentInset = UIEdgeInsetsMake(marginHeight, 0, -marginHeight, 0);
            self.tblCPBanner.contentOffset = CGPointMake(0, -marginHeight);
        } else {
            self.tblCPBanner.contentInset = UIEdgeInsetsZero;
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
    [self setBackground];
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

            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat scale = (CGFloat)block.scale / 100.0;
            CGFloat imageViewWidth = screenWidth * scale;
            CGFloat imageViewHeight = imageViewWidth / aspectRatio;

            cell.imgCPBannerWidthConstraint.constant = imageViewWidth;
            cell.imgCPBannerHeightConstraint.constant = imageViewHeight;
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
            [cell.imgCPBanner setImageWithURL:[NSURL URLWithString:imageUrl]callback:^(BOOL callback) {
                if (callback) {
                    [UIView performWithoutAnimation:^{
                        [cell setNeedsLayout];
                        [cell layoutIfNeeded];
                        [tableView beginUpdates];
                        [tableView endUpdates];
                        [cell.activitydata stopAnimating];
                    }];
                }
            }];
        }
        return  cell;
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

            [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:self.data forScreen:screen forButtonBlock:block forImageBlock:nil blockType:@"button"];

            if (hasActionsArray) {
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
        [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:self.data forScreen:screen forButtonBlock:nil forImageBlock:block blockType:@"image"];

        if (hasActionsArray) {
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
        [CPUtils userContentController:userContentController didReceiveScriptMessage:message];
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
    for (CPAppBannerAction *actionItem in actions) {
        [self performActionCallback:actionItem];
    }
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
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
    UIColor *color = [CPUtils readableForegroundColorForBackgroundColor:backgroundColor];

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
    if (self.data.closeButtonEnabled) {
        if (self.data.closeButtonPositionStaticEnabled) {
            self.tblviewTopBannerConstraint.constant =  25;
        }
    }
}

#pragma mark - setup background image
- (void)setBackground {
    [self.imgviewBackground setContentMode:UIViewContentModeScaleAspectFill];

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkImageUrl != nil && ![self.data.background.darkImageUrl isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    if ([self.data darkModeEnabled:self.traitCollection] && self.data.background.darkColor != nil && ![self.data.background.darkColor isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.darkColor]];
        return;
    }

    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]] && ![self.data.background.imageUrl isEqualToString:@""]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
        if (self.data.screens[self.currentScreenIndex].background != nil && ![self.data.screens[self.currentScreenIndex].background isKindOfClass:[NSNull class]] && self.data.screens[self.currentScreenIndex].background.color != nil && ![self.data.screens[self.currentScreenIndex].background.color isKindOfClass:[NSNull class]] && ![self.data.screens[self.currentScreenIndex].background.color isEqualToString:@""]) {
            [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.screens[self.currentScreenIndex].background.color]];
        } else {
            [self.imgviewBackground setBackgroundColor:[UIColor whiteColor]];
        }
    } else {
        [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
    }
}

- (void)setUpPageControl {
    if (self.data.carouselEnabled == true) {
        [self.pageControl setNumberOfPages:self.data.screens.count];
        self.pageControl.hidden = NO;
        self.pageControlHeightConstraint.constant = 30;
        self.tblviewBottomBannerConstraint.constant = 25;
    } else {
        [self.pageControl setNumberOfPages:0];
        self.pageControl.hidden = YES;
        self.pageControlHeightConstraint.constant = 0;
        self.tblviewBottomBannerConstraint.constant = 10;
    }
}

#pragma mark - setup background color
- (void)setBackgroundColor {
    [self.contentView setBackgroundColor:[UIColor clearColor]];

    if (self.data.type == CPAppBannerTypeFull) {
        if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
            if (self.data.screens[self.currentScreenIndex].background != nil && ![self.data.screens[self.currentScreenIndex].background isKindOfClass:[NSNull class]] && self.data.screens[self.currentScreenIndex].background.color != nil && ![self.data.screens[self.currentScreenIndex].background.color isKindOfClass:[NSNull class]] && ![self.data.screens[self.currentScreenIndex].background.color isEqualToString:@""]) {
                [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.screens[self.currentScreenIndex].background.color]];
            } else {
                [self.contentView setBackgroundColor:[UIColor whiteColor]];
            }
        } else {
            [self.contentView setBackgroundColor:[UIColor whiteColor]];
            if (self.data.background.color != nil && ![self.data.background.color isKindOfClass:[NSNull class]] && ![self.data.background.color isEqualToString:@""] ) {
                [self.contentView setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
            }
        }
    }
}

@end
