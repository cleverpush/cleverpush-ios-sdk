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

extern NSString* _Nullable const CLEVERPUSH_SDK_VERSION;

#pragma mark - Initialise with launch options
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister handleInitialized:(CPInitializedBlock _Nullable)initializedCallback;
+ (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegister;

+ (void)setTrackingConsentRequired:(BOOL)required;
+ (void)setTrackingConsent:(BOOL)consent;
+ (void)setSubscribeConsentRequired:(BOOL)required;
+ (void)setSubscribeConsent:(BOOL)consent;
+ (void)enableDevelopmentMode;
+ (void)subscribe;
+ (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock;
+ (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock;

+ (void)disableAppBanners;
+ (void)enableAppBanners;
+ (void)setAppBannerTrackingEnabled:(BOOL)enabled;
+ (BOOL)popupVisible;
+ (void)unsubscribe;
+ (void)unsubscribe:(void(^ _Nullable)(BOOL))callback;
+ (void)syncSubscription;
+ (void)didRegisterForRemoteNotifications:(UIApplication* _Nullable)app deviceToken:(NSData* _Nullable)inDeviceToken;
+ (void)handleDidFailRegisterForRemoteNotification:(NSError* _Nullable)err;
+ (void)handleNotificationOpened:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString* _Nullable)actionIdentifier;
+ (void)handleNotificationReceived:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive;
+ (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock withRetry:(BOOL)retryOnFailure;
+ (void)enqueueFailedRequest:(NSURLRequest* _Nullable)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse* _Nullable)response data:(NSData* _Nullable)data error:(NSError* _Nullable)error onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId;
+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
+ (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback;
+ (void)addSubscriptionTag:(NSString* _Nullable)tagId;
+ (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
+ (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId;
+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
+ (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback;
+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId;
+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback;
+ (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds;
+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value callback:(void(^ _Nullable)())callback;
+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value;
+ (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value callback:(void(^ _Nullable)())callback;
+ (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
+ (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
+ (BOOL)hasSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value;
+ (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token;
+ (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)getAvailableTags:(void(^ _Nullable)(NSArray <CPChannelTag*>* _Nullable))callback;
+ (void)getAvailableTopics:(void(^ _Nullable)(NSArray <CPChannelTopic*>* _Nullable))callback;
+ (void)getAvailableAttributes:(void(^ _Nullable)(NSMutableArray* _Nullable))callback;
+ (void)setSubscriptionLanguage:(NSString* _Nullable)language;
+ (void)setSubscriptionCountry:(NSString* _Nullable)country;
+ (void)setTopicsDialogWindow:(UIWindow* _Nullable)window;
+ (void)setTopicsChangedListener:(CPTopicsChangedBlock _Nullable)changedBlock;
+ (void)setSubscriptionTopics:(NSMutableArray* _Nullable)topics;
+ (void)setBrandingColor:(UIColor* _Nullable)color;
+ (void)setNormalTintColor:(UIColor* _Nullable)color;
+ (UIColor* _Nullable)getNormalTintColor;
+ (void)setAutoClearBadge:(BOOL)autoClear;
+ (void)setAutoResubscribe:(BOOL)resubscribe;
+ (void)setAppBannerDraftsEnabled:(BOOL)showDraft;
+ (void)setSubscriptionChanged:(BOOL)subscriptionChanged;
+ (void)setIncrementBadge:(BOOL)increment;
+ (void)setShowNotificationsInForeground:(BOOL)show;
+ (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
+ (void)setAutoRequestNotificationPermission:(BOOL)autoRequest;
+ (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData;
+ (void)addChatView:(CPChatView* _Nullable)chatView;
+ (void)showTopicsDialog;
+ (void)showTopicDialogOnNewAdded;
+ (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow;
+ (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow callback:(void(^ _Nullable)())callback;
+ (void)getChannelConfig:(void(^ _Nullable)(NSDictionary* _Nullable))callback;
+ (void)getSubscriptionId:(void(^ _Nullable)(NSString* _Nullable))callback;
+ (void)getDeviceToken:(void(^ _Nullable)(NSString* _Nullable))callback;
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
+ (CPIabTcfMode)getIabTcfMode;

+ (UIColor*)getBrandingColor;

+ (NSMutableArray*)getAvailableAttributes __attribute__((deprecated));
+ (NSDictionary*)getSubscriptionAttributes;

+ (BOOL)isDevelopmentModeEnabled;
+ (BOOL)getAppBannerDraftsEnabled;
+ (BOOL)getSubscriptionChanged;
+ (BOOL)isSubscribed;
+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void(^)(UIBackgroundFetchResult))completionHandler;
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
