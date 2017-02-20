#import <Foundation/Foundation.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#define XC8_AVAILABLE 1
#import <UserNotifications/UserNotifications.h>
#endif

@interface CPNotificationOpenedResult : NSObject

@property(readonly)NSDictionary* payload;
-(instancetype)initWithPayload:(NSDictionary *)payload;

@end;

typedef void (^CPResultSuccessBlock)(NSDictionary* result);
typedef void (^CPFailureBlock)(NSError* error);

typedef void (^CPHandleNotificationOpenedBlock)(CPNotificationOpenedResult * result);

extern NSString * const kCPSettingsKeyInFocusDisplayOption;

@interface CleverPush : NSObject

extern NSString * const SDK_VERSION;

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback;
+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback settings:(NSDictionary*)settings;

+ (NSString*)channelId;

+ (void)registerForPushNotifications;

+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive;

+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;
+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock;

@end
