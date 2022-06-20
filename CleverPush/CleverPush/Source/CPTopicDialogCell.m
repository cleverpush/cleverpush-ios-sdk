#import "CPTopicDialogCell.h"

#define separatorTag 1001
#define separatorHeight 0.45
#define separatorX 1.0
#define separatorY 1.0

@implementation CPTopicDialogCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)createSeparator{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    if (separatorView == nil) {
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(separatorX, self.bounds.size.height-separatorY, (self.bounds.size.width - (separatorX*2)), separatorHeight)];
        separatorView.tag = separatorTag;
        [separatorView setBackgroundColor:[UIColor lightGrayColor]];
        [self.contentView addSubview:separatorView];
    }
}

- (void)updateSeparatorWithTopicHighlighter{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    [self layoutIfNeeded];
    [separatorView setFrame:CGRectMake(separatorX, self.bounds.size.height-separatorY, (self.bounds.size.width - (separatorX*2)), separatorHeight)];
}

- (void)hideSeprator:(BOOL)isHidden{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    [separatorView setHidden:isHidden];
}

@end
