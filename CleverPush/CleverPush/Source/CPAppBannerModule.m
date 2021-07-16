#import "CPAppBannerModule.h"

@interface CPAppBannerModule()

@end

@implementation CPAppBannerModule

#pragma mark - Class Variables
NSString *ShownAppBannersDefaultsKey = @"CleverPush_SHOWN_APP_BANNERS";
NSMutableArray<CPAppBanner*> *banners;
NSMutableArray<CPAppBanner*> *activeBanners;
NSMutableArray<CPAppBanner*> *pendingBanners;
NSMutableArray* pendingBannerListeners;
NSMutableDictionary *events;
CPAppBannerActionBlock handleBannerOpened;

BOOL initialized = NO;
BOOL showDrafts = NO;
BOOL pendingBannerRequest = NO;
BOOL bannersDisabled = NO;

long MIN_SESSION_LENGTH = 30 * 60 * 1000L;
long lastSessionTimestamp;
long sessions = 0;
dispatch_queue_t dispatchQueue = nil;

#pragma mark - Get sessions from NSUserDefaults
+ (long)getSessions {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:@"CleverPush_APP_BANNER_SESSIONS"];
}

#pragma mark - Save sessions in NSUserDefaults
+ (void)saveSessions {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:sessions forKey:@"CleverPush_APP_BANNER_SESSIONS"];
    [userDefaults synchronize];
}

#pragma mark - Call back while banner has been open-up successfully
+ (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    handleBannerOpened = callback;
}

#pragma mark - load the events
+ (void)triggerEvent:(NSString *)key value:(NSString *)value {
    if (events != nil) {
        [events setValue:value forKey:key];
    }
    [self startup];
}

#pragma mark - Show banners by channel-id and banner-id
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId {
    [self showBanner:channelId bannerId:bannerId notificationId:nil];
}

#pragma mark - Show banners by channel-id and banner-id
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId {
    [CPAppBannerModule getBanners:channelId bannerId:bannerId notificationId:notificationId completion:^(NSMutableArray<CPAppBanner *> *banners) {
        for (CPAppBanner* banner in banners) {
            if ([banner.id isEqualToString:bannerId]) {
                if (bannersDisabled) {
                    [pendingBanners addObject:banner];
                    break;
                }
                [CPAppBannerModule showBanner:banner];
                break;
            }
        }
    }];
}

#pragma mark - Initialised and load the data in to banner by creating banner and schedule banners
+ (void)startup {
    [CPAppBannerModule createBanners:banners];
    [CPAppBannerModule scheduleBanners];
}

#pragma mark - fetch the details of shownAppBanners from NSUserDefaults by key CleverPush_SHOWN_APP_BANNERS
+ (NSMutableArray*)shownAppBanners {
    NSMutableArray* shownAppBanners = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:ShownAppBannersDefaultsKey]];
    if (!shownAppBanners) {
        shownAppBanners = [[NSMutableArray alloc] init];
    }
    return shownAppBanners;
}

#pragma mark - function determine that the banner is visible or not
+ (BOOL)isBannerShown:(NSString*)bannerId {
    return [[CPAppBannerModule shownAppBanners] containsObject:bannerId];
}

