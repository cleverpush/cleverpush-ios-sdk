#import "CPAppBannerBlockType.h"
#import "CPAppBannerAlignment.h"
#import "CPAppBannerBlock.h"

@interface CPAppBannerTextBlock : CPAppBannerBlock

@end

@interface CPAppBannerTextBlock ()

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *color;
@property (nonatomic) int size;
@property (nonatomic) CPAppBannerAlignment alignment;

- (id)initWithJson:(NSDictionary*)json;

@end
