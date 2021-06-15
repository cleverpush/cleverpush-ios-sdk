#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>
#import <StoreKit/StoreKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#define XC8_AVAILABLE 1
#import <UserNotifications/UserNotifications.h>
#endif

#import "CPChatView.h"
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
-(instancetype)initWithPayload:(NSDictionary *)payload;

@end;

@interface CPNotificationOpenedResult : NSObject

@property(readonly)NSDictionary* payload;
@property(readonly)CPNotification* notification;
@property(readonly)CPSubscription* subscription;
@property(readonly)NSString* action;
-(instancetype)initWithPayload:(NSDictionary *)payload action:(NSString*)action;

@end;

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPHandleSubscribedBlock)(NSString * result);

typedef void (^CPHandleNotificationReceivedBlock)(CPNotificationReceivedResult* result);
typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult* result);

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPAppBannerActionBlock)(CPAppBannerAction* action);

extern NSString * const kCPSettingsKeyInFocusDisplayOption;

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

+ (void)disableAppBanners;
+ (void)enableAppBanners;
+ (void)unsubscribe;
+ (void)unsubscribe:(void(^)(BOOL))callback;
+ (void)syncSubscription;
+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err;
+ (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier;
+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive;
+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)addSubscriptionTag:(NSString*)tagId;
+ (void)removeSubscriptionTag:(NSString*)tagId;
+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value;
+ (void)getAvailableTags:(void(^)(NSArray *))callback;
+ (void)getAvailableTopics:(void(^)(NSArray *))callback;
+ (void)getAvailableAttributes:(void(^)(NSDictionary *))callback;
+ (void)setSubscriptionLanguage:(NSString*)language;
+ (void)setSubscriptionCountry:(NSString*)country;
+ (void)setTopicsDialogWindow:(UIWindow *)window;
+ (void)setSubscriptionTopics:(NSMutableArray *)topics;
+ (void)setBrandingColor:(UIColor *)color;
+ (void)setNormalTintColor:(UIColor *)color;
+ (void)setChatBackgroundColor:(UIColor *)color;
+ (void)setAutoClearBadge:(BOOL)autoClear;
+ (void)setIncrementBadge:(BOOL)increment;
+ (void)addChatView:(CPChatView*)chatView;
+ (void)showTopicsDialog;
+ (void)showTopicsDialog:(UIWindow *)targetWindow;
+ (void)getChannelConfig:(void(^)(NSDictionary *))callback;
+ (void)getSubscriptionId:(void(^)(NSString *))callback;
+ (void)trackEvent:(NSString*)eventName;
+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount;
+ (void)trackPageView:(NSString*)url;
+ (void)trackPageView:(NSString*)url params:(NSDictionary*)params;
+ (void)increaseSessionVisits;
+ (void)showAppBanner:(NSString*)bannerId;
+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback;
+ (void)triggerAppBannerEvent:(NSString *)key value:(NSString *)value;
+ (void)setApiEndpoint:(NSString*)apiEndpoint;
+ (void)updateBadge:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (UIViewController*)topViewController;

+ (NSArray*)getAvailableTags __attribute__((deprecated));
+ (NSArray*)getAvailableTopics __attribute__((deprecated));
+ (NSArray*)getSubscriptionTags;
+ (NSArray*)getNotifications;
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

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));
+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent API_AVAILABLE(ios(10.0));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification*) notification actionIdentifier:(NSString*)actionIdentifier;
#pragma clang diagnostic pop

@end
