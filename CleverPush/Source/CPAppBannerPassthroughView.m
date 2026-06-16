#import "CPAppBannerPassthroughView.h"
#import <WebKit/WebKit.h>

@implementation CPAppBannerPassthroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    if (hitView == nil || hitView == self || self.bannerContainerView == nil) {
        return nil;
    }

    if (self.closeButtonView && [hitView isDescendantOfView:self.closeButtonView]) {
        return hitView;
    }

    if (self.htmlTouchPassthroughEnabled && [self.bannerContainerView isKindOfClass:[WKWebView class]]) {
        if (![hitView isDescendantOfView:self.bannerContainerView] && hitView != self.bannerContainerView) {
            return nil;
        }

        if (self.webViewTouchableRects == nil || self.webViewTouchableRects.count == 0) {
            return hitView;
        }

        CGPoint webViewPoint = [self convertPoint:point toView:self.bannerContainerView];
        for (NSValue *rectValue in self.webViewTouchableRects) {
            if (CGRectContainsPoint([rectValue CGRectValue], webViewPoint)) {
                return hitView;
            }
        }

        return nil;
    }

    if (![hitView isDescendantOfView:self.bannerContainerView]) {
        return nil;
    }

    WKWebView *webViewAtPoint = [self cp_webViewContainingPoint:point inAncestor:self.bannerContainerView];
    if (webViewAtPoint != nil) {
        if (hitView == webViewAtPoint || [hitView isDescendantOfView:webViewAtPoint]) {
            return hitView;
        }
        return webViewAtPoint;
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

#pragma mark - WKWebView lookup
- (nullable WKWebView *)cp_webViewContainingPoint:(CGPoint)point inAncestor:(UIView *)ancestor {
    if (ancestor == nil || ancestor.hidden || ancestor.alpha < 0.01 || !ancestor.userInteractionEnabled) {
        return nil;
    }

    CGPoint localPoint = [self convertPoint:point toView:ancestor];
    if (![ancestor pointInside:localPoint withEvent:nil]) {
        return nil;
    }

    for (UIView *subview in [ancestor.subviews reverseObjectEnumerator]) {
        WKWebView *match = [self cp_webViewContainingPoint:point inAncestor:subview];
        if (match != nil) {
            return match;
        }
    }

    if ([ancestor isKindOfClass:[WKWebView class]]) {
        return (WKWebView *)ancestor;
    }

    return nil;
}

@end
