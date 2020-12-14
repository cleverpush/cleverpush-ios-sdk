#import <UIKit/UIKit.h>

typedef void (^ActionBlock)();

@interface CPUIBlockButton : UIButton {
    ActionBlock _actionBlock;
}

- (void)handleControlEvent:(UIControlEvents)event withBlock:(ActionBlock) action;

@end
