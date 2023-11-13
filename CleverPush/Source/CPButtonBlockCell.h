#import <UIKit/UIKit.h>
#import "CPUIBlockButton.h"

@interface CPButtonBlockCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CPUIBlockButton *btnCPBanner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnCPBannerHeightConstraint;

@end

