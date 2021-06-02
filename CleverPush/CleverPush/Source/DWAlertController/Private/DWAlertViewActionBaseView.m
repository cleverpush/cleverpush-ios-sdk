#import "DWAlertViewActionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

static void *DWAlertViewActionBaseViewKVOContext = &DWAlertViewActionBaseViewKVOContext;
static NSString *const AlertActionEnabledKeyPath = @"alertAction.enabled";

@implementation DWAlertViewActionBaseView

- (instancetype)initWithAlertAction:(DWAlertAction *)alertAction {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _alertAction = alertAction;
        
        self.backgroundColor = [UIColor clearColor];
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = alertAction.title;
        self.exclusiveTouch = YES;
        
        [self addObserver:self
               forKeyPath:AlertActionEnabledKeyPath
                  options:NSKeyValueObservingOptionInitial
                  context:DWAlertViewActionBaseViewKVOContext];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self
              forKeyPath:AlertActionEnabledKeyPath
                 context:DWAlertViewActionBaseViewKVOContext];
}

- (void)updateForCurrentContentSizeCategory {
}

- (void)updateEnabledState {
    UIAccessibilityTraits traits = UIAccessibilityTraitButton;
    if (!self.alertAction.enabled) {
        traits |= UIAccessibilityTraitNotEnabled;
    }
    self.accessibilityTraits = traits;
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if (context == DWAlertViewActionBaseViewKVOContext) {
        if ([keyPath isEqualToString:AlertActionEnabledKeyPath]) {
            [self updateEnabledState];
        }
        else {
            NSAssert(NO, @"Unknown keyPath");
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        [self.delegate actionView:self touchBegan:touch];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        [self.delegate actionView:self touchMoved:touch];
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        [self.delegate actionView:self touchEnded:touch];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        [self.delegate actionView:self touchCancelled:touch];
    }
    [super touchesCancelled:touches withEvent:event];
}

@end

NS_ASSUME_NONNULL_END
