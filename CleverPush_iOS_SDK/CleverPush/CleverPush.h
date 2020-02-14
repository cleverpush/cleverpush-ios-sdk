#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#define XC8_AVAILABLE 1
#import <UserNotifications/UserNotifications.h>
#endif
#import <CoreLocation/CoreLocation.h>

#import "CPChatView.h"
#import "CPNotificationViewController.h"

@interface CPNotificationReceivedResult : NSObject

@property(readonly)NSDictionary* payload;
@property(readonly)NSDictionary* notification;
@property(readonly)NSDictionary* subscription;
-(instancetype)initWithPayload:(NSDictionary *)payload;

@end;

@interface CPNotificationOpenedResult : NSObject

@property(readonly)NSDictionary* payload;
@property(readonly)NSDictionary* notification;
@property(readonly)NSDictionary* subscription;
-(instancetype)initWithPayload:(NSDictionary *)payload;

@end;

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPHandleSubscribedBlock)(NSString * result);

typedef void (^CPHandleNotificationReceivedBlock)(CPNotificationReceivedResult * result);
typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult * result);

extern NSString * const kCPSettingsKeyInFocusDisplayOption;

@interface CleverPush : NSObject <CLLocationManagerDelegate>

extern NSString * const CLEVERPUSH_SDK_VERSION;

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

+ (NSString*)channelId;

+ (BOOL)isSubscribed;
+ (void)subscribe;
+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock;
+ (void)unsubscribe;
+ (void)syncSubscription;

+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err;
+ (void)handleNotificationOpened:(NSDictionary*)messageDict isActive:(BOOL)isActive;
+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive;
+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent;
+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent;
+ (void)processLocalActionBasedNotification:(UILocalNotification*) notification identifier:(NSString*)identifier;

+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;

+ (void)addSubscriptionTag:(NSString*)tagId;
+ (void)removeSubscriptionTag:(NSString*)tagId;
+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value;
+ (NSArray*)getAvailableTags;
+ (NSArray*)getAvailableTopics;
+ (NSDictionary*)getAvailableAttributes;
+ (NSArray*)getSubscriptionTags;
+ (BOOL)hasSubscriptionTag:(NSString*)tagId;
+ (NSDictionary*)getSubscriptionAttributes;
+ (NSString*)getSubscriptionAttribute:(NSString*)attributeId;
+ (void)setSubscriptionLanguage:(NSString*)language;
+ (void)setSubscriptionCountry:(NSString*)country;
+ (NSMutableArray*)getSubscriptionTopics;
+ (void)setSubscriptionTopics:(NSMutableArray *)topics;
+ (void)setBrandingColor:(UIColor *)color;
+ (UIColor*)getBrandingColor;
+ (void)setChatBackgroundColor:(UIColor *)color;
+ (UIColor*)getChatBackgroundColor;
+ (void)setAutoClearBadge:(BOOL)autoClear;
+ (void)addChatView:(CPChatView*)chatView;
+ (void)showTopicsDialog;
+ (void)showAppBanners;
+ (void)showAppBanners:(void(^)(NSString *))urlOpenedCallback;
+ (void)reLayoutAppBanner;
+ (NSArray*)getNotifications;
+ (NSDictionary*)getChannelConfig;
+ (NSString*)getSubscriptionId;
+ (void)trackEvent:(NSString*)eventName;
+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount;
+ (void)requestLocationPermission;

@end
