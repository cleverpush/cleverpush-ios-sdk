#import "DWAnimatableShapeLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAnimatableShapeLayer ()

@property (null_resettable, strong, nonatomic) NSMutableSet *animatableKeys;

@end

@implementation DWAnimatableShapeLayer

- (void)setAnimationsDisabled {
    [self.animatableKeys removeObject:@"path"];
}

#pragma mark - Private

- (NSMutableSet *)animatableKeys {
    if (!_animatableKeys) {
        _animatableKeys = [NSMutableSet setWithObject:@"path"];
    }
    return _animatableKeys;
}

- (nullable id<CAAction>)actionForKey:(NSString *)event {
    if ([self.animatableKeys containsObject:event]) {
        return [self customAnimationForKey:event];
    }
    return [super actionForKey:event];
}

- (CABasicAnimation *)customAnimationForKey:(NSString *)key {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
    animation.fromValue = [self.presentationLayer valueForKey:key];
    animation.duration = [CATransaction animationDuration];
    return animation;
}

@end

NS_ASSUME_NONNULL_END
