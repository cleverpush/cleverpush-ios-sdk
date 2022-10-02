#import <Foundation/Foundation.h>
#import "CPAppBannerBlockType.h"

@interface CPAppBannerBlock : NSObject
@end

@interface CPAppBannerBlock ()

@property (nonatomic) CPAppBannerBlockType type;

- (id)initWithJson:(NSDictionary*)json;
- (CPAppBannerBlock*)create:(NSDictionary*)json;

@end
