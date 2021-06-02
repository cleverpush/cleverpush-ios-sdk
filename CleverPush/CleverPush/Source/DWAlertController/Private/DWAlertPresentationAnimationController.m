#import "DWAlertPresentationAnimationController.h"

#import "DWAlertInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DWAlertPresentationAnimationController

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toViewController =
    [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController =
    [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [[transitionContext containerView] addSubview:toViewController.view];
    
    toViewController.view.transform = CGAffineTransformMakeScale(1.2, 1.2);
    toViewController.view.alpha = 0.0;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0
         usingSpringWithDamping:DWAlertTransitionAnimationDampingRatio
          initialSpringVelocity:DWAlertTransitionAnimationInitialVelocity
                        options:DWAlertTransitionAnimationOptions
                     animations:^{
        fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        toViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.alpha = 1.0;
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
