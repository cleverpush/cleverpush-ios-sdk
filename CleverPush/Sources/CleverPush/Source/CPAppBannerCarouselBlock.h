#import <Foundation/Foundation.h>
#import "CPAppBannerDismissType.h"
#import "CPAppBannerFrequency.h"
#import "CPAppBannerStatus.h"
#import "CPAppBannerStopAtType.h"
#import "CPAppBannerType.h"
#import "CPAppBannerBackground.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerType.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPUtils.h"

@interface CPAppBannerCarouselBlock : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;

- (id)initWithJson:(NSDictionary*)json;

@end
