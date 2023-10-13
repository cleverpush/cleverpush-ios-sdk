#import <Foundation/Foundation.h>
#import "CPAppBannerBlock.h"
#import "CPAppBannerBackground.h"

@interface CPAppBannerCarouselBlock : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (assign) BOOL isScreenClicked;
@property (assign) BOOL isScreenAlreadyShown;
@property (nonatomic, strong) CPAppBannerBackground *background;

- (id)initWithJson:(NSDictionary*)json;

@end
