#import "CPAppBanner.h"
#import "CPLog.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBanner

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.id = [json stringForKey:@"_id"];
        self.channel = [json stringForKey:@"channel"];
        self.name = [json stringForKey:@"name"];
        self.HTMLContent = [json stringForKey:@"content"];
        self.contentType = [json stringForKey:@"contentType"];
        self.appVersionFilterRelation = [json stringForKey:@"appVersionFilterRelation"];
        self.appVersionFilterValue = [json stringForKey:@"appVersionFilterValue"];
        self.fromVersion = [json stringForKey:@"fromVersion"];
        self.toVersion = [json stringForKey:@"toVersion"];

        if ([json stringForKey:@"testId"] != nil) {
            self.testId = [json stringForKey:@"testId"];
        }

        if ([[json stringForKey:@"type"] isEqual:@"top"]) {
            self.type = CPAppBannerTypeTop;
        } else if ([[json stringForKey:@"type"] isEqualToString:@"full"]) {
            self.type = CPAppBannerTypeFull;
        } else if ([[json stringForKey:@"type"] isEqualToString:@"bottom"]) {
            self.type = CPAppBannerTypeBottom;
        } else {
            self.type = CPAppBannerTypeCenter;
        }

        if ([[json stringForKey:@"status"] isEqualToString:@"draft"]) {
            self.status = CPAppBannerStatusDraft;
        } else {
            self.status = CPAppBannerStatusPublished;
        }

        self.background = [[CPAppBannerBackground alloc] initWithJson:[json objectForKey:@"background"]];

        self.blocks = [NSMutableArray new];
        if ([json objectForKey:@"blocks"] != nil) {

            for (NSDictionary *blockJson in [json objectForKey:@"blocks"]) {

                CPAppBannerBlock* block;

                if ([[blockJson stringForKey:@"type"] isEqual:@"button"]) {
                    block = [[CPAppBannerButtonBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson stringForKey:@"type"] isEqual:@"text"]) {
                    block = [[CPAppBannerTextBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson stringForKey:@"type"] isEqual:@"image"]) {
                    block = [[CPAppBannerImageBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson stringForKey:@"type"] isEqual:@"html"]) {
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
        }

        self.languages = [NSMutableArray new];

        if ([json objectForKey:@"languages"] != nil) {
            for (NSString *supportedLanguage in [json objectForKey:@"languages"]) {
                [self.languages addObject:supportedLanguage];
            }
        }

        self.connectedBanners = [NSMutableArray new];
        if (
            [json objectForKey:@"connectedBannersEnabled"] != nil
            && [[json objectForKey:@"connectedBannersEnabled"] isEqual:[NSNumber numberWithBool:true]]
            && [json objectForKey:@"connectedBanners"] != nil
        ) {
            for (NSString *connectedBanner in [json objectForKey:@"connectedBanners"]) {
                [self.connectedBanners addObject:connectedBanner];
            }
        }

        if ([[json objectForKey:@"startAt"] isKindOfClass:[NSString class]]) {
            self.startAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"startAt"]];
        }
        if ([[json objectForKey:@"stopAt"] isKindOfClass:[NSString class]]) {
            self.stopAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"stopAt"]];
        }

        if ([[json stringForKey:@"dismissType"] isEqual:@"timeout"]) {
            self.dismissType = CPAppBannerDismissTypeTimeout;
        } else if ([[json stringForKey:@"dismissType"] isEqual:@"till_dismissed"]) {
            self.dismissType = CPAppBannerDismissTypeTillDismissed;
        }

        if ([json stringForKey:@"dismissTimeout"] != nil) {
            self.dismissTimeout = [[json stringForKey:@"dismissTimeout"] intValue];
        } else {
            self.dismissTimeout = 60;
        }

        if ([[json stringForKey:@"stopAtType"] isEqual:@"forever"]) {
            self.stopAtType = CPAppBannerStopAtTypeForever;
        } else if ([[json stringForKey:@"stopAtType"] isEqual:@"specific_time"]) {
            self.stopAtType = CPAppBannerStopAtTypeSpecificTime;
        }

        if ([[json stringForKey:@"frequency"] isEqual:@"once"]) {
            self.frequency = CPAppBannerFrequencyOnce;
        } else if ([[json stringForKey:@"frequency"] isEqual:@"once_per_session"]) {
            self.frequency = CPAppBannerFrequencyOncePerSession;
        }

        self.triggers = [NSMutableArray new];

        if ([json objectForKey:@"triggers"] != nil) {
            for (NSDictionary *triggerJson in [json objectForKey:@"triggers"]) {
                [self.triggers addObject:[[CPAppBannerTrigger alloc] initWithJson:triggerJson]];
            }
        }

        if ([[json stringForKey:@"triggerType"] isEqual:@"conditions"]) {
            self.triggerType = CPAppBannerTriggerTypeConditions;
        } else {
            self.triggerType = CPAppBannerTriggerTypeAppOpen;
        }

        self.carouselEnabled = NO;
        if ([[json objectForKey:@"carouselEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.carouselEnabled = YES;
        }

        self.multipleScreensEnabled = NO;
        if ([[json objectForKey:@"enableMultipleScreens"] isEqual:[NSNumber numberWithBool:true]]) {
            self.multipleScreensEnabled = YES;
        }

        self.darkModeEnabled = NO;
        if ([[json objectForKey:@"darkModeEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.darkModeEnabled = YES;
        }

        self.marginEnabled = YES;
        if ([json objectForKey:@"marginEnabled"] != nil && ![[json objectForKey:@"marginEnabled"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"marginEnabled"] boolValue]) {
            if ([json objectForKey:@"marginEnabled"] == false) {
                self.marginEnabled = NO;
            }
        }

        self.closeButtonEnabled = NO;
        if ([[json objectForKey:@"closeButtonEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.closeButtonEnabled = YES;
        }

        if ([json stringForKey:@"subscribedType"] != nil && [[json stringForKey:@"subscribedType"] isEqual:@"subscribed"]) {
            self.subscribedType = CPAppBannerSubscribedTypeSubscribed;
        } else if ([json stringForKey:@"subscribedType"] != nil && [[json stringForKey:@"subscribedType"] isEqual:@"unsubscribed"]) {
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

- (BOOL)darkModeEnabled:(UITraitCollection*)traitCollection {
    if (@available(iOS 12.0, *)) {
        return [traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark && self.darkModeEnabled;
    }
    return NO;
}

@end
