#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "UNUserNotificationCenter+CleverPush.h"
#import "UIApplicationDelegate+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CZPickerView.h"
#import "JKAlertDialog.h"

#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>
#import <StoreKit/StoreKit.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#import <UserNotifications/UserNotifications.h>
#endif

@implementation CPNotificationReceivedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [_payload valueForKey:@"notification"];
        if ([_notification valueForKey:@"title"] == nil) {
            [_notification setValue:[_payload valueForKeyPath:@"aps.alert.title"] forKey:@"title"];
        }
        if ([_notification valueForKey:@"text"] == nil) {
            [_notification setValue:[_payload valueForKeyPath:@"aps.alert.body"] forKey:@"text"];
        }
        _subscription = [_payload valueForKey:@"subscription"];
    }
    return self;
}

@end

@implementation CPNotificationOpenedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [_payload valueForKey:@"notification"];
        if ([_notification valueForKey:@"title"] == nil) {
            [_notification setValue:[_payload valueForKeyPath:@"aps.alert.title"] forKey:@"title"];
        }
        if ([_notification valueForKey:@"text"] == nil) {
            [_notification setValue:[_payload valueForKeyPath:@"aps.alert.body"] forKey:@"text"];
        }
        _subscription = [_payload valueForKey:@"subscription"];
    }
    return self;
}

@end


@interface DirectDownloadDelegate : NSObject <NSURLSessionDataDelegate> {
    NSError* error;
    NSURLResponse* response;
    BOOL done;
    NSFileHandle* outputHandle;
}
@property (readonly, getter=isDone) BOOL done;
@property (readonly) NSError* error;
@property (readonly) NSURLResponse* response;

@end


@implementation DirectDownloadDelegate
@synthesize error, response, done;

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [outputHandle writeData:data];
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)aResponse completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    response = aResponse;
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)anError {
    error = anError;
    done = YES;
    
    [outputHandle closeFile];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)anError {
    done = YES;
    error = anError;
    [outputHandle closeFile];
}

- (id)initWithFilePath:(NSString*)path {
    if (self = [super init]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        outputHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return self;
}
@end

@interface NSURLSession (DirectDownload)
+ (NSString *)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error;
@end

@implementation NSURLSession (DirectDownload)

+ (NSString *)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    DirectDownloadDelegate *delegate = [[DirectDownloadDelegate alloc] initWithFilePath:localPath];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    [task resume];
    
    [session finishTasksAndInvalidate];
    
    while (![delegate isDone]) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSError *downloadError = [delegate error];
    if (downloadError != nil) {
        if (error)
            *error = downloadError;
        return nil;
    }
    
    return delegate.response.MIMEType;
}

@end


@implementation CleverPush

NSString * const CLEVERPUSH_SDK_VERSION = @"0.2.5";

static BOOL registeredWithApple = NO;
static BOOL startFromNotification = NO;

static NSString* channelId;
static BOOL autoRegister = YES;
NSDate* lastSync;
NSString* subscriptionId;
NSString* deviceToken;
CPResultSuccessBlock cpTokenUpdateSuccessBlock;
CPFailureBlock cpTokenUpdateFailureBlock;
CPHandleNotificationOpenedBlock handleNotificationOpened;
CPHandleNotificationReceivedBlock handleNotificationReceived;
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
NSDictionary* channelConfig;
NSArray* appBanners;
NSArray* channelTopics;
UIBackgroundTaskIdentifier mediaBackgroundTask;
CZPickerView *channelTopicsPicker;
JKAlertDialog* currentAppBannerPopup;
WKWebView* currentAppBannerWebView;
id currentAppBannerUrlOpenedCallback;
BOOL channelTopicsPickerVisible = NO;
UIColor* brandingColor;
UIColor* chatBackgroundColor;
static NSString* lastNotificationReceivedId;
static NSString* lastNotificationOpenedId;

static id isNil(id object)
{
    return object ?: [NSNull null];
}

BOOL handleSubscribedCalled = false;

+ (NSString*)channelId {
    return channelId;
}

+ (NSString*)subscriptionId {
    return subscriptionId;
}

+ (BOOL)startFromNotification {
    BOOL val = startFromNotification;
    startFromNotification = NO;
    return val;
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId
   handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback
    handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    return [self initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions
                  channelId:(NSString*)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback
               autoRegister:(BOOL)autoRegisterParam {
    handleNotificationReceived = receivedCallback;
    handleNotificationOpened = openedCallback;
    handleSubscribed = subscribedCallback;
    autoRegister = autoRegisterParam;
    brandingColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];

    if (self) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

        if (newChannelId) {
            channelId = newChannelId;
        } else {
            channelId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CleverPush_CHANNEL_ID"];
        }

        if (channelId == nil) {
            channelId  = [userDefaults stringForKey:@"CleverPush_CHANNEL_ID"];
        } else if (![channelId isEqualToString:[userDefaults stringForKey:@"CleverPush_CHANNEL_ID"]]) {
            [userDefaults setObject:channelId forKey:@"CleverPush_CHANNEL_ID"];
            [userDefaults setObject:nil forKey:@"CleverPush_SUBSCRIPTION_ID"];
            [userDefaults synchronize];
        }

        if (!channelId) {
            NSLog(@"CleverPush: Channel ID not specified, trying to fetch config via Bundle Identifier...");
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self getChannelConfig];
                
                if (!channelId) {
                    NSLog(@"CleverPush: Initialization stopped - No Channel ID available");
                    return;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self initWithChannelId];
                });
            });
            NSLog(@"CleverPush: Got Channel ID, initializing");
        } else {
            [self initWithChannelId];
        }
    }

    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
    }

    [self clearBadge:false];

    return self;
}

