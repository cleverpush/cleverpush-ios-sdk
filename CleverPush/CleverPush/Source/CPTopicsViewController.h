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
@property (nonatomic, assign) BOOL deselectedAll;

- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics;
- (NSMutableArray*)getSelectedTopics;

@end
