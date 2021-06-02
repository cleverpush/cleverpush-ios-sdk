#import "DWAlertDismissalAnimationController.h"

#import "DWAlertInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DWAlertDismissalAnimationController

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController =
    [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController =
    [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0
         usingSpringWithDamping:DWAlertTransitionAnimationDampingRatio
          initialSpringVelocity:DWAlertTransitionAnimationInitialVelocity
                        options:DWAlertTransitionAnimationOptions
                     animations:^{
        toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        fromViewController.view.alpha = 0.0;
    }
                     completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return DWAlertTransitionAnimationDuration;
}

@end

NS_ASSUME_NONNULL_END