+ (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)viewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navContObj = (UINavigationController*)viewController;
        return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
    } else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        UIViewController* presentedViewController = viewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        for (UIView *view in [viewController.view subviews])
        {
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]])
            {
                if ([(UIViewController *)subViewController presentedViewController]  && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

+ (void)initWithChannelId {
    UIApplication* sharedApp = [UIApplication sharedApplication];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    subscriptionId = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_ID"];
    deviceToken = [userDefaults stringForKey:@"CleverPush_DEVICE_TOKEN"];
    if (([sharedApp respondsToSelector:@selector(currentUserNotificationSettings)])) {
        registeredWithApple = [sharedApp currentUserNotificationSettings].types != (NSUInteger)nil;
    } else {
        registeredWithApple = deviceToken != nil;
    }
    
    if (autoRegister || registeredWithApple) {
        [self subscribe];
    }
    
    if (subscriptionId != nil) {
        if (![self notificationsEnabled]) {
            [self unsubscribe];
        } else if ([self shouldSync]) {
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:10.0f];
        } else {
            if (handleSubscribed && !handleSubscribedCalled) {
                handleSubscribed(subscriptionId);
                handleSubscribedCalled = true;
            }
            if (handleSubscribedInternal) {
                handleSubscribedInternal(subscriptionId);
            }
        }
    }

    NSInteger appOpens = [userDefaults integerForKey:@"CleverPush_APP_OPENS"];
    appOpens++;
    [userDefaults setInteger:appOpens forKey:@"CleverPush_APP_OPENS"];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        channelConfig = [self getChannelConfig];
        
        if ([channelConfig valueForKey:@"appReviewEnabled"]) {
            int appReviewOpens = (int)[[channelConfig valueForKey:@"appReviewOpens"] integerValue];
            if (!appReviewOpens) {
                appReviewOpens = 0;
            }
            int appReviewDays = (int)[[channelConfig valueForKey:@"appReviewDays"] integerValue];
            if (!appReviewDays) {
                appReviewDays = 0;
            }
            int appReviewSeconds = (int)[[channelConfig valueForKey:@"appReviewSeconds"] integerValue];
            if (!appReviewSeconds) {
                appReviewSeconds = 0;
            }
            NSInteger currentAppDays = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"] ? [self daysBetweenDate:[NSDate date] andDate:[userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"]] : 0;
              
             NSString *appReviewTitle = [channelConfig valueForKey:@"appReviewTitle"];
            if (!appReviewTitle) {
                appReviewTitle = @"Möchtest du unsere App im Store bewerten?";
            }
            
            if ([userDefaults integerForKey:@"CleverPush_APP_OPENS"] >= appReviewOpens && currentAppDays >= appReviewDays) {
                NSLog(@"CleverPush: showing app review alert");
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * appReviewSeconds);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:appReviewTitle
                                                                                             message:@""
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Ja"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                        [SKStoreReviewController requestReview];
                    }];
                    [alertController addAction:actionYes];
                    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"Nein"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:nil];
                    [alertController addAction:actionNo];
                    UIViewController* topViewController = [CleverPush topViewController];
                    [topViewController presentViewController:alertController animated:YES completion:nil];
                });
            }
        }
    });
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;

    NSCalendar *calendar = [NSCalendar currentCalendar];

    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
        interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
        interval:NULL forDate:toDateTime];

    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
        fromDate:fromDate toDate:toDate options:0];

    return [difference day];
}

- (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    NSDate *fromDate;
    NSDate *toDate;

    NSCalendar *calendar = [NSCalendar currentCalendar];

    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
        interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
        interval:NULL forDate:toDateTime];

    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
        fromDate:fromDate toDate:toDate options:0];

    return [difference day];
}

+ (BOOL)shouldSync {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    lastSync = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_LAST_SYNC"];
    NSDate* nextSync = [NSDate date];
    if (lastSync) {
        nextSync = [lastSync dateByAddingTimeInterval:3*24*60*60]; // 3 days after last sync
    }
    NSLog(@"CleverPush next sync: %@", nextSync);
    return [nextSync compare:[NSDate date]] == NSOrderedAscending;
}

+ (NSDictionary*)getChannelConfig {
    if (channelConfig) {
        return channelConfig;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getChannelConfig) object:nil];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    if (channelId != NULL) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel/%@/config", channelId]];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                channelConfig = result;
            }
            dispatch_semaphore_signal(sema);
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
            dispatch_semaphore_signal(sema);
        }];
    } else {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", [[NSBundle mainBundle] bundleIdentifier]]];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                channelId = [result objectForKey:@"channelId"];
                NSLog(@"Detected Channel ID from Bundle Identifier: %@", channelId);
                
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:channelId forKey:@"CleverPush_CHANNEL_ID"];
                [userDefaults setObject:nil forKey:@"CleverPush_SUBSCRIPTION_ID"];
                [userDefaults synchronize];
                
                channelConfig = result;
            }
            
            dispatch_semaphore_signal(sema);
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error);
            
            dispatch_semaphore_signal(sema);
        }];
    }
    
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return channelConfig;
}

