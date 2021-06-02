#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWDimmingView : UIView

/**
 Visible part of the dimming view (a hole)
 */
@property (nullable, strong, nonatomic) UIBezierPath *visiblePath;

/**
 Dimmed part of the view (entire view by default)
 */
@property (null_resettable, strong, nonatomic) UIBezierPath *dimmedPath;

/**
 Defaults to 1.0
 */
@property (assign, nonatomic) float dimmingOpacity;

/**
 [UIColor blackColor] by default
 */
@property (strong, nonatomic) UIColor *dimmingColor;

/**
 Inverts visible and dimmed paths
 */
@property (assign, nonatomic) BOOL inverted;

/**
 Disable `path` animations of underlying layer
 */
- (void)setPathAnimationsDisabled;

@end

NS_ASSUME_NONNULL_END
