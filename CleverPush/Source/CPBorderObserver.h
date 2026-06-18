#import <UIKit/UIKit.h>

#pragma mark - Keeps a view's solid / dashed / dotted border in sync with its bounds
@interface CPBorderObserver : NSObject

+ (void)applyBorderToView:(UIView *)view
                    width:(CGFloat)width
                    color:(UIColor *)color
                    style:(NSString *)style
             cornerRadius:(CGFloat)cornerRadius;

@end
