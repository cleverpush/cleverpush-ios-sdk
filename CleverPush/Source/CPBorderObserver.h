#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Keeps a view's solid / dashed / dotted border in sync with its bounds
@interface CPBorderObserver : NSObject

+ (void)applyBorderToView:(UIView *)view
                    width:(CGFloat)width
                    color:(nullable UIColor *)color
                    style:(nullable NSString *)style
             cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
