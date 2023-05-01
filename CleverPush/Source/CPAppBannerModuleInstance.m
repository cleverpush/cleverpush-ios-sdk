#import "CPAppBannerModuleInstance.h"
#import "CPUtils.h"
#import "CPLog.h"
#import "NSDictionary+SafeExpectations.h"
#import "NSString+VersionComparator.h"

@interface CPAppBannerModuleInstance()

@end

@implementation CPAppBannerModuleInstance

#pragma mark - Class Variables
NSString *ShownAppBannersDefaultsKey = CLEVERPUSH_SHOWN_APP_BANNERS_KEY;
NSMutableArray<CPAppBanner*> *banners;
NSMutableArray<CPAppBanner*> *activeBanners;
NSMutableArray<CPAppBanner*> *pendingBanners;
NSMutableArray<CPAppBanner*> *activePendingBanners;
NSMutableArray* pendingBannerListeners;
NSMutableArray<NSDictionary*> *events;
CPAppBannerActionBlock handleBannerOpened;

BOOL initialized = NO;
BOOL showDrafts = NO;
BOOL pendingBannerRequest = NO;
BOOL bannersDisabled = NO;
BOOL isFromNotification = NO;
BOOL trackingEnabled = YES;

long MIN_SESSION_LENGTH = 30 * 60;
long MIN_SESSION_LENGTH_DEV = 30;
long lastSessionTimestamp;
long sessions = 0;

#pragma mark - Get sessions from NSUserDefaults
- (long)getSessions {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:CLEVERPUSH_APP_BANNER_SESSIONS_KEY];
}

#pragma mark - Save sessions in NSUserDefaults
- (void)saveSessions {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:sessions forKey:CLEVERPUSH_APP_BANNER_SESSIONS_KEY];
    [userDefaults synchronize];
}

#pragma mark - Call back while banner has been open-up successfully
- (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    handleBannerOpened = callback;
}

#pragma mark - load the events
- (void)triggerEvent:(NSString *)eventId properties:(NSDictionary *)properties {
    if ([self getEvents] != nil) {
        [events addObject:@{
            @"id": eventId,
            @"properties": properties ?: [NSDictionary new]
        }];
    } else {
        [CPLog debug:@"triggerEvent - events are nil"];
    }
    [self startup];
}

#pragma mark - Show banners by channel-id and banner-id
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId {
    [self showBanner:channelId bannerId:bannerId notificationId:nil];
}

#pragma mark - Show banners by channel-id and banner-id
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId {
    [self getBanners:channelId bannerId:bannerId notificationId:notificationId groupId:nil completion:^(NSMutableArray<CPAppBanner *> *banners) {
        for (CPAppBanner* banner in banners) {
            if ([banner.id isEqualToString:bannerId]) {
                if ([self getBannersDisabled]) {
                    [pendingBanners addObject:banner];
                    break;
                }
                [self showBanner:banner];
                break;
            }
        }
    }];
}

#pragma mark - Initialised and load the data in to banner by creating banner and schedule banners
- (void)startup {
    [self createBanners:banners];
    [self scheduleBanners];
}

#pragma mark - fetch the details of shownAppBanners from NSUserDefaults by key CleverPush_SHOWN_APP_BANNERS
- (NSMutableArray*)shownAppBanners {
    NSMutableArray* shownAppBanners = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:ShownAppBannersDefaultsKey]];
    if (!shownAppBanners) {
        shownAppBanners = [[NSMutableArray alloc] init];
    }
    return shownAppBanners;
}

#pragma mark - function determine that the banner is visible or not
- (BOOL)isBannerShown:(NSString*)bannerId {
    return [[self shownAppBanners] containsObject:bannerId];
}

