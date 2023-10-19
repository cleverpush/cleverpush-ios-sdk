#import <UIKit/UIKit.h>
#import "CPImageBlockCell.h"
#import "CPAppBannerBlock.h"
#import "CPAppBanner.h"

@interface CPInboxDetailContainer : UICollectionViewCell <UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
@property (weak, nonatomic) IBOutlet UITableView *tblCPBanner;
@property (weak, nonatomic) IBOutlet UIImageView *imgviewBackground;
@property (weak, nonatomic) IBOutlet UIView *viewBannerCardContainer;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (strong, nonatomic) CPAppBanner *data;
@property (nonatomic, copy) CPAppBannerActionBlock actionCallback;
@property (nonatomic, assign) id controller;
@property (strong, nonatomic) id <HeightDelegate> delegate;
@property (strong, nonatomic) id <NavigateNextPage> changePage;

- (void)setActionCallback:(CPAppBannerActionBlock)callback;

@end
