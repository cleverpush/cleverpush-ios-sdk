#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DWAlertActionStyle) {
    DWAlertActionStyleDefault = 0,
    DWAlertActionStyleCancel,
    DWAlertActionStyleDestructive,
} NS_SWIFT_NAME(DWAlertAction.Style);

@interface DWAlertAction : NSObject

#pragma mark - Class Variables
@property (nullable, readonly, copy, nonatomic) NSString *title;
@property (readonly, assign, nonatomic) DWAlertActionStyle style;
@property (assign, nonatomic, getter = isEnabled) BOOL enabled;

#pragma mark - Class Methods
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(DWAlertActionStyle)style handler:(void (^__nullable)(DWAlertAction *action))handler;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
