#import <UIKit/UIKit.h>

@interface CPTopicsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    
    UITableView *tableView;
    NSMutableArray *availableTopics;
    NSMutableArray *parentTopics;
    NSDictionary *childTopics;
    NSMutableArray *selectedTopics;
    BOOL hasTopics;
}

- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics;
- (NSMutableArray*)getSelectedTopics;

@end
