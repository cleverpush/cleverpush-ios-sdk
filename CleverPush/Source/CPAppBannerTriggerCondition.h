#import <Foundation/Foundation.h>
#import "CPAppBannerTriggerConditionType.h"

@interface CPAppBannerTriggerCondition : NSObject

#pragma mark - Class Variables
@property (nonatomic) CPAppBannerTriggerConditionType type;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic) int sessions;
@property (nonatomic) int seconds;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
