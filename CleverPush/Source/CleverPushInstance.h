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

@property(readonly)NSDictionary* _Nullable payload;
@property(readonly)CPNotification* _Nullable notification;
@property(readonly)CPSubscription* _Nullable subscription;
- (instancetype _Nullable)initWithPayload:(NSDictionary * _Nullable)payload;

@end;

@interface CPNotificationOpenedResult : NSObject

@property(readonly)NSDictionary* _Nullable payload;
@property(readonly)CPNotification* _Nullable notification;
@property(readonly)CPSubscription* _Nullable subscription;
@property(readonly)NSString* _Nullable action;
- (instancetype _Nullable)initWithPayload:(NSDictionary * _Nullable)payload action:(NSString* _Nullable)action;

@end;

@class CPChannelTag;
@class CPChannelTopic;
@class CPAppBanner;

typedef void (^CPResultSuccessBlock)(NSDictionary* _Nullable result);
typedef void (^CPFailureBlock)(NSError* _Nullable error);

typedef void (^CPHandleSubscribedBlock)(NSString * _Nullable result);

typedef void (^CPTopicsChangedBlock)();

typedef void (^CPHandleNotificationReceivedBlock)(CPNotificationReceivedResult* _Nullable result);
typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult* _Nullable result);
typedef void (^CPInitializedBlock)(BOOL success, NSString* _Nullable failureMessage);

typedef void (^CPResultSuccessBlock)(NSDictionary* _Nullable result);
typedef void (^CPFailureBlock)(NSError* _Nullable error);

typedef void (^CPAppBannerActionBlock)(CPAppBannerAction* _Nullable action);
typedef void (^CPAppBannerShownBlock)(CPAppBanner* _Nullable appBanner);
typedef void (^CPAppBannerDisplayBlock)(UIViewController * _Nullable viewController);

typedef void (^CPLogListener)(NSString* _Nullable message);

@interface CleverPushInstance : NSObject

