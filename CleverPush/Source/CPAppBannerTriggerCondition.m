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
            if ([[json objectForKey:@"type"] isEqualToString:@"unsubscribe"]) {
                // We'll use a special event here which is only used internally
                self.type = CPAppBannerTriggerConditionTypeEvent;
                self.event = CLEVERPUSH_APP_BANNER_UNSUBSCRIBE_EVENT;
            }
            if ([[json objectForKey:@"type"] isEqualToString:@"sessions"]) {
                self.type = CPAppBannerTriggerConditionTypeSessions;
            }
            if ([[json objectForKey:@"type"] isEqualToString:@"duration"]) {
                self.type = CPAppBannerTriggerConditionTypeDuration;
            }
        }

        if ([json objectForKey:@"event"] && [[json objectForKey:@"event"] isKindOfClass:[NSString class]]) {
            self.event = [json objectForKey:@"event"];
        }

        self.eventProperties = [NSMutableArray new];
        if ([json objectForKey:@"eventProperties"] != nil) {
            for (NSDictionary *eventPropertyJson in [json objectForKey:@"eventProperties"]) {
                [self.eventProperties addObject:[[CPAppBannerTriggerConditionEventProperty alloc] initWithJson:eventPropertyJson]];
            }
        }

        if ([json objectForKey:@"operator"] && [[json objectForKey:@"operator"] isKindOfClass:[NSString class]]) {
            self.relation = [json objectForKey:@"operator"];
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
