#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerAction.h"

@interface CPAppBannerImageBlock : CPAppBannerBlock

#pragma mark - Class Variables
@property (nonatomic, strong) CPAppBannerAction* action;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic) int scale;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
