#import "CPAppBanner.h"

@implementation CPAppBanner

- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.id = [json objectForKey:@"_id"];
        self.channel = [json objectForKey:@"channel"];
        self.name = [json objectForKey:@"name"];
        self.HTMLContent = [json objectForKey:@"content"];
        self.contentType = [json objectForKey:@"contentType"];
        if ([[json objectForKey:@"type"] isEqual:@"top"]) {
            self.status = CPAppBannerTypeTop;
        } else if ([[json objectForKey:@"type"] isEqual:@"full"]) {
            self.status = CPAppBannerTypeFull;
        } else if ([[json objectForKey:@"type"] isEqual:@"bottom"]) {
            self.status = CPAppBannerTypeBottom;
        } else {
            self.status = CPAppBannerTypeCenter;
        }
        
        if ([[json objectForKey:@"status"] isEqual:@"draft"]) {
            self.status = CPAppBannerStatusDraft;
        } else {
            self.status = CPAppBannerStatusPublished;
        }
        
        self.background = [[CPAppBannerBackground alloc] initWithJson:[json objectForKey:@"background"]];

        
        self.blocks = [NSMutableArray new];
        if ([json objectForKey:@"blocks"] != nil) {
            for (NSDictionary *blockJson in [json objectForKey:@"blocks"]) {
                CPAppBannerBlock* block;
                if ([[blockJson objectForKey:@"type"] isEqual:@"button"]) {
                    block = [[CPAppBannerButtonBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"text"]) {
                    block = [[CPAppBannerTextBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"image"]) {
                    block = [[CPAppBannerImageBlock alloc] initWithJson:blockJson];
                }
                else {
                    continue;
                }
                
                [self.blocks addObject:block];
            }
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        
        if ([[json objectForKey:@"startAt"] isKindOfClass:[NSString class]]) {
            self.startAt = [formatter dateFromString:[json objectForKey:@"startAt"]];
        }
        if ([[json objectForKey:@"stopAt"] isKindOfClass:[NSString class]]) {
            self.stopAt = [formatter dateFromString:[json objectForKey:@"stopAt"]];
        }
        
        if ([[json objectForKey:@"dismissType"] isEqual:@"timeout"]) {
            self.status = CPAppBannerDismissTypeTimeout;
        } else if ([[json objectForKey:@"dismissType"] isEqual:@"till_dismissed"]) {
            self.status = CPAppBannerDismissTypeTillDismissed;
        }
        
        if ([json objectForKey:@"dismissTimeout"] != nil) {
            self.dismissTimeout = [[json objectForKey:@"dismissTimeout"] intValue];
        } else {
            self.dismissTimeout = 60;
        }
        
        if ([[json objectForKey:@"stopAtType"] isEqual:@"forever"]) {
            self.stopAtType = CPAppBannerStopAtTypeForever;
        } else if ([[json objectForKey:@"stopAtType"] isEqual:@"specific_time"]) {
            self.stopAtType = CPAppBannerStopAtTypeSpecificTime;
        }
        
        if ([[json objectForKey:@"frequency"] isEqual:@"once"]) {
            self.frequency = CPAppBannerFrequencyOnce;
        } else if ([[json objectForKey:@"frequency"] isEqual:@"once_per_session"]) {
            self.frequency = CPAppBannerFrequencyOncePerSession;
        }
        
        self.triggers = [NSMutableArray new];
        if ([json objectForKey:@"triggers"] != nil) {
            for (NSDictionary *triggerJson in [json objectForKey:@"triggers"]) {
                [self.triggers addObject:[[CPAppBannerTrigger alloc] initWithJson:triggerJson]];
            }
        }
        
        if ([[json objectForKey:@"triggerType"] isEqual:@"conditions"]) {
            self.triggerType = CPAppBannerTriggerTypeConditions;
        } else {
            self.triggerType = CPAppBannerTriggerTypeAppOpen;
        }
    }
    return self;
}

@end