#pragma mark - update/set the NSUserDefaults of key CleverPush_SHOWN_APP_BANNERS
- (void)setBannerIsShown:(CPAppBanner*)banner {
    NSMutableArray* shownAppBanners = [self shownAppBanners];
    [shownAppBanners addObject:banner.id];

    if (banner.connectedBanners != nil) {
        for (NSString *connectedBannerId in banner.connectedBanners) {
            if ([shownAppBanners containsObject:connectedBannerId]) {
                continue;
            }
            [shownAppBanners addObject:connectedBannerId];
        }
    }

    [[NSUserDefaults standardUserDefaults] setObject:shownAppBanners forKey:ShownAppBannersDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Initialised a session
- (void)initSession:(NSString*)channelId afterInit:(BOOL)afterInit {
    if ([self getLastSessionTimestamp] > 0
        && ((long)NSDate.date.timeIntervalSince1970 - [self getLastSessionTimestamp]) < [self getMinimumSessionLength]
        ) {
        return;
    }
    activeBanners = [self getActiveBanners];
    [self setLastSessionTimestamp:(long)NSDate.date.timeIntervalSince1970];
    [self setSessions:sessions + 1];
    [self saveSessions];

    if (afterInit) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self getBanners:channelId completion:^(NSMutableArray<CPAppBanner*>* banners) {
                [self startup];
            }];
        });
    }
}

#pragma mark - Initialised a banner with channel
- (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam fromNotification:(BOOL)fromNotification {
    if ([self isInitialized]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self setPendingBannerListeners:[NSMutableArray new]];
    [self setActiveBanners:[NSMutableArray new]];
    [self setPendingBanners:[NSMutableArray new]];
    activePendingBanners = [NSMutableArray new];
    [self setEvents:[NSMutableArray new]];
    [self loadBannersDisabled];
    [self updateShowDraftsFlag:showDraftsParam];
    [self setSessions:[self getSessions]];
    [self updateInitialisedFlag:YES];
    [self setFromNotification:fromNotification];
    if (![self isFromNotification]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self getBanners:channelId completion:^(NSMutableArray<CPAppBanner*>* banners) {
                [self startup];
            }];
        });
    }
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
- (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [self getBanners:channelId bannerId:nil notificationId:nil groupId:nil completion:callback];
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
- (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId groupId:(NSString*)groupId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    if (notificationId == nil) {
        [pendingBannerListeners addObject:callback];
        if ([self getPendingBannerRequest]) {
            return;
        }
        [self setPendingBannerRequest:YES];
    }

    NSString* bannersPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", channelId];

    if ([CleverPush isDevelopmentModeEnabled]) {
        bannersPath = [NSString stringWithFormat:@"%@&t=%f", bannersPath, NSDate.date.timeIntervalSince1970];
    }

    if (notificationId != nil) {
        bannersPath = [NSString stringWithFormat:@"%@&notificationId=%@", bannersPath, notificationId];
    }

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:bannersPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSMutableArray *jsonBanners = [[NSMutableArray alloc] init];
        BOOL useGroupId = groupId != nil && ![groupId isEqualToString:@""];

        if (useGroupId) {
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF contains '%@'", groupId]], [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF contains 'published'"]]]];
            jsonBanners = [[[result objectForKey:@"banners"] filteredArrayUsingPredicate:predicate] mutableCopy];
        } else {
            jsonBanners = [[result objectForKey:@"banners"] mutableCopy];
        }
        
        if (jsonBanners != nil) {
            NSArray *sortedArray = [self sortArrayByDateAndAlphabet:jsonBanners];
            jsonBanners = [sortedArray mutableCopy];
            [self setBanners:[NSMutableArray new]];
            for (NSDictionary* json in jsonBanners) {
                CPAppBanner* banner = [[CPAppBanner alloc] initWithJson:json];

                if (useGroupId) {
                    if (![self bannerTargetingAllowed:banner]) {
                        continue;
                    }

                    if (![self bannerTimeAllowed:banner]) {
                        continue;
                    }
                }

                [banners addObject:banner];
            }

            if (notificationId && callback) {
                callback([self getListOfBanners]);
            } else {
                for (void (^listener)(NSMutableArray<CPAppBanner*>*) in pendingBannerListeners) {
                    if (listener && [self getListOfBanners]) {
                        __strong void (^callbackBlock)(NSMutableArray<CPAppBanner*>*) = listener;
                        callbackBlock([self getListOfBanners]);
                    }
                }
            }
            [self setPendingBannerRequest:NO];
            [self setPendingBannerListeners:[NSMutableArray new]];
        }
    } onFailure:^(NSError* error) {
        [CPLog error:@"Failed getting app banners %@", error];
    }];
}

