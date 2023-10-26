#import <Foundation/Foundation.h>
#import "CPAppBannerBlock.h"
#import "CPAppBannerBackground.h"

@interface CPAppBannerEventFilters : NSObject

@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) NSString *property;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *fromValue;
@property (nonatomic, strong) NSString *toValue;
@property (nonatomic, strong) NSString *banner;
@property (nonatomic, assign) NSString *count;
@property (nonatomic, strong) NSString *createdDateTime;
@property (nonatomic, strong) NSString *updatedDateTime;

- (id)initWithJson:(NSDictionary*)json;

@end