#pragma mark - update/set the NSUserDefaults of key CleverPush_SHOWN_APP_BANNERS
+ (void)setBannerIsShown:(NSString*)bannerId {
    NSMutableArray* bannerIds = [CPAppBannerModule shownAppBanners];
    [bannerIds addObject:bannerId];
    
    NSMutableArray* shownAppBanners = [CPAppBannerModule shownAppBanners];
    [shownAppBanners addObject:bannerId];
    [[NSUserDefaults standardUserDefaults] setObject:shownAppBanners forKey:ShownAppBannersDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Initialised a session
+ (void)initSession {
    long minLength = [CleverPush isDevelopmentModeEnabled] ? 30 * 1000L : MIN_SESSION_LENGTH;
    if (
        lastSessionTimestamp > 0
        && ((long)NSDate.date.timeIntervalSince1970 - lastSessionTimestamp) < minLength
        ) {
        return;
    }
    
    if ([activeBanners count] > 0) {
        activeBanners = [NSMutableArray new];
    }
    
    lastSessionTimestamp = (long)NSDate.date.timeIntervalSince1970;
    
    sessions += 1;
    [self saveSessions];
    
    banners = nil;
    [CPAppBannerModule startup];
}

#pragma mark - Initialised a banner with channel
+ (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam fromNotification:(BOOL)fromNotification {
    if (initialized) {
        return;
    }
    
    dispatchQueue = dispatch_queue_create("CleverPush_AppBanners", nil);
    pendingBannerListeners = [NSMutableArray new];
    activeBanners = [NSMutableArray new];
    pendingBanners = [NSMutableArray new];
    events = [NSMutableDictionary new];
    [CPAppBannerModule loadBannersDisabled];
    
    showDrafts = showDraftsParam;
    sessions = [CPAppBannerModule getSessions];
    
    initialized = YES;
    
    if (!fromNotification) {
        dispatch_sync(dispatchQueue, ^{
            [CPAppBannerModule getBanners:channelId completion:^(NSMutableArray<CPAppBanner*>* banners) {
                [CPAppBannerModule startup];
            }];
        });
    }
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
+ (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [CPAppBannerModule getBanners:channelId bannerId:nil notificationId:nil completion:callback];
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
+ (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    if (notificationId == nil) {
        [pendingBannerListeners addObject:callback];
        if (pendingBannerRequest) {
            return;
        }
        pendingBannerRequest = YES;
    }
    
    NSString* bannersPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", channelId];
    
    if ([CleverPush isDevelopmentModeEnabled]) {
        bannersPath = [NSString stringWithFormat:@"%@&t=%f", bannersPath, NSDate.date.timeIntervalSince1970];
    }
    
    if (notificationId != nil) {
        bannersPath = [NSString stringWithFormat:@"%@&notificationId=%@", bannersPath, notificationId];
    }
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:bannersPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSArray *jsonBanners = [result objectForKey:@"banners"];
        if (jsonBanners != nil) {
            banners = [NSMutableArray new];
            for (NSDictionary* json in jsonBanners) {
                [banners addObject:[[CPAppBanner alloc] initWithJson:json]];
            }
            
            if (notificationId && callback) {
                callback(banners);
            } else {
                for (void (^listener)(NSMutableArray<CPAppBanner*>*) in pendingBannerListeners) {
                    if (listener && banners) {
                        __strong void (^callbackBlock)(NSMutableArray<CPAppBanner*>*) = listener;
                        callbackBlock(banners);
                    }
                }
            }
            
            pendingBannerRequest = NO;
            pendingBannerListeners = [NSMutableArray new];
        }
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed getting app banners %@", error);
    }];
}

#pragma mark - Create banners based on conditional attributes within the objects
+ (void)createBanners:(NSMutableArray*)banners {
    for (CPAppBanner* banner in banners) {
        if (banner.status == CPAppBannerStatusDraft && !showDrafts) {
            continue;
        }
        
        if (banner.frequency == CPAppBannerFrequencyOnce && [CPAppBannerModule isBannerShown:banner.id]) {
            continue;
        }
        
        if (banner.stopAtType == CPAppBannerStopAtTypeSpecificTime && [banner.stopAt compare:[NSDate date]] == NSOrderedDescending) {
            continue;
        }
        
        if (banner.triggerType == CPAppBannerTriggerTypeConditions) {
            BOOL triggers = NO;
            for (CPAppBannerTrigger *trigger in banner.triggers) {
                BOOL triggerTrue = NO;
                for (CPAppBannerTriggerCondition *condition in trigger.conditions) {
                    BOOL conditionTrue = NO;
                    if (condition.type == CPAppBannerTriggerConditionTypeDuration) {
                        banner.delaySeconds = condition.seconds;
                        conditionTrue = YES;
                    }
                    if (condition.type == CPAppBannerTriggerConditionTypeSessions) {
                        if (condition.relation != nil && [condition.relation isEqualToString:@"lt"]) {
                            conditionTrue = sessions < condition.sessions;
                        } else {
                            conditionTrue = sessions > condition.sessions;
                        }
                    }
                    if (condition.type == CPAppBannerTriggerConditionTypeEvent && events != nil) {
                        NSString *event = [events objectForKey:condition.key];
                        conditionTrue = event != nil && [event isEqualToString:condition.value];
                    }
                    
                    if (conditionTrue) {
                        triggerTrue = YES;
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
        for (CPAppBanner* tryBanner in activeBanners) {
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
+ (void)scheduleBanners {
    if (bannersDisabled) {
        for (CPAppBanner* banner in activeBanners) {
            [pendingBanners addObject:banner];
        }
        [activeBanners removeObjectsInArray:pendingBanners];
        return;
    }
    
    for (CPAppBanner* banner in activeBanners) {
        if ([banner.startAt compare:[NSDate date]] == NSOrderedAscending) {
            if (banner.delaySeconds > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * banner.delaySeconds), dispatchQueue, ^(void) {
                    [CPAppBannerModule showBanner:banner];
                });
            } else {
                dispatch_sync(dispatchQueue, ^{
                    [CPAppBannerModule showBanner:banner];
                });
            }
        } else {
            double delay = [[NSDate date] timeIntervalSinceDate:banner.startAt] + banner.delaySeconds;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delay), dispatchQueue, ^(void) {
                [CPAppBannerModule showBanner:banner];
            });
        }
    }
}

#pragma mark - show banner with the call back of the send banner event "clicked", "delivered"
+ (void)showBanner:(CPAppBanner*)banner {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        CPAppBannerController* bannerController;
        
        if ([banner.contentType isEqualToString:@"html"]) {
            bannerController = [[CPAppBannerController alloc] initWithHTMLBanner:banner];
        } else {
            bannerController = [[CPAppBannerController alloc] initWithBanner:banner];
        }
        
        __strong CPAppBannerActionBlock callbackBlock = ^(CPAppBannerAction* action) {
            [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:banner];
            
            if (handleBannerOpened && action) {
                handleBannerOpened(action);
            }
            
            if (action && [action.type isEqualToString:@"subscribe"]) {
                [CleverPush subscribe];
            }
        };
        [bannerController setActionCallback:callbackBlock];
                
        if (banner.frequency == CPAppBannerFrequencyOnce) {
            [CPAppBannerModule setBannerIsShown:banner.id];
        }
        
        if (banner.stopAtType == CPAppBannerStopAtTypeSpecificTime) {
            if ([banner.stopAt compare:[NSDate date]] == NSOrderedDescending) {
                [CPAppBannerModule presentAppBanner:bannerController banner:banner];
            } else {
                NSLog(@"CleverPush: Banner display date has been elapsed");
            }
        } else {
            [CPAppBannerModule presentAppBanner:bannerController banner:banner];
        }
    });
}

+ (void)presentAppBanner:(CPAppBannerController*)controller banner:(CPAppBanner*)banner {
    if (!CleverPush.popupVisible) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"CleverPush_APP_BANNER_VISIBLE"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        UIViewController* topController = [CleverPush topViewController];
        [topController presentViewController:controller animated:NO completion:nil];
        if (banner.dismissType == CPAppBannerDismissTypeTimeout) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (long)banner.dismissTimeout), dispatchQueue, ^(void) {
                [controller onDismiss];
            });
        }
        [CPAppBannerModule sendBannerEvent:@"delivered" forBanner:banner];
    } else {
        NSLog(@"CleverPush: You can not present two banners at the same time");
    }
}

