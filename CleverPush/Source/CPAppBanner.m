#import "CPAppBanner.h"
#import "CPLog.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBanner

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.id = [json cleverPushStringForKey:@"_id"];
        self.channel = [json cleverPushStringForKey:@"channel"];
        self.name = [json cleverPushStringForKey:@"name"];
        self.contentType = [json cleverPushStringForKey:@"contentType"];
        if ([self.contentType isEqualToString:@"html"]) {
            self.HTMLContent = [json cleverPushStringForKey:@"content"];
        }
        self.appVersionFilterRelation = [json cleverPushStringForKey:@"appVersionFilterRelation"];
        self.appVersionFilterValue = [json cleverPushStringForKey:@"appVersionFilterValue"];
        self.fromVersion = [json cleverPushStringForKey:@"fromVersion"];
        self.toVersion = [json cleverPushStringForKey:@"toVersion"];

        self.title = [json cleverPushStringForKey:@"title"];
        self.bannerDescription = [json cleverPushStringForKey:@"description"];
        self.mediaUrl = [json cleverPushStringForKey:@"mediaUrl"];

        if ([json cleverPushStringForKey:@"testId"] != nil) {
            self.testId = [json cleverPushStringForKey:@"testId"];
        }

        if ([[json cleverPushStringForKey:@"type"] isEqual:@"top"]) {
            self.type = CPAppBannerTypeTop;
        } else if ([[json cleverPushStringForKey:@"type"] isEqualToString:@"full"]) {
            self.type = CPAppBannerTypeFull;
        } else if ([[json cleverPushStringForKey:@"type"] isEqualToString:@"bottom"]) {
            self.type = CPAppBannerTypeBottom;
        } else {
            self.type = CPAppBannerTypeCenter;
        }

        if ([[json cleverPushStringForKey:@"status"] isEqualToString:@"draft"]) {
            self.status = CPAppBannerStatusDraft;
        } else {
            self.status = CPAppBannerStatusPublished;
        }

        self.background = [[CPAppBannerBackground alloc] initWithJson:[json objectForKey:@"background"]];

        self.blocks = [NSMutableArray new];
        if ([json objectForKey:@"blocks"] != nil) {

            for (NSDictionary *blockJson in [json objectForKey:@"blocks"]) {

                CPAppBannerBlock* block;

                if ([[blockJson cleverPushStringForKey:@"type"] isEqual:@"button"]) {
                    block = [[CPAppBannerButtonBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson cleverPushStringForKey:@"type"] isEqual:@"text"]) {
                    block = [[CPAppBannerTextBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson cleverPushStringForKey:@"type"] isEqual:@"image"]) {
                    block = [[CPAppBannerImageBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson cleverPushStringForKey:@"type"] isEqual:@"html"]) {
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
                if (supportedLanguage != nil && ![supportedLanguage isKindOfClass:[NSNull class]] && [supportedLanguage isKindOfClass:[NSString class]]) {
                    [self.languages addObject:supportedLanguage];
                }
            }
        }

        self.connectedBanners = [NSMutableArray new];
        if (
            [json objectForKey:@"connectedBannersEnabled"] != nil
            && [[json objectForKey:@"connectedBannersEnabled"] isEqual:[NSNumber numberWithBool:true]]
            && [json objectForKey:@"connectedBanners"] != nil
        ) {
            for (NSString *connectedBanner in [json objectForKey:@"connectedBanners"]) {
                if (connectedBanner != nil && ![connectedBanner isKindOfClass:[NSNull class]] && [connectedBanner isKindOfClass:[NSString class]]) {
                    [self.connectedBanners addObject:connectedBanner];
                }
            }
        }

        if ([[json objectForKey:@"startAt"] isKindOfClass:[NSString class]]) {
            self.startAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"startAt"]];
        }
        if ([[json objectForKey:@"stopAt"] isKindOfClass:[NSString class]]) {
            self.stopAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"stopAt"]];
        }

        if ([[json cleverPushStringForKey:@"dismissType"] isEqual:@"timeout"]) {
            self.dismissType = CPAppBannerDismissTypeTimeout;
        } else if ([[json cleverPushStringForKey:@"dismissType"] isEqual:@"till_dismissed"]) {
            self.dismissType = CPAppBannerDismissTypeTillDismissed;
        }

        if ([json cleverPushStringForKey:@"dismissTimeout"] != nil) {
            self.dismissTimeout = [[json cleverPushStringForKey:@"dismissTimeout"] intValue];
        } else {
            self.dismissTimeout = 60;
        }

        if ([json cleverPushStringForKey:@"everyXDays"] != nil) {
            self.everyXDays = [[json cleverPushStringForKey:@"everyXDays"] intValue];
        }

        if ([[json cleverPushStringForKey:@"stopAtType"] isEqual:@"forever"]) {
            self.stopAtType = CPAppBannerStopAtTypeForever;
        } else if ([[json cleverPushStringForKey:@"stopAtType"] isEqual:@"specific_time"]) {
            self.stopAtType = CPAppBannerStopAtTypeSpecificTime;
        }

        if ([[json cleverPushStringForKey:@"frequency"] isEqual:@"once"]) {
            self.frequency = CPAppBannerFrequencyOnce;
        } else if ([[json cleverPushStringForKey:@"frequency"] isEqual:@"once_per_session"]) {
            self.frequency = CPAppBannerFrequencyOncePerSession;
        } else if ([[json cleverPushStringForKey:@"frequency"] isEqual:@"every_trigger"]) {
            self.frequency = CPAppBannerFrequencyEveryTrigger;
        } else if ([[json cleverPushStringForKey:@"frequency"] isEqual:@"every_x_days"]) {
            self.frequency = CPAppBannerFrequencyEveryXDays;
        }

        self.triggers = [NSMutableArray new];

        if ([json objectForKey:@"triggers"] != nil) {
            for (NSDictionary *triggerJson in [json objectForKey:@"triggers"]) {
                [self.triggers addObject:[[CPAppBannerTrigger alloc] initWithJson:triggerJson]];
            }
        }

        self.eventFilters = [NSMutableArray new];
        if ([json objectForKey:@"eventFilters"] != nil) {
            for (NSDictionary *eventFilterJson in [json objectForKey:@"eventFilters"]) {
                [self.eventFilters addObject:[[CPAppBannerEventFilters alloc] initWithJson:eventFilterJson]];
            }
        }

        if ([[json cleverPushStringForKey:@"triggerType"] isEqual:@"conditions"]) {
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

        self.marginEnabled = NO;
        if ([[json objectForKey:@"marginEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.marginEnabled = YES;
        }

        self.closeButtonEnabled = NO;
        if ([[json objectForKey:@"closeButtonEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.closeButtonEnabled = YES;
        }

        self.closeButtonPositionStaticEnabled = NO;
        if ([[json objectForKey:@"closeButtonPositionStaticEnabled"] isEqual:[NSNumber numberWithBool:true]]) {
            self.closeButtonPositionStaticEnabled = YES;
        }

        if ([json cleverPushStringForKey:@"subscribedType"] != nil && [[json cleverPushStringForKey:@"subscribedType"] isEqual:@"subscribed"]) {
            self.subscribedType = CPAppBannerSubscribedTypeSubscribed;
        } else if ([json cleverPushStringForKey:@"subscribedType"] != nil && [[json cleverPushStringForKey:@"subscribedType"] isEqual:@"unsubscribed"]) {
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
        
        if ([json objectForKey:@"osTarget"] && [[json objectForKey:@"osTarget"] isKindOfClass:[NSArray class]]) {
            self.osTarget = [json objectForKey:@"osTarget"];
        }

        if ([json cleverPushStringForKey:@"notificationPermission"] != nil && [[json cleverPushStringForKey:@"notificationPermission"] isEqual:@"withPermission"]) {
            self.notificationPermission = CPAppBannerNotificationWithPermission;
        } else if ([json cleverPushStringForKey:@"notificationPermission"] != nil && [[json cleverPushStringForKey:@"notificationPermission"] isEqual:@"withoutPermission"]) {
            self.notificationPermission = CPAppBannerNotificationWithoutPermission;
        } else {
            self.notificationPermission = CPAppBannerNotificationPermissionAll;
        }
        
        self.attributesLogic = CPAppBannerAttributeLogicTypeAnd;
        if ([[json cleverPushStringForKey:@"attributesLogic"] isEqual:@"and"]) {
            self.attributesLogic = CPAppBannerAttributeLogicTypeAnd;
        } else if ([[json cleverPushStringForKey:@"attributesLogic"] isEqual:@"or"]) {
            self.attributesLogic = CPAppBannerAttributeLogicTypeOr;
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