+ (NSString*)getSubscriptionId {
    if (subscriptionId) {
        return subscriptionId;
    }
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    handleSubscribedInternal = ^(NSString *subscriptionIdNew) {
        dispatch_semaphore_signal(sema);
    };
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return subscriptionId;
}

+ (void)ensureMainThreadSync:(dispatch_block_t) onMainBlock {
    if ([NSThread isMainThread]) {
        onMainBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), onMainBlock);
    }
}

+ (BOOL)notificationsEnabled {
    __block BOOL isEnabled = NO;
    
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion) { .majorVersion = 10, .minorVersion = 0, .patchVersion = 0 }]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull notificationSettings) {
            if (notificationSettings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                isEnabled = YES;
            }
            dispatch_semaphore_signal(sema);
        }];

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } else {
        [self ensureMainThreadSync:^{
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]){
                UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
                
                if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone)) {
                    isEnabled = NO;
                } else {
                    isEnabled = YES;
                }
            } else {
                if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
                    isEnabled = YES;
                } else{
                    isEnabled = NO;
                }
            }
        }];
    }
    
    return isEnabled;
}

+ (void)subscribe {
    [self subscribe:nil];
}

+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock {
    if (subscriptionId == nil && channelId != nil) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"channel/confirm-alert"]];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 channelId, @"channelId",
                                 @"iOS", @"platformName",
                                 @"SDK", @"browserType",
                                 nil];
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:nil onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: /channel/confirm-alert request error %@", error);
        }];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions options = (UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge);
        [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted && subscriptionId == nil) {
                    [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];

                    NSDictionary* channelConfig = [self getChannelConfig];
                    if (channelConfig != nil && ([channelConfig valueForKey:@"confirmAlertHideChannelTopics"] == nil || ![[channelConfig valueForKey:@"confirmAlertHideChannelTopics"] boolValue])) {
                        NSArray* channelTopics = [channelConfig valueForKey:@"channelTopics"];
                        if (channelTopics != nil && [channelTopics count] > 0) {
                            NSArray* topics = [self getSubscriptionTopics];
                            if (!topics || [topics count] == 0) {
                                NSMutableArray* selectedTopicIds = [[NSMutableArray alloc] init];
                                for (id channelTopic in channelTopics) {
                                    if (channelTopic != nil && ([channelTopic valueForKey:@"defaultUnchecked"] == nil || ![[channelTopic valueForKey:@"defaultUnchecked"] boolValue])) {
                                        [selectedTopicIds addObject:[channelTopic valueForKey:@"_id"]];
                                    }
                                }
                                if ([selectedTopicIds count] > 0) {
                                    [self setSubscriptionTopics:selectedTopicIds];
                                }
                            }
                            
                            [self showTopicsDialog];
                        }
                    }
                }
                
                if (granted && subscribedBlock) {
                    subscribedBlock(subscriptionId);
                }
            });
        }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
    } else if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        Class uiUserNotificationSettings = NSClassFromString(@"UIUserNotificationSettings");
        
        NSSet* categories = [[[UIApplication sharedApplication] currentUserNotificationSettings] categories];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[uiUserNotificationSettings settingsForTypes:UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge categories:categories]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
    }
}

+ (void)unsubscribe {
    NSString* subscriptionIdLocal = [self getSubscriptionId];
    if (subscriptionIdLocal) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/unsubscribe"];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 channelId, @"channelId",
                                 subscriptionIdLocal, @"subscriptionId",
                                 nil];
        
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:nil onFailure:nil];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_ID"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_LAST_SYNC"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        subscriptionId = nil;
        handleSubscribedCalled = false;
    }
}

+ (BOOL)isSubscribed {
    BOOL isSubscribed = NO;
    if (subscriptionId && [self notificationsEnabled]) {
        isSubscribed = YES;
    }
    return isSubscribed;
}

+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err {
    if (err.code == 3000) {
        if ([((NSString*)[err.userInfo objectForKey:NSLocalizedDescriptionKey]) rangeOfString:@"no valid 'aps-environment'"].location != NSNotFound) {
            NSLog(@"ERROR! 'Push Notification' capability not turned on! Enable it in Xcode under 'Project Target' -> Capability.");
        } else {
            NSLog(@"%@", [NSString stringWithFormat:@"ERROR! Unkown 3000 error returned from APNs when getting a push token: %@", err]);
        }
    } else if (err.code == 3010) {
       NSLog(@"%@", [NSString stringWithFormat:@"Error! iOS Simulator does not support push! Please test on a real iOS device. Error: %@", err]);
    } else {
        NSLog(@"%@", [NSString stringWithFormat:@"Error registering for Apple push notifications! Error: %@", err]);
    }
}

+ (void)registerDeviceToken:(id)newDeviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    if (subscriptionId == nil) {
        NSLog(@"CleverPush: registerDeviceToken: subscriptionId is nil");
        
        deviceToken = newDeviceToken;
        cpTokenUpdateSuccessBlock = successBlock;
        cpTokenUpdateFailureBlock = failureBlock;

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
            [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
                if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                    [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
                }
            }];
        } else {
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        }
        return;
    }

    if ([deviceToken isEqualToString:newDeviceToken]) {
        if (successBlock)
            successBlock(nil);
        return;
    }

    deviceToken = newDeviceToken;

    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"CleverPush_DEVICETOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static BOOL registrationInProgress = false;


