#import <UIKit/UIKit.h>
#import "CPImageBlockCell.h"
#import "CPAppBannerBlock.h"
#import "CPAppBanner.h"

@protocol HeightDelegate <NSObject>
- (void)manageTableHeightDelegate:(CGSize)value;
@end

@protocol NavigateNextPage <NSObject>
- (void)navigateToNextPage;
- (void)navigateToNextPage:(NSString *)value;
@end

@interface CPBannerCardContainer : UICollectionViewCell <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tblCPBanner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tblCPBannerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBannerConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewBannerConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerViewBannerConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tblviewTopBannerConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *imgviewBackground;
@property (weak, nonatomic) IBOutlet UIView *viewBannerCardContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, assign) id controller;
@property (nonatomic, weak) id <HeightDelegate> delegate;
@property (nonatomic, weak) id <NavigateNextPage> changePage;
@property (nonatomic, assign) BOOL isVoucherCodeAvailable;
@property (nonatomic, assign) NSString *voucherCode;

- (void)setActionCallback:(CPAppBannerActionBlock)callback;
- (void)setDynamicCloseButton:(BOOL)closeButtonEnabled;

@end
