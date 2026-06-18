#import "CPBorderObserver.h"
#import <objc/runtime.h>

static const void *CPBorderObserverKey = &CPBorderObserverKey;

@interface CPBorderObserver ()

@property (nonatomic, weak) UIView *view;
@property (nonatomic, strong) CALayer *observedLayer;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic) CGFloat width;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSString *style;
@property (nonatomic) CGFloat cornerRadius;

- (instancetype)initWithView:(UIView *)view;
- (void)apply;

@end

@implementation CPBorderObserver

+ (void)applyBorderToView:(UIView *)view
                    width:(CGFloat)width
                    color:(UIColor *)color
                    style:(NSString *)style
             cornerRadius:(CGFloat)cornerRadius {
    if (view == nil) {
        return;
    }
    
    CPBorderObserver *observer = objc_getAssociatedObject(view, CPBorderObserverKey);
    if (observer == nil) {
        observer = [[CPBorderObserver alloc] initWithView:view];
        objc_setAssociatedObject(view, CPBorderObserverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    observer.width = width;
    observer.color = color;
    observer.style = style;
    observer.cornerRadius = cornerRadius;
    [observer apply];
}

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _view = view;
        _observedLayer = view.layer;
        [_observedLayer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        [self apply];
    }
}

- (void)apply {
    UIView *view = self.view;
    if (view == nil) {
        return;
    }
    
    NSString *normalizedStyle = self.style ? [self.style lowercaseString] : @"";
    BOOL isDashed = [normalizedStyle isEqualToString:@"dashed"];
    BOOL isDotted = [normalizedStyle isEqualToString:@"dotted"];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if (self.width <= 0) {
        view.layer.borderWidth = 0;
        [self.borderLayer removeFromSuperlayer];
        self.borderLayer = nil;
        [CATransaction commit];
        return;
    }
    
    UIColor *borderColor = self.color != nil ? self.color : [UIColor whiteColor];
    
    if (isDashed || isDotted) {
        view.layer.borderWidth = 0;
        
        if (self.borderLayer == nil) {
            self.borderLayer = [CAShapeLayer layer];
            self.borderLayer.fillColor = [UIColor clearColor].CGColor;
            [view.layer addSublayer:self.borderLayer];
        }
        
        CGFloat inset = self.width / 2.0;
        CGRect borderRect = CGRectInset(view.bounds, inset, inset);
        CGFloat pathRadius = MAX(self.cornerRadius - inset, 0);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:pathRadius];
        
        self.borderLayer.frame = view.bounds;
        self.borderLayer.path = path.CGPath;
        self.borderLayer.lineWidth = self.width;
        self.borderLayer.strokeColor = borderColor.CGColor;
        
        if (isDotted) {
            self.borderLayer.lineCap = kCALineCapRound;
            self.borderLayer.lineDashPattern = @[@(0.01), @(self.width * 2)];
        } else {
            self.borderLayer.lineCap = kCALineCapButt;
            self.borderLayer.lineDashPattern = @[@(self.width * 3), @(self.width * 2)];
        }
    } else {
        // solid (default)
        [self.borderLayer removeFromSuperlayer];
        self.borderLayer = nil;
        view.layer.borderWidth = self.width;
        view.layer.borderColor = borderColor.CGColor;
    }
    
    [CATransaction commit];
}

- (void)dealloc {
    [_observedLayer removeObserver:self forKeyPath:@"bounds"];
}

@end
