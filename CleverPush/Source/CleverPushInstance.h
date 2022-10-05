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
- (instancetype)initWithPayload:(NSDictionary *)payload action:(NSString*)action;

@end;

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPHandleSubscribedBlock)(NSString * result);

typedef void (^CPHandleNotificationReceivedBlock)(CPNotificationReceivedResult* result);
typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult* result);

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPAppBannerActionBlock)(CPAppBannerAction* action);

typedef void (^CPLogListener)(NSString* message);

@class CPChannelTag;
@class CPChannelTopic;
@class CPAppBanner;

@interface CleverPushInstance : NSObject

extern NSString * const CLEVERPUSH_SDK_VERSION;

#pragma mark - Initialise with launch options
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister;

- (void)setTrackingConsentRequired:(BOOL)required;
- (void)setTrackingConsent:(BOOL)consent;
- (void)enableDevelopmentMode;
- (void)subscribe;
- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock;
- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock;

- (void)disableAppBanners;
- (void)enableAppBanners;
- (BOOL)popupVisible;
- (void)unsubscribe;
- (void)unsubscribe:(void(^)(BOOL))callback;
- (void)syncSubscription;
- (void)syncSubscription:(CPFailureBlock)failureBlock;
- (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
- (void)handleDidFailRegisterForRemoteNotification:(NSError*)err;
- (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier;
- (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive;
- (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
- (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
- (void)addSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback;
- (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
- (void)addSubscriptionTags:(NSArray <NSString*>*)tagIds;
- (void)addSubscriptionTag:(NSString*)tagId;
- (void)removeSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback;
- (void)removeSubscriptionTopic:(NSString*)topicId;
- (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback;
- (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
- (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds;
- (void)removeSubscriptionTag:(NSString*)tagId;
- (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value;
- (void)pushSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
- (void)pullSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
- (BOOL)hasSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
- (void)getAvailableTags:(void(^)(NSArray <CPChannelTag*>*))callback;
- (void)getAvailableTopics:(void(^)(NSArray <CPChannelTopic*>*))callback;
- (void)getAvailableAttributes:(void(^)(NSDictionary *))callback;
- (void)setSubscriptionLanguage:(NSString*)language;
- (void)setSubscriptionCountry:(NSString*)country;
- (void)setTopicsDialogWindow:(UIWindow *)window;
- (void)addSubscriptionTopic:(NSString*)topicId callback:(void(^)(NSString *))callback;
- (void)addSubscriptionTopic:(NSString*)topicId;
- (void)setSubscriptionTopics:(NSMutableArray <NSString*>*)topics;
- (void)setBrandingColor:(UIColor *)color;
- (void)setNormalTintColor:(UIColor *)color;
- (UIColor*)getNormalTintColor;
- (void)setChatBackgroundColor:(UIColor *)color;
- (void)setAutoClearBadge:(BOOL)autoClear;
- (void)setIncrementBadge:(BOOL)increment;
- (void)setShowNotificationsInForeground:(BOOL)show;
- (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
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
- (void)trackEvent:(NSString*)eventName;
- (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount;
- (void)triggerFollowUpEvent:(NSString*)eventName;
- (void)triggerFollowUpEvent:(NSString*)eventName parameters:(NSDictionary*)parameters;
- (void)trackPageView:(NSString*)url;
- (void)trackPageView:(NSString*)url params:(NSDictionary*)params;
- (void)increaseSessionVisits;
- (void)showAppBanner:(NSString*)bannerId;
- (void)getAppBanners:(NSString*)channelId callback:(void(^)(NSArray <CPAppBanner*>*))callback;
- (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback;
- (void)triggerAppBannerEvent:(NSString *)key value:(NSString *)value;
- (void)setApiEndpoint:(NSString*)apiEndpoint;
- (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
- (void)addStoryView:(CPStoryView*)storyView;
- (void)updateDeselectFlag:(BOOL)value;
- (void)setOpenWebViewEnabled:(BOOL)opened;
- (void)setUnsubscribeStatus:(BOOL)status;
- (UIViewController*)topViewController;
- (NSArray<NSString*>*)getSubscriptionTags;
- (NSArray<CPNotification*>*)getNotifications;
- (void)removeNotification:(NSString*)notificationId;
- (void)setMaximumNotificationCount:(int)limit;
- (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray<CPNotification*>*))callback;
- (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback;
- (NSArray<NSString*>*)getSeenStories;
- (NSMutableArray<NSString*>*)getSubscriptionTopics;
- (NSArray*)getAvailableTags __attribute__((deprecated));
- (NSArray*)getAvailableTopics __attribute__((deprecated));

- (NSObject*)getSubscriptionAttribute:(NSString*)attributeId;
- (NSString*)getSubscriptionId;
- (NSString*)getApiEndpoint;
- (NSString*)channelId;

- (UIColor*)getBrandingColor;
- (UIColor*)getChatBackgroundColor;

- (NSDictionary*)getAvailableAttributes __attribute__((deprecated));
- (NSDictionary*)getSubscriptionAttributes;

- (BOOL)isDevelopmentModeEnabled;
- (BOOL)isSubscribed;
- (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (BOOL)hasSubscriptionTag:(NSString*)tagId;
- (BOOL)hasSubscriptionTopic:(NSString*)topicId;
- (BOOL)getDeselectValue;
- (BOOL)getUnsubscribeStatus;
- (void)setConfirmAlertShown;

- (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
- (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)processLocalActionBasedNotification:(UILocalNotification*) notification actionIdentifier:(NSString*)actionIdentifier;
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
- (void)initAppReview;
- (BOOL)hasNewTopicAfterOneHour:(NSDictionary*)config initialDifference:(NSInteger)initialDifference displayDialogDifference:(NSInteger)displayAfter;
- (NSInteger)secondsAfterLastCheck;
- (void)showPendingTopicsDialog;
- (BOOL)hasSubscriptionTopics;
- (BOOL)isSubscriptionInProgress;
- (void)setSubscriptionInProgress:(BOOL)progress;
- (NSDictionary*)getAvailableAttributesFromConfig:(NSDictionary*)channelConfig;
- (NSString*)getCurrentPageUrl;
- (void)checkTags:(NSString*)urlStr params:(NSDictionary*)params;
- (void)autoAssignTagMatches:(CPChannelTag*)tag pathname:(NSString*)pathname params:(NSDictionary*)params callback:(void(^)(BOOL))callback;
- (BOOL)getTrackingConsentRequired;
- (BOOL)getHasTrackingConsent;
- (BOOL)getHasTrackingConsentCalled;
- (void)waitForTrackingConsent:(void(^)(void))callback;
- (void)sendSubscriptionTagsToApi:(NSString*)tagId callback:(void (^)(NSString *))callback;
- (void)removeSubscriptionTagsFromApi:(NSString*)tagId callback:(void (^)(NSString *))callback;
- (void)initTopicsDialogData:(NSDictionary*)config syncToBackend:(BOOL)syncToBackend;

- (void)setLogListener:(CPLogListener)listener;

@end
