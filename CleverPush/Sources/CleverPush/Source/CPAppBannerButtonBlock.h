#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerAction.h"

@interface CPAppBannerButtonBlock : CPAppBannerBlock

#pragma mark - Class Variables
@property (nonatomic) CPAppBannerAlignment alignment;
@property (nonatomic, strong) CPAppBannerAction* action;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *background;
@property (nonatomic, strong) NSString *family;
@property (nonatomic) int size;
@property (nonatomic) int radius;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
