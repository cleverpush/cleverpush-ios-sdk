#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPAppBannerPassthroughView : UIView
@property (nonatomic, weak, nullable) UIView *bannerContainerView;
@property (nonatomic, weak, nullable) UIView *closeButtonView;

@end

NS_ASSUME_NONNULL_END
