#import <UIKit/UIKit.h>
#import "CPImageBlockCell.h"
#import "CPAppBannerBlock.h"
#import "CPAppBanner.h"

@protocol HeightDelegate <NSObject>
- (void)ManageTableHeightDelegate:(CGSize)value;
@end

@protocol NavigateNextPage <NSObject>
- (void)NavigateToNextPage;
@end

@interface CPCardContainer : UICollectionViewCell <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tblCPBanner;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, assign) id controller;
@property (nonatomic, weak) id <HeightDelegate> delegate;
@property (nonatomic, weak) id <NavigateNextPage> changePage;

- (void)setActionCallback:(CPAppBannerActionBlock)callback;

@end
