//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wnullability-completeness"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>
#import <StoreKit/StoreKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#define XC8_AVAILABLE 1
#import <UserNotifications/UserNotifications.h>
#endif

#import "CPChatView.h"
#import "CPStoryView.h"
#import "CPNotificationViewController.h"
#import "CleverPushHTTPClient.h"
#import "CPAppBannerAction.h"
#import "CPNotification.h"
#import "CPSubscription.h"
#import "CPChannelTag.h"
#import "CPChannelTopic.h"
#import "CPIabTcfMode.h"

@interface CPNotificationReceivedResult : NSObject

@property(readonly)NSDictionary* payload;
@property(readonly)CPNotification* notification;
@property(readonly)CPSubscription* subscription;
- (instancetype)initWithPayload:(NSDictionary *)payload;

@end;

@interface CPNotificationOpenedResult : NSObject

@property(readonly)NSDictionary* payload;
@property(readonly)CPNotification* notification;
@property(readonly)CPSubscription* subscription;
@property(readonly)NSString* action;
- (instancetype)initWithPayload:(NSDictionary *)payload action:(NSString* _Nullable)action;

@end;

@class CPChannelTag;
@class CPChannelTopic;
@class CPAppBanner;

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPHandleSubscribedBlock)(NSString * result);

typedef void (^CPTopicsChangedBlock)();

typedef void (^CPHandleNotificationReceivedBlock)(CPNotificationReceivedResult* result);
typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult* result);
typedef void (^CPInitializedBlock)(BOOL success, NSString* _Nullable failureMessage);

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPAppBannerActionBlock)(CPAppBannerAction* action);
typedef void (^CPAppBannerShownBlock)(CPAppBanner* appBanner);
typedef void (^CPAppBannerDisplayBlock)(UIViewController *viewController);

typedef void (^CPLogListener)(NSString* message);

@interface CleverPushInstance : NSObject

extern NSString * const CLEVERPUSH_SDK_VERSION;

#pragma mark - Initialise with launch options
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister  handleInitialized:(CPInitializedBlock _Nullable)initializedCallback;
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;

- (void)setTrackingConsentRequired:(BOOL)required;
- (void)setTrackingConsent:(BOOL)consent;
- (void)setSubscribeConsentRequired:(BOOL)required;
- (void)setSubscribeConsent:(BOOL)consent;
- (void)enableDevelopmentMode;
- (void)subscribe;
- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock;
- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock;

