#import "CPAppBanner.h"

@implementation CPAppBanner

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.id = [json objectForKey:@"_id"];
        self.channel = [json objectForKey:@"channel"];
        self.name = [json objectForKey:@"name"];
        self.HTMLContent = [json objectForKey:@"content"];
        self.contentType = [json objectForKey:@"contentType"];
        if ([json objectForKey:@"testId"] != nil) {
            self.testId = [json objectForKey:@"testId"];
        }
        if ([[json objectForKey:@"type"] isEqual:@"top"]) {
            self.type = CPAppBannerTypeTop;
        } else if ([[json objectForKey:@"type"] isEqual:@"full"]) {
            self.type = CPAppBannerTypeFull;
        } else if ([[json objectForKey:@"type"] isEqual:@"bottom"]) {
            self.type = CPAppBannerTypeBottom;
        } else {
            self.type = CPAppBannerTypeCenter;
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
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"html"]) {
                    block = [[CPAppBannerHTMLBlock alloc] initWithJson:blockJson];
                } else {
                    continue;
                }
                [self.blocks addObject:block];
            }
        }

        self.screens = [NSMutableArray new];

        if ([json objectForKey:@"screens"] != nil) {
            for (NSDictionary *screensJson in [json objectForKey:@"screens"]) {
                CPAppBannerCarouselBlock* screensBlock;
                screensBlock = [[CPAppBannerCarouselBlock alloc] initWithJson:screensJson];
                [self.screens addObject:screensBlock];
            }
        } else {
            CPAppBannerCarouselBlock* screensBlock;
            screensBlock = [[CPAppBannerCarouselBlock alloc] init];
            screensBlock.id = 0;
            screensBlock.blocks = self.blocks;
            [self.screens addObject:screensBlock];
            NSLog(@"self.screens: %@", self.screens);
        }

        if ([[json objectForKey:@"startAt"] isKindOfClass:[NSString class]]) {
            self.startAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"startAt"]];
        }
        if ([[json objectForKey:@"stopAt"] isKindOfClass:[NSString class]]) {
            self.stopAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"stopAt"]];
        }

        if ([[json objectForKey:@"dismissType"] isEqual:@"timeout"]) {
            self.dismissType = CPAppBannerDismissTypeTimeout;
        } else if ([[json objectForKey:@"dismissType"] isEqual:@"till_dismissed"]) {
            self.dismissType = CPAppBannerDismissTypeTillDismissed;
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

        self.carouselEnabled = NO;
        if ([[json objectForKey:@"carouselEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.carouselEnabled = YES;
        }

        self.marginEnabled = YES;
        if ([json objectForKey:@"marginEnabled"] != nil && ![[json objectForKey:@"marginEnabled"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"marginEnabled"] boolValue]) {
            if ([json objectForKey:@"marginEnabled"] == false) {
                self.marginEnabled = NO;
            }
        }

        self.closeButtonEnabled = YES;
        if ([json objectForKey:@"closeButtonEnabled"] != nil && ![[json objectForKey:@"closeButtonEnabled"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"closeButtonEnabled"] boolValue]) {
            if ([json objectForKey:@"closeButtonEnabled"] == false) {
                self.closeButtonEnabled = NO;
            }
        }

        if ([json objectForKey:@"subscribedType"] != nil && [[json objectForKey:@"subscribedType"] isEqual:@"subscribed"]) {
            self.subscribedType = CPAppBannerSubscribedTypeSubscribed;
        } else if ([json objectForKey:@"subscribedType"] != nil && [[json objectForKey:@"subscribedType"] isEqual:@"unsubscribed"]) {
            self.subscribedType = CPAppBannerSubscribedTypeUnsubscribed;
        } else {
            self.subscribedType = CPAppBannerSubscribedTypeAll;
        }

        if ([json objectForKey:@"tags"] && [[json objectForKey:@"tags"] isKindOfClass:[NSArray class]]) {
            self.tags = [json objectForKey:@"tags"];
        }
        if ([json objectForKey:@"excludeTags"] && [[json objectForKey:@"excludeTags"] isKindOfClass:[NSArray class]]) {
            self.excludeTags = [json objectForKey:@"excludeTags"];
        }
        if ([json objectForKey:@"topics"] && [[json objectForKey:@"topics"] isKindOfClass:[NSArray class]]) {
            self.topics = [json objectForKey:@"topics"];
        }
        if ([json objectForKey:@"excludeTopics"] && [[json objectForKey:@"excludeTopics"] isKindOfClass:[NSArray class]]) {
            self.excludeTopics = [json objectForKey:@"excludeTopics"];
        }
        if ([json objectForKey:@"attributes"] && [[json objectForKey:@"attributes"] isKindOfClass:[NSArray class]]) {
            self.attributes = [json objectForKey:@"attributes"];
        }
    }
    return self;
}

@end