+ (void)syncSubscription {
    if (registrationInProgress) {
        return;
    }
    
    NSLog(@"CleverPush: syncSubscription");

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];

    registrationInProgress = true;

    NSMutableURLRequest* request;
    request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* language = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_LANGUAGE"];
    NSString* country = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_COUNTRY"];
    if (!language) {
        language = [[NSLocale preferredLanguages] firstObject];
    }
    NSString* timezone = [[NSTimeZone localTimeZone] name];
    
    [request setAllHTTPHeaderFields:@{
                                      @"User-Agent": [NSString stringWithFormat:@"CleverPush iOS SDK %@", CLEVERPUSH_SDK_VERSION],
                                      @"Accept-Language": language
                                      }];

    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             deviceToken, @"apnsToken",
                             @"SDK", @"browserType",
                             CLEVERPUSH_SDK_VERSION, @"browserVersion",
                             @"iOS", @"platformName",
                             [[UIDevice currentDevice] systemVersion], @"platformVersion",
                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"appVersion",
                             isNil(country), @"country",
                             isNil(timezone), @"timezone",
                             isNil(language), @"language",
                             subscriptionId, @"subscriptionId",
                             nil];
    
    NSArray* topics = [self getSubscriptionTopics];
    if (topics) {
        [dataDic setObject:topics forKey:@"topics"];
    }

    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];

    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        registrationInProgress = false;

        if ([results objectForKey:@"id"] != nil) {
            if (!subscriptionId) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"];
            }
            
            subscriptionId = [results objectForKey:@"id"];
            [[NSUserDefaults standardUserDefaults] setObject:subscriptionId forKey:@"CleverPush_SUBSCRIPTION_ID"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"CleverPush_SUBSCRIPTION_LAST_SYNC"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            if (handleSubscribed && !handleSubscribedCalled) {
                handleSubscribed(subscriptionId);
                handleSubscribedCalled = true;
            }
            if (handleSubscribedInternal) {
                handleSubscribedInternal(subscriptionId);
            }
        }
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: syncSubscription failure %@", error);

        registrationInProgress = false;
    }];
}

+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive {
    NSDictionary* notification = [messageDict valueForKey:@"notification"];
    if (!notification) {
        return;
    }
    
    NSString* notificationId = [notification valueForKey:@"_id"];
    
    if (isEmpty(notificationId) || [notificationId isEqualToString:lastNotificationReceivedId]) {
        return;
    }
    lastNotificationReceivedId = notificationId;
    
    NSLog(@"CleverPush: handleNotificationReceived, isActive %@, Payload %@", @(isActive), messageDict);
    
    [CleverPush setNotificationDelivered:notification withChannelId:[messageDict valueForKeyPath:@"channel._id"] withSubscriptionId:[messageDict valueForKeyPath:@"subscription._id"]];
    
    if (!handleNotificationReceived) {
        return;
    }

    CPNotificationReceivedResult * result = [[CPNotificationReceivedResult alloc] initWithPayload:messageDict];

    handleNotificationReceived(result);
}

+ (NSString*)randomStringWithLength:(int)length {
    NSString* letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString* randomString = [[NSMutableString alloc] initWithCapacity:length];
    for (int i = 0; i < length; i++) {
        int ln = (uint32_t)letters.length;
        int rand = arc4random_uniform(ln);
        [randomString appendFormat:@"%C", [letters characterAtIndex:rand]];
    }
    return randomString;
}

+ (NSString*)downloadMedia:(NSString*)urlString {
    NSURL* url = [NSURL URLWithString:urlString];
    NSString* extension = url.pathExtension;
    
    if ([extension isEqualToString:@""]) {
        extension = nil;
    }
    
    NSArray *supportedAttachmentTypes = @[@"aiff", @"wav", @"mp3", @"mp4", @"jpg", @"jpeg", @"png", @"gif", @"mpeg", @"mpg", @"avi", @"m4a", @"m4v"];
    if (extension != nil && ![supportedAttachmentTypes containsObject:extension]) {
        return nil;
    }
    
    NSString* name = [self randomStringWithLength:8];
    if (extension) {
        name = [name stringByAppendingString:[NSString stringWithFormat:@".%@", extension]];
    }
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [paths[0] stringByAppendingPathComponent:name];
    
    @try {
        NSError *error;
        [NSURLSession downloadItemAtURL:url toFile:filePath error:&error];
        if (error) {
            NSLog(@"CleverPush: error while attempting to download file with URL: %@", error);
            return nil;
        }
        
        /*
        NSArray* cachedFiles = [[NSUserDefaults standardUserDefaults] objectForKey:@"CACHED_MEDIA"];
        NSMutableArray* appendedCache;
        if (cachedFiles) {
            appendedCache = [[NSMutableArray alloc] initWithArray:cachedFiles];
            [appendedCache addObject:name];
        } else {
            appendedCache = [[NSMutableArray alloc] initWithObjects:name, nil];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:appendedCache forKey:@"CACHED_MEDIA"];
        [[NSUserDefaults standardUserDefaults] synchronize];
         */
        
        return name;
    } @catch (NSException *exception) {
        NSLog(@"CleverPush: error while downloading file (%@), error: %@", url, exception.description);
        return nil;
    }
}