#pragma mark - check the banner triggering allowed or not.
- (BOOL)bannerTargetingAllowed:(CPAppBanner*)banner {
    BOOL allowed = YES;

    if (banner.languages.count > 0 && [NSLocale preferredLanguages].count > 0) {
        if (![banner.languages containsObject:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]) {
            allowed = NO;
        }
    }
    
    if (banner.subscribedType == CPAppBannerSubscribedTypeSubscribed && ![CleverPush isSubscribed]) {
        allowed = NO;
    }

    if (banner.subscribedType == CPAppBannerSubscribedTypeUnsubscribed && [CleverPush isSubscribed]) {
        allowed = NO;
    }

    if (allowed && banner.tags && [banner.tags count] > 0) {
        allowed = NO;
        for (NSString *tag in banner.tags) {
            if ([CleverPush hasSubscriptionTag:tag]) {
                allowed = YES;
                break;
            }
        }
    }

    if (allowed && banner.excludeTags && [banner.excludeTags count] > 0) {
        for (NSString *tag in banner.excludeTags) {
            if ([CleverPush hasSubscriptionTag:tag]) {
                allowed = NO;
                break;
            }
        }
    }

    if (allowed && banner.topics && [banner.topics count] > 0) {
        allowed = NO;
        for (NSString *topic in banner.topics) {
            if ([CleverPush hasSubscriptionTopic:topic]) {
                allowed = YES;
                break;
            }
        }
    }

    if (allowed && banner.excludeTopics && [banner.excludeTopics count] > 0) {
        for (NSString *topic in banner.excludeTopics) {
            if ([CleverPush hasSubscriptionTopic:topic]) {
                allowed = NO;
                break;
            }
        }
    }

    if (allowed && banner.attributes && [banner.attributes count] > 0) {
        allowed = NO;

        if (![CleverPush isSubscribed]) {
            return allowed;
        }

        for (NSDictionary *attribute in banner.attributes) {
            NSString *attributeId = [attribute cleverPushStringForKey:@"id"];
            NSString *compareAttributeValue = [attribute cleverPushStringForKey:@"value"];
            if (!compareAttributeValue || [compareAttributeValue isKindOfClass:[NSNull class]]) {
                compareAttributeValue = @"";
            }

            NSString *attributeValue = (NSString*)[CleverPush getSubscriptionAttribute:attributeId];
            NSString *relation = [attribute cleverPushStringForKey:@"relation"];
            if (!relation || [relation isKindOfClass:[NSNull class]]) {
                relation = @"equals";
            }

            BOOL attributeFilterAllowed = [self checkRelationFilter:attributeValue compareWith:compareAttributeValue relation:relation isAllowed:YES compareWithFrom:banner.fromVersion compareWithTo:banner.toVersion];
            if (attributeFilterAllowed) {
                allowed = YES;
                break;
            }
        }
    }

    NSString* appVersion = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleShortVersionString"];
    allowed = [self checkRelationAppVersionFilter:appVersion compareWith:banner.appVersionFilterValue relation:banner.appVersionFilterRelation isAllowed:allowed compareWithFrom:banner.fromVersion compareWithTo:banner.toVersion];
    return allowed;
}

- (BOOL)bannerTimeAllowed:(CPAppBanner*)banner {
    return banner.stopAtType == CPAppBannerStopAtTypeSpecificTime && [banner.stopAt compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark - check the banner triggering allowed as per selected custom attributes.
- (BOOL)checkRelationFilter:(NSString*)value compareWith:(NSString*)compareValue relation:(NSString*)relation isAllowed:(BOOL)allowed compareWithFrom:(NSString*)compareValueFrom compareWithTo:(NSString*)compareValueTo {
    return [self checkRelationFilter:value compareWith:compareValue compareWithFrom:compareValue compareWithTo:compareValue relation:relation isAllowed:allowed];
}

#pragma mark - check the banner triggering allowed as per selected custom attributes.
- (BOOL)checkRelationFilter:(NSString*)value compareWith:(NSString*)compareValue compareWithFrom:(NSString*)compareValueFrom compareWithTo:(NSString*)compareValueTo relation:(NSString*)relation isAllowed:(BOOL)allowed {
    if (relation == nil || compareValue == nil || value == nil) {
        allowed = NO;
    }
    if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeEquals)]) {
        if (!CHECK_FILTER_EQUAL_TO(value, compareValue)) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeGreaterThan)]) {
        if (!CHECK_FILTER_GREATER_THAN(value, compareValue)) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeLessThan)]) {
        if (!CHECK_FILTER_LESS_THAN(value, compareValue)) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeNotEqual)]) {
        if (CHECK_FILTER_EQUAL_TO(value, compareValue)) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeContains)]) {
        if ([value rangeOfString:compareValue].location == NSNotFound) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeNotContains)]) {
        if ([value rangeOfString:compareValue].location != NSNotFound) {
            allowed = NO;
        }
    }
    return allowed;
}

