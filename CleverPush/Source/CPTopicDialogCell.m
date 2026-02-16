#import "CPTopicDialogCell.h"

#define separatorTag 1001
#define separatorHeight 0.45
#define separatorY 1.0

@implementation CPTopicDialogCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleText.numberOfLines = 0;
    self.titleText.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleText.adjustsFontSizeToFitWidth = NO;
    [self.titleText setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleText setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.topicHighlighter setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    if (@available(iOS 26.0, *)) {
        for (NSLayoutConstraint *constraint in self.contentView.constraints) {
            if (constraint.firstItem == self.contentView &&
                constraint.secondItem == self.operatableSwitch &&
                constraint.firstAttribute == NSLayoutAttributeTrailing &&
                constraint.secondAttribute == NSLayoutAttributeTrailing) {
                constraint.constant = 10.0;
                break;
            }
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (CGFloat)getSwitchTrailingMargin {
    for (NSLayoutConstraint *constraint in self.contentView.constraints) {
        if (constraint.firstItem == self.contentView && 
            constraint.secondItem == self.operatableSwitch &&
            constraint.firstAttribute == NSLayoutAttributeTrailing &&
            constraint.secondAttribute == NSLayoutAttributeTrailing) {
            return constraint.constant;
        }
    }
    return 5.0;
}

- (void)createSeparator{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    if (separatorView == nil) {
        CGFloat leftMargin = self.leadingConstraints.constant;
        CGFloat rightMargin = [self getSwitchTrailingMargin];
        CGFloat separatorWidth = self.bounds.size.width - leftMargin - rightMargin;
        
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, self.bounds.size.height-separatorY, separatorWidth, separatorHeight)];
        separatorView.tag = separatorTag;
        [separatorView setBackgroundColor:[UIColor lightGrayColor]];
        [self.contentView addSubview:separatorView];
    }
}

- (void)updateSeparatorWithTopicHighlighter{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    [self layoutIfNeeded];
    
    CGFloat leftMargin = self.leadingConstraints.constant;
    CGFloat rightMargin = [self getSwitchTrailingMargin];
    CGFloat separatorWidth = self.bounds.size.width - leftMargin - rightMargin;
    
    [separatorView setFrame:CGRectMake(leftMargin, self.bounds.size.height-separatorY, separatorWidth, separatorHeight)];
}

- (void)hideSeprator:(BOOL)isHidden{
    UIView *separatorView = [self.contentView viewWithTag:separatorTag];
    [separatorView setHidden:isHidden];
}

@end
