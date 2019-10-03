#define AlertPadding 10
#define MenuHeight 44

#define AlertHeight 80
#define AlertWidth 270

#import "JKAlertDialog.h"
@implementation JKAlertDialogItem
@end

@implementation JKAlertDialog
- (instancetype)init{
    self = [super init];
    if (self) {
        _items = [[NSMutableArray alloc] init];
        
        [self buildViews];
    }
    return self;
}
-(void)buildViews{
    self.frame = [self screenBounds];
     _coverView = [[UIView alloc]initWithFrame:[self topView].bounds];
    _coverView.backgroundColor = [UIColor blackColor];
    _coverView.alpha = 0;
    _coverView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [[self topView] addSubview:_coverView];
    
    int maxWidth = [UIScreen mainScreen].bounds.size.width - 100;
    
    _alertView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, maxWidth, AlertHeight)];
    _alertView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _alertView.layer.cornerRadius = 5;
    _alertView.layer.masksToBounds = YES;
    _alertView.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:_alertView];
  
    _contentScrollView = [[UIScrollView alloc]initWithFrame:CGRectZero];
    [_alertView addSubview:_contentScrollView];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
}
- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)layoutSubviews{
    _contentScrollView.frame = CGRectMake(0, 0, _alertView.frame.size.width, _alertView.frame.size.height);
    self.contentView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    _contentScrollView.contentSize = self.contentView.frame.size;
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    [_contentScrollView addSubview:self.contentView];
    [self reLayout];
}

- (void)reLayout{
    CGFloat plus;
    if (self.contentView) {
        plus = self.contentView.frame.size.height-(_alertView.frame.size.height);
    }else{
        plus = -(_alertView.frame.size.height);
    }
    plus = MAX(0, plus);
    CGFloat height = MIN([self screenBounds].size.height,_alertView.frame.size.height+plus);
    
    int maxWidth = [UIScreen mainScreen].bounds.size.width - 100;
    
    _alertView.frame = CGRectMake(_alertView.frame.origin.x, _alertView.frame.origin.y, maxWidth, height);
    _alertView.center = self.center;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (CGFloat)heightWithString:(NSString*)string fontSize:(CGFloat)fontSize width:(CGFloat)width
{
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]};
    return  [string boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attrs context:nil].size.height;
}

#pragma mark - show and dismiss
-(UIView*)topView{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    return  window.subviews[0];
}
- (void)show {
    [UIView animateWithDuration:0.5 animations:^{
        _coverView.alpha = 0.5;

    } completion:^(BOOL finished) {
        
    }];
    
    [[self topView] addSubview:self];
    [self showAnimation];
}

- (void)dismiss {
    [self hideAnimation];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
//    [self removeFromSuperview];
}

- (void)showAnimation {
    CAKeyframeAnimation *popAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    popAnimation.duration = 0.4;
    popAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.01f, 0.01f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1f, 1.1f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9f, 0.9f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DIdentity]];
    popAnimation.keyTimes = @[@0.2f, @0.5f, @0.75f, @1.0f];
    popAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                     [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                     [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [_alertView.layer addAnimation:popAnimation forKey:nil];
}

- (void)hideAnimation{
    [UIView animateWithDuration:0.4 animations:^{
        _coverView.alpha = 0.0;
        _alertView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
         [self removeFromSuperview];
    }];

    
}


#pragma mark - Handle device orientation changes
// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification
{
    //    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.frame = [self screenBounds];
    //NSLog(@"self.frame%@",NSStringFromCGRect(self.frame));
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         [self reLayout];
                     }
                     completion:nil
     ];
  

}
- (CGRect)screenBounds
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    // On iOS7, screen width and height doesn't automatically follow orientation
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }
    
    return CGRectMake(0, 0, screenWidth, screenHeight);
}
@end
