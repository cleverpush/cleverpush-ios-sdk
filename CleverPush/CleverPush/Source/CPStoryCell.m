#import "CPStoryCell.h"
#define IMAGEVIEW_BORDER_LENGTH 75

@implementation CPStoryCell

#pragma mark - Initialised cell frame
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - UICollectionViewCell Setup
- (void)setup {
    self.backgroundColor = UIColor.clearColor;
    self.outerRing = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGEVIEW_BORDER_LENGTH, IMAGEVIEW_BORDER_LENGTH)];
    [self addSubview:self.outerRing];
    self.image = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, IMAGEVIEW_BORDER_LENGTH - 10, IMAGEVIEW_BORDER_LENGTH - 10)];
    [self.outerRing addSubview:_image];
    self.name = [[UILabel alloc] initWithFrame:CGRectMake(0, self.outerRing.frame.size.height, IMAGEVIEW_BORDER_LENGTH, 30)];
    [self addSubview:self.name];
}
@end
