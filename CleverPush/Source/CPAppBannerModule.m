#import "CPAppBannerModule.h"

@interface CPAppBannerModule()

@end

@implementation CPAppBannerModule

#pragma mark - Class Variables

static CPAppBannerModuleInstance* singletonInstance = nil;

+ (CPAppBannerModuleInstance *)moduleInstance {
    if (singletonInstance == nil) singletonInstance = [[CPAppBannerModuleInstance alloc] init];
    return singletonInstance;
}

#pragma mark - Get sessions from NSUserDefaults
+ (long)getSessions {
    return [self.moduleInstance getSessions];
}

#pragma mark - Save sessions in NSUserDefaults
+ (void)saveSessions {
    [self.moduleInstance saveSessions];
}

#pragma mark - Call back while banner has been open-up successfully
+ (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    [self.moduleInstance setBannerOpenedCallback:callback];
}

#pragma mark - load the events
+ (void)triggerEvent:(NSString *)key value:(NSString *)value {
    [self.moduleInstance triggerEvent:key value:value];
}

#pragma mark - Show banners by channel-id and banner-id
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:nil];
}

#pragma mark - Show banners by channel-id and banner-id
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:notificationId];
}

#pragma mark - Initialised and load the data in to banner by creating banner and schedule banners
+ (void)startup {
    [self.moduleInstance startup];
}

#pragma mark - fetch the details of shownAppBanners from NSUserDefaults by key CleverPush_SHOWN_APP_BANNERS
+ (NSMutableArray*)shownAppBanners {
    return [self.moduleInstance shownAppBanners];
}

#pragma mark - function determine that the banner is visible or not
+ (BOOL)isBannerShown:(NSString*)bannerId {
    return [self.moduleInstance isBannerShown:bannerId];
}

#pragma mark - update/set the NSUserDefaults of key CleverPush_SHOWN_APP_BANNERS
+ (void)setBannerIsShown:(NSString*)bannerId {
    [self.moduleInstance setBannerIsShown:bannerId];
}

#pragma mark - Initialised a session
+ (void)initSession:(NSString*)channelId afterInit:(BOOL)afterInit {
    [self.moduleInstance initSession:channelId afterInit:afterInit];
}

#pragma mark - Initialised a banner with channel
+ (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam fromNotification:(BOOL)fromNotification {
    [self.moduleInstance initBannersWithChannel:channelId showDrafts:showDraftsParam fromNotification:fromNotification];
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
+ (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [self.moduleInstance getBanners:channelId completion:callback];
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
+ (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [self.moduleInstance getBanners:channelId bannerId:bannerId notificationId:notificationId completion:callback];
}

#pragma mark - check the banner triggering allowed or not.
+ (BOOL)bannerTargetingAllowed:(CPAppBanner*)banner {
    return [self.moduleInstance bannerTargetingAllowed:banner];
}

#pragma mark - Create banners based on conditional attributes within the objects
+ (void)createBanners:(NSMutableArray*)banners {
    [self.moduleInstance createBanners:banners];
}

#pragma mark - manage the schedule to display the banner at a specific time
+ (void)scheduleBanners {
    [self.moduleInstance scheduleBanners];
}

#pragma mark - show banner with the call back of the send banner event "clicked", "delivered"
+ (void)showBanner:(CPAppBanner*)banner {
    [self.moduleInstance showBanner:banner];
}

+ (void)presentAppBanner:(CPAppBannerViewController*)appBannerViewController  banner:(CPAppBanner*)banner {
    [self.moduleInstance presentAppBanner:appBannerViewController banner:banner];
}
#pragma mark - track the record of the banner callback events by calling an api (app-banner/event/@"event-name")
+ (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner {
    [self.moduleInstance sendBannerEvent:event forBanner:banner];
}

#pragma mark - Apps can disable banners for a certain time and enable them later again (e.g. when user is currently watching a video)
+ (void)loadBannersDisabled {
    [self.moduleInstance loadBannersDisabled];
}

+ (void)saveBannersDisabled {
    [self.moduleInstance saveBannersDisabled];
}

+ (void)disableBanners {
    [self.moduleInstance disableBanners];
}

+ (void)enableBanners {
    [self.moduleInstance enableBanners];
}

@end
