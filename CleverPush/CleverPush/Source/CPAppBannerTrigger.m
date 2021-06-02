#import "CPAppBannerTrigger.h"

@implementation CPAppBannerTrigger

#pragma mark - wrapping the data of the trigger conditions to CPAppBannerTrigger NSObject

- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self && json && ![json isKindOfClass:[NSNull class]]) {
        self.conditions = [NSMutableArray new];
        if ([json objectForKey:@"conditions"] != nil) {
            for (NSDictionary *conditionJson in [json objectForKey:@"conditions"]) {
                [self.conditions addObject:[[CPAppBannerTriggerCondition alloc] initWithJson:conditionJson]];
            }
        }
    }
    return self;
}

@end
