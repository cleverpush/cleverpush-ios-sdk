#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#import <UserNotifications/UserNotifications.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

#import "CleverPush.h"
#import "UNUserNotificationCenter+CleverPush.h"
#import "UIApplicationDelegate+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CPNotificationCategoryController.h"
#import "CPUtils.h"
#import "CPTopicsViewController.h"
#import "CPTranslate.h"
#import "CPAppBannerModule.h"
#import "DWAlertController/DWAlertController.h"
#import "DWAlertController/DWAlertAction.h"
#import "CleverPushInstance.h"
#endif

@implementation CleverPush

static CleverPushInstance* singletonInstance = nil;
static CleverPush* singleInstance = nil;

#pragma mark - Singleton shared instance of the cleverpush.

+ (CleverPushInstance *)CPSharedInstance {
    if (singletonInstance == nil) singletonInstance = [[CleverPushInstance alloc] init];
    return singletonInstance;
}

#pragma mark - methods to initialize SDK
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (void)setTrackingConsentRequired:(BOOL)required {
    [self.CPSharedInstance setTrackingConsentRequired:required];
}

+ (void)setTrackingConsent:(BOOL)consent {
    [self.CPSharedInstance setTrackingConsent:consent];
}

+ (void)enableDevelopmentMode {
    [self.CPSharedInstance enableDevelopmentMode];
}

+ (void)subscribe {
    [self.CPSharedInstance subscribe];
}

+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock {
    [self.CPSharedInstance subscribe:subscribedBlock];
}

+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance subscribe:subscribedBlock failure:failureBlock];
}

+ (void)disableAppBanners {
    [self.CPSharedInstance disableAppBanners];
}

+ (void)enableAppBanners {
    [self.CPSharedInstance enableAppBanners];
}

+ (void)setAppBannerTrackingEnabled:(BOOL)enabled {
    [self.CPSharedInstance setAppBannerTrackingEnabled:enabled];
}

+ (BOOL)popupVisible {
    return [self.CPSharedInstance popupVisible];
}

+ (void)unsubscribe {
    [self.CPSharedInstance unsubscribe];
}

+ (void)unsubscribe:(void(^)(BOOL))callback {
    [self.CPSharedInstance unsubscribe:callback];
}

+ (void)syncSubscription {
    [self.CPSharedInstance syncSubscription];
}

+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken {
    [self.CPSharedInstance didRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
}

+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err {
    [self.CPSharedInstance handleDidFailRegisterForRemoteNotification:err];
}

+ (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier {
    [self.CPSharedInstance handleNotificationOpened:messageDict isActive:isActive actionIdentifier:actionIdentifier];
}

+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive {
    [self.CPSharedInstance handleNotificationReceived:messageDict isActive:isActive];
}

+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance enqueueRequest:request onSuccess:successBlock onFailure:failureBlock];
}

+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
}

+ (void)addSubscriptionTopic:(NSString*)topicId {
    [self.CPSharedInstance addSubscriptionTopic:topicId];
}

+ (void)addSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback {
    [self.CPSharedInstance addSubscriptionTopic:topicId callback:callback];
}

+ (void)addSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance addSubscriptionTopic:topicId callback:callback onFailure:failureBlock];
}

+ (void)removeSubscriptionTopic:(NSString*)topicId {
    [self.CPSharedInstance removeSubscriptionTopic:topicId];
}

+ (void)removeSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback {
    [self.CPSharedInstance removeSubscriptionTopic:topicId callback:callback];
}

+ (void)removeSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance removeSubscriptionTopic:topicId callback:callback onFailure:failureBlock];
}

+ (void)addSubscriptionTag:(NSString*)tagId {
    [self.CPSharedInstance addSubscriptionTag:tagId];
}

