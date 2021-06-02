#import "Private/DWAlertAction+DWProtected.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DWAlertAction

#pragma mark - Initialise with title, style and handler
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(DWAlertActionStyle)style handler:(void (^__nullable)(DWAlertAction *action))handler {
    return [[self alloc] initWithTitle:title style:style handler:handler];
}

#pragma mark - Execution of DWAlertAction
- (instancetype)initWithTitle:(nullable NSString *)title style:(DWAlertActionStyle)style handler:(void (^__nullable)(DWAlertAction *action))handler {
    self = [super init];
    if (self) {
        _title = [title copy];
        _style = style;
        _handler = [handler copy];
        _enabled = YES;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
