#import "CPAppBannerTriggerCondition.h"

@implementation CPAppBannerTriggerConditionEventProperty

#pragma mark - wrapping the data of the banner trigger condition in to CPAppBannerTriggerConditionEventProperty NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self && json && ![json isKindOfClass:[NSNull class]]) {

        if ([json objectForKey:@"property"] && [[json objectForKey:@"property"] isKindOfClass:[NSString class]]) {
            self.property = [json objectForKey:@"property"];
        }

        if ([json objectForKey:@"value"] && [[json objectForKey:@"value"] isKindOfClass:[NSString class]]) {
            self.value = [json objectForKey:@"value"];
        }

        if ([json objectForKey:@"relation"] && [[json objectForKey:@"relation"] isKindOfClass:[NSString class]]) {
            self.relation = [json objectForKey:@"relation"];
        }
    }
    return self;
}

@end