#pragma mark - track the record of the banner callback events by calling an api (app-banner/event/@"event-name")
+ (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"app-banner/event/%@", event]];
    
    NSString* subscriptionId = nil;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    }
    
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             banner.id, @"bannerId",
                             banner.channel, @"channelId",
                             subscriptionId, @"subscriptionId",
                             nil];
    
    NSLog(@"CleverPush: sendBannerEvent: %@ %@", event, dataDic);
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [CleverPush enqueueRequest:request onSuccess:nil onFailure:nil];
}

#pragma mark - Apps can disable banners for a certain time and enable them later again (e.g. when user is currently watching a video)

+ (void)loadBannersDisabled {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    bannersDisabled = [userDefaults boolForKey:@"CleverPush_APP_BANNERS_DISABLED"];
}

+ (void)saveBannersDisabled {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:bannersDisabled forKey:@"CleverPush_APP_BANNERS_DISABLED"];
    [userDefaults synchronize];
}

+ (void)disableBanners {
    bannersDisabled = YES;
    [CPAppBannerModule saveBannersDisabled];
}

+ (void)enableBanners {
    bannersDisabled = NO;
    [CPAppBannerModule saveBannersDisabled];
    if (pendingBanners && [pendingBanners count] > 0) {
        [activeBanners addObjectsFromArray:pendingBanners];
        pendingBanners = [[NSMutableArray alloc] init];
        
        [CPAppBannerModule scheduleBanners];
    }
}

@end
