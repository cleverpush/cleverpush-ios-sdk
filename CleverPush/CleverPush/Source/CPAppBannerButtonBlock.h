#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerAction.h"

@interface CPAppBannerButtonBlock : CPAppBannerBlock

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *family;
@property (nonatomic, strong) NSString *background;
@property (nonatomic) int size;
@property (nonatomic) CPAppBannerAlignment alignment;
@property (nonatomic) int radius;
@property (nonatomic, strong) CPAppBannerAction* action;

- (id)initWithJson:(NSDictionary*)json;

@end

