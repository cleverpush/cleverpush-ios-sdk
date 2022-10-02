#import "UIControl+CPBlockActions.h"

@interface CPBlockActionWrapper : NSObject

@property (nonatomic, copy) void (^blockAction)(void);

- (void) invokeBlock:(id)sender;

@end

@implementation CPBlockActionWrapper

@synthesize blockAction;

- (void) invokeBlock:(id)sender {
    [self blockAction]();
}

@end

@implementation UIControl (CPBlockActions)

NSMutableArray *blockActions;

#pragma mark - Event handler with contol events
- (void) addEventHandler:(void(^)(void))handler forControlEvents:(UIControlEvents)controlEvents {
    if (blockActions == nil) {
        blockActions = [NSMutableArray array];
    }
    
    CPBlockActionWrapper * target = [[CPBlockActionWrapper alloc] init];
    [target setBlockAction:handler];
    [blockActions addObject:target];
    
    [self addTarget:target action:@selector(invokeBlock:) forControlEvents:controlEvents];
}

@end
