#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface CPTopicDialogCell : UITableViewCell
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraints;
@property (weak, nonatomic) IBOutlet UISwitch *operatableSwitch;
@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *topicHighlighter;

@end
NS_ASSUME_NONNULL_END