+ (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback {
    [self.CPSharedInstance addSubscriptionTag:tagId callback:^(NSString *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance addSubscriptionTag:tagId callback:^(NSString *callbackInner) {
        callback(callbackInner);
    } onFailure:failureBlock];
}

+ (void)addSubscriptionTags:(NSArray*)tagIds {
    [self.CPSharedInstance addSubscriptionTags:tagIds];
}


+ (void)addSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback {
    [self.CPSharedInstance addSubscriptionTags:tagIds callback:^(NSArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)removeSubscriptionTag:(NSString*)tagId {
    [self.CPSharedInstance removeSubscriptionTag:tagId];
}

+ (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback {
    [self.CPSharedInstance removeSubscriptionTag:tagId callback:^(NSString *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance removeSubscriptionTag:tagId callback:^(NSString *callbackInner) {
        callback(callbackInner);
    } onFailure:failureBlock];
}

+ (void)removeSubscriptionTags:(NSArray*)tagIds {
    [self.CPSharedInstance removeSubscriptionTags:tagIds];
}

+ (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback {
    [self.CPSharedInstance removeSubscriptionTags:tagIds callback:^(NSArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)startLiveActivity:(NSString*)activityId pushToken:(NSString*)token {
    [self.CPSharedInstance startLiveActivity:activityId pushToken:token];
}

+ (void)startLiveActivity:(NSString*)activityId pushToken:(NSString*)token onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    [self.CPSharedInstance startLiveActivity:activityId pushToken:token onSuccess:successBlock onFailure:failureBlock];
}

+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId value:value callback:nil];
}

+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value callback:(void(^)())callback {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId value:value callback:callback];
}

+ (void)pushSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    [self.CPSharedInstance pushSubscriptionAttributeValue:attributeId value:value];
}

+ (void)pullSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    [self.CPSharedInstance pullSubscriptionAttributeValue:attributeId value:value];
}

+ (BOOL)hasSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    return [self.CPSharedInstance hasSubscriptionAttributeValue:attributeId value:value];
}

+ (void)getAvailableTags:(void(^)(NSArray <CPChannelTag*>*))callback {
    [self.CPSharedInstance getAvailableTags:^(NSArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAvailableTopics:(void(^)(NSArray <CPChannelTopic*>*))callback {
    [self.CPSharedInstance getAvailableTopics:^(NSArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAvailableAttributes:(void(^)(NSDictionary *))callback {
    [self.CPSharedInstance getAvailableAttributes:^(NSDictionary *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)setSubscriptionLanguage:(NSString*)language {
    [self.CPSharedInstance setSubscriptionLanguage:language];
}

+ (void)setSubscriptionCountry:(NSString*)country {
    [self.CPSharedInstance setSubscriptionCountry:country];
}

+ (void)setTopicsDialogWindow:(UIWindow *)window {
    [self.CPSharedInstance setTopicsDialogWindow:window];
}

+ (void)setTopicsChangedListener:(CPTopicsChangedBlock)changedBlock {
    [self.CPSharedInstance setTopicsChangedListener:changedBlock];
}

+ (void)setSubscriptionTopics:(NSMutableArray *)topics {
    [self.CPSharedInstance setSubscriptionTopics:topics];
}

+ (void)setBrandingColor:(UIColor *)color {
    [self.CPSharedInstance setBrandingColor:color];
}

+ (void)setNormalTintColor:(UIColor *)color {
    [self.CPSharedInstance setNormalTintColor:color];
}

+ (UIColor*)getNormalTintColor {
    return [self.CPSharedInstance getNormalTintColor];
}

+ (void)setAutoClearBadge:(BOOL)autoClear {
    [self.CPSharedInstance setAutoClearBadge:autoClear];
}

+ (void)setAppBannerDraftsEnabled:(BOOL)showDraft {
    [self.CPSharedInstance setAppBannerDraftsEnabled:showDraft];
}

+ (void)setSubscriptionChanged:(BOOL)subscriptionChanged {
    [self.CPSharedInstance setSubscriptionChanged:subscriptionChanged];
}

+ (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore {
    [self.CPSharedInstance setIgnoreDisabledNotificationPermission:ignore];
}

+ (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData {
    [self.CPSharedInstance setKeepTargetingDataOnUnsubscribe:keepData];
}

+ (void)setIncrementBadge:(BOOL)increment {
    [self.CPSharedInstance setIncrementBadge:increment];
}

+ (void)setShowNotificationsInForeground:(BOOL)show {
    [self.CPSharedInstance setShowNotificationsInForeground:show];
}

+ (void)addChatView:(CPChatView*)chatView {
    [self.CPSharedInstance addChatView:chatView];
}

+ (void)showTopicsDialog {
    [self.CPSharedInstance showTopicsDialog];
}

+ (void)showTopicDialogOnNewAdded {
    [self.CPSharedInstance showTopicDialogOnNewAdded];
}

+ (void)showTopicsDialog:(UIWindow *)targetWindow {
    [self.CPSharedInstance showTopicsDialog:targetWindow];
}

+ (void)showTopicsDialog:(UIWindow *)targetWindow callback:(void(^)())callback {
    [self.CPSharedInstance showTopicsDialog:targetWindow callback:callback];
}

+ (void)getChannelConfig:(void(^)(NSDictionary *))callback {
    [self.CPSharedInstance getChannelConfig:^(NSDictionary *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getSubscriptionId:(void(^)(NSString *))callback {
    [self.CPSharedInstance getSubscriptionId:^(NSString *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getDeviceToken:(void(^)(NSString *))callback {
    [self.CPSharedInstance getDeviceToken:callback];
}

+ (void)trackEvent:(NSString*)eventName {
    [self.CPSharedInstance trackEvent:eventName];
}

+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount {
    [self.CPSharedInstance trackEvent:eventName amount:amount];
}

+ (void)trackEvent:(NSString*)eventName properties:(NSDictionary*)properties {
    [self.CPSharedInstance trackEvent:eventName properties:properties];
}

+ (void)triggerFollowUpEvent:(NSString*)eventName {
    [self.CPSharedInstance triggerFollowUpEvent:eventName];
}

+ (void)triggerFollowUpEvent:(NSString*)eventName parameters:(NSDictionary*)parameters {
    [self.CPSharedInstance triggerFollowUpEvent:eventName parameters:parameters];
}

+ (void)trackPageView:(NSString*)url {
    [self.CPSharedInstance trackPageView:url];
}

+ (void)trackPageView:(NSString*)url params:(NSDictionary*)params {
    [self.CPSharedInstance trackPageView:url params:params];
}

+ (void)increaseSessionVisits {
    [self.CPSharedInstance increaseSessionVisits];
}

+ (void)showAppBanner:(NSString*)bannerId {
    [self.CPSharedInstance showAppBanner:bannerId];
}

+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    [self.CPSharedInstance setAppBannerOpenedCallback:^(CPAppBannerAction *action) {
        callback(action);
    }];
}

+ (void)setAppBannerShownCallback:(CPAppBannerShownBlock)callback {
    [self.CPSharedInstance setAppBannerShownCallback:^(CPAppBanner *appBanner) {
        callback(appBanner);
    }];
}

+ (void)getAppBanners:(NSString*)channelId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback {
    [self.CPSharedInstance getAppBanners:channelId callback:^(NSMutableArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAppBannersByGroup:(NSString*)groupId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback {
    [self.CPSharedInstance getAppBannersByGroup:groupId callback:^(NSMutableArray *callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)setApiEndpoint:(NSString*)apiEndpoint {
    [self.CPSharedInstance setApiEndpoint:apiEndpoint];
}

+ (void)setAuthorizerToken:(NSString *)authorizerToken {
    [self.CPSharedInstance setAuthorizerToken:authorizerToken];
}

+ (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0)) {
    [self.CPSharedInstance updateBadge:replacementContent];
}

+ (void)addStoryView:(CPStoryView*)storyView {
    [self.CPSharedInstance addStoryView:storyView];
}

+ (void)updateDeselectFlag:(BOOL)value {
    [self.CPSharedInstance updateDeselectFlag:value];
}

+ (void)setOpenWebViewEnabled:(BOOL)opened {
    [self.CPSharedInstance setOpenWebViewEnabled:opened];
}

+ (void)setUnsubscribeStatus:(BOOL)status {
    [self.CPSharedInstance setUnsubscribeStatus:status];
}

+ (void)setConfirmAlertShown {
    [self.CPSharedInstance setConfirmAlertShown];
}

+ (void)areNotificationsEnabled:(void(^)(BOOL))callback {
    [self.CPSharedInstance areNotificationsEnabled:callback];
}

+ (UIViewController*)topViewController {
    return [self.CPSharedInstance topViewController];
}

+ (NSArray*)getAvailableTags __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableTags];
}

+ (NSArray*)getAvailableTopics __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableTopics];
}

+ (NSArray*)getSubscriptionTags {
    return [self.CPSharedInstance getSubscriptionTags];
}

+ (NSArray*)getNotifications {
    return [self.CPSharedInstance getNotifications];
}

+ (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray<CPNotification*>*))callback {
    [self.CPSharedInstance getNotifications:combineWithApi callback:^(NSArray<CPNotification*> *notifications) {
        callback(notifications);
    }];
}

+ (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback {
    [self.CPSharedInstance getNotifications:combineWithApi limit:limit skip:skip callback:^(NSArray<CPNotification*> *notifications) {
        callback(notifications);
    }];
}

+ (NSArray*)getSeenStories {
    return [self.CPSharedInstance getSeenStories];
}

+ (NSMutableArray*)getSubscriptionTopics {
    return [self.CPSharedInstance getSubscriptionTopics];
}

+ (NSObject*)getSubscriptionAttribute:(NSString*)attributeId {
    return [self.CPSharedInstance getSubscriptionAttribute:attributeId];
}

+ (NSString*)getSubscriptionId {
    return [self.CPSharedInstance getSubscriptionId];
}

+ (NSString*)getApiEndpoint {
    return [self.CPSharedInstance getApiEndpoint];
}

+ (NSString*)channelId {
    return [self.CPSharedInstance channelId];
}

+ (UIColor*)getBrandingColor {
    return [self.CPSharedInstance getBrandingColor];
}


+ (NSDictionary*)getAvailableAttributes __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableAttributes];
}

+ (NSDictionary*)getSubscriptionAttributes {
    return [self.CPSharedInstance getSubscriptionAttributes];
}

+ (BOOL)isDevelopmentModeEnabled {
    return [self.CPSharedInstance isDevelopmentModeEnabled];
}

+ (BOOL)getAppBannerDraftsEnabled {
    return [self.CPSharedInstance getAppBannerDraftsEnabled];
}

+ (BOOL)getSubscriptionChanged {
    return [self.CPSharedInstance getSubscriptionChanged];
}

+ (BOOL)isSubscribed {
    return [self.CPSharedInstance isSubscribed];
}

+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    return [self.CPSharedInstance handleSilentNotificationReceived:application UserInfo:messageDict completionHandler:completionHandler];
}

+ (BOOL)hasSubscriptionTag:(NSString*)tagId {
    return [self.CPSharedInstance hasSubscriptionTag:tagId];
}

#pragma mark - check the topicId exists in the subscriptionTopics or not
+ (BOOL)hasSubscriptionTopic:(NSString*)topicId {
    return [self.CPSharedInstance hasSubscriptionTopic:topicId];
}

+ (BOOL)getDeselectValue {
    return [self.CPSharedInstance getDeselectValue];
}

+ (BOOL)getUnsubscribeStatus {
    return [self.CPSharedInstance getUnsubscribeStatus];
}

+ (void)setLogListener:(CPLogListener)listener {
    [self.CPSharedInstance setLogListener:listener];
}

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0)) {
    return [self.CPSharedInstance didReceiveNotificationExtensionRequest:request withMutableNotificationContent:replacementContent];
}

+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0)) {
    return [self.CPSharedInstance serviceExtensionTimeWillExpireRequest:request withMutableNotificationContent:replacementContent];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification*)notification actionIdentifier:(NSString*)actionIdentifier {
    [self.CPSharedInstance processLocalActionBasedNotification:notification actionIdentifier:actionIdentifier];
}

+ (void)removeNotification:(NSString*)notificationId {
    [self.CPSharedInstance removeNotification:notificationId];
}

+ (void)setMaximumNotificationCount:(int)limit {
    [self.CPSharedInstance setMaximumNotificationCount:limit];
}

#pragma mark - Singleton shared instance of the cleverpush.
+ (CleverPush*)sharedInstance {
    @synchronized(singleInstance) {
        if (!singleInstance)
            singleInstance = [CleverPush new];
    }

    return singleInstance;
}

@end

@implementation UIApplication (CleverPush)

+ (void)load {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([[processInfo processName] isEqualToString:@"IBDesignablesAgentCocoaTouch"] || [[processInfo processName] isEqualToString:@"IBDesignablesAgent-iOS"]) {
        return;
    }

    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.0")) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

    BOOL existing = injectSelector([CleverPushAppDelegate class], @selector(cleverPushLoadedTagSelector:), self, @selector(cleverPushLoadedTagSelector:));
    if (existing) {
        return;
    }

    injectToProperClass(@selector(setCleverPushDelegate:), @selector(setDelegate:), @[], [CleverPushAppDelegate class], [UIApplication class]);

#pragma clang diagnostic pop

    [self setupUNUserNotificationCenterDelegate];
}

#pragma mark - Notification delegates injections.
+ (void)setupUNUserNotificationCenterDelegate {
    if (!NSClassFromString(@"UNUserNotificationCenter")) {
        return;
    }

    [CleverPushUNUserNotificationCenter injectSelectors];

    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter* currentNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        if (!currentNotificationCenter.delegate) {
            currentNotificationCenter.delegate = (id)[CleverPush sharedInstance];
        }
    }
}

@end
