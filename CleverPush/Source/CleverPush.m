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

+ (CleverPushInstance*)CPSharedInstance {
    if (singletonInstance == nil) singletonInstance = [[CleverPushInstance alloc] init];
    return singletonInstance;
}

#pragma mark - methods to initialize SDK with launch options
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  autoRegister:(BOOL)autoRegister handleInitialized:(CPInitializedBlock _Nullable)initializedCallback{
    return [self.CPSharedInstance initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister handleInitialized:initializedCallback];
}

#pragma mark - methods to initialize SDK with UISceneConnectionOptions
+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback  API_AVAILABLE(ios(13.0)){
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegisterParam API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  autoRegister:(BOOL)autoRegister API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  autoRegister:(BOOL)autoRegister handleInitialized:(CPInitializedBlock _Nullable)initializedCallback API_AVAILABLE(ios(13.0)) {
    return [self.CPSharedInstance initWithConnectionOptions:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister handleInitialized:initializedCallback];
}


+ (void)setTrackingConsentRequired:(BOOL)required {
    [self.CPSharedInstance setTrackingConsentRequired:required];
}

+ (void)setTrackingConsent:(BOOL)consent {
    [self.CPSharedInstance setTrackingConsent:consent];
}

+ (void)setSubscribeConsentRequired:(BOOL)required {
    [self.CPSharedInstance setSubscribeConsentRequired:required];
}

+ (void)setSubscribeConsent:(BOOL)consent {
    [self.CPSharedInstance setSubscribeConsent:consent];
}

+ (void)enableDevelopmentMode {
    [self.CPSharedInstance enableDevelopmentMode];
}

+ (void)subscribe {
    [self.CPSharedInstance subscribe];
}

+ (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock {
    [self.CPSharedInstance subscribe:subscribedBlock];
}

+ (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock {
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

+ (void)unsubscribe:(void(^ _Nullable)(BOOL))callback {
    [self.CPSharedInstance unsubscribe:callback];
}

+ (void)syncSubscription {
    [self.CPSharedInstance syncSubscription];
}

+ (void)didRegisterForRemoteNotifications:(UIApplication* _Nullable)app deviceToken:(NSData* _Nullable)inDeviceToken {
    [self.CPSharedInstance didRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
}

+ (void)handleDidFailRegisterForRemoteNotification:(NSError* _Nullable)err {
    [self.CPSharedInstance handleDidFailRegisterForRemoteNotification:err];
}

+ (void)handleNotificationOpened:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString* _Nullable)actionIdentifier {
    [self.CPSharedInstance handleNotificationOpened:messageDict isActive:isActive actionIdentifier:actionIdentifier];
}

+ (void)handleNotificationReceived:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive {
    [self.CPSharedInstance handleNotificationReceived:messageDict isActive:isActive];
}

+ (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance enqueueRequest:request onSuccess:successBlock onFailure:failureBlock];
}

+ (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock withRetry:(BOOL)retryOnFailure {
    [self.CPSharedInstance enqueueRequest:request onSuccess:successBlock onFailure:failureBlock withRetry:retryOnFailure];
}

+ (void)enqueueFailedRequest:(NSURLRequest* _Nullable)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance enqueueFailedRequest:request withRetryCount:retryCount onSuccess:successBlock onFailure:failureBlock];
}

+ (void)handleJSONNSURLResponse:(NSURLResponse* _Nullable)response data:(NSData* _Nullable)data error:(NSError* _Nullable)error onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
}

+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId {
    [self.CPSharedInstance addSubscriptionTopic:topicId];
}

+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance addSubscriptionTopic:topicId callback:callback];
}

+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance addSubscriptionTopic:topicId callback:callback onFailure:failureBlock];
}

+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId {
    [self.CPSharedInstance removeSubscriptionTopic:topicId];
}

+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance removeSubscriptionTopic:topicId callback:callback];
}

+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance removeSubscriptionTopic:topicId callback:callback onFailure:failureBlock];
}

+ (void)addSubscriptionTag:(NSString* _Nullable)tagId {
    [self.CPSharedInstance addSubscriptionTag:tagId];
}

+ (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance addSubscriptionTag:tagId callback:^(NSString*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance addSubscriptionTag:tagId callback:^(NSString*callbackInner) {
        callback(callbackInner);
    } onFailure:failureBlock];
}

