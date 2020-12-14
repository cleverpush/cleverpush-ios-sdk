#import "CPIntrinsicTableView.h"

@implementation CPIntrinsicTableView

#pragma mark - UIView

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
}

#pragma mark - UITableView

- (void)endUpdates
{
    [super endUpdates];
    [self invalidateIntrinsicContentSize];
}

- (void)reloadData
{
    [super reloadData];
    [self invalidateIntrinsicContentSize];
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [super reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [super reloadSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [super insertSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [super deleteSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

@end
