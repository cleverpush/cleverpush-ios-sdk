#import <Foundation/Foundation.h>
#import "CPAppBannerBlock.h"
#import "CPAppBannerBackground.h"
#import "CPAppBannerTriggerConditionEventProperty.h"

@interface CPAppBannerEventFilters : NSObject

@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) NSString *property;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *fromValue;
@property (nonatomic, strong) NSString *toValue;
@property (nonatomic, strong) NSString *banner;
@property (nonatomic, assign) NSString *count;
@property (nonatomic, strong) NSString *createdAt;
@property (nonatomic, strong) NSString *updatedAt;
@property (nonatomic, strong) NSString *eventProperty;
@property (nonatomic, strong) NSString *eventValue;
@property (nonatomic, strong) NSString *eventRelation;
@property (nonatomic, strong) NSMutableArray<CPAppBannerTriggerConditionEventProperty*> *eventProperties;

- (id)initWithJson:(NSDictionary*)json;

@end