+ (void)addAttachments:(NSString*)mediaUrl toContent:(UNMutableNotificationContent*)content {
    NSMutableArray* unAttachments = [NSMutableArray new];
    
    NSURL* nsURL = [NSURL URLWithString:mediaUrl];
    
    if (nsURL) {
        NSString* urlScheme = [nsURL.scheme lowercaseString];
        if ([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"]) {
            NSString* name = [self downloadMedia:mediaUrl];
            
            if (name) {
                NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString* filePath = [paths[0] stringByAppendingPathComponent:name];
                NSURL* url = [NSURL fileURLWithPath:filePath];
                NSError* error;
                UNNotificationAttachment* attachment = [UNNotificationAttachment
                                                        attachmentWithIdentifier:@""
                                                        URL:url
                                                        options:0
                                                        error:&error];
                if (attachment) {
                    [unAttachments addObject:attachment];
                }
            }
        }
    }
    
    content.attachments = unAttachments;
}

+ (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    BOOL startedBackgroundJob = NO;
    
    NSLog(@"CleverPush: handleSilentNotificationReceived");
    
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        [CleverPush handleNotificationReceived:messageDict isActive:NO];
    }
    
    return startedBackgroundJob;
}

+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive {
    NSString* notificationId = [payload valueForKeyPath:@"notification._id"];;
    
    if (isEmpty(notificationId) || [notificationId isEqualToString:lastNotificationOpenedId]) {
        return;
    }
    lastNotificationOpenedId = notificationId;
    
    NSLog(@"CleverPush: handleNotificationOpened, %@", payload);
    
    [CleverPush setNotificationClicked:notificationId withChannelId:[payload valueForKeyPath:@"channel._id"] withSubscriptionId:[payload valueForKeyPath:@"subscription._id"]];

    [self clearBadge:true];

    if (!handleNotificationOpened) {
        return;
    }

    CPNotificationOpenedResult * result = [[CPNotificationOpenedResult alloc] initWithPayload:payload];

    handleNotificationOpened(result);
}

+ (void)processLocalActionBasedNotification:(UILocalNotification*) notification identifier:(NSString*)identifier {
    if (!notification.userInfo) {
        return;
    }
    
    NSLog(@"CleverPush processLocalActionBasedNotification");
    
    BOOL isActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    [self handleNotificationReceived:notification.userInfo isActive:isActive];
    
    if (!isActive) {
        [self handleNotificationOpened:notification.userInfo
                              isActive:isActive];
    }
}

+ (void)setNotificationDelivered:(NSDictionary*)notification {
    [self setNotificationDelivered:notification withChannelId:channelId withSubscriptionId:[self getSubscriptionId]];
}

+ (void)setNotificationDelivered:(NSDictionary*)notification withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId {
    NSLog(@"CleverPush: setNotificationDelivered @% @% @%", channelId, [notification valueForKey:@"_id"], subscriptionId);
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/delivered"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             [notification valueForKey:@"_id"], @"notificationId",
                             subscriptionId, @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
    
    // save notification to user defaults
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [bundle bundleIdentifier]]];
    
    NSMutableDictionary *notificationMutable = [notification mutableCopy];
    [notificationMutable removeObjectsForKeys:[notification allKeysForObject:[NSNull null]]];
    
    NSMutableArray* notifications = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"CleverPush_NOTIFICATIONS"]];
    if (!notifications) {
        notifications = [[NSMutableArray alloc] init];
    }
    [notifications addObject:notificationMutable];
    [userDefaults setObject:notifications forKey:@"CleverPush_NOTIFICATIONS"];
    [userDefaults synchronize];
}

+ (void)setNotificationClicked:(NSString*)notificationId {
    [self setNotificationClicked:notificationId withChannelId:channelId withSubscriptionId:[self getSubscriptionId]];
}

+ (void)setNotificationClicked:(NSString*)notificationId withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/clicked"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             notificationId, @"notificationId",
                             subscriptionId, @"subscriptionId",
                             nil];

    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
}

+ (BOOL)clearBadge:(BOOL)fromNotificationOpened {
    bool wasSet = [UIApplication sharedApplication].applicationIconBadgeNumber > 0;
    if ((!(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) && fromNotificationOpened) || wasSet) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
    return wasSet;
}

+ (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
    NSUInteger length = deviceToken.length;
    if (length == 0) {
        return nil;
    }
    const unsigned char *buffer = deviceToken.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length * 2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    return [hexString copy];
}

+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)deviceToken {
    NSString* parsedDeviceToken = [self stringFromDeviceToken:deviceToken];
    NSLog(@"%@", [NSString stringWithFormat:@"Device Registered with Apple: %@", parsedDeviceToken]);
    [CleverPush registerDeviceToken:parsedDeviceToken onSuccess:^(NSDictionary* results) {
        NSLog(@"%@", [NSString stringWithFormat: @"Device Registered with CleverPush: %@", subscriptionId]);
    } onFailure:^(NSError* error) {
        NSLog(@"%@", [NSString stringWithFormat: @"Error in CleverPush Registration: %@", error]);
    }];
}

