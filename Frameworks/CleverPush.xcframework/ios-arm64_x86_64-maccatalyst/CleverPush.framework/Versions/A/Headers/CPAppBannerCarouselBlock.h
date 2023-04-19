#import <Foundation/Foundation.h>
#import "CPAppBannerBlock.h"

@interface CPAppBannerCarouselBlock : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (assign) BOOL isScreenClicked;

- (id)initWithJson:(NSDictionary*)json;

@end
