#import "CPAppBannerTriggerCondition.h"

@implementation CPAppBannerTriggerCondition

#pragma mark - wrapping the data of the banner trigger condition in to CPAppBannerTriggerCondition NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self && json && ![json isKindOfClass:[NSNull class]]) {
        if ([json objectForKey:@"type"] && [[json objectForKey:@"type"] isKindOfClass:[NSString class]]) {
            if ([[json objectForKey:@"type"] isEqualToString:@"event"]) {
                self.type = CPAppBannerTriggerConditionTypeEvent;
            }
            if ([[json objectForKey:@"type"] isEqualToString:@"sessions"]) {
                self.type = CPAppBannerTriggerConditionTypeSessions;
            }
            if ([[json objectForKey:@"type"] isEqualToString:@"duration"]) {
                self.type = CPAppBannerTriggerConditionTypeDuration;
            }
        }
        
        if ([json objectForKey:@"key"] && [[json objectForKey:@"key"] isKindOfClass:[NSString class]]) {
            self.key = [json objectForKey:@"key"];
        }
        
        if ([json objectForKey:@"value"] && [[json objectForKey:@"value"] isKindOfClass:[NSString class]]) {
            self.value = [json objectForKey:@"value"];
        }
        
        if ([json objectForKey:@"relation"] && [[json objectForKey:@"relation"] isKindOfClass:[NSString class]]) {
            self.relation = [json objectForKey:@"relation"];
        }
        
        if ([json objectForKey:@"sessions"]) {
            self.sessions = [[json objectForKey:@"sessions"] intValue];
        }
        
        if ([json objectForKey:@"seconds"]) {
            self.seconds = [[json objectForKey:@"seconds"] intValue];
        }
    }
    return self;
}

@end