+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    NSLog(@"CleverPush: HTTP: %@ %@", [request HTTPMethod], [request URL].absoluteString);
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                if (successBlock != nil || failureBlock != nil) {
                    [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
                }
            }] resume];
}

+ (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    NSHTTPURLResponse* HTTPResponse = (NSHTTPURLResponse*)response;
    NSInteger statusCode = [HTTPResponse statusCode];
    NSError* jsonError = nil;
    NSMutableDictionary* innerJson;
    
    if (data != nil && [data length] > 0) {
        innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (jsonError) {
            if (failureBlock != nil)
                failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"returned" : jsonError}]);
            return;
        }
    }
    
    if (error == nil && statusCode >= 200 && statusCode <= 299) {
        if (successBlock != nil) {
            if (innerJson != nil)
                successBlock(innerJson);
            else
                successBlock(nil);
        }
    }
    else if (failureBlock != nil) {
        if (innerJson != nil && error == nil)
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"returned" : innerJson}]);
        else if (error != nil)
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"error" : error}]);
        else
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:nil]);
    }
}

+ (void)addSubscriptionTag:(NSString*)tagId {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/tag"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             tagId, @"tagId",
                             [self getSubscriptionId], @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray* subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TAGS"]];
        if (!subscriptionTags) {
            subscriptionTags = [[NSMutableArray alloc] init];
        }
        
        if (![subscriptionTags containsObject:tagId]) {
            [subscriptionTags addObject:tagId];
        }
        [userDefaults setObject:subscriptionTags forKey:@"CleverPush_SUBSCRIPTION_TAGS"];
        [userDefaults synchronize];
    } onFailure:nil];
}

+ (void)removeSubscriptionTag:(NSString*)tagId {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/untag"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             tagId, @"tagId",
                             [self getSubscriptionId], @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray* subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TAGS"]];
        if (!subscriptionTags) {
            subscriptionTags = [[NSMutableArray alloc] init];
        }
        [subscriptionTags removeObject:tagId];
        [userDefaults setObject:subscriptionTags forKey:@"CleverPush_SUBSCRIPTION_TAGS"];
        [userDefaults synchronize];
    } onFailure:nil];
}

+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/attribute"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             attributeId, @"attributeId",
                             value, @"value",
                             [self getSubscriptionId], @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:@"CleverPush_SUBSCRIPTION_ATTRIBUTES"]];
        if (!subscriptionAttributes) {
            subscriptionAttributes = [[NSMutableDictionary alloc] init];
        }
        [subscriptionAttributes setValue:value forKey:attributeId];
        [userDefaults setObject:subscriptionAttributes forKey:@"CleverPush_SUBSCRIPTION_ATTRIBUTES"];
        [userDefaults synchronize];
    } onFailure:nil];
}

+ (NSArray*)getAvailableTags {
    NSDictionary* channelConfig = [self getChannelConfig];
    if (channelConfig != nil) {
        NSArray* channelTags = [channelConfig valueForKey:@"channelTags"];
        if (channelTags != nil) {
            return channelTags;
        }
    }
    return [[NSArray alloc] init];
}

+ (NSArray*)getAvailableTopics {
    NSDictionary* channelConfig = [self getChannelConfig];
    if (channelConfig != nil) {
        NSArray* channelTopics = [channelConfig valueForKey:@"channelTopics"];
        if (channelTopics != nil) {
            return channelTopics;
        }
    }
    return [[NSArray alloc] init];
}

+ (NSDictionary*)getAvailableAttributes {
    NSDictionary* channelConfig = [self getChannelConfig];
    if (channelConfig != nil) {
        NSDictionary* customAttributes = [channelConfig valueForKey:@"customAttributes"];
        if (customAttributes != nil) {
            return customAttributes;
        }
    }
    return [[NSDictionary alloc] init];
}

+ (NSArray*)getSubscriptionTags {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTags = [userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TAGS"];
    if (!subscriptionTags) {
        return [[NSArray alloc] init];
    }
    return subscriptionTags;
}

+ (BOOL)hasSubscriptionTag:(NSString*)tagId {
    return [[self getSubscriptionTags] containsObject:tagId];
}

+ (NSDictionary*)getSubscriptionAttributes {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* subscriptionAttributes = [userDefaults dictionaryForKey:@"CleverPush_SUBSCRIPTION_ATTRIBUTES"];
    if (!subscriptionAttributes) {
        return [[NSDictionary alloc] init];
    }
    return subscriptionAttributes;
}

+ (NSString*)getSubscriptionAttribute:(NSString*)attributeId {
    return [[self getSubscriptionAttributes] objectForKey:attributeId];
}

+ (void)setSubscriptionLanguage:(NSString *)language {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentLanguage = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_LANGUAGE"];
    if (!currentLanguage || (language && ![currentLanguage isEqualToString:language])) {
        [userDefaults setObject:language forKey:@"CleverPush_SUBSCRIPTION_LANGUAGE"];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:5.0f];
        });
    }
}

+ (void)setSubscriptionCountry:(NSString *)country {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentCountry = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_COUNTRY"];
    if (!currentCountry || (country && ![currentCountry isEqualToString:country])) {
        [userDefaults setObject:country forKey:@"CleverPush_SUBSCRIPTION_COUNTRY"];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:5.0f];
        });
    }
}

