#import "CPStoryCell.h"

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
}

@end
