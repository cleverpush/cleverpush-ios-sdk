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
#import "CleverPushInstance.h"
#import "CPInboxView.h"
#import "CleverPushUserDefaults.h"

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
+ (void)enableDevelopmentMode;
+ (void)subscribe;
+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock;
+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock;

+ (void)disableAppBanners;
+ (void)enableAppBanners;
+ (BOOL)popupVisible;
+ (void)unsubscribe;
+ (void)unsubscribe:(void(^)(BOOL))callback;
+ (void)syncSubscription;
+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err;
+ (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier;
+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive;
+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*)error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)addSubscriptionTags:(NSArray*)tagIds callback:(void(^)(NSArray *))callback;
+ (void)addSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
+ (void)addSubscriptionTags:(NSArray*)tagIds;
+ (void)addSubscriptionTag:(NSString*)tagId;
+ (void)removeSubscriptionTags:(NSArray*)tagIds callback:(void(^)(NSArray *))callback;
+ (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
+ (void)removeSubscriptionTags:(NSArray*)tagIds;
+ (void)removeSubscriptionTag:(NSString*)tagId;
+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value;
+ (void)pushSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (void)pullSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (BOOL)hasSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value;
+ (void)getAvailableTags:(void(^)(NSArray *))callback;
+ (void)getAvailableTopics:(void(^)(NSArray *))callback;
+ (void)getAvailableAttributes:(void(^)(NSDictionary *))callback;
+ (void)setSubscriptionLanguage:(NSString*)language;
+ (void)setSubscriptionCountry:(NSString*)country;
+ (void)setTopicsDialogWindow:(UIWindow *)window;
+ (void)setSubscriptionTopics:(NSMutableArray *)topics;
+ (void)setBrandingColor:(UIColor *)color;
+ (void)setNormalTintColor:(UIColor *)color;
+ (UIColor*)getNormalTintColor;
+ (void)setChatBackgroundColor:(UIColor *)color;
+ (void)setAutoClearBadge:(BOOL)autoClear;
+ (void)setIncrementBadge:(BOOL)increment;
+ (void)setShowNotificationsInForeground:(BOOL)show;
+ (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore;
+ (void)addChatView:(CPChatView*)chatView;
+ (void)showTopicsDialog;
+ (void)showTopicDialogOnNewAdded;
+ (void)showTopicsDialog:(UIWindow *)targetWindow;
+ (void)showTopicsDialog:(UIWindow *)targetWindow callback:(void(^)())callback;
+ (void)getChannelConfig:(void(^)(NSDictionary *))callback;
+ (void)getSubscriptionId:(void(^)(NSString *))callback;
+ (void)trackEvent:(NSString*)eventName;
+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount;
+ (void)triggerFollowUpEvent:(NSString*)eventName;
+ (void)triggerFollowUpEvent:(NSString*)eventName parameters:(NSDictionary*)parameters;
+ (void)trackPageView:(NSString*)url;
+ (void)trackPageView:(NSString*)url params:(NSDictionary*)params;
+ (void)increaseSessionVisits;
+ (void)showAppBanner:(NSString*)bannerId;
+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback;
+ (void)getAppBanners:(NSString*)channelId callback:(void(^)(NSArray *))callback;
+ (void)triggerAppBannerEvent:(NSString *)key value:(NSString *)value;
+ (void)setApiEndpoint:(NSString*)apiEndpoint;
+ (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (void)addStoryView:(CPStoryView*)storyView;
+ (void)updateDeselectFlag:(BOOL)value;
+ (void)setOpenWebViewEnabled:(BOOL)opened;
+ (void)setUnsubscribeStatus:(BOOL)status;
+ (UIViewController*)topViewController;
+ (BOOL)hasSubscriptionTopic:(NSString*)topicId;

+ (NSArray*)getAvailableTags __attribute__((deprecated));
+ (NSArray*)getAvailableTopics __attribute__((deprecated));
+ (NSArray*)getSubscriptionTags;
+ (NSArray<CPNotification*>*)getNotifications;
+ (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray *))callback;
+ (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback;
+ (void)removeNotification:(NSString*)notificationId;
+ (NSArray*)getSeenStories;
+ (NSMutableArray*)getSubscriptionTopics;

+ (NSString*)getSubscriptionAttribute:(NSString*)attributeId;
+ (NSString*)getSubscriptionId;
+ (NSString*)getApiEndpoint;
+ (NSString*)channelId;

+ (UIColor*)getBrandingColor;
+ (UIColor*)getChatBackgroundColor;

+ (NSDictionary*)getAvailableAttributes __attribute__((deprecated));
+ (NSDictionary*)getSubscriptionAttributes;

+ (BOOL)isDevelopmentModeEnabled;
+ (BOOL)isSubscribed;
+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (BOOL)hasSubscriptionTag:(NSString*)tagId;
+ (BOOL)getDeselectValue;
+ (BOOL)getUnsubscribeStatus;

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification*) notification actionIdentifier:(NSString*)actionIdentifier;
#pragma clang diagnostic pop

@end
