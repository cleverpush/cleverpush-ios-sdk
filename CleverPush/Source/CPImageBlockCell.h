#import <UIKit/UIKit.h>
#import "CPAspectKeepImageView.h"

@interface CPImageBlockCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CPAspectKeepImageView *imgCPBanner;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitydata;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imgCPBannerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imgCPBannerWidthConstraint;

@end
