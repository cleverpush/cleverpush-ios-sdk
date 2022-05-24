#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"

@interface CPAppBannerTextBlock : CPAppBannerBlock

@end

@interface CPAppBannerTextBlock ()

#pragma mark - Class Variables
@property (nonatomic) CPAppBannerAlignment alignment;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *family;
@property (nonatomic) int size;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
