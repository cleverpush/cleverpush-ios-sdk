#import <Foundation/Foundation.h>
#import "CPAppBannerTriggerConditionType.h"

@interface CPAppBannerTriggerCondition : NSObject

@property (nonatomic) CPAppBannerTriggerConditionType type;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic) int sessions;
@property (nonatomic) int seconds;

- (id)initWithJson:(NSDictionary*)json;

@end
