#import "CPTopicDialogCell.h"

#define separatorTag 1001

@implementation CPTopicDialogCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void)createSeparator{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    if (separatorView == nil) {
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(8, self.bounds.size.height-1, (self.bounds.size.width - 16), 0.45)];
        separatorView.tag = separatorTag;
        [separatorView setBackgroundColor:[UIColor lightGrayColor]];
        [self.contentView addSubview:separatorView];
    }
}

-(void)updateSeparatorWithTopicHighlighter :(BOOL) isTopicHighlighter{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    if (isTopicHighlighter) {
        [separatorView setFrame:CGRectMake(23, self.bounds.size.height-4, (self.bounds.size.width - 32), 1.0)];
    }else{
        [separatorView setFrame:CGRectMake(8, self.bounds.size.height-4, (self.bounds.size.width - 16), 1.0)];
    }
}

-(void)hideSeprator :(BOOL) isHidden{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    [separatorView setHidden:isHidden];
}


@end
