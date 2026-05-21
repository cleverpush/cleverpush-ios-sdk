#import "CPAppBannerPassthroughView.h"

@implementation CPAppBannerPassthroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    if (hitView == nil || hitView == self || self.bannerContainerView == nil) {
        return nil;
    }

    if (self.closeButtonView && [hitView isDescendantOfView:self.closeButtonView]) {
        return hitView;
    }

    if (![hitView isDescendantOfView:self.bannerContainerView]) {
        return nil;
    }

    if (hitView == self.bannerContainerView) {
        if ([hitView isMemberOfClass:[UIView class]]) {
            return nil;
        }
        return hitView;
    }

    if ([hitView isKindOfClass:[UICollectionView class]]) {
        return nil;
    }

    if ([hitView isMemberOfClass:[UIView class]]) {
        return nil;
    }

    return hitView;
}

@end
