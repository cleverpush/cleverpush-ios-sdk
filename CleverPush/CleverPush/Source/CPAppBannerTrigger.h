#import <Foundation/Foundation.h>
#import "CPAppBannerTriggerCondition.h"

@interface CPAppBannerTrigger : NSObject

@property (nonatomic, strong) NSMutableArray<CPAppBannerTriggerCondition*> *conditions;

- (id)initWithJson:(NSDictionary*)json;

@end
