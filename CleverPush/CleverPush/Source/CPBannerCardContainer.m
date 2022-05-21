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

@implementation CPBannerCardContainer
@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tblCPBanner.delegate = self;
    self.tblCPBanner.dataSource = self;
    [self.tblCPBanner addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
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
        if (self.data.type == CPAppBannerTypeFull) {
            self.tblCPBanner.frame = frame;
        } else {
            frame.size = self.tblCPBanner.contentSize;
            self.tblCPBanner.frame = frame;
        }
    }
    [self dynamicHeight:frame.size];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.blocks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeImage) {
        CPImageBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPImageBlockCell" forIndexPath:indexPath];
        CPAppBannerImageBlock *block = (CPAppBannerImageBlock*)self.blocks[indexPath.row];
        if (block.imageUrl != nil && ![block.imageUrl isKindOfClass:[NSNull class]]) {
            [cell.imgCPBanner setImageWithURL:[NSURL URLWithString:block.imageUrl]callback:^(BOOL callback) {
                if (callback) {
                    [cell setNeedsLayout];
                    [cell layoutIfNeeded];
                    [tableView beginUpdates];
                    [tableView endUpdates];
                }
            }];
        }
        return  cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeButton) {
        CPButtonBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPButtonBlockCell" forIndexPath:indexPath];
        
        CPAppBannerButtonBlock *block = (CPAppBannerButtonBlock*)self.blocks[indexPath.row];
        
        [cell.btnCPBanner setTitle:block.text forState:UIControlStateNormal];
        [cell.btnCPBanner setTitleColor:[UIColor colorWithHexString:block.color] forState:UIControlStateNormal];
        
        if ([CPUtils fontFamilyExists:block.family]) {
            [cell.btnCPBanner.titleLabel setFont:[UIFont fontWithName:block.family size:(CGFloat)(block.size * 1.2)]];
        } else {
            NSLog(@"CleverPush: Font Family not found for button block");
            [cell.btnCPBanner.titleLabel setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightSemibold]];
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
        cell.btnCPBanner.backgroundColor = [UIColor colorWithHexString:block.background];
        cell.btnCPBanner.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0);
        cell.btnCPBanner.translatesAutoresizingMaskIntoConstraints = false;
        cell.btnCPBanner.layer.cornerRadius = (CGFloat)block.radius;
        cell.btnCPBanner.adjustsImageWhenHighlighted = YES;
        [cell.btnCPBanner setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        [cell.btnCPBanner handleControlEvent:UIControlEventTouchUpInside withBlock:^{
            [self actionCallback:block.action from:YES];
        }];
        return cell;
    } else if (self.blocks[indexPath.row].type == CPAppBannerBlockTypeText) {
        CPTextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPTextBlockCell" forIndexPath:indexPath];
        CPAppBannerTextBlock *block = (CPAppBannerTextBlock*)self.blocks[indexPath.row];
        NSLog(@"CleverPush:%@", block.text);

        cell.txtCPBanner.text = block.text;
        cell.txtCPBanner.numberOfLines = 0;
        cell.txtCPBanner.textColor = [UIColor colorWithHexString:block.color];
        
        if ([CPUtils fontFamilyExists:block.family]) {
            [cell.txtCPBanner setFont:[UIFont fontWithName:block.family size:(CGFloat)(block.size * 1.2)]];
        } else {
            NSLog(@"CleverPush: Font Family not found for Text block");
            [cell.txtCPBanner setFont:[UIFont systemFontOfSize:(CGFloat)(block.size * 1.2) weight:UIFontWeightSemibold]];
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
            cell.webHTMLBlock.backgroundColor = UIColor.clearColor;
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
    if (self.data.blocks[indexPath.row].type == CPAppBannerBlockTypeImage) {
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
    if (action.dismiss && action.openInWebview) {
        [CPUtils openSafari:action.url dismissViewController:self.controller];
    } else if (!action.dismiss && action.openInWebview) {
        [CPUtils openSafari:action.url];
    } else if (action.dismiss && ![action.screen isEqualToString:@""] && action.screen != nil) {
        if (self.data.multipleScreensEnabled) {
            [self.changePage navigateToNextPage:action.screen];
        } else {
            [self onDismiss];
        }
    } else if (action.dismiss) {
        [self onDismiss];
    } else {
        if (self.data.carouselEnabled || self.data.multipleScreensEnabled) {
            [self.changePage navigateToNextPage];
        }
    }
}

- (void)onDismiss {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.controller dismissViewControllerAnimated:NO completion:nil];
    });
}

@end