#pragma mark - check the banner triggering allowed as per selected version match with app version or not.
- (BOOL)checkRelationAppVersionFilter:(NSString*)value compareWith:(NSString*)compareValue relation:(NSString*)relation isAllowed:(BOOL)allowed compareWithFrom:(NSString*)compareValueFrom compareWithTo:(NSString*)compareValueTo {
    return [self checkRelationAppVersionFilter:value compareWith:compareValue compareWithFrom:compareValue compareWithTo:compareValue relation:relation isAllowed:allowed];
}

#pragma mark - check the banner triggering allowed as per selected version match with app version or not.
- (BOOL)checkRelationAppVersionFilter:(NSString*)value compareWith:(NSString*)compareValue compareWithFrom:(NSString*)compareValueFrom compareWithTo:(NSString*)compareValueTo relation:(NSString*)relation isAllowed:(BOOL)allowed {
    if (relation == nil || compareValue == nil) {
        return allowed;
    }
    if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeEquals)]) {
        if (allowed && ![value isEqualToVersion:compareValue]) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeGreaterThan)]) {
        if ([value isEqualOrOlderThanVersion:compareValue]) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeLessThan)]) {
        if ([value isEqualOrNewerThanVersion:compareValue]) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeBetween)]) {
        if (![value isEqualToVersion:compareValueFrom] && [value isEqualOrOlderThanVersion:compareValueFrom] && ![value isEqualToVersion:compareValueTo] && [value isEqualOrOlderThanVersion:compareValueTo]) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeNotEqual)]) {
        if (allowed && [value isEqualToVersion:compareValue]) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeContains)]) {
        if ([value rangeOfString:compareValue].location == NSNotFound) {
            allowed = NO;
        }
    } else if (allowed && [relation isEqualToString:filterRelationType(CPFilterRelationTypeNotContains)]) {
        if ([value rangeOfString:compareValue].location != NSNotFound) {
            allowed = NO;
        }
    }
    return allowed;
}

