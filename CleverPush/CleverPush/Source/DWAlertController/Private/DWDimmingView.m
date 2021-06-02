#import "DWDimmingView.h"

#import "DWAnimatableShapeLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWDimmingView ()

@property (strong, nonatomic) DWAnimatableShapeLayer *fillLayer;

@end

@implementation DWDimmingView

@synthesize dimmedPath = _dimmedPath;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDimmingView];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDimmingView];
    }
    return self;
}

- (UIBezierPath *)dimmedPath {
    if (!_dimmedPath) {
        _dimmedPath = [UIBezierPath bezierPathWithRect:self.bounds];
    }
    return _dimmedPath;
}

- (void)setDimmedPath:(nullable UIBezierPath *)dimmedPath {
    _dimmedPath = dimmedPath;
    [self updateWithVisiblePath:self.visiblePath];
}

- (void)setVisiblePath:(nullable UIBezierPath *)visiblePath {
    _visiblePath = visiblePath;
    [self updateWithVisiblePath:visiblePath];
}

- (void)setDimmingOpacity:(float)dimmingOpacity {
    _dimmingOpacity = dimmingOpacity;
    self.fillLayer.opacity = dimmingOpacity;
}

- (void)setDimmingColor:(UIColor *)dimmingColor {
    _dimmingColor = dimmingColor;
    self.fillLayer.fillColor = dimmingColor.CGColor;
}

- (void)setInverted:(BOOL)inverted {
    _inverted = inverted;
    [self updateWithVisiblePath:self.visiblePath];
}

- (void)setPathAnimationsDisabled {
    [self.fillLayer setAnimationsDisabled];
}

#pragma mark - Private

- (DWAnimatableShapeLayer *)fillLayer {
    if (!_fillLayer) {
        _fillLayer = [DWAnimatableShapeLayer layer];
        _fillLayer.fillRule = kCAFillRuleEvenOdd;
        [self.layer addSublayer:_fillLayer];
    }
    return _fillLayer;
}

- (void)setupDimmingView {
    self.dimmingOpacity = 1.0;
    self.dimmingColor = [UIColor blackColor];
}

- (void)updateWithVisiblePath:(nullable UIBezierPath *)visiblePath {
    UIBezierPath *dimmedPath = nil;
    if (self.inverted) {
        dimmedPath = visiblePath;
    }
    else {
        dimmedPath = [UIBezierPath bezierPathWithCGPath:self.dimmedPath.CGPath];
        if (visiblePath) {
            visiblePath.usesEvenOddFillRule = YES;
            [dimmedPath appendPath:visiblePath];
        }
    }
    dimmedPath.usesEvenOddFillRule = YES;
    
    self.fillLayer.path = dimmedPath.CGPath;
}

@end

NS_ASSUME_NONNULL_END
