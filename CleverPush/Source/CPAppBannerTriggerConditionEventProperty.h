#import <Foundation/Foundation.h>

@interface CPAppBannerTriggerConditionEventProperty : NSObject

#pragma mark - Class Variables
@property (nonatomic, strong) NSString *property;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSString *value;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
