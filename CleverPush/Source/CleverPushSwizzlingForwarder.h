#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CleverPushSwizzlingForwarder : NSObject

- (instancetype)initWithTarget:(id)object withYourSelector:(SEL)yourSelector withOriginalSelector:(SEL)originalSelector;
- (BOOL)hasReceiver;
- (void)invokeWithArgs:(NSArray *)args;

@end

NS_ASSUME_NONNULL_END