- (BOOL)checkEventTriggerCondition:(CPAppBannerTriggerCondition*)condition {
    for (NSDictionary* triggeredEvent in events) {
        if (![[triggeredEvent cleverPushStringForKey:@"id"] isEqualToString:condition.event]) {
            continue;
        }

        if (condition.eventProperties == nil || condition.eventProperties.count == 0) {
            return YES;
        }

        BOOL conditionTrue = YES;

        NSDictionary *properties = (NSDictionary*) [triggeredEvent objectForKey:@"properties"];
        for (CPAppBannerTriggerConditionEventProperty* eventProperty in condition.eventProperties) {
            NSString *propertyValue = [properties cleverPushStringForKey:eventProperty.property];
            NSString *comparePropertyValue = eventProperty.value;

            BOOL eventPropertiesMatching = [self checkRelationFilter:propertyValue compareWith:comparePropertyValue relation:eventProperty.relation isAllowed:YES compareWithFrom:comparePropertyValue compareWithTo:comparePropertyValue];
            if (!eventPropertiesMatching) {
                conditionTrue = NO;
                break;
            }
        }

        if (conditionTrue) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Create banners based on conditional attributes within the objects
- (void)createBanners:(NSMutableArray*)banners {
    for (CPAppBanner* banner in banners) {
        if (banner.frequency == CPAppBannerFrequencyOnce && [self isBannerShown:banner.id]) {
            continue;
        }

        if (banner.triggerType == CPAppBannerTriggerTypeConditions) {
            BOOL triggers = NO;
            for (CPAppBannerTrigger *trigger in banner.triggers) {
                BOOL triggerTrue = YES;
                for (CPAppBannerTriggerCondition *condition in trigger.conditions) {
                    // true by default to make the AND check work
                    BOOL conditionTrue = YES;
                    if (condition.type == CPAppBannerTriggerConditionTypeDuration) {
                        banner.delaySeconds = condition.seconds;
                        conditionTrue = YES;
                    } else if (condition.type == CPAppBannerTriggerConditionTypeSessions) {
                        if (condition.relation != nil && [condition.relation isEqualToString:@"lt"]) {
                            conditionTrue = sessions < condition.sessions;
                        } else {
                            conditionTrue = sessions > condition.sessions;
                        }
                    } else if (condition.type == CPAppBannerTriggerConditionTypeEvent && condition.event != nil && events != nil) {
                        conditionTrue = [self checkEventTriggerCondition:condition];
                    } else {
                        conditionTrue = NO;
                    }

                    if (!conditionTrue) {
                        triggerTrue = NO;
                        break;
                    }
                }

                if (triggerTrue) {
                    triggers = YES;
                    break;
                }
            }

            if (!triggers) {
                continue;
            }
        }

        BOOL contains = NO;
        for (CPAppBanner* tryBanner in [self getActiveBanners]) {
            if ([tryBanner.id isEqualToString:banner.id]) {
                contains = YES;
                break;
            }
        }

        if (!contains) {
            [activeBanners addObject:banner];
        }
    }
}

#pragma mark - manage the schedule to display the banner at a specific time
- (void)scheduleBanners {
    if ([self getBannersDisabled]) {
        for (CPAppBanner* banner in activeBanners) {
            [pendingBanners addObject:banner];
        }
        [activeBanners removeObjectsInArray:pendingBanners];
        return;
    }

    for (CPAppBanner* banner in [self getActiveBanners]) {
        if (!banner.startAt || [banner.startAt compare:[NSDate date]] == NSOrderedAscending) {
            if (banner.delaySeconds > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * banner.delaySeconds), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    [self showBanner:banner];
                });
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    [self showBanner:banner];
                });
            }
        } else {
            double startAtDelay = [banner.startAt timeIntervalSinceDate:[NSDate date]];
            double totalDelay = startAtDelay + banner.delaySeconds;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * totalDelay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self showBanner:banner];
            });
        }
    }
}

