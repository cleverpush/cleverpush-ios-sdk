#import <Foundation/Foundation.h>
#import "CPAppBannerBlock.h"
#import "CPAppBannerBackground.h"

@interface CPAppBannerEventFilters : NSObject

@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) NSString *property;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *from_value;
@property (nonatomic, strong) NSString *to_value;

- (id)initWithJson:(NSDictionary*)json;

@end
