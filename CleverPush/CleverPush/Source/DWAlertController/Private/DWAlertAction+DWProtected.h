#import "../DWAlertAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAlertAction ()

@property (nullable, copy, nonatomic) void (^handler)(DWAlertAction *action);

@end

NS_ASSUME_NONNULL_END
