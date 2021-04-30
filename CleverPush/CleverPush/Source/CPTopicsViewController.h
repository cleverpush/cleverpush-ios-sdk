#import <UIKit/UIKit.h>
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
@property (nonatomic, assign) BOOL deselectedAll;
@property (nonatomic, weak) id<ManageHeight> delegate;

- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics;
- (NSMutableArray*)getSelectedTopics;

@end

@protocol ManageHeight <NSObject>

- (void)rearrangeHeight;

@end