extern NSString* _Nullable const CLEVERPUSH_SDK_VERSION;

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
- (void)unsubscribe:(void(^ _Nullable)(BOOL))callback;
- (void)syncSubscription;
- (void)syncSubscription:(CPFailureBlock _Nullable)failureBlock;
- (void)didRegisterForRemoteNotifications:(UIApplication* _Nullable)app deviceToken:(NSData* _Nullable)inDeviceToken;
- (void)handleDidFailRegisterForRemoteNotification:(NSError* _Nullable)err;
- (void)handleNotificationOpened:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString* _Nullable)actionIdentifier;
- (void)handleNotificationReceived:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive;
- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock withRetry:(BOOL)retryOnFailure;
- (void)enqueueFailedRequest:(NSURLRequest* _Nullable)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)handleJSONNSURLResponse:(NSURLResponse* _Nullable) response data:(NSData* _Nullable) data error:(NSError* _Nullable) error onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTopic:(NSString* _Nullable)topicId;
- (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
- (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value callback:(void(^ _Nullable)())callback;
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value callback:(void(^ _Nullable)())callback;
- (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (BOOL)hasSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token;
- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)getAvailableTags:(void(^ _Nullable)(NSArray <CPChannelTag*>* _Nullable))callback;
- (void)getAvailableTopics:(void(^ _Nullable)(NSArray <CPChannelTopic*>* _Nullable))callback;
- (void)getAvailableAttributes:(void(^ _Nullable)(NSMutableArray* _Nullable))callback;
- (void)setSubscriptionLanguage:(NSString* _Nullable)language;
- (void)setSubscriptionCountry:(NSString* _Nullable)country;
- (void)setTopicsDialogWindow:(UIWindow* _Nullable)window;
- (void)setTopicsChangedListener:(CPTopicsChangedBlock _Nullable)changedBlock;
- (void)setSubscriptionTopics:(NSMutableArray <NSString*>* _Nullable)topics;
- (void)setBrandingColor:(UIColor* _Nullable)color;
- (void)setNormalTintColor:(UIColor* _Nullable)color;
- (UIColor* _Nullable)getNormalTintColor;
- (void)setAutoClearBadge:(BOOL)autoClear;
- (void)setAutoResubscribe:(BOOL)resubscribe;
- (void)setAppBannerDraftsEnabled:(BOOL)showDraft;
- (void)setSubscriptionChanged:(BOOL)subscriptionChanged;
- (void)setIncrementBadge:(BOOL)increment;
- (void)setShowNotificationsInForeground:(BOOL)show;
- (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
- (void)setAutoRequestNotificationPermission:(BOOL)autoRequest;
- (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData;
- (void)addChatView:(CPChatView* _Nullable)chatView;
- (void)showTopicsDialog;
- (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow;
- (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow callback:(void(^ _Nullable)())callback;
- (void)showTopicDialogOnNewAdded;
- (void)getChannelConfig:(void(^ _Nullable)(NSDictionary* _Nullable))callback;
- (void)getSubscriptionId:(void(^ _Nullable)(NSString* _Nullable))callback;
- (void)getDeviceToken:(void(^ _Nullable)(NSString* _Nullable))callback;
- (NSString* _Nullable)getDeviceToken;
- (void)trackEvent:(NSString* _Nullable)eventName;
- (void)trackEvent:(NSString* _Nullable)eventName amount:(NSNumber* _Nullable)amount;
- (void)trackEvent:(NSString* _Nullable)eventName properties:(NSDictionary* _Nullable)properties;
- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName;
- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName parameters:(NSDictionary* _Nullable)parameters;
- (void)trackPageView:(NSString* _Nullable)url;
- (void)trackPageView:(NSString* _Nullable)url params:(NSDictionary* _Nullable)params;
- (void)increaseSessionVisits;
- (void)showAppBanner:(NSString* _Nullable)bannerId;
- (void)getAppBanners:(NSString* _Nullable)channelId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback;
- (void)getAppBannersByGroup:(NSString* _Nullable)groupId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback;
- (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock _Nullable)callback;
- (void)setAppBannerShownCallback:(CPAppBannerShownBlock _Nullable)callback;
- (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock _Nullable)callback;
- (void)setApiEndpoint:(NSString* _Nullable)apiEndpoint;
- (void)setAppGroupIdentifierSuffix:(NSString* _Nullable)suffix;
- (void)setIabTcfMode:(CPIabTcfMode)mode;
- (void)setAuthorizerToken:(NSString* _Nullable)authorizerToken;
- (void)setCustomTopViewController:(UIViewController* _Nullable)viewController;
- (void)setLocalEventTrackingRetentionDays:(int)days;
- (void)updateBadge:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0));
- (void)addStoryView:(CPStoryView* _Nullable)storyView;
- (void)updateDeselectFlag:(BOOL)value;
- (void)setOpenWebViewEnabled:(BOOL)opened;
- (void)setUnsubscribeStatus:(BOOL)status;
- (UIViewController* _Nullable)topViewController;
- (NSArray<NSString*>* _Nullable)getSubscriptionTags;
- (NSArray<CPNotification*>* _Nullable)getNotifications;
- (void)removeNotification:(NSString* _Nullable)notificationId;
- (void)setMaximumNotificationCount:(int)limit;
- (void)getNotifications:(BOOL)combineWithApi callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback;
- (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback;
- (NSArray<NSString*>* _Nullable)getSeenStories;
- (NSMutableArray<NSString*>* _Nullable)getSubscriptionTopics;
- (NSArray* _Nullable)getAvailableTags __attribute__((deprecated));
- (NSArray* _Nullable)getAvailableTopics __attribute__((deprecated));

- (NSObject* _Nullable)getSubscriptionAttribute:(NSString* _Nullable)attributeId;
- (NSString* _Nullable)getSubscriptionId;
- (NSString* _Nullable)getApiEndpoint;
- (NSString* _Nullable)getAppGroupIdentifierSuffix;
- (NSString* _Nullable)channelId;
- (UIViewController* _Nullable)getCustomTopViewController;
- (int)getLocalEventTrackingRetentionDays;
- (CPIabTcfMode)getIabTcfMode;

- (UIColor* _Nullable)getBrandingColor;

- (NSMutableArray* _Nullable)getAvailableAttributes __attribute__((deprecated));
- (NSDictionary* _Nullable)getSubscriptionAttributes;
- (NSMutableDictionary* _Nullable)handleActionInNotification:(NSDictionary* _Nullable)notificationPayload withAction:(NSString* _Nullable)actionIdentifier
                                             payloadMutable:(NSMutableDictionary* _Nullable)payloadMutable;

- (BOOL)isDevelopmentModeEnabled;
- (BOOL)getAppBannerDraftsEnabled;
- (BOOL)getSubscriptionChanged;
- (BOOL)isSubscribed;
- (BOOL)handleSilentNotificationReceived:(UIApplication* _Nullable)application UserInfo:(NSDictionary* _Nullable)messageDict completionHandler:(void(^ _Nullable)(UIBackgroundFetchResult))completionHandler;
- (BOOL)hasSubscriptionTag:(NSString* _Nullable)tagId;
- (BOOL)hasSubscriptionTopic:(NSString* _Nullable)topicId;
- (BOOL)getDeselectValue;
- (BOOL)getUnsubscribeStatus;
- (void)setConfirmAlertShown;
- (void)areNotificationsEnabled:(void(^ _Nullable)(BOOL))callback;
- (void)setDatabaseInfo;

- (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0));
- (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)processLocalActionBasedNotification:(UILocalNotification* _Nullable) notification actionIdentifier:(NSString* _Nullable)actionIdentifier;
#pragma clang diagnostic pop

#pragma mark - refactor for testcases
- (NSString* _Nullable)subscriptionId;
- (void)setSubscriptionId:(NSString* _Nullable)subscriptionId;
- (NSString* _Nullable)getChannelIdFromBundle;
- (NSString* _Nullable)getChannelIdFromUserDefaults;
- (BOOL)getPendingChannelConfigRequest;
- (NSInteger)getAppOpens;
- (void)incrementAppOpens;
- (void)getChannelConfigFromBundleId:(NSString* _Nullable)configPath;
- (void)getChannelConfigFromChannelId:(NSString* _Nullable)configPath;
- (NSString* _Nullable)getBundleName;
- (BOOL)isChannelIdChanged:(NSString* _Nullable)channelId;
- (void)addOrUpdateChannelId:(NSString* _Nullable)channelId;
- (void)clearSubscriptionData;
- (void)fireChannelConfigListeners;
- (BOOL)getAutoClearBadge;
- (BOOL)clearBadge:(BOOL)fromNotificationOpened;
- (BOOL)shouldSync;
- (void)setHandleSubscribedCalled:(BOOL)subscribed;
- (BOOL)getHandleSubscribedCalled;
- (CPHandleSubscribedBlock _Nullable)getSubscribeHandler;
- (void)setSubscribeHandler:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
- (void)initFeatures;
- (void)initIabTcf;
- (void)initAppReview;
- (BOOL)hasNewTopicAfterOneHour:(NSDictionary* _Nullable)config initialDifference:(NSInteger)initialDifference displayDialogDifference:(NSInteger)displayAfter;
- (NSInteger)secondsAfterLastCheck;
- (void)showPendingTopicsDialog;
- (BOOL)hasSubscriptionTopics;
- (BOOL)isSubscriptionInProgress;
- (void)setSubscriptionInProgress:(BOOL)progress;
- (NSMutableArray* _Nullable)getAvailableAttributesFromConfig:(NSDictionary* _Nullable)channelConfig;
- (NSString* _Nullable)getCurrentPageUrl;
- (void)checkTags:(NSString* _Nullable)urlStr params:(NSDictionary* _Nullable)params;
- (void)autoAssignTagMatches:(CPChannelTag* _Nullable)tag pathname:(NSString* _Nullable)pathname params:(NSDictionary* _Nullable)params callback:(void(^ _Nullable)(BOOL))callback;
- (BOOL)getTrackingConsentRequired;
- (BOOL)getHasTrackingConsent;
- (BOOL)getHasTrackingConsentCalled;
- (void)waitForTrackingConsent:(void(^ _Nullable)(void))callback;
- (BOOL)getSubscribeConsentRequired;
- (BOOL)getHasSubscribeConsent;
- (BOOL)getHasSubscribeConsentCalled;
- (void)waitForSubscribeConsent:(void(^ _Nullable)(void))callback;
- (void)addSubscriptionTagToApi:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)removeSubscriptionTagFromApi:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
- (void)initTopicsDialogData:(NSDictionary* _Nullable)config syncToBackend:(BOOL)syncToBackend;

- (void)setLogListener:(CPLogListener _Nullable)listener;

@end