#pragma mark - show banner with the call back of the send banner event "clicked", "delivered"
- (void)showBanner:(CPAppBanner*)banner {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (banner.frequency == CPAppBannerFrequencyOnce && [self isBannerShown:banner.id]) {
            [CPLog debug:@"Skipping banner because: already shown"];
            return;
        }

        if (banner.status == CPAppBannerStatusDraft && ![CleverPush getAppBannerDraftsEnabled]) {
            [CPLog debug:@"Skipping banner because: status is draft"];
            return;
        }

        if (![self bannerTargetingAllowed:banner]) {
            [CPLog debug:@"Skipping banner because: targeting not allowed"];
            return;
        }

        if (![self bannerTimeAllowed:banner]) {
            [CPLog debug:@"Skipping banner because: date is after stop date"];
            return;
        }

        NSBundle *bundle = [CPUtils getAssetsBundle];
        CPAppBannerViewController *appBannerViewController;
        if (bundle) {
            appBannerViewController = [[CPAppBannerViewController alloc] initWithNibName:@"CPAppBannerViewController" bundle:bundle];
        } else {
            appBannerViewController = [[CPAppBannerViewController alloc] initWithNibName:@"CPAppBannerViewController" bundle:[NSBundle mainBundle]];
        }

        __strong CPAppBannerActionBlock callbackBlock = ^(CPAppBannerAction* action) {
            CPAppBannerCarouselBlock *screens = [[CPAppBannerCarouselBlock alloc] init];
            CPAppBannerButtonBlock *buttons = [[CPAppBannerButtonBlock alloc] init];
            CPAppBannerImageBlock *images = [[CPAppBannerImageBlock alloc] init];
            NSMutableArray *buttonBlocks  = [[NSMutableArray alloc] init];
            NSMutableArray *imageBlocks  = [[NSMutableArray alloc] init];
            NSString *type;
            
            for (CPAppBannerCarouselBlock *screensList in banner.screens) {
                if (!screensList.isScreenClicked) {
                    screens = screensList;
                    break;
                }
            }
            for (CPAppBannerBlock *bannerBlock in screens.blocks) {
                if (bannerBlock.type == CPAppBannerBlockTypeButton) {
                    [buttonBlocks addObject:(CPAppBannerBlock*)bannerBlock];
                } else if (bannerBlock.type == CPAppBannerBlockTypeImage) {
                    [imageBlocks addObject:(CPAppBannerBlock*)bannerBlock];
                }
            }
            for (CPAppBannerButtonBlock *button in buttonBlocks) {
                if ([button.id isEqualToString:action.blockId]) {
                    buttons = (CPAppBannerButtonBlock*)button;
                    type = @"button";
                    break;
                }
            }
            for (CPAppBannerImageBlock *image in imageBlocks) {
                if ([image.id isEqualToString:action.blockId]) {
                    images = (CPAppBannerImageBlock*)image;
                    type = @"image";
                    break;
                }
            }
            
            if ([type isEqualToString:@"button"]) {
                if (screens != nil && buttons != nil) {
                    [self sendBannerEvent:@"clicked" forBanner:banner forScreen:screens forButtonBlock:buttons forImageBlock:nil blockType:type];
                }
            } else if ([type isEqualToString:@"image"]) {
                if (screens != nil && images != nil) {
                    [self sendBannerEvent:@"clicked" forBanner:banner forScreen:screens forButtonBlock:nil forImageBlock:images blockType:type];
                }
            }

            if (handleBannerOpened && action) {
                handleBannerOpened(action);
            }

            if (action && [action.type isEqualToString:@"url"] && action.url != nil && action.openBySystem) {
                [[UIApplication sharedApplication] openURL:action.url];
            }

            if (action && [action.type isEqualToString:@"subscribe"]) {
                [CleverPush subscribe];
            }

            if (action && [action.type isEqualToString:@"addTags"]) {
                [CleverPush addSubscriptionTags:action.tags];
            }

            if (action && [action.type isEqualToString:@"removeTags"]) {
                [CleverPush removeSubscriptionTags:action.tags];
            }

            if (action && [action.type isEqualToString:@"addTopics"]) {
                NSMutableArray *topics = [NSMutableArray arrayWithArray:[CleverPush getSubscriptionTopics]];
                for (NSString *topic in action.topics) {
                    if (![topics containsObject:topic]) {
                        [topics addObject:topic];
                    }
                }
                [CleverPush setSubscriptionTopics:topics];
            }

            if (action && [action.type isEqualToString:@"removeTopics"]) {
                NSMutableArray *topics = [NSMutableArray arrayWithArray:[CleverPush getSubscriptionTopics]];
                for (NSString *topic in action.topics) {
                    if ([topics containsObject:topic]) {
                        [topics removeObject:topic];
                    }
                }
                [CleverPush setSubscriptionTopics:topics];
            }

            if (action && [action.type isEqualToString:@"setAttribute"]) {
                [CleverPush setSubscriptionAttribute:action.attributeId value:action.attributeValue];
            }

            if (action && [action.type isEqualToString:@"copyToClipboard"]) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = action.name;
            }
        };
        [appBannerViewController setActionCallback:callbackBlock];

        if (banner.frequency == CPAppBannerFrequencyOnce) {
            [self setBannerIsShown:banner];
        }

        // remove banner so it will not show again this session
        [banners removeObject:banner];
        [activeBanners removeObject:banner];

        [self presentAppBanner:appBannerViewController banner:banner];
    });
}

- (void)showNextActivePendingBanner:(CPAppBanner*)banner {
    [activePendingBanners removeObject:banner];
    if (activePendingBanners.count != 0) {
        [self showBanner:activePendingBanners.firstObject];
    }
}