+ (void)addSubscriptionTags:(NSArray* _Nullable)tagIds {
    [self.CPSharedInstance addSubscriptionTags:tagIds];
}


+ (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback {
    [self.CPSharedInstance addSubscriptionTags:tagIds callback:^(NSArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId {
    [self.CPSharedInstance removeSubscriptionTag:tagId];
}

+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance removeSubscriptionTag:tagId callback:^(NSString*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance removeSubscriptionTag:tagId callback:^(NSString*callbackInner) {
        callback(callbackInner);
    } onFailure:failureBlock];
}

+ (void)removeSubscriptionTags:(NSArray* _Nullable)tagIds {
    [self.CPSharedInstance removeSubscriptionTags:tagIds];
}

+ (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback {
    [self.CPSharedInstance removeSubscriptionTags:tagIds callback:^(NSArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token {
    [self.CPSharedInstance startLiveActivity:activityId pushToken:token];
}

+ (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance startLiveActivity:activityId pushToken:token onSuccess:successBlock onFailure:failureBlock];
}

+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId value:value callback:nil];
}

+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value callback:(void(^ _Nullable)(void))callback {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId value:value callback:callback];
}

+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId arrayValue:value callback:nil];
}

+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value callback:(void(^ _Nullable)(void))callback {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId arrayValue:value callback:callback];
}

+ (void)setSubscriptionAttribute:(NSString * _Nullable)attributeId arrayValue:(NSArray<NSString *> * _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance setSubscriptionAttribute:attributeId arrayValue:value onSuccess:successBlock onFailure:failureBlock];
}

+ (void)setSubscriptionAttributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    [self.CPSharedInstance setSubscriptionAttributes:attributes];
}

+ (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    [self.CPSharedInstance pushSubscriptionAttributeValue:attributeId value:value];
}

+ (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance pushSubscriptionAttributeValue:attributeId value:value onSuccess:successBlock onFailure:failureBlock];
}

+ (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    [self.CPSharedInstance pullSubscriptionAttributeValue:attributeId value:value];
}

+ (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self.CPSharedInstance pullSubscriptionAttributeValue:attributeId value:value onSuccess:successBlock onFailure:failureBlock];
}

+ (BOOL)hasSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    return [self.CPSharedInstance hasSubscriptionAttributeValue:attributeId value:value];
}

