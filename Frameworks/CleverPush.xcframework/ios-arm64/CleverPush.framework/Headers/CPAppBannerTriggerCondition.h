#import <Foundation/Foundation.h>
#import "CPAppBannerTriggerConditionType.h"
#import "CPAppBannerTriggerConditionEventProperty.h"

#define CLEVERPUSH_APP_BANNER_UNSUBSCRIBE_EVENT @"CleverPush_APP_BANNER_UNSUBSCRIBE_EVENT"

@interface CPAppBannerTriggerCondition : NSObject

#pragma mark - Class Variables
@property (nonatomic) CPAppBannerTriggerConditionType type;
@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) NSMutableArray<CPAppBannerTriggerConditionEventProperty*> *eventProperties;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSString *deepLinkUrl;
@property (nonatomic, strong) NSString *value;
@property (nonatomic) int sessions;
@property (nonatomic) int seconds;

#pragma mark - Class Methods
- (id)initWithJson:(NSDictionary*)json;

@end
