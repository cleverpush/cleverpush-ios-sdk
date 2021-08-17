#import "CPIntrinsicTableView.h"

@implementation CPIntrinsicTableView

#pragma mark - UIView
#pragma mark Get the dynamic height of the tableView
- (CGSize)intrinsicContentSize {
    [self layoutIfNeeded];
    return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
}

#pragma mark - UITableView
#pragma mark end updates tableView
- (void)endUpdates {
    [super endUpdates];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Reload tableView data
- (void)reloadData {
    [super reloadData];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Reload specific row in a tableView
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Reload specific Section in a tableView
- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super reloadSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Insert Row at apecific index in a tableView
- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Insert Section at apecific index in a tableView
- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Delete Row at apecific index in a tableView
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Delete Section at apecific index in a tableView
- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

@end