+ (NSArray*)getSubscriptionTopics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTopics = [userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    if (!subscriptionTopics) {
        return [[NSArray alloc] init];
    }
    return subscriptionTopics;
}

+ (void)setSubscriptionTopics:(NSMutableArray *)topics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:topics forKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    [userDefaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:5.0f];
    });
}

+ (NSArray*)getNotifications {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    NSArray* notifications = [userDefaults arrayForKey:@"CleverPush_NOTIFICATIONS"];
    if (!notifications) {
        return [[NSArray alloc] init];
    }
    
    return notifications;
}

+ (NSArray*)getAppBanners {
    if (appBanners) {
        return appBanners;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getChannelConfig) object:nil];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    if (channelId != NULL) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel/%@/app-banners", channelId]];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                appBanners = [result valueForKey:@"banners"];
            }
            dispatch_semaphore_signal(sema);
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed getting the app banners %@", error);
            dispatch_semaphore_signal(sema);
        }];
    } else {
        dispatch_semaphore_signal(sema);
    }
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return appBanners;
}

+ (void)setBrandingColor:(UIColor *)color {
    brandingColor = color;
}

+ (UIColor*)getBrandingColor {
    return brandingColor;
}

+ (void)setChatBackgroundColor:(UIColor *)color {
    chatBackgroundColor = color;
}

+ (UIColor*)getChatBackgroundColor {
    return chatBackgroundColor;
}

+ (void)showTopicsDialog {
    if (channelTopicsPickerVisible) {
        return;
    }
    channelTopicsPickerVisible = YES;
    
    channelTopics = [self getAvailableTopics];
    if ([channelTopics count] == 0) {
        NSLog(@"CleverPush: showTopicsDialog: No topics found. Create some first in the CleverPush channel settings.");
    }
    
    NSString* headerTitle = @"Abonnierte Themen";
    NSDictionary* config = [self getChannelConfig];
    if (config != nil && [config valueForKey:@"confirmAlertSelectTopicsLaterTitle"] != nil && ![[config valueForKey:@"confirmAlertSelectTopicsLaterTitle"] isEqualToString:@""]) {
        headerTitle = [config valueForKey:@"confirmAlertSelectTopicsLaterTitle"];
    }
    
    channelTopicsPicker = [[CZPickerView alloc] initWithHeaderTitle:headerTitle
                                                  cancelButtonTitle:@"Abbrechen"
                                                 confirmButtonTitle:@"Speichern"];
    channelTopicsPicker.allowMultipleSelection = YES;
    channelTopicsPicker.delegate = self;
    channelTopicsPicker.dataSource = self;
    channelTopicsPicker.headerBackgroundColor = [UIColor whiteColor];
    channelTopicsPicker.headerTitleColor = [UIColor darkGrayColor];
    channelTopicsPicker.confirmButtonBackgroundColor = brandingColor;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [channelTopicsPicker show];
    });
}

+ (NSString *)czpickerView:(CZPickerView *)pickerView titleForRow:(NSInteger)row {
    return [channelTopics[row] valueForKey:@"name"];
}

