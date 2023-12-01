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
#import "CPAppBanner.h"
#import "CPNotification.h"
#import "CPSubscription.h"
#import "CPChannelTag.h"
#import "CPChannelTopic.h"
#import "CleverPushInstance.h"
#import "CPInboxView.h"
#import "CleverPushUserDefaults.h"
#import "CPIabTcfMode.h"

@interface CleverPush : NSObject

extern NSString * const CLEVERPUSH_SDK_VERSION;

#pragma mark - Initialise with launch options
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;

+ (void)setTrackingConsentRequired:(BOOL)required;
+ (void)setTrackingConsent:(BOOL)consent;
+ (void)setSubscribeConsentRequired:(BOOL)required;
+ (void)setSubscribeConsent:(BOOL)consent;
+ (void)enableDevelopmentMode;
+ (void)subscribe;
+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock;
+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock;

+ (void)disableAppBanners;
+ (void)enableAppBanners;
+ (void)setAppBannerTrackingEnabled:(BOOL)enabled;
+ (BOOL)popupVisible;
+ (void)unsubscribe;
+ (void)unsubscribe:(void(^)(BOOL))callback;
+ (void)syncSubscription;
+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err;
+ (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier;
+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive;
+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock withRetry:(BOOL)retryOnFailure;
+ (void)enqueueFailedRequest:(NSURLRequest *)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*)error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)addSubscriptionTopic:(NSString*)topicId;
+ (void)addSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback;
+ (void)addSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
+ (void)addSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback;
+ (void)addSubscriptionTag:(NSString*)tagId;
+ (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
+ (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
+ (void)addSubscriptionTags:(NSArray <NSString*>*)tagIds;
+ (void)removeSubscriptionTopic:(NSString*)topicId;
+ (void)removeSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback;
+ (void)removeSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
+ (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback;
+ (void)removeSubscriptionTag:(NSString*)tagId;
+ (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
+ (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
+ (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds;
+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value;
+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value callback:(void(^)())callback;
+ (void)setSubscriptionAttribute:(NSString*)attributeId arrayValue:(NSArray <NSString*>*)value;
+ (void)setSubscriptionAttribute:(NSString*)attributeId arrayValue:(NSArray <NSString*>*)value callback:(void(^)())callback;
+ (void)pushSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (void)pullSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (BOOL)hasSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (void)startLiveActivity:(NSString*)activityId pushToken:(NSString*)token;
+ (void)startLiveActivity:(NSString*)activityId pushToken:(NSString*)token onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)getAvailableTags:(void(^)(NSArray <CPChannelTag*>*))callback;
+ (void)getAvailableTopics:(void(^)(NSArray <CPChannelTopic*>*))callback;
+ (void)getAvailableAttributes:(void(^)(NSMutableArray *))callback;
+ (void)setSubscriptionLanguage:(NSString*)language;
+ (void)setSubscriptionCountry:(NSString*)country;
+ (void)setTopicsDialogWindow:(UIWindow *)window;
+ (void)setTopicsChangedListener:(CPTopicsChangedBlock)changedBlock;
+ (void)setSubscriptionTopics:(NSMutableArray *)topics;
+ (void)setBrandingColor:(UIColor *)color;
+ (void)setNormalTintColor:(UIColor *)color;
+ (UIColor*)getNormalTintColor;
+ (void)setAutoClearBadge:(BOOL)autoClear;
+ (void)setAutoResubscribe:(BOOL)resubscribe;
+ (void)setAppBannerDraftsEnabled:(BOOL)showDraft;
+ (void)setSubscriptionChanged:(BOOL)subscriptionChanged;
+ (void)setIncrementBadge:(BOOL)increment;
+ (void)setShowNotificationsInForeground:(BOOL)show;
+ (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
+ (void)setAutoRequestNotificationPermission:(BOOL)autoRequest;
+ (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData;
+ (void)addChatView:(CPChatView*)chatView;
+ (void)showTopicsDialog;
+ (void)showTopicDialogOnNewAdded;
+ (void)showTopicsDialog:(UIWindow *)targetWindow;
+ (void)showTopicsDialog:(UIWindow *)targetWindow callback:(void(^)())callback;
+ (void)getChannelConfig:(void(^)(NSDictionary *))callback;
+ (void)getSubscriptionId:(void(^)(NSString *))callback;
+ (void)getDeviceToken:(void(^)(NSString *))callback;
+ (void)trackEvent:(NSString*)eventName;
+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount;
+ (void)trackEvent:(NSString*)eventName properties:(NSDictionary*)properties;
+ (void)triggerFollowUpEvent:(NSString*)eventName;
+ (void)triggerFollowUpEvent:(NSString*)eventName parameters:(NSDictionary*)parameters;
+ (void)trackPageView:(NSString*)url;
+ (void)trackPageView:(NSString*)url params:(NSDictionary*)params;
+ (void)increaseSessionVisits;
+ (void)showAppBanner:(NSString*)bannerId;
+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback;
+ (void)setAppBannerShownCallback:(CPAppBannerShownBlock)callback;
+ (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock)callback;
+ (void)getAppBanners:(NSString*)channelId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback;
+ (void)getAppBannersByGroup:(NSString*)groupId callback:(void(^)(NSMutableArray <CPAppBanner*>*))callback;
+ (void)setApiEndpoint:(NSString*)apiEndpoint;
+ (void)setAppGroupIdentifierSuffix:(NSString*)suffix;
+ (void)setIabTcfMode:(CPIabTcfMode)mode;
+ (void)setAuthorizerToken:(NSString*)authorizerToken;
+ (void)setCustomTopViewController:(UIViewController*)viewController;
+ (void)setLocalEventTrackingRetentionDays:(int)days;
+ (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (void)addStoryView:(CPStoryView*)storyView;
+ (void)updateDeselectFlag:(BOOL)value;
+ (void)setOpenWebViewEnabled:(BOOL)opened;
+ (void)setUnsubscribeStatus:(BOOL)status;
+ (UIViewController*)topViewController;
+ (BOOL)hasSubscriptionTopic:(NSString*)topicId;

+ (NSArray*)getAvailableTags __attribute__((deprecated));
+ (NSArray*)getAvailableTopics __attribute__((deprecated));
+ (NSArray<NSString*>*)getSubscriptionTags;
+ (NSArray<CPNotification*>*)getNotifications;
+ (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray<CPNotification*>*))callback;
+ (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback;
+ (void)removeNotification:(NSString*)notificationId;

+ (NSArray<NSString*>*)getSeenStories;
+ (NSMutableArray<NSString*>*)getSubscriptionTopics;
+ (void)setMaximumNotificationCount:(int)limit;

+ (NSObject*)getSubscriptionAttribute:(NSString*)attributeId;
+ (NSString*)getSubscriptionId;
+ (NSString*)getApiEndpoint;
+ (NSString*)getAppGroupIdentifierSuffix;
+ (NSString*)channelId;
+ (UIViewController*)getCustomTopViewController;
+ (int)getLocalEventTrackingRetentionDays;

+ (UIColor*)getBrandingColor;

+ (NSMutableArray*)getAvailableAttributes __attribute__((deprecated));
+ (NSDictionary*)getSubscriptionAttributes;

+ (BOOL)isDevelopmentModeEnabled;
+ (BOOL)getAppBannerDraftsEnabled;
+ (BOOL)getSubscriptionChanged;
+ (BOOL)isSubscribed;
+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (BOOL)hasSubscriptionTag:(NSString*)tagId;
+ (BOOL)getDeselectValue;
+ (BOOL)getUnsubscribeStatus;
+ (void)setConfirmAlertShown;
+ (void)areNotificationsEnabled:(void(^)(BOOL))callback;

+ (void)setLogListener:(CPLogListener)listener;

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification*) notification actionIdentifier:(NSString*)actionIdentifier;
#pragma clang diagnostic pop

@end
