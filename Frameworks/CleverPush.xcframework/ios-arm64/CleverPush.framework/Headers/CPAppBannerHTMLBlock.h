#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerAction.h"

@interface CPAppBannerHTMLBlock : CPAppBannerBlock

#pragma mark - Class Variables
@property (nonatomic, strong) CPAppBannerAction* action;
@property (nonatomic, strong) NSString *url;
@property (nonatomic) int height;
@property (nonatomic) int scale;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