- (void)disableAppBanners;
- (void)enableAppBanners;
- (void)setAppBannerTrackingEnabled:(BOOL)enabled;
- (BOOL)popupVisible;
- (void)unsubscribe;
- (void)unsubscribe:(void(^)(BOOL))callback;
- (void)syncSubscription;
- (void)syncSubscription:(CPFailureBlock _Nullable)failureBlock;
- (void)didRegisterForRemoteNotifications:(UIApplication* _Nullable)app deviceToken:(NSData* _Nullable)inDeviceToken;
- (void)handleDidFailRegisterForRemoteNotification:(NSError* _Nullable)err;
- (void)handleNotificationOpened:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString* _Nullable)actionIdentifier;
- (void)handleNotificationReceived:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive;
- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock withRetry:(BOOL)retryOnFailure;
- (void)enqueueFailedRequest:(NSURLRequest *_Nullable)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)handleJSONNSURLResponse:(NSURLResponse* _Nullable) response data:(NSData* _Nullable) data error:(NSError* _Nullable) error onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTopic:(NSString* _Nullable)topicId;
- (void)addSubscriptionTopic:(NSString * _Nullable)topicId callback:(void(^ _Nullable)(NSString * _Nullable))callback;
- (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString * _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTags:(NSArray<NSString *> * _Nullable)tagIds callback:(void(^ _Nullable)(NSArray<NSString *> * _Nullable))callback;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString * _Nullable))callback;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString * _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString * _Nullable))callback;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString * _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTags:(NSArray<NSString *> * _Nullable)tagIds callback:(void(^ _Nullable)(NSArray<NSString *> * _Nullable))callback;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString * _Nullable))callback;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString * _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value callback:(void(^ _Nullable)())callback;
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>*)value callback:(void(^ _Nullable)())callback;
- (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (BOOL)hasSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token;
- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)getAvailableTags:(void(^)(NSArray <CPChannelTag*>*))callback;
- (void)getAvailableTopics:(void(^)(NSArray <CPChannelTopic*>*))callback;
- (void)getAvailableAttributes:(void(^)(NSMutableArray *))callback;
- (void)setSubscriptionLanguage:(NSString* _Nullable)language;
- (void)setSubscriptionCountry:(NSString* _Nullable)country;
- (void)setTopicsDialogWindow:(UIWindow *)window;
- (void)setTopicsChangedListener:(CPTopicsChangedBlock)changedBlock;
- (void)setSubscriptionTopics:(NSMutableArray <NSString*>*)topics;
- (void)setBrandingColor:(UIColor *)color;
- (void)setNormalTintColor:(UIColor *)color;
- (UIColor*)getNormalTintColor;
- (void)setAutoClearBadge:(BOOL)autoClear;
- (void)setAutoResubscribe:(BOOL)resubscribe;
- (void)setAppBannerDraftsEnabled:(BOOL)showDraft;
- (void)setSubscriptionChanged:(BOOL)subscriptionChanged;
- (void)setIncrementBadge:(BOOL)increment;
- (void)setShowNotificationsInForeground:(BOOL)show;
- (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
- (void)setAutoRequestNotificationPermission:(BOOL)autoRequest;
- (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData;
- (void)addChatView:(CPChatView*)chatView;
- (void)showTopicsDialog;
- (void)showTopicsDialog:(UIWindow *)targetWindow;
- (void)showTopicsDialog:(UIWindow *)targetWindow callback:(void(^)())callback;
- (void)showTopicDialogOnNewAdded;
- (void)getChannelConfig:(void(^)(NSDictionary *))callback;
- (void)getSubscriptionId:(void(^)(NSString *))callback;
- (void)getDeviceToken:(void(^)(NSString *))callback;
- (NSString*)getDeviceToken;
- (void)trackEvent:(NSString* _Nullable)eventName;
- (void)trackEvent:(NSString* _Nullable)eventName amount:(NSNumber*)amount;
- (void)trackEvent:(NSString* _Nullable)eventName properties:(NSDictionary* _Nullable)properties;
- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName;
- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName parameters:(NSDictionary* _Nullable)parameters;
- (void)trackPageView:(NSString* _Nullable)url;
- (void)trackPageView:(NSString* _Nullable)url params:(NSDictionary* _Nullable)params;
- (void)increaseSessionVisits;
- (void)showAppBanner:(NSString* _Nullable)bannerId;
- (void)getAppBanners:(NSString* _Nullable)channelId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback;
- (void)getAppBannersByGroup:(NSString* _Nullable)groupId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback;
- (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback;
- (void)setAppBannerShownCallback:(CPAppBannerShownBlock)callback;
- (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock)callback;
- (void)setApiEndpoint:(NSString* _Nullable)apiEndpoint;
- (void)setAppGroupIdentifierSuffix:(NSString* _Nullable)suffix;
- (void)setIabTcfMode:(CPIabTcfMode)mode;
- (void)setAuthorizerToken:(NSString* _Nullable)authorizerToken;
- (void)setCustomTopViewController:(UIViewController*)viewController;
- (void)setLocalEventTrackingRetentionDays:(int)days;
- (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
- (void)addStoryView:(CPStoryView*)storyView;
- (void)updateDeselectFlag:(BOOL)value;
- (void)setOpenWebViewEnabled:(BOOL)opened;
- (void)setUnsubscribeStatus:(BOOL)status;
- (UIViewController*)topViewController;
- (NSArray<NSString*>*)getSubscriptionTags;
- (NSArray<CPNotification*>*)getNotifications;
- (void)removeNotification:(NSString* _Nullable)notificationId;
- (void)setMaximumNotificationCount:(int)limit;
- (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray<CPNotification*>*))callback;
- (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback;
- (NSArray<NSString*>*)getSeenStories;
- (NSMutableArray<NSString*>*)getSubscriptionTopics;
- (NSArray*)getAvailableTags __attribute__((deprecated));
- (NSArray*)getAvailableTopics __attribute__((deprecated));

- (NSObject*)getSubscriptionAttribute:(NSString* _Nullable)attributeId;
- (NSString*)getSubscriptionId;
- (NSString*)getApiEndpoint;
- (NSString*)getAppGroupIdentifierSuffix;
- (NSString*)channelId;
- (UIViewController*)getCustomTopViewController;
- (int)getLocalEventTrackingRetentionDays;
- (CPIabTcfMode)getIabTcfMode;

- (UIColor*)getBrandingColor;

- (NSMutableArray*)getAvailableAttributes __attribute__((deprecated));
- (NSDictionary*)getSubscriptionAttributes;
- (NSMutableDictionary*)handleActionInNotification:(NSDictionary* _Nullable)notificationPayload withAction:(NSString* _Nullable)actionIdentifier
    payloadMutable:(NSMutableDictionary *)payloadMutable;

- (BOOL)isDevelopmentModeEnabled;
- (BOOL)getAppBannerDraftsEnabled;
- (BOOL)getSubscriptionChanged;
- (BOOL)isSubscribed;
- (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary* _Nullable)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (BOOL)hasSubscriptionTag:(NSString* _Nullable)tagId;
- (BOOL)hasSubscriptionTopic:(NSString* _Nullable)topicId;
- (BOOL)getDeselectValue;
- (BOOL)getUnsubscribeStatus;
- (void)setConfirmAlertShown;
- (void)areNotificationsEnabled:(void(^)(BOOL))callback;
- (void)setDatabaseInfo;

- (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
- (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)processLocalActionBasedNotification:(UILocalNotification*) notification actionIdentifier:(NSString* _Nullable)actionIdentifier;
#pragma clang diagnostic pop

#pragma mark - refactor for testcases
- (NSString*)subscriptionId;
- (void)setSubscriptionId:(NSString *)subscriptionId;
- (NSString*)getChannelIdFromBundle;
- (NSString*)getChannelIdFromUserDefaults;
- (BOOL)getPendingChannelConfigRequest;
- (NSInteger)getAppOpens;
- (void)incrementAppOpens;
- (void)getChannelConfigFromBundleId:(NSString *)configPath;
- (void)getChannelConfigFromChannelId:(NSString *)configPath;
- (NSString*)getBundleName;
- (BOOL)isChannelIdChanged:(NSString *)channelId;
- (void)addOrUpdateChannelId:(NSString *)channelId;
- (void)clearSubscriptionData;
- (void)fireChannelConfigListeners;
- (BOOL)getAutoClearBadge;
- (BOOL)clearBadge:(BOOL)fromNotificationOpened;
- (BOOL)shouldSync;
- (void)setHandleSubscribedCalled:(BOOL)subscribed;
- (BOOL)getHandleSubscribedCalled;
- (CPHandleSubscribedBlock)getSubscribeHandler;
- (void)setSubscribeHandler:(CPHandleSubscribedBlock)subscribedCallback;
- (void)initFeatures;
- (void)initIabTcf;
- (void)initAppReview;
- (BOOL)hasNewTopicAfterOneHour:(NSDictionary* _Nullable)config initialDifference:(NSInteger)initialDifference displayDialogDifference:(NSInteger)displayAfter;
- (NSInteger)secondsAfterLastCheck;
- (void)showPendingTopicsDialog;
- (BOOL)hasSubscriptionTopics;
- (BOOL)isSubscriptionInProgress;
- (void)setSubscriptionInProgress:(BOOL)progress;
- (NSMutableArray*)getAvailableAttributesFromConfig:(NSDictionary* _Nullable)channelConfig;
- (NSString*)getCurrentPageUrl;
- (void)checkTags:(NSString* _Nullable)urlStr params:(NSDictionary* _Nullable)params;
- (void)autoAssignTagMatches:(CPChannelTag*)tag pathname:(NSString* _Nullable)pathname params:(NSDictionary* _Nullable)params callback:(void(^)(BOOL))callback;
- (BOOL)getTrackingConsentRequired;
- (BOOL)getHasTrackingConsent;
- (BOOL)getHasTrackingConsentCalled;
- (void)waitForTrackingConsent:(void(^)(void))callback;
- (BOOL)getSubscribeConsentRequired;
- (BOOL)getHasSubscribeConsent;
- (BOOL)getHasSubscribeConsentCalled;
- (void)waitForSubscribeConsent:(void(^)(void))callback;
- (void)addSubscriptionTagToApi:(NSString* _Nullable)tagId callback:(void (^)(NSString *))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTagFromApi:(NSString* _Nullable)tagId callback:(void (^)(NSString *))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)initTopicsDialogData:(NSDictionary* _Nullable)config syncToBackend:(BOOL)syncToBackend;

- (void)setLogListener:(CPLogListener)listener;

@end

#pragma clang diagnostic pop