+ (void)getAvailableTags:(void(^ _Nullable)(NSArray <CPChannelTag*>*))callback {
    [self.CPSharedInstance getAvailableTags:^(NSArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAvailableTopics:(void(^ _Nullable)(NSArray <CPChannelTopic*>*))callback {
    [self.CPSharedInstance getAvailableTopics:^(NSArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAvailableAttributes:(void(^ _Nullable)(NSMutableArray* _Nullable))callback {
    [self.CPSharedInstance getAvailableAttributes:^(NSMutableArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)setSubscriptionLanguage:(NSString* _Nullable)language {
    [self.CPSharedInstance setSubscriptionLanguage:language];
}

+ (void)setSubscriptionCountry:(NSString* _Nullable)country {
    [self.CPSharedInstance setSubscriptionCountry:country];
}

+ (void)setTopicsDialogWindow:(UIWindow* _Nullable)window {
    [self.CPSharedInstance setTopicsDialogWindow:window];
}

+ (void)setTopicsChangedListener:(CPTopicsChangedBlock _Nullable)changedBlock {
    [self.CPSharedInstance setTopicsChangedListener:changedBlock];
}

+ (void)setSubscriptionTopics:(NSMutableArray* _Nullable)topics {
    [self.CPSharedInstance setSubscriptionTopics:topics];
}

+ (void)setSubscriptionTopics:(NSMutableArray<NSString*>* _Nullable)topics onSuccess:(void (^ _Nullable)(void))successBlock onFailure:(CPFailureBlock _Nullable)failure {
    [self.CPSharedInstance setSubscriptionTopics:topics onSuccess:successBlock onFailure:failure];
}

+ (void)setBrandingColor:(UIColor* _Nullable)color {
    [self.CPSharedInstance setBrandingColor:color];
}

+ (void)setNormalTintColor:(UIColor* _Nullable)color {
    [self.CPSharedInstance setNormalTintColor:color];
}

+ (UIColor* _Nullable)getNormalTintColor {
    return [self.CPSharedInstance getNormalTintColor];
}

+ (void)setAutoClearBadge:(BOOL)autoClear {
    [self.CPSharedInstance setAutoClearBadge:autoClear];
}

+ (void)setAutoResubscribe:(BOOL)resubscribe {
    [self.CPSharedInstance setAutoResubscribe:resubscribe];
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

+ (void)setAutoRequestNotificationPermission:(BOOL)autoRequest {
    [self.CPSharedInstance setAutoRequestNotificationPermission:autoRequest];
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

+ (void)setDisplayAlertEnabledForNotifications:(BOOL)enabled {
    [self.CPSharedInstance setDisplayAlertEnabledForNotifications:enabled];
}

+ (void)setSoundEnabledForNotifications:(BOOL)enabled {
    [self.CPSharedInstance setSoundEnabledForNotifications:enabled];
}

+ (void)setBadgeCountEnabledForNotifications:(BOOL)enabled {
    [self.CPSharedInstance setBadgeCountEnabledForNotifications:enabled];
}

+ (void)addChatView:(CPChatView* _Nullable)chatView {
    [self.CPSharedInstance addChatView:chatView];
}

+ (void)showTopicsDialog {
    [self.CPSharedInstance showTopicsDialog];
}

+ (void)showTopicDialogOnNewAdded {
    [self.CPSharedInstance showTopicDialogOnNewAdded];
}

+ (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow {
    [self.CPSharedInstance showTopicsDialog:targetWindow];
}

+ (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow callback:(void(^ _Nullable)(void))callback {
    [self.CPSharedInstance showTopicsDialog:targetWindow callback:callback];
}

+ (void)getChannelConfig:(void(^ _Nullable)(NSDictionary* _Nullable))callback {
    [self.CPSharedInstance getChannelConfig:^(NSDictionary*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getSubscriptionId:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance getSubscriptionId:^(NSString*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getDeviceToken:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self.CPSharedInstance getDeviceToken:callback];
}

+ (void)trackEvent:(NSString* _Nullable)eventName {
    [self.CPSharedInstance trackEvent:eventName];
}

+ (void)trackEvent:(NSString* _Nullable)eventName amount:(NSNumber* _Nullable)amount {
    [self.CPSharedInstance trackEvent:eventName amount:amount];
}

+ (void)trackEvent:(NSString* _Nullable)eventName properties:(NSDictionary* _Nullable)properties {
    [self.CPSharedInstance trackEvent:eventName properties:properties];
}

+ (void)triggerFollowUpEvent:(NSString* _Nullable)eventName {
    [self.CPSharedInstance triggerFollowUpEvent:eventName];
}

+ (void)triggerFollowUpEvent:(NSString* _Nullable)eventName parameters:(NSDictionary* _Nullable)parameters {
    [self.CPSharedInstance triggerFollowUpEvent:eventName parameters:parameters];
}

+ (void)trackPageView:(NSString* _Nullable)url {
    [self.CPSharedInstance trackPageView:url];
}

+ (void)trackPageView:(NSString* _Nullable)url params:(NSDictionary* _Nullable)params {
    [self.CPSharedInstance trackPageView:url params:params];
}

+ (void)increaseSessionVisits {
    [self.CPSharedInstance increaseSessionVisits];
}

+ (void)showAppBanner:(NSString* _Nullable)bannerId {
    [self.CPSharedInstance showAppBanner:bannerId];
}

+ (void)showAppBanner:(NSString* _Nullable)bannerId appBannerClosedCallback:(CPAppBannerClosedBlock _Nullable)appBannerClosedCallback {
    [self.CPSharedInstance showAppBanner:bannerId appBannerClosedCallback:appBannerClosedCallback];
}

+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock _Nullable)callback {
    [self.CPSharedInstance setAppBannerOpenedCallback:^(CPAppBannerAction*action) {
        callback(action);
    }];
}

+ (void)setAppBannerShownCallback:(CPAppBannerShownBlock _Nullable)callback {
    [self.CPSharedInstance setAppBannerShownCallback:^(CPAppBanner*appBanner) {
        callback(appBanner);
    }];
}

+ (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock _Nullable)callback {
    [self.CPSharedInstance setShowAppBannerCallback:^(UIViewController*viewController) {
        callback(viewController);
    }];
}

+ (void)getAppBanners:(NSString* _Nullable)channelId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback {
    [self.CPSharedInstance getAppBanners:channelId callback:^(NSMutableArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)getAppBannersByGroup:(NSString* _Nullable)groupId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback {
    [self.CPSharedInstance getAppBannersByGroup:groupId callback:^(NSMutableArray*callbackInner) {
        callback(callbackInner);
    }];
}

+ (void)setApiEndpoint:(NSString* _Nullable)apiEndpoint {
    [self.CPSharedInstance setApiEndpoint:apiEndpoint];
}

+ (void)setAppGroupIdentifierSuffix:(NSString* _Nullable)suffix {
    [self.CPSharedInstance setAppGroupIdentifierSuffix:suffix];
}

+ (void)setIabTcfMode:(CPIabTcfMode)mode {
    [self.CPSharedInstance setIabTcfMode:mode];
}

+ (void)setAuthorizerToken:(NSString* _Nullable)authorizerToken {
    [self.CPSharedInstance setAuthorizerToken:authorizerToken];
}

+ (void)setCustomTopViewController:(UIViewController* _Nullable)viewController {
    [self.CPSharedInstance setCustomTopViewController:viewController];
}

+ (void)setAppBannerModalPresentationStyle:(UIModalPresentationStyle)style {
    [[self CPSharedInstance] setAppBannerModalPresentationStyle:style];
}

+ (void)setLocalEventTrackingRetentionDays:(int)days {
    [self.CPSharedInstance setLocalEventTrackingRetentionDays:days];
}

+ (void)setBadgeCount:(NSInteger)count {
    [self.CPSharedInstance setBadgeCount:count];
}

+ (void)updateBadge:(UNMutableNotificationContent* _Nullable)replacementContent {
    [self.CPSharedInstance updateBadge:replacementContent];
}

+ (void)addStoryView:(CPStoryView* _Nullable)storyView {
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

+ (void)setHandleUniversalLinksInAppForDomains:(NSArray<NSString *> *)domains {
    [self.CPSharedInstance setHandleUniversalLinksInAppForDomains:domains];
}

+ (void)setConfirmAlertShown {
    [self.CPSharedInstance setConfirmAlertShown];
}

+ (void)areNotificationsEnabled:(void(^ _Nullable)(BOOL))callback {
    [self.CPSharedInstance areNotificationsEnabled:callback];
}

+ (UIViewController* _Nullable)topViewController {
    return [self.CPSharedInstance topViewController];
}

+ (NSArray* _Nullable)getAvailableTags __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableTags];
}

+ (NSArray* _Nullable)getAvailableTopics __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableTopics];
}

+ (NSArray* _Nullable)getSubscriptionTags {
    return [self.CPSharedInstance getSubscriptionTags];
}

+ (NSArray* _Nullable)getNotifications {
    return [self.CPSharedInstance getNotifications];
}

+ (void)getNotifications:(BOOL)combineWithApi callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback {
    [self.CPSharedInstance getNotifications:combineWithApi callback:^(NSArray<CPNotification*>*notifications) {
        callback(notifications);
    }];
}

+ (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback {
    [self.CPSharedInstance getNotifications:combineWithApi limit:limit skip:skip callback:^(NSArray<CPNotification*>*notifications) {
        callback(notifications);
    }];
}

+ (NSArray* _Nullable)getSeenStories {
    return [self.CPSharedInstance getSeenStories];
}

+ (NSArray<NSString*>* _Nullable)getHandleUniversalLinksInAppForDomains {
    return [self.CPSharedInstance getHandleUniversalLinksInAppForDomains];
}

+ (NSMutableArray* _Nullable)getSubscriptionTopics {
    return [self.CPSharedInstance getSubscriptionTopics];
}

+ (NSObject* _Nullable)getSubscriptionAttribute:(NSString* _Nullable)attributeId {
    return [self.CPSharedInstance getSubscriptionAttribute:attributeId];
}

+ (NSString* _Nullable)getSubscriptionId {
    return [self.CPSharedInstance getSubscriptionId];
}

+ (NSString* _Nullable)getApiEndpoint {
    return [self.CPSharedInstance getApiEndpoint];
}

+ (NSString* _Nullable)getAppGroupIdentifierSuffix {
    return [self.CPSharedInstance getAppGroupIdentifierSuffix];
}

+ (CPIabTcfMode)getIabTcfMode {
    return [self.CPSharedInstance getIabTcfMode];
}

+ (UIViewController* _Nullable)getCustomTopViewController {
    return [self.CPSharedInstance getCustomTopViewController];
}

+ (UIModalPresentationStyle)getAppBannerModalPresentationStyle {
    return [[self CPSharedInstance] getAppBannerModalPresentationStyle];
}

+ (int)getLocalEventTrackingRetentionDays {
    return [self.CPSharedInstance getLocalEventTrackingRetentionDays];
}

+ (void)getBadgeCount:(void (^ _Nullable)(NSInteger))completionHandler {
    return [self.CPSharedInstance getBadgeCount:completionHandler];
}

+ (NSString* _Nullable)channelId {
    return [self.CPSharedInstance channelId];
}

+ (UIColor* _Nullable)getBrandingColor {
    return [self.CPSharedInstance getBrandingColor];
}

+ (NSMutableArray* _Nullable)getAvailableAttributes __attribute__((deprecated)) {
    return [self.CPSharedInstance getAvailableAttributes];
}

+ (NSDictionary* _Nullable)getSubscriptionAttributes {
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

+ (BOOL)handleSilentNotificationReceived:(UIApplication* _Nullable)application UserInfo:(NSDictionary* _Nullable)messageDict completionHandler:(void(^ _Nullable)(UIBackgroundFetchResult))completionHandler{
    return [self.CPSharedInstance handleSilentNotificationReceived:application UserInfo:messageDict completionHandler:completionHandler];
}

+ (BOOL)hasSubscriptionTag:(NSString* _Nullable)tagId {
    return [self.CPSharedInstance hasSubscriptionTag:tagId];
}

#pragma mark - check the topicId exists in the subscriptionTopics or not
+ (BOOL)hasSubscriptionTopic:(NSString* _Nullable)topicId {
    return [self.CPSharedInstance hasSubscriptionTopic:topicId];
}

+ (BOOL)getDeselectValue {
    return [self.CPSharedInstance getDeselectValue];
}

+ (BOOL)getUnsubscribeStatus {
    return [self.CPSharedInstance getUnsubscribeStatus];
}

+ (BOOL)getHandleUrlFromSceneDelegate {
    return [self.CPSharedInstance getHandleUrlFromSceneDelegate];
}

+ (void)setLogListener:(CPLogListener _Nullable)listener {
    [self.CPSharedInstance setLogListener:listener];
}

+ (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    return [self.CPSharedInstance didReceiveNotificationExtensionRequest:request withMutableNotificationContent:replacementContent];
}

+ (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    return [self.CPSharedInstance serviceExtensionTimeWillExpireRequest:request withMutableNotificationContent:replacementContent];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification* _Nullable)notification actionIdentifier:(NSString* _Nullable)actionIdentifier {
    [self.CPSharedInstance processLocalActionBasedNotification:notification actionIdentifier:actionIdentifier];
}

+ (void)removeNotification:(NSString* _Nullable)notificationId {
    [self.CPSharedInstance removeNotification:notificationId];
}

+ (void)removeNotification:(NSString* _Nullable)notificationId removeFromNotificationCenter:(BOOL)removeFromCenter {
    [self.CPSharedInstance removeNotification:notificationId removeFromNotificationCenter:removeFromCenter];
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
    NSProcessInfo*processInfo = [NSProcessInfo processInfo];
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

    injectSelector([UIApplication class], @selector(setDelegate:), [CleverPushAppDelegate class], @selector(setCleverPushDelegate:));

#pragma clang diagnostic pop

    [self setupUNUserNotificationCenterDelegate];
}

#pragma mark - Notification delegates injections.
+ (void)setupUNUserNotificationCenterDelegate {
    if (!NSClassFromString(@"UNUserNotificationCenter")) {
        return;
    }

    [CleverPushUNUserNotificationCenter injectSelectors];

    UNUserNotificationCenter* currentNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    if (!currentNotificationCenter.delegate) {
        currentNotificationCenter.delegate = (id)[CleverPush sharedInstance];
    }
}

@end
