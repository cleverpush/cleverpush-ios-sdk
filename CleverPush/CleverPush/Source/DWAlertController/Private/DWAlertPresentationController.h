#import <UIKit/UIKit.h>

#import "../DWAlertAppearanceMode.h"
#import "DWDimmingView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAlertPresentationController : UIPresentationController

/**
 Appearance mode of the dimming view
 */
@property (nonatomic, assign) DWAlertAppearanceMode appearanceMode;

@property (nullable, strong, nonatomic) DWDimmingView *dimmingView;

@end

NS_ASSUME_NONNULL_END
