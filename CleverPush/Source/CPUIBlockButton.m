#import "CPUIBlockButton.h"

@implementation CPUIBlockButton

#pragma mark - UIButton set target of the Action Block
- (void)handleControlEvent:(UIControlEvents)event withBlock:(ActionBlock) action {
    _actionBlock = action;
    [self addTarget:self action:@selector(callActionBlock:) forControlEvents:event];
}

#pragma mark - UIButton call back event
- (void)callActionBlock:(id)sender{
    _actionBlock();
}

@end
