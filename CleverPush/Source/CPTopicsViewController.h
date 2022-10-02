#import <UIKit/UIKit.h>
#import "CPUtils.h"

@protocol ManageHeight;

@interface CPTopicsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UITableView *tableView;
    NSMutableArray *availableTopics;
    NSMutableArray *parentTopics;
    NSDictionary *childTopics;
    NSMutableArray *selectedTopics;
    BOOL hasTopics;
}

#pragma mark - Class Variables
@property (nonatomic, assign) BOOL topicsDialogShowUnsubscribe;
@property (nonatomic, weak) id<ManageHeight> delegate;
@property (nonatomic, assign) BOOL topicsDialogShowWhenNewAdded;

#pragma mark - Class Methods
- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics;
- (NSMutableArray*)getSelectedTopics;
@end

#pragma mark - Custom delegate method
@protocol ManageHeight <NSObject>

- (void)rearrangeHeight;

@end