+ (bool)czpickerView:(CZPickerView *)pickerView checkedForRow:(NSInteger)row {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* selectedTags = [userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    NSDictionary* topic = channelTopics[row];
    NSString* topicId;
    if (topic) {
        topicId = [topic valueForKey:@"_id"];
    }
    return selectedTags && [selectedTags containsObject:topicId];
}

+ (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView {
    return channelTopics.count;
}

+ (void)czpickerViewDidClickCancelButton:(CZPickerView *)pickerView {
    channelTopicsPickerVisible = NO;
}

+ (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemsAtRows:(NSArray *)rows {
    if (!channelTopicsPickerVisible) {
        return;
    }
    channelTopicsPickerVisible = NO;
    
    NSMutableArray* selectedTopics = [[NSMutableArray alloc] init];
    for (NSNumber *n in rows) {
        NSInteger row = [n integerValue];
        NSDictionary* topic = channelTopics[row];
        if (topic) {
            [selectedTopics addObject:[topic valueForKey:@"_id"]];
        }
    }
    
    [CleverPush setSubscriptionTopics:selectedTopics];
}

+ (IBAction)closeCurrentAppBanner:(id)sender {
    if (currentAppBannerPopup != nil) {
        [currentAppBannerPopup dismiss];
        currentAppBannerPopup = nil;
    }
}

+ (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (currentAppBannerPopup != nil) {
        [currentAppBannerWebView removeObserver:self forKeyPath:@"URL"] ;
        
        if ([keyPath isEqualToString:@"URL"] && currentAppBannerWebView != nil && currentAppBannerUrlOpenedCallback != nil) {
            ((void(^)(NSString *))currentAppBannerUrlOpenedCallback)([currentAppBannerWebView URL].absoluteString);
            currentAppBannerUrlOpenedCallback = nil;
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
        
        [currentAppBannerPopup dismiss];
        currentAppBannerPopup = nil;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (void)showAppBanners {
    [self showAppBanners:nil];
}

+ (void)showAppBanners:(void(^)(NSString *))urlOpenedCallback {
    NSArray *banners = [self getAppBanners];
    if ([banners count] == 0) {
        NSLog(@"CleverPush: showAppBanners: No banners found. Create some first in the CleverPush channel settings.");
    }
    
    currentAppBannerUrlOpenedCallback = urlOpenedCallback;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSDictionary *banner in banners) {
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray* shownAppBanners = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"CleverPush_SHOWN_APP_BANNERS"]];
            if (!shownAppBanners) {
                shownAppBanners = [[NSMutableArray alloc] init];
            }
            
            if (banner != nil && (([banner valueForKey:@"frequency"] != nil && ([[banner valueForKey:@"frequency"]  isEqual: @"oncePerSession"] || [[banner valueForKey:@"frequency"]  isEqual: @"always"])) || (([banner valueForKey:@"frequency"] == nil || [[banner valueForKey:@"frequency"]  isEqual: @"once"]) && ![shownAppBanners containsObject:[banner valueForKey:@"_id"]]))) {
                [shownAppBanners addObject:[banner valueForKey:@"_id"]];
                [[NSUserDefaults standardUserDefaults] setObject:shownAppBanners forKey:@"CleverPush_SHOWN_APP_BANNERS"];
                [userDefaults synchronize];

                WKWebView *webView = [[WKWebView alloc] init];
                [webView loadHTMLString:[banner valueForKey:@"content"] baseURL:nil];
                [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:NULL];
                
                UIButton *closeButton = [[UIButton alloc] initWithFrame: CGRectMake(0,0,20,20)];
                [closeButton setTitle:@"×" forState:UIControlStateNormal];
                [closeButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
                [closeButton addTarget:self action:@selector(closeCurrentAppBanner:) forControlEvents:UIControlEventTouchUpInside];
                [webView addSubview:closeButton];
                
                JKAlertDialog *alert = [[JKAlertDialog alloc]init];
            
                alert.contentView = webView;
                [alert show];
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    /*
                    [webView evaluateJavaScript:@"document.body.scrollHeight"
                    completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                        if (!error) {
                            NSLog(@"eval 2 %@", result);
                            
                        }
                    }];
                     */
                    
                    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - 100;
                    CGFloat maxHeight = [UIScreen mainScreen].bounds.size.height - 100;
                    
                    CGRect frame = webView.frame;
                    frame.size.height = 1;
                    webView.frame = frame;
                    
                    frame.size = webView.scrollView.contentSize;
                    webView.frame = frame;
                    
                    if (frame.size.width > maxWidth) {
                        frame.size.width = maxWidth;
                    }
                
                    if (frame.size.height > maxHeight) {
                        frame.size.height = maxHeight;
                    }
                    
                    
                    NSLog(@"frame.size.width %f", frame.size.width / 2);
                    NSLog(@"frame.size.height %f", frame.size.height / 2);
                    NSLog(@"x %f", ([UIScreen mainScreen].bounds.size.width / 2) - (frame.size.width / 2));
                    NSLog(@"y %f", ([UIScreen mainScreen].bounds.size.height / 2) - (frame.size.height / 2));
                    
                    // frame.origin.x = -1 * (frame.size.width / 2);
                    // frame.origin.y = -1 * (frame.size.height / 2);
                    
                    webView.frame = frame;
                    [alert reLayout];
                });
                
                currentAppBannerPopup = alert;
                currentAppBannerWebView = webView;
                
                break;
            }
        }
    });
}

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    NSLog(@"CleverPush: didReceiveNotificationExtensionRequest");
    
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    NSDictionary* payload = request.content.userInfo;
    NSDictionary* notification = [payload valueForKey:@"notification"];
    NSString* channelId = [payload valueForKeyPath:@"channel._id"];
    NSString* subscriptionId = [payload valueForKeyPath:@"subscription._id"];
    
    [self handleNotificationReceived:payload isActive:NO];
    
    NSString* mediaUrl = [payload valueForKeyPath:@"notification.mediaUrl"];
    if (![mediaUrl isKindOfClass:[NSNull class]]) {
        NSLog(@"CleverPush: appending media: %@", mediaUrl);
        [self addAttachments:mediaUrl toContent:replacementContent];
    }
    
    return replacementContent;
}

+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    NSLog(@"CleverPush: serviceExtensionTimeWillExpireRequest");
    
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    return replacementContent;
}

static CleverPush* singleInstance = nil;
+ (CleverPush*)sharedInstance {
    @synchronized(singleInstance) {
        if (!singleInstance)
            singleInstance = [CleverPush new];
    }
    
    return singleInstance;
}

static inline BOOL isEmpty(id thing) {
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

@end

@implementation UIApplication (CleverPush)

+ (void)load {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([[processInfo processName] isEqualToString:@"IBDesignablesAgentCocoaTouch"] || [[processInfo processName] isEqualToString:@"IBDesignablesAgent-iOS"])
        return;
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.0")) {
        return;
    }
    
    BOOL existing = injectSelector([CleverPushAppDelegate class], @selector(cleverPushLoadedTagSelector:), self, @selector(cleverPushLoadedTagSelector:));
    if (existing) {
        return;
    }
    
    injectToProperClass(@selector(setCleverPushDelegate:), @selector(setDelegate:), @[], [CleverPushAppDelegate class], [UIApplication class]);
    
    [self setupUNUserNotificationCenterDelegate];
}

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
