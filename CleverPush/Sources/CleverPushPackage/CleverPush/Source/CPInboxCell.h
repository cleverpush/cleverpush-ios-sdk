#import <UIKit/UIKit.h>
#import "CPAspectKeepImageView.h"

@interface CPInboxCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *imageParentView;
@property (weak, nonatomic) IBOutlet CPAspectKeepImageView *imageThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *notificationTitle;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *notificationDate;

@end
