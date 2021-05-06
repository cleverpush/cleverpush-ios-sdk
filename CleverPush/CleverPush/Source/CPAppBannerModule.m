#import "CPAppBannerModule.h"

@interface CPAppBannerModule()

@end

@implementation CPAppBannerModule

#pragma mark - Class Variables
NSString *ShownAppBannersDefaultsKey = @"CleverPush_SHOWN_APP_BANNERS";
NSMutableArray<CPAppBanner*> *banners;
NSMutableArray<CPAppBanner*> *activeBanners;
NSMutableArray* pendingBannerListeners;
NSMutableDictionary *events;
CPAppBannerActionBlock handleBannerOpened;

BOOL showDrafts = NO;
BOOL pendingBannerRequest = NO;

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
    [CPAppBannerModule getBanners:channelId completion:^(NSMutableArray<CPAppBanner *> *banners) {
        for (CPAppBanner* banner in banners) {
            if ([banner.id isEqualToString:bannerId]) {
                [CPAppBannerModule showBanner:banner];
                break;
            }
        }
    }];
}

#pragma mark - Initialised and load the daya in to banner by creating banner and schedule banners
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
        /*
         for (CPAppBanner* banner : activeBanners) {
         popup.dismiss();
         }
         */
        activeBanners = [NSMutableArray new];
    }
    
    lastSessionTimestamp = (long)NSDate.date.timeIntervalSince1970;
    
    sessions += 1;
    [self saveSessions];
    
    banners = nil;
    [CPAppBannerModule startup];
}

#pragma mark - Initialised a banner with channel
+ (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam {
    pendingBannerListeners = [[NSMutableArray alloc] init];
    activeBanners = [NSMutableArray new];
    dispatchQueue = dispatch_queue_create("CleverPush_AppBanners", nil);
    
    events = [NSMutableDictionary new];
    
    showDrafts = showDraftsParam;
    sessions = [CPAppBannerModule getSessions];
    
    dispatch_sync(dispatchQueue, ^{
        [CPAppBannerModule getBanners:channelId completion:^(NSMutableArray<CPAppBanner*>* banners) {
            [CPAppBannerModule startup];
        }];
    });
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
+ (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [pendingBannerListeners addObject:callback];
    if (pendingBannerRequest) {
        return;
    }
    pendingBannerRequest = YES;
    
    NSString* bannersPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", channelId];
    if ([CleverPush isDevelopmentModeEnabled]) {
        bannersPath = [NSString stringWithFormat:@"%@&t=%f", bannersPath, NSDate.date.timeIntervalSince1970];
    }
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:bannersPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSArray *jsonBanners = [result objectForKey:@"banners"];
        if (jsonBanners != nil) {
            banners = [NSMutableArray new];
            for (NSDictionary* json in jsonBanners) {
                [banners addObject:[[CPAppBanner alloc] initWithJson:json]];
            }
            
            pendingBannerRequest = NO;
            for (void (^listener)(NSMutableArray<CPAppBanner*>*) in pendingBannerListeners) {
                if (listener && banners) {
                    __strong void (^callbackBlock)(NSMutableArray<CPAppBanner*>*) = listener;
                    callbackBlock(banners);
                }
            }
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
        
        if (banner.stopAtType == CPAppBannerStopAtTypeSpecificTime && [banner.stopAt compare:[NSDate date]] == NSOrderedAscending) {
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
    for (CPAppBanner* banner in activeBanners) {
        if ([banner.startAt compare:[NSDate date]] == NSOrderedAscending) {
            if (banner.delaySeconds > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * banner.delaySeconds), dispatchQueue, ^(void){
                    [CPAppBannerModule showBanner:banner];
                });
            } else {
                dispatch_sync(dispatchQueue, ^{
                    [CPAppBannerModule showBanner:banner];
                });
            }
        } else {
            double delay = [[NSDate date] timeIntervalSinceDate:banner.startAt] + banner.delaySeconds;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delay), dispatchQueue, ^(void){
                [CPAppBannerModule showBanner:banner];
            });
        }
    }
}

#pragma mark - show banner with the call back of the send banner event "clicked", "delivered"
+ (void)showBanner:(CPAppBanner*)banner {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        if ([banner.contentType isEqualToString:@"block"]){
            CPAppBannerController* bannerController = [[CPAppBannerController alloc] initWithBanner:banner];
            
            __strong CPAppBannerActionBlock callbackBlock = ^(CPAppBannerAction* action){
                [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:banner];
                
                if (handleBannerOpened && action) {
                    handleBannerOpened(action);
                }
                
                if (action && [action.type isEqualToString:@"subscribe"]) {
                    [CleverPush subscribe];
                }
            };
            [bannerController setActionCallback:callbackBlock];
            
            UIViewController* topController = [CPAppBannerController topViewController];
            [topController presentViewController:bannerController animated:NO completion:nil];
            
            if (banner.frequency == CPAppBannerFrequencyOnce) {
                [CPAppBannerModule setBannerIsShown:banner.id];
            }
            
            if (banner.dismissType == CPAppBannerDismissTypeTimeout) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (long)banner.dismissTimeout), dispatchQueue, ^(void){
                    [bannerController onDismiss];
                });
            }
            
            [CPAppBannerModule sendBannerEvent:@"delivered" forBanner:banner];
        }
        else{
            CPAppBannerController* bannerController = [[CPAppBannerController alloc] initWithHTMLBanner:banner];
            
            __strong CPAppBannerActionBlock callbackBlock = ^(CPAppBannerAction* action){
                [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:banner];
                
                if (handleBannerOpened && action) {
                    handleBannerOpened(action);
                }
                
                if (action && [action.type isEqualToString:@"subscribe"]) {
                    [CleverPush subscribe];
                }
            };
            [bannerController setActionCallback:callbackBlock];
            
            UIViewController* topController = [CPAppBannerController topViewController];
            [topController presentViewController:bannerController animated:NO completion:nil];
            
            if (banner.frequency == CPAppBannerFrequencyOnce) {
                [CPAppBannerModule setBannerIsShown:banner.id];
            }
            
            if (banner.dismissType == CPAppBannerDismissTypeTimeout) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (long)banner.dismissTimeout), dispatchQueue, ^(void){
                    [bannerController onDismiss];
                });
            }
            
            [CPAppBannerModule sendBannerEvent:@"delivered" forBanner:banner];
        }
    });
}

#pragma mark - track the record of the banner callback events by calling an api (app-banner/event/@"event-name")
+ (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"app-banner/event/%@", event]];
    
    NSLog(@"CleverPush: sendBannerEvent: %@", event);
    
    NSString* subscriptionId = nil;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    }
    
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             banner.id, @"bannerId",
                             banner.channel, @"channelId",
                             subscriptionId, @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [CleverPush enqueueRequest:request onSuccess:nil onFailure:nil];
}

@end
