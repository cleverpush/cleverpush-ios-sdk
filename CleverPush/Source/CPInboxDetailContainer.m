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
#import "CPInboxDetailContainer.h"

@implementation CPInboxDetailContainer
@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tblCPBanner.delegate = self;
    self.tblCPBanner.dataSource = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self backgroundPopupShadow];
        [self setBackground];
    });
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
            CGFloat aspectRatio = cell.imgCPBanner.frame.size.width / block.imageWidth;
                if (block.imageWidth > [UIScreen mainScreen].bounds.size.width) {
                    cell.imgCPBannerWidthConstraint.constant = [UIScreen mainScreen].bounds.size.width;
                    cell.imgCPBannerHeightConstraint.constant = block.imageWidth / aspectRatio;
                } else {
                    cell.imgCPBannerWidthConstraint.constant = block.imageWidth;
                    cell.imgCPBannerHeightConstraint.constant = block.imageHeight;
                }
        }

        cell.activitydata.transform = CGAffineTransformMakeScale(1, 1);
        [cell.activitydata startAnimating];

        NSString *imageUrl;
        if ([self.data darkModeEnabled:self.tblCPBanner.traitCollection] && block.darkImageUrl != nil) {
            imageUrl = block.darkImageUrl;
        } else {
            imageUrl = block.imageUrl;
        }

        if (imageUrl != nil && ![imageUrl isKindOfClass:[NSNull class]]) {
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

        [cell.btnCPBanner setTitle:block.text forState:UIControlStateNormal];

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

        cell.btnCPBanner.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0);
        cell.btnCPBanner.translatesAutoresizingMaskIntoConstraints = false;
        cell.btnCPBanner.layer.cornerRadius = (CGFloat)block.radius * 0.6;
        cell.btnCPBanner.adjustsImageWhenHighlighted = YES;
        [cell.btnCPBanner setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

        [cell.btnCPBanner handleControlEvent:UIControlEventTouchUpInside withBlock:^{
            [self actionCallback:block.action from:YES];
        }];
        return cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeText) {
        CPTextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPTextBlockCell" forIndexPath:indexPath];
        CPAppBannerTextBlock *block = (CPAppBannerTextBlock*) self.blocks[indexPath.row];

        cell.txtCPBanner.text = block.text;
        cell.txtCPBanner.numberOfLines = 0;

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

        if (block.url != nil && ![block.url isKindOfClass:[NSNull class]]) {
            cell.webHTMLBlock.scrollView.scrollEnabled = false;
            cell.webHTMLBlock.scrollView.bounces = false;
            cell.webHTMLBlock.opaque = false;
            cell.webHTMLBlock.scrollView.backgroundColor = UIColor.clearColor;
            cell.webHTMLBlock.allowsBackForwardNavigationGestures = false;
            cell.webHTMLBlock.contentMode = UIViewContentModeScaleToFill;
            cell.webHTMLBlock.layer.cornerRadius = 15.0;
            NSURL *url = [NSURL URLWithString:block.url];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [cell.webHTMLBlock loadRequest:request];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeImage) {
        CPAppBannerImageBlock *block = (CPAppBannerImageBlock*)self.blocks[indexPath.row];
        [self actionCallback:block.action from:NO];
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

- (void)actionCallback:(CPAppBannerAction*)action from:(BOOL)buttonBlock {
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

    if (self.data.background.imageUrl != nil && ![self.data.background.imageUrl isKindOfClass:[NSNull class]]) {
        [self.imgviewBackground setImageWithURL:[NSURL URLWithString:self.data.background.imageUrl]];
        return;
    }

    [self.imgviewBackground setBackgroundColor:[UIColor colorWithHexString:self.data.background.color]];
}

@end