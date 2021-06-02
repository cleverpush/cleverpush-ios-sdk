#import <UIKit/UIKit.h>

typedef void (^ActionBlock)(void);

#pragma mark - UIButton category
@interface CPUIBlockButton : UIButton {
    ActionBlock _actionBlock;
}

#pragma mark - UIButton handle control events by ActionBlock
- (void)handleControlEvent:(UIControlEvents)event withBlock:(ActionBlock) action;

@end
