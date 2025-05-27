#import "CPAppBannerModule.h"

@interface CPAppBannerModule()

@end

@implementation CPAppBannerModule

#pragma mark - Class Variables

static CPAppBannerModuleInstance* singletonInstance = nil;

+ (CPAppBannerModuleInstance *)moduleInstance {
    if (singletonInstance == nil) {
        singletonInstance = [[CPAppBannerModuleInstance alloc] init];
    }
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

#pragma mark - Callback while banner has been open-up successfully
+ (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    [self.moduleInstance setBannerOpenedCallback:callback];
}

#pragma mark - Callback while banner has been shown successfully
+ (void)setBannerShownCallback:(CPAppBannerShownBlock)callback {
    [self.moduleInstance setBannerShownCallback:callback];
}

#pragma mark - Callback while banner has been ready to display
+ (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock)callback {
    [self.moduleInstance setShowAppBannerCallback:callback];
}

#pragma mark - load the events
+ (void)triggerEvent:(NSString *)eventId properties:(NSDictionary *)properties {
    [self.moduleInstance triggerEvent:eventId properties:properties];
}

+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId force:(BOOL)force {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:nil force:force appBannerClosedCallback:nil];
}

+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId force:(BOOL)force appBannerClosedCallback:(CPAppBannerClosedBlock)appBannerClosedCallback {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:nil force:force appBannerClosedCallback:appBannerClosedCallback];
}

+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId force:(BOOL)force {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:notificationId force:force appBannerClosedCallback:nil];
}

+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId force:(BOOL)force appBannerClosedCallback:(CPAppBannerClosedBlock)appBannerClosedCallback {
    [self.moduleInstance showBanner:channelId bannerId:bannerId notificationId:notificationId force:force appBannerClosedCallback:appBannerClosedCallback];
}

#pragma mark - Initialised and load the data in to banner by creating banner and schedule banners
+ (void)startup {
    [self.moduleInstance startup];
}

#pragma mark - Resets the initialization, e.g. when channel ID has been changed
+ (void)resetInitialization {
    [self.moduleInstance resetInitialization];
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
+ (void)setBannerIsShown:(CPAppBanner*)banner {
    [self.moduleInstance setBannerIsShown:banner];
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
+ (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId groupId:(NSString*)groupId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    [self.moduleInstance getBanners:channelId bannerId:bannerId notificationId:notificationId groupId:groupId completion:callback];
}

#pragma mark - check the banner triggering allowed or not.
+ (BOOL)bannerTargetingAllowed:(CPAppBanner*)banner {
    return [self.moduleInstance bannerTargetingAllowed:banner];
}

#pragma mark - check the banner targeting with the events filter allowed or not.
+ (BOOL)bannerTargetingWithEventFiltersAllowed:(CPAppBanner*)banner {
    return [self.moduleInstance bannerTargetingWithEventFiltersAllowed:banner];
}

#pragma mark - Create banners based on conditional attributes within the objects
+ (void)createBanners:(NSMutableArray*)banners {
    [self.moduleInstance createBanners:banners];
}

#pragma mark - manage the schedule to display the banner at a specific time
+ (void)scheduleBanners {
    [self.moduleInstance scheduleBanners];
}

+ (void)presentAppBanner:(CPAppBannerViewController*)appBannerViewController  banner:(CPAppBanner*)banner {
    [self.moduleInstance presentAppBanner:appBannerViewController banner:banner];
}

#pragma mark - show next banner with sort by date and alphabetically
+ (void)showNextActivePendingBanner:(CPAppBanner*)banner {
    [self.moduleInstance showNextActivePendingBanner:banner];
}

#pragma mark - track the record of the banner callback events by calling an api (app-banner/event/@"event-name")
+ (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner forScreen:(CPAppBannerCarouselBlock*)screen forButtonBlock:(CPAppBannerButtonBlock*)button forImageBlock:(CPAppBannerImageBlock*)image blockType:(NSString*)type {
    [self.moduleInstance sendBannerEvent:event forBanner:banner forScreen:screen forButtonBlock:button forImageBlock:image blockType:type];
}

+ (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner forScreen:(CPAppBannerCarouselBlock*)screen forButtonBlock:(CPAppBannerButtonBlock*)block forImageBlock:(CPAppBannerImageBlock*)image blockType:(NSString*)type
         withCustomData:(NSMutableDictionary*)customData {
    [self.moduleInstance sendBannerEvent:event forBanner:banner forScreen:screen forButtonBlock:block forImageBlock:image blockType:type withCustomData:customData];
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

+ (void)setTrackingEnabled:(BOOL)enabled {
    [self.moduleInstance setTrackingEnabled:enabled];
}

+ (void)setCurrentEventId:(NSString*)eventId {
    [self.moduleInstance setCurrentEventId:eventId];
}

+ (void)preloadBannerImages:(CPAppBanner*)banner {
    [CPAppBannerViewController preloadImagesForBanner:banner];
}

@end