- (void)presentAppBanner:(CPAppBannerViewController*)appBannerViewController  banner:(CPAppBanner*)banner {
    if ([CleverPush popupVisible]) {
        [activePendingBanners addObject:banner];
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:true forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [appBannerViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [appBannerViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    appBannerViewController.data = banner;

    UIViewController* topController = [CleverPush topViewController];
    [topController presentViewController:appBannerViewController animated:YES completion:nil];

    if (banner.dismissType == CPAppBannerDismissTypeTimeout) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (long)banner.dismissTimeout), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [appBannerViewController onDismiss];
        });
    }
    [self sendBannerEvent:@"delivered" forBanner:banner forScreen:nil forButtonBlock:nil forImageBlock:nil blockType:nil];
}

#pragma mark - track the record of the banner callback events by calling an api (app-banner/event/@"event-name")
- (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner forScreen:(CPAppBannerCarouselBlock*)screen forButtonBlock:(CPAppBannerButtonBlock*)block forImageBlock:(CPAppBannerImageBlock*)image blockType:(NSString*)type {
    if (!trackingEnabled) {
        [CPLog debug:@"sendBannerEvent: not sending event because tracking has been disabled."];
        return;
    }

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:[NSString stringWithFormat:@"app-banner/event/%@", event]];

    NSString* subscriptionId = nil;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    }
    NSMutableDictionary* dataDic = [[NSMutableDictionary alloc]init];
    if (banner.testId != nil) {
        dataDic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    banner.id, @"bannerId",
                    banner.channel, @"channelId",
                    banner.testId, @"testId",
                    subscriptionId, @"subscriptionId",
                    nil] mutableCopy];
    } else {
        dataDic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    banner.id, @"bannerId",
                    banner.channel, @"channelId",
                    subscriptionId, @"subscriptionId",
                    nil] mutableCopy];
    }
    
    if ([event isEqualToString:@"clicked"]) {
        if ([type isEqualToString:@"button"]) {
            if (block != nil) {
                if (block.id != nil) {
                    [dataDic setObject:block.id forKey:@"blockId"];
                }
                if (block.action != nil && block.action.screen != nil && ![block.action.screen isEqual: @""]) {
                    [dataDic setObject:[[block valueForKey:@"action"] valueForKey:@"screen"] forKey:@"screenId"];
                }
            }
        } else  if ([type isEqualToString:@"image"]) {
            if (image != nil) {
                if (image.id != nil) {
                    [dataDic setObject:image.id forKey:@"blockId"];
                }
                if (image.action != nil && image.action.screen != nil && ![image.action.screen isEqual: @""]) {
                    [dataDic setObject:[[image valueForKey:@"action"] valueForKey:@"screen"] forKey:@"screenId"];
                }
            }
        }
        
        [CPLog info:@"sendBannerEvent: %@ %@", event, dataDic];
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if ([dataDic valueForKey:@"screenId"] != nil && ![[dataDic valueForKey:@"screenId"]  isEqual: @""]) {
                    screen.isScreenClicked = true;
            }
        } onFailure:nil];
    } else {
        [CPLog info:@"sendBannerEvent: %@ %@", event, dataDic];
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [CleverPush enqueueRequest:request onSuccess:nil onFailure:nil];
    }
}

#pragma mark - Apps can disable banners for a certain time and enable them later again (e.g. when user is currently watching a video)
- (void)loadBannersDisabled {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [self setBannersDisabled:[userDefaults boolForKey:CLEVERPUSH_APP_BANNERS_DISABLED_KEY]];
}

- (void)saveBannersDisabled {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:[self getBannersDisabled] forKey:CLEVERPUSH_APP_BANNERS_DISABLED_KEY];
    [userDefaults synchronize];
}

- (void)disableBanners {
    [self setBannersDisabled:YES];
    [self saveBannersDisabled];
}

- (void)enableBanners {
    [self setBannersDisabled:NO];
    [self saveBannersDisabled];
    if ([self getPendingBanners] && [[self getPendingBanners] count] > 0) {
        [activeBanners addObjectsFromArray:[self getPendingBanners]];
        [self setPendingBanners:[[NSMutableArray alloc] init]];
        [self scheduleBanners];
    }
}

