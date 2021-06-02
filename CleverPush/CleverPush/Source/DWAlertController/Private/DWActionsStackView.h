#import <UIKit/UIKit.h>

#import "DWAlertViewActionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@class DWActionsStackView;

@protocol DWActionsStackViewDelegate <NSObject>

- (void)actionsStackViewDidUpdateLayout:(DWActionsStackView *)view;
- (void)actionsStackView:(DWActionsStackView *)view didAction:(DWAlertAction *)action;
- (void)actionsStackView:(DWActionsStackView *)view highlightActionAtRect:(CGRect)rect;

@end

/**
 Stack view of DWAlertController's actions
 */
@interface DWActionsStackView : UIStackView

@property (readonly, copy, nonatomic) NSArray<DWAlertViewActionBaseView *> *arrangedSubviews;
@property (nullable, weak, nonatomic) id<DWActionsStackViewDelegate> delegate;
@property (nullable, strong, nonatomic) DWAlertAction *preferredAction;

- (void)addActionButton:(DWAlertViewActionBaseView *)button;
- (void)resetActionsState;
- (void)removeAllActions;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithArrangedSubviews:(NSArray<__kindof UIView *> *)views NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
