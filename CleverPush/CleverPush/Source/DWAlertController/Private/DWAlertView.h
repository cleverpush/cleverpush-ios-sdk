#import <UIKit/UIKit.h>

#import "../DWAlertAppearanceMode.h"

NS_ASSUME_NONNULL_BEGIN

@class DWAlertAction;
@class DWAlertView;

@protocol DWAlertViewDelegate <NSObject>

- (void)alertView:(DWAlertView *)alertView didAction:(DWAlertAction *)action;

@end

/**
 Internal view of DWAlertController
 */
@interface DWAlertView : UIView

/**
 A Class to use as custom action view.
 Must be a subclass of `DWAlertViewActionBaseView`
 */
@property (null_resettable, strong, nonatomic) Class actionViewClass;
@property (nullable, weak, nonatomic) id<DWAlertViewDelegate> delegate;
@property (nullable, strong, nonatomic) DWAlertAction *preferredAction;

@property (nonatomic, assign) DWAlertAppearanceMode appearanceMode;

@property (strong, nonatomic) UIColor *normalTintColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *disabledTintColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *destructiveTintColor UI_APPEARANCE_SELECTOR;

- (void)setupChildView:(UIView *)childView;
- (void)addAction:(DWAlertAction *)action;
- (void)resetActionsState;
- (void)removeAllActions;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
