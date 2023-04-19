#import <Foundation/Foundation.h>
#import "CPAppBannerTriggerCondition.h"

@interface CPAppBannerTrigger : NSObject

#pragma mark - Class Variables
@property (nonatomic, strong) NSMutableArray<CPAppBannerTriggerCondition*> *conditions;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
