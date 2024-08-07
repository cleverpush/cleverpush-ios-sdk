#import <UIKit/UIKit.h>

@interface CPStoryCell : UICollectionViewCell

@property (strong,nonatomic) UIView *outerRing;
@property (strong,nonatomic) UIImageView *image;
@property (strong,nonatomic) UILabel *name;
@property (strong,nonatomic) UILabel *unReadCount;

@end
