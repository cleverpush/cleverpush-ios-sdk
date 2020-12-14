#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerAction.h"

@interface CPAppBannerImageBlock : CPAppBannerBlock

@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic) int scale;
@property (nonatomic, strong) CPAppBannerAction* action;

- (id)initWithJson:(NSDictionary*)json;

@end