- (void)setTrackingEnabled:(BOOL)enabled {
    trackingEnabled = enabled;
}

#pragma mark - Group array of objects by dates and alphabets.
- (NSArray *)sortArrayByDateAndAlphabet:(NSArray *)array {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id bannerElement1, id bannerElement2) {
        NSDate *bannerStartdate1;
        NSDate *bannerStartdate2;
        NSComparisonResult result;
        
        if (bannerElement1[@"startAt"] != nil && ![bannerElement1[@"startAt"] isKindOfClass:[NSNull class]]) {
            bannerStartdate1 = [dateFormatter dateFromString:bannerElement1[@"startAt"]];
        }
        if (bannerElement2[@"startAt"] != nil && ![bannerElement2[@"startAt"] isKindOfClass:[NSNull class]]) {
            bannerStartdate2 = [dateFormatter dateFromString:bannerElement2[@"startAt"]];
        }
        if (bannerStartdate1 != nil && bannerStartdate2 != nil) {
            result = [bannerStartdate1 compare:bannerStartdate2];
            NSString *bannerName1;
            NSString *bannerName2;
            if (result == NSOrderedSame) {
                if  (bannerElement1[@"name"] != nil && ![bannerElement1[@"name"] isKindOfClass:[NSNull class]]) {
                    bannerName1 = bannerElement1[@"name"];
                }
                if (bannerElement2[@"name"] != nil && ![bannerElement2[@"name"] isKindOfClass:[NSNull class]]) {
                    bannerName2 = bannerElement2[@"name"];
                }
                if (bannerName1 != nil && bannerName2 != nil) {
                    result = [bannerName1 compare:bannerName2];
                }
            }
        }
        return result;
    }];
    return sortedArray;
}

#pragma mark - refactor for testcases

- (void)setBanners:(NSMutableArray*)appBanner {
    banners = appBanner;
}

- (NSMutableArray *)getListOfBanners {
    return banners;
}

- (NSMutableArray *)getActiveBanners {
    return activeBanners;
}

- (long)getMinimumSessionLength {
    return [CleverPush isDevelopmentModeEnabled] ? MIN_SESSION_LENGTH_DEV : MIN_SESSION_LENGTH;
}

- (void)setSessions:(long)sessionsCount{
    sessions = sessionsCount;
}

- (BOOL)getPendingBannerRequest {
    return pendingBannerRequest;
}

- (void)setPendingBannerRequest:(BOOL)value {
    pendingBannerRequest = value;
}

- (long)getLastSessionTimestamp {
    return lastSessionTimestamp;
}

- (void)setLastSessionTimestamp:(long)timeStamp {
    lastSessionTimestamp = timeStamp;
}

- (NSMutableArray *)getPendingBannerListeners {
    return pendingBannerListeners;
}

- (void)setPendingBannerListeners:(NSMutableArray*)listeners {
    pendingBannerListeners = listeners;
}

- (void)setActiveBanners:(NSMutableArray*)banners {
    activeBanners = banners;
}

- (void)setPendingBanners:(NSMutableArray*)banners {
    pendingBanners = banners;
}

- (void)setEvents:(NSMutableArray<NSDictionary*>*)event {
    events = event;
}

- (void)setEventsValueForKey:(NSString*)value key:(NSString*)key {
    [events setValue:value forKey:key];
}

- (NSMutableArray<NSDictionary*>*)getEvents {
    return events;
}

- (BOOL)getShowDraftsFlag {
    return showDrafts;
}

- (void)updateShowDraftsFlag:(BOOL)value {
    showDrafts = value;
}

- (void)updateInitialisedFlag:(BOOL)value {
    initialized = value;
}

- (BOOL)isInitialized {
    return initialized;
}

- (void)resetInitialization {
    initialized = NO;
}

-(NSMutableArray *)getPendingBanners {
    return pendingBanners;
}

- (void)setBannersDisabled:(BOOL)value {
    bannersDisabled = value;
}

- (BOOL)getBannersDisabled {
    return bannersDisabled;
}

- (void)setFromNotification:(BOOL)value{
    isFromNotification = value;
}

- (BOOL)isFromNotification{
    return isFromNotification;
}

@end
