#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPAppBannerPassthroughView : UIView
@property (nonatomic, weak, nullable) UIView *bannerContainerView;
@property (nonatomic, weak, nullable) UIView *closeButtonView;
@property (nonatomic, assign) BOOL htmlTouchPassthroughEnabled;
@property (nonatomic, copy, nullable) NSArray<NSValue *> *webViewTouchableRects;

@end

NS_ASSUME_NONNULL_END
