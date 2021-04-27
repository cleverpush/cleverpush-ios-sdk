#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#import <UserNotifications/UserNotifications.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import "CleverPush.h"
#import "UNUserNotificationCenter+CleverPush.h"
#import "UIApplicationDelegate+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CPNotificationCategoryController.h"
#import "CPUtils.h"
#import "CPTopicsViewController.h"
#import "CPTranslate.h"
#import "CPAppBannerModule.h"
#import "DWAlertController/DWAlertController.h"
#import "DWAlertController/DWAlertAction.h"

#endif

@implementation CPNotificationReceivedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
        
        _notification = [CPNotification initWithJson:[[_payload valueForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload valueForKey:@"subscription"] mutableCopy]];
    }
    return self;
}

@end

@implementation CPNotificationOpenedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload action:(NSString*)action {
    self = [super init];
    if (self) {
        _payload = inPayload;
        
        _notification = [CPNotification initWithJson:[[_payload valueForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload valueForKey:@"subscription"] mutableCopy]];
        
        _action = action;
    }
    return self;
}

@end

@interface CPPendingCallbacks : NSObject
@property CPResultSuccessBlock successBlock;
@property CPFailureBlock failureBlock;

@end

@implementation CPPendingCallbacks

@end

@implementation CleverPush

NSString * const CLEVERPUSH_SDK_VERSION = @"1.4.7";

static BOOL registeredWithApple = NO;
static BOOL startFromNotification = NO;
static BOOL autoClearBadge = YES;
static BOOL incrementBadge = NO;
static BOOL autoRegister = YES;
static BOOL registrationInProgress = false;

static NSString* channelId;
static NSString* lastNotificationReceivedId;
static NSString* lastNotificationOpenedId;
static NSDictionary* channelConfig;
static CleverPush* singleInstance = nil;

NSDate* lastSync;
NSString* subscriptionId;
NSString* deviceToken;
NSString* currentPageUrl;
NSMutableDictionary* autoAssignSessionsCounted;
NSMutableArray* pendingChannelConfigListeners;
NSArray* appBanners;
NSMutableArray* pendingAppBannersListeners;
NSMutableArray* pendingSubscriptionListeners;
NSArray* channelTopics;
UIBackgroundTaskIdentifier mediaBackgroundTask;
WKWebView* currentAppBannerWebView;
UIColor* brandingColor;
UIColor* chatBackgroundColor;
UIWindow* topicsDialogWindow;
NSString* apiEndpoint = @"https://api.cleverpush.com";
NSMutableArray* pendingTrackingConsentListeners;

CPChatView* currentChatView;
CPResultSuccessBlock cpTokenUpdateSuccessBlock;
CPFailureBlock cpTokenUpdateFailureBlock;
CPHandleNotificationOpenedBlock handleNotificationOpened;
CPHandleNotificationReceivedBlock handleNotificationReceived;
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
DWAlertController *channelTopicsPicker;

BOOL pendingChannelConfigRequest = NO;
BOOL pendingAppBannersRequest = NO;
BOOL channelTopicsPickerVisible = NO;
BOOL developmentMode = NO;
BOOL trackingConsentRequired = NO;
BOOL hasTrackingConsent = NO;
BOOL hasTrackingConsentCalled = NO;
BOOL handleSubscribedCalled = false;

id currentAppBannerUrlOpenedCallback;
int sessionVisits;
long sessionStartedTimestamp;
double channelTopicsPickerShownAt;

static id isNil(id object) {
    return object ?: [NSNull null];
}


+ (NSString*)channelId {
    return channelId;
}

+ (NSString*)subscriptionId {
    return subscriptionId;
}

+ (void)setTrackingConsentRequired:(BOOL)required {
    trackingConsentRequired = required;
}

+ (void)setTrackingConsent:(BOOL)consent {
    hasTrackingConsentCalled = YES;
    hasTrackingConsent = consent;
    
    if (hasTrackingConsent) {
        [self fireTrackingConsentListeners];
    } else {
        pendingTrackingConsentListeners = [NSMutableArray new];
    }
}

+ (void)enableDevelopmentMode {
    developmentMode = YES;
    NSLog(@"CleverPush: ! SDK is running in development mode. Only use this while testing !");
}

+ (BOOL)isDevelopmentModeEnabled {
    return developmentMode;
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
    channelConfig = nil;
    
    pendingChannelConfigListeners = [[NSMutableArray alloc] init];
    pendingAppBannersListeners = [[NSMutableArray alloc] init];
    pendingSubscriptionListeners = [[NSMutableArray alloc] init];
    pendingTrackingConsentListeners = [[NSMutableArray alloc] init];
    autoAssignSessionsCounted = [[NSMutableDictionary alloc] init];
    
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
    }
    
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
            [userDefaults synchronize];
            [self clearSubscriptionData];
        }
        
        if (!channelId) {
            NSLog(@"CleverPush: Channel ID not specified, trying to fetch config via Bundle Identifier...");
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self getChannelConfig:^(NSDictionary* channelConfig) {
                    if (!channelId) {
                        NSLog(@"CleverPush: Initialization stopped - No Channel ID available");
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self initWithChannelId];
                    });
                }];
            });
            NSLog(@"CleverPush: Got Channel ID, initializing");
        } else {
            [self initWithChannelId];
        }
    }
    
    if (autoClearBadge) {
        [self clearBadge:false];
    }
    
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
    NSLog(@"CleverPush: initializing SDK %@ with channelId: %@", CLEVERPUSH_SDK_VERSION, channelId);
    
    UIApplication* sharedApp = [UIApplication sharedApplication];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    subscriptionId = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_ID"];
    deviceToken = [userDefaults stringForKey:@"CleverPush_DEVICE_TOKEN"];
    if (([sharedApp respondsToSelector:@selector(currentUserNotificationSettings)])) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        registeredWithApple = [sharedApp currentUserNotificationSettings].types != (NSUInteger)nil;
#pragma clang diagnostic pop
    } else {
        registeredWithApple = deviceToken != nil;
    }
    
    if (autoRegister) {
        [self subscribe];
    }
    
    if (subscriptionId != nil) {
        if (![self notificationsEnabled]) {
            [self unsubscribe];
        } else if ([self shouldSync]) {
            NSLog(@"CleverPush: syncSubscription called from initWithChannelId");
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
    
    [self initFeatures];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

+ (void)applicationWillEnterForeground {
    [self updateBadge:nil];
    [self trackSessionStart];
    [CPAppBannerModule initSession];
}

+ (void)applicationDidEnterBackground {
    [self updateBadge:nil];
    [self trackSessionEnd];
}

+ (void)initFeatures {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self showPendingTopicsDialog];
        [self initAppReview];
        
        [CPAppBannerModule initBannersWithChannel:channelId showDrafts:developmentMode];
        [CPAppBannerModule initSession];
    });
}

+ (void)initAppReview {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil && [channelConfig valueForKey:@"appReviewEnabled"]) {
            NSString* iosStoreId = [channelConfig valueForKey:@"iosStoreId"];
            
            if ([userDefaults objectForKey:@"CleverPush_APP_REVIEW_SHOWN"]) {
                // already shown
                return;
            }
            
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
            NSInteger currentAppDays = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"] ? [self daysBetweenDate:[userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"] andDate:[NSDate date]] : 0;
            
            NSString *appReviewTitle = [channelConfig valueForKey:@"appReviewTitle"];
            if (!appReviewTitle) {
                appReviewTitle = @"Do you like our app?";
            }
            
            NSString *appReviewYes = [channelConfig valueForKey:@"appReviewYes"];
            if (!appReviewYes) {
                appReviewYes = @"Yes";
            }
            
            NSString *appReviewNo = [channelConfig valueForKey:@"appReviewNo"];
            if (!appReviewNo) {
                appReviewNo = @"No";
            }
            
            NSString *appReviewFeedbackTitle = [channelConfig valueForKey:@"appReviewFeedbackTitle"];
            if (!appReviewFeedbackTitle) {
                appReviewFeedbackTitle = @"Do you want to tell us what you do not like?";
            }
            
            NSString *appReviewEmail = [channelConfig valueForKey:@"appReviewEmail"];
            
            if ([userDefaults integerForKey:@"CleverPush_APP_OPENS"] >= appReviewOpens && currentAppDays >= appReviewDays) {
                NSLog(@"CleverPush: showing app review alert");
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * appReviewSeconds);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    if ([userDefaults objectForKey:@"CleverPush_APP_REVIEW_SHOWN"]) {
                        return;
                    }
                    
                    [userDefaults setObject:[NSDate date] forKey:@"CleverPush_APP_REVIEW_SHOWN"];
                    [userDefaults synchronize];
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:appReviewTitle
                                                                                             message:@""
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:appReviewYes
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                        if (iosStoreId == nil || [iosStoreId isKindOfClass:[NSNull class]]) {
                            return;
                        }
                        
                        NSURL *storeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@?action=write-review", iosStoreId]];
                        if (@available(iOS 10.0, *)) {
                            [[UIApplication sharedApplication] openURL:storeUrl options:@{} completionHandler:nil];
                        } else {
                            // Fallback on earlier versions
                        }
                    }];
                    [alertController addAction:actionYes];
                    
                    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:appReviewNo style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        if (appReviewEmail) {
                            UIAlertController *alertFeedbackController = [UIAlertController alertControllerWithTitle:appReviewFeedbackTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];
                            
                            UIAlertAction *actionFeedbackYes = [UIAlertAction actionWithTitle:appReviewYes style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                NSString *emailUrl = [NSString stringWithFormat:@"mailto:%@?subject=App+Feedback", appReviewEmail];
                                if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0){
                                    if (@available(iOS 10.0, *)) {
                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailUrl] options:@{} completionHandler:^(BOOL success) {
                                            if (!success) {
                                                NSLog(@"CleverPush: failed to open mail app: %@", emailUrl);
                                            }
                                        }];
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailUrl]];
#pragma clang diagnostic pop
                                }
                            }];
                            [alertFeedbackController addAction:actionFeedbackYes];
                            
                            UIAlertAction *actionFeedbackNo = [UIAlertAction actionWithTitle:appReviewNo
                                                                                       style:UIAlertActionStyleDefault
                                                                                     handler:nil];
                            [alertFeedbackController addAction:actionFeedbackNo];
                            
                            UIViewController* topViewController = [CleverPush topViewController];
                            [topViewController presentViewController:alertFeedbackController animated:YES completion:nil];
                        }
                    }];
                    [alertController addAction:actionNo];
                    
                    UIViewController* topViewController = [CleverPush topViewController];
                    [topViewController presentViewController:alertController animated:YES completion:nil];
                });
            }
        }
    }];
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
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
    NSLog(@"CleverPush: next sync: %@", nextSync);
    return [nextSync compare:[NSDate date]] == NSOrderedAscending;
}

+ (void)fireChannelConfigListeners {
    pendingChannelConfigRequest = NO;
    
    for (void (^listener)(NSDictionary *) in pendingChannelConfigListeners) {
        
        // NSLog(@"CleverPush: pendingChannelConfigListener channelConfig %@", channelConfig);
        // check if listener and channelConfig are non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener && channelConfig) {
            __strong void (^callbackBlock)(NSDictionary *) = listener;
            callbackBlock(channelConfig);
        }
    }
    pendingChannelConfigListeners = [NSMutableArray new];
}

+ (void)getChannelConfig:(void(^)(NSDictionary *))callback {
    if (channelConfig) {
        callback(channelConfig);
        return;
    }
    
    [pendingChannelConfigListeners addObject:callback];
    if (pendingChannelConfigRequest) {
        return;
    }
    pendingChannelConfigRequest = YES;
    
    if (channelId != NULL) {
        NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", channelId];
        if (developmentMode) {
            configPath = [NSString stringWithFormat:@"%@?t=%f", configPath, NSDate.date.timeIntervalSince1970];
        }
        
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                NSLog(@"%@", result);
                channelConfig = result;
            }
            [self fireChannelConfigListeners];
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
            [self fireChannelConfigListeners];
        }];
    } else {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", [[NSBundle mainBundle] bundleIdentifier]]];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                channelId = [result objectForKey:@"channelId"];
                NSLog(@"CleverPush: Detected Channel ID from Bundle Identifier: %@", channelId);
                
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:channelId forKey:@"CleverPush_CHANNEL_ID"];
                [userDefaults setObject:nil forKey:@"CleverPush_SUBSCRIPTION_ID"];
                [userDefaults synchronize];
                
                channelConfig = result;
            }
            
            [self fireChannelConfigListeners];
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error);
            
            [self fireChannelConfigListeners];
        }];
    }
}

+ (NSString*)getChannelId {
    return channelId;
}

+ (void)getSubscriptionId:(void(^)(NSString *))callback {
    if (subscriptionId) {
        callback(subscriptionId);
    } else {
        [pendingSubscriptionListeners addObject:[callback copy]];
    }
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

+ (void)fireTrackingConsentListeners {
    for (void (^listener)(void *) in pendingTrackingConsentListeners) {
        // check if listener is non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener) {
            __strong void (^callbackBlock)() = listener;
            callbackBlock();
        }
    }
    pendingTrackingConsentListeners = [NSMutableArray new];
}

+ (void)waitForTrackingConsent:(void(^)(void))callback {
    if (!trackingConsentRequired || hasTrackingConsent) {
        callback();
        return;
    }
    
    if (!hasTrackingConsentCalled) {
        [pendingTrackingConsentListeners addObject:callback];
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
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
                if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone)) {
                    isEnabled = NO;
                } else {
                    isEnabled = YES;
                }
#pragma clang diagnostic pop
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

+ (void)setConfirmAlertShown {
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

+ (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull notificationSettings) {
            if (subscriptionId == nil && channelId != nil && notificationSettings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                [self setConfirmAlertShown];
            }
            
            UNAuthorizationOptions options = (UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge);
            [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"CleverPush: requestAuthorizationWithOptions error: %@", error);
                    } else if (!granted) {
                        NSLog(@"CleverPush: requestAuthorizationWithOptions not granted");
                    }
                    
                    if (granted) {
                        if (subscriptionId == nil) {
                            NSLog(@"CleverPush: syncSubscription called from subscribe");
                            [self performSelector:@selector(syncSubscription) withObject:nil];
                            
                            [self getChannelConfig:^(NSDictionary* channelConfig) {
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
                                        
                                        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                                        [userDefaults setBool:YES forKey:@"CleverPush_TOPICS_DIALOG_PENDING"];
                                        [userDefaults synchronize];
                                        
                                        [self showPendingTopicsDialog];
                                    }
                                }
                            }];
                            
                            if (subscribedBlock) {
                                [self getSubscriptionId:^(NSString* subscriptionId) {
                                    subscribedBlock(subscriptionId);
                                }];
                            }
                        } else if (subscribedBlock) {
                            subscribedBlock(subscriptionId);
                        }
                    }
                });
            }];
        }];
        
        [self ensureMainThreadSync:^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }];
        
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        [self ensureMainThreadSync:^{
            if (subscriptionId == nil && channelId != nil) {
                if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
                    UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
                    if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone)) {
                        [self setConfirmAlertShown];
                    }
                } else {
                    if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
                        [self setConfirmAlertShown];
                    }
                }
            }
            
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
                Class uiUserNotificationSettings = NSClassFromString(@"UIUserNotificationSettings");
                
                NSSet* categories = [[[UIApplication sharedApplication] currentUserNotificationSettings] categories];
                
                [[UIApplication sharedApplication] registerUserNotificationSettings:[uiUserNotificationSettings settingsForTypes:UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge categories:categories]];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            } else {
                // iOS < 8.0
            }
        }];
#pragma clang diagnostic pop
    }
}

+ (void)clearSubscriptionData {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_ID"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_LAST_SYNC"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_TOPICS_VERSION"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_TAGS"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_SUBSCRIPTION_ATTRIBUTES"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    handleSubscribedCalled = false;
    subscriptionId = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];
}

+ (void)unsubscribe {
    [self unsubscribe:^(BOOL success) {
        if (success) {
            NSLog(@"CleverPush: unsubscribe success");
        } else {
            NSLog(@"CleverPush: unsubscribe failure");
        }
    }];
}

+ (void)unsubscribe:(void(^)(BOOL))callback {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];
    
    if (subscriptionId) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/unsubscribe"];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 channelId, @"channelId",
                                 subscriptionId, @"subscriptionId",
                                 nil];
        
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            [self clearSubscriptionData];
            callback(YES);
        } onFailure:^(NSError* error) {
            [self clearSubscriptionData];
            callback(NO);
        }];
        
    } else {
        [self clearSubscriptionData];
        callback(YES);
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
        deviceToken = newDeviceToken;
        cpTokenUpdateSuccessBlock = successBlock;
        cpTokenUpdateFailureBlock = failureBlock;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
            [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
                if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                    NSLog(@"CleverPush: syncSubscription called from registerDeviceToken");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
                    });
                }
            }];
        } else {
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        }
        return;
    }
    
    if ([deviceToken isEqualToString:newDeviceToken]) {
        if (successBlock) {
            successBlock(nil);
        }
        return;
    }
    
    deviceToken = newDeviceToken;
    
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"CleverPush_DEVICE_TOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



+ (void)syncSubscription {
    if (registrationInProgress) {
        NSLog(@"CleverPush: syncSubscription aborted - registration already in progress");
        return;
    }
    
    if (!deviceToken) {
        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"CleverPush_DEVICE_TOKEN"];
    }
    
    if (!deviceToken && !subscriptionId) {
        NSLog(@"CleverPush: syncSubscription aborted - no deviceToken and no subscriptionId available");
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];
    
    registrationInProgress = true;
    
    NSMutableURLRequest* request;
    request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* language = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_LANGUAGE"];
    if (!language) {
        language = [[[NSLocale preferredLanguages] firstObject] substringToIndex:2];
    }
    NSString* country = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_COUNTRY"];
    if (!country) {
        country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    NSString* timezone = [[NSTimeZone localTimeZone] name];
    
    [request setAllHTTPHeaderFields:@{
        @"User-Agent": [NSString stringWithFormat:@"CleverPush iOS SDK %@", CLEVERPUSH_SDK_VERSION],
        @"Accept-Language": language
    }];
    
    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    @"SDK", @"browserType",
                                    CLEVERPUSH_SDK_VERSION, @"browserVersion",
                                    @"iOS", @"platformName",
                                    [[UIDevice currentDevice] systemVersion], @"platformVersion",
                                    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"appVersion",
                                    isNil(country), @"country",
                                    isNil(timezone), @"timezone",
                                    isNil(language), @"language",
                                    nil];
    
    if (subscriptionId) {
        [dataDic setObject:subscriptionId forKey:@"subscriptionId"];
    }
    if (deviceToken) {
        [dataDic setObject:deviceToken forKey:@"apnsToken"];
    }
    
    NSArray* topics = [self getSubscriptionTopics];
    if (topics != nil && [topics count] >= 0) {
        [dataDic setObject:topics forKey:@"topics"];
        NSInteger topicsVersion = [userDefaults integerForKey:@"CleverPush_SUBSCRIPTION_TOPICS_VERSION"];
        if (topicsVersion) {
            [dataDic setObject:[NSNumber numberWithInteger:topicsVersion] forKey:@"topicsVersion"];
        }
    }
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    NSLog(@"CleverPush: syncSubscription Request data:%@ id:%@", dataDic, subscriptionId);
    
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        registrationInProgress = false;
        
        // NSLog(@"CleverPush: syncSubscription Result %@", results);
        
        if ([results valueForKey:@"topics"] != nil) {
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:[results valueForKey:@"topics"] forKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
            if ([results valueForKey:@"topicsVersion"] != nil) {
                [userDefaults setInteger:[[results objectForKey:@"topicsVersion"] integerValue] forKey:@"CleverPush_SUBSCRIPTION_TOPICS_VERSION"];
            }
            [userDefaults synchronize];
        }
        
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
            for (id (^listener)() in pendingSubscriptionListeners) {
                listener(subscriptionId);
            }
            pendingSubscriptionListeners = [NSMutableArray new];
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
    
    if (isEmpty(notificationId) || ([notificationId isEqualToString:lastNotificationReceivedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationReceivedId = notificationId;
    
    NSLog(@"CleverPush: handleNotificationReceived, isActive %@, Payload %@", @(isActive), messageDict);
    
    [CleverPush setNotificationDelivered:notification withChannelId:[messageDict valueForKeyPath:@"channel._id"] withSubscriptionId:[messageDict valueForKeyPath:@"subscription._id"]];
    
    if (isActive && notification != nil && [notification valueForKey:@"chatNotification"] != nil && ![[notification valueForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification valueForKey:@"chatNotification"] boolValue]) {
        
        if (currentChatView != nil) {
            [currentChatView loadChat];
        }
    }
    
    if (!handleNotificationReceived) {
        return;
    }
    
    CPNotificationReceivedResult * result = [[CPNotificationReceivedResult alloc] initWithPayload:messageDict];
    
    handleNotificationReceived(result);
}

+ (void)addAttachments:(NSString*)mediaUrl toContent:(UNMutableNotificationContent*)content {
    NSMutableArray* unAttachments = [NSMutableArray new];
    
    NSURL* nsURL = [NSURL URLWithString:mediaUrl];
    
    if (nsURL) {
        NSString* urlScheme = [nsURL.scheme lowercaseString];
        if ([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"]) {
            NSString* name = [CPUtils downloadMedia:mediaUrl];
            
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

+ (void)addCarouselAttachments:(NSDictionary*)notification toContent:(UNMutableNotificationContent*)content {
    NSMutableArray* unAttachments = [NSMutableArray new];
    
    NSArray *images = [[NSArray alloc] init];
    images = [notification objectForKey:@"carouselItems"];
    [images enumerateObjectsUsingBlock:
     ^(NSDictionary *image, NSUInteger index, BOOL *stop)
     {
        NSString* mediaUrl = [image objectForKey:@"mediaUrl"];
        if (mediaUrl != nil) {
            NSURL* nsURL = [NSURL URLWithString:mediaUrl];
            
            if (nsURL) {
                NSString* urlScheme = [nsURL.scheme lowercaseString];
                if ([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"]) {
                    NSString* name = [CPUtils downloadMedia:mediaUrl];
                    
                    if (name) {
                        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                        NSString* filePath = [paths[0] stringByAppendingPathComponent:name];
                        NSURL* url = [NSURL fileURLWithPath:filePath];
                        NSError* error;
                        UNNotificationAttachment* attachment = [UNNotificationAttachment
                                                                attachmentWithIdentifier:[NSString stringWithFormat:@"media_%lu.jpg", (unsigned long)index]
                                                                URL:url
                                                                options:0
                                                                error:&error];
                        if (attachment) {
                            [unAttachments addObject:attachment];
                        }
                    }
                }
            }
        }
    }];
    
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

+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier {
    NSString* notificationId = [payload valueForKeyPath:@"notification._id"];
    NSDictionary* notification = [payload valueForKey:@"notification"];
    
    if (isEmpty(notificationId) || ([notificationId isEqualToString:lastNotificationOpenedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationOpenedId = notificationId;
    
    NSString* action = actionIdentifier;
    
    if (action != nil && ([action isEqualToString:@"__DEFAULT__"] || [action isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])) {
        action = nil;
    }
    
    NSLog(@"CleverPush: handleNotificationOpened, %@, %@", action, payload);
    
    [CleverPush setNotificationClicked:notificationId withChannelId:[payload valueForKeyPath:@"channel._id"] withSubscriptionId:[payload valueForKeyPath:@"subscription._id"] withAction:action];
    
    if (autoClearBadge) {
        [self clearBadge:true];
    }
    
    // badge count
    [self updateBadge:nil];
    
    if (notification != nil && [notification valueForKey:@"chatNotification"] != nil && ![[notification valueForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification valueForKey:@"chatNotification"] boolValue]) {
        
        if (currentChatView != nil) {
            [currentChatView loadChat];
        }
    }
    
    if (!handleNotificationOpened) {
        return;
    }
    
    CPNotificationOpenedResult * result = [[CPNotificationOpenedResult alloc] initWithPayload:payload action:action];
    
    handleNotificationOpened(result);
}

+ (void)updateBadge:(UNMutableNotificationContent*)replacementContent {
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [bundle bundleIdentifier]]];
    if ([userDefaults boolForKey:@"CleverPush_INCREMENT_BADGE"]) {
        if (replacementContent != nil) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                replacementContent.badge = @([notifications count] + 1);
                
                dispatch_semaphore_signal(sema);
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        } else {
            [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[notifications count]];
                });
            }];
        }
        
    } else {
        NSLog(@"CleverPush: updateBadge - no incrementBadge used");
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (void)processLocalActionBasedNotification:(UILocalNotification*)notification actionIdentifier:(NSString*)actionIdentifier {
    if (!notification.userInfo) {
        return;
    }
    
    NSLog(@"CleverPush processLocalActionBasedNotification");
    
    BOOL isActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    [self handleNotificationReceived:notification.userInfo isActive:isActive];
    
    if (!isActive) {
        [self handleNotificationOpened:notification.userInfo isActive:isActive actionIdentifier:actionIdentifier];
    }
}
#pragma clang diagnostic pop

+ (void)setNotificationDelivered:(NSDictionary*)notification {
    [self setNotificationDelivered:notification withChannelId:channelId withSubscriptionId:[self getSubscriptionId]];
}

+ (void)setNotificationDelivered:(NSDictionary*)notification withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId {
    
    NSString *notificationId = [notification valueForKey:@"_id"];
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/delivered"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             notificationId, @"notificationId",
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
    
    [userDefaults setObject:notificationId forKey:@"CleverPush_LAST_NOTIFICATION_ID"];
    [userDefaults synchronize];
    
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
    [self setNotificationClicked:notificationId withChannelId:channelId withSubscriptionId:[self getSubscriptionId] withAction:nil];
}

+ (void)setNotificationClicked:(NSString*)notificationId withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId withAction:(NSString*)action {
    NSLog(@"CleverPush: setNotificationClicked notification:%@, subscription:%@, channel:%@, action:%@", notificationId, channelId, subscriptionId, action);
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/clicked"];
    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    channelId, @"channelId",
                                    notificationId, @"notificationId",
                                    subscriptionId, @"subscriptionId",
                                    nil];
    
    if (action != nil) {
        [dataDic setValue:action forKey:@"action"];
    }
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
}

+ (BOOL)clearBadge:(BOOL)fromNotificationOpened {
    bool wasSet = [UIApplication sharedApplication].applicationIconBadgeNumber > 0;
    if ((!(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) && fromNotificationOpened) || wasSet) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        
        NSBundle *bundle = [NSBundle mainBundle];
        if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
            bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
        }
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [bundle bundleIdentifier]]];
        if ([userDefaults objectForKey:@"CleverPush_BADGE_COUNT"] != nil) {
            [userDefaults setInteger:0 forKey:@"CleverPush_BADGE_COUNT"];
            [userDefaults synchronize];
        }
        
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
    NSLog(@"CleverPush: %@", [NSString stringWithFormat:@"Device Registered with Apple: %@", parsedDeviceToken]);
    [CleverPush registerDeviceToken:parsedDeviceToken onSuccess:^(NSDictionary* results) {
        NSLog(@"CleverPush: %@", [NSString stringWithFormat: @"Device Registered with CleverPush: %@", subscriptionId]);
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush: %@", [NSString stringWithFormat: @"Error in CleverPush Registration: %@", error]);
    }];
}

+ (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    NSLog(@"CleverPush: HTTP -> %@ %@", [request HTTPMethod], [request URL].absoluteString);
    
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
    
    if (data != nil && !isEmpty(data)) {
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
    NSLog(@"CleverPush: addSubscriptionTag: %@", tagId);
    
    [self waitForTrackingConsent:^{
        NSLog(@"CleverPush: addSubscriptionTag 2: %@", tagId);
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        __block NSMutableArray* subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TAGS"]];
        
        if ([subscriptionTags containsObject:tagId]) {
            NSLog(@"CleverPush: addSubscriptionTag - already has tag, skipping API call");
            return;
        }
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/tag"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     tagId, @"tagId",
                                     [self getSubscriptionId], @"subscriptionId",
                                     nil];
            
            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];
            
            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                if (!subscriptionTags) {
                    subscriptionTags = [[NSMutableArray alloc] init];
                }
                
                if (![subscriptionTags containsObject:tagId]) {
                    [subscriptionTags addObject:tagId];
                }
                [userDefaults setObject:subscriptionTags forKey:@"CleverPush_SUBSCRIPTION_TAGS"];
                [userDefaults synchronize];
            } onFailure:nil];
        });
    }];
}

+ (void)removeSubscriptionTag:(NSString*)tagId {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
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
        });
    }];
}

+ (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
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
        });
    }];
}

+ (NSArray*)getAvailableTags {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSArray* channelTags = nil;
    [self getAvailableTags:^(NSArray* channelTags_) {
        channelTags = channelTags_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return channelTags;
}

+ (void)getAvailableTags:(void(^)(NSArray *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTags = [channelConfig valueForKey:@"channelTags"];
            if (channelTags != nil && ![channelTags isKindOfClass:[NSNull class]] && [channelTags count] > 0) {
                NSMutableArray* channelTagsArray = [NSMutableArray new];
                [channelTags enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL *stop) {
                    CPChannelTag* tag = [CPChannelTag initWithJson:item];
                    [channelTagsArray addObject:tag];
                }];
                callback(channelTagsArray);
                return;
            }
        }
        callback([[NSArray alloc] init]);
    }];
}

+ (NSArray*)getAvailableTopics {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSArray* channelTopics = nil;
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return channelTopics;
}

+ (void)getAvailableTopics:(void(^)(NSArray *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTopics = [channelConfig valueForKey:@"channelTopics"];
            if (channelTopics != nil && ![channelTopics isKindOfClass:[NSNull class]] && [channelTopics count] > 0) {
                NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sort" ascending:YES];
                NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
                NSArray *sortedTopics = [channelTopics sortedArrayUsingDescriptors:descriptors];
                
                NSMutableArray* channelTopicsArray = [NSMutableArray new];
                [sortedTopics enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL *stop) {
                    CPChannelTopic* topic = [CPChannelTopic initWithJson:item];
                    [channelTopicsArray addObject:topic];
                }];
                callback(channelTopicsArray);
                return;
            }
        }
        callback([[NSArray alloc] init]);
    }];
}

+ (NSDictionary*)getAvailableAttributes {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSDictionary* customAttributes = nil;
    [self getAvailableAttributes:^(NSDictionary* customAttributes_) {
        customAttributes = customAttributes_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return customAttributes;
}

+ (void)getAvailableAttributes:(void(^)(NSDictionary *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSDictionary* customAttributes = [channelConfig valueForKey:@"customAttributes"];
            if (customAttributes != nil) {
                callback(customAttributes);
                return;
            }
        }
        callback([[NSDictionary alloc] init]);
    }];
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
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
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
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
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

+ (BOOL)hasSubscriptionTopics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTopics = [userDefaults arrayForKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    return subscriptionTopics ? YES : NO;
}

+ (void)setSubscriptionTopics:(NSMutableArray *)topics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger topicsVersion = [userDefaults integerForKey:@"CleverPush_SUBSCRIPTION_TOPICS_VERSION"];
    if (!topicsVersion) {
        topicsVersion = 1;
    } else {
        topicsVersion += 1;
    }
    
    [userDefaults setObject:topics forKey:@"CleverPush_SUBSCRIPTION_TOPICS"];
    [userDefaults setInteger:topicsVersion forKey:@"CleverPush_SUBSCRIPTION_TOPICS_VERSION"];
    [userDefaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
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

+ (void)fireAppBannersListeners {
    pendingAppBannersRequest = NO;
    for (void (^listener)(void *) in pendingAppBannersListeners) {
        // check if listener is non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener && appBanners) {
            __strong void (^callbackBlock)() = listener;
            callbackBlock(appBanners);
        }
    }
    pendingAppBannersListeners = [NSMutableArray new];
}

+ (void)getAppBanners:(void(^)(NSArray *))callback {
    if (appBanners) {
        callback(appBanners);
        return;
    }
    
    [pendingAppBannersListeners addObject:callback];
    if (pendingAppBannersRequest) {
        return;
    }
    pendingAppBannersRequest = YES;
    
    if (channelId != NULL) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel/%@/app-banners", channelId]];
        [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (result != nil) {
                appBanners = [result valueForKey:@"banners"];
            }
            [self fireAppBannersListeners];
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed getting the app banners %@", error);
            [self fireAppBannersListeners];
        }];
    } else {
        [self fireAppBannersListeners];
    }
}

+ (void)trackEvent:(NSString*)eventName {
    return [self trackEvent:eventName amount:nil];
}

+ (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSArray* channelEvents = [channelConfig valueForKey:@"channelEvents"];
            if (channelEvents == nil) {
                NSLog(@"Event not found");
                return;
            }
            
            NSUInteger eventIndex = [channelEvents indexOfObjectWithOptions:NSEnumerationConcurrent
                                                                passingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *event = (NSDictionary*) obj;
                return event != nil && [[event valueForKey:@"name"] isEqualToString:eventName];
            }];
            if (eventIndex == NSNotFound) {
                NSLog(@"Event not found");
                return;
            }
            
            NSDictionary *event = [channelEvents objectAtIndex:eventIndex];
            NSString *eventId = [event valueForKey:@"_id"];
            
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/conversion"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     eventId, @"eventId",
                                     isNil(amount), @"amount",
                                     [self getSubscriptionId], @"subscriptionId",
                                     nil];
            
            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];
            
            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                
            } onFailure:nil];
        }];
    });
}

+ (void)autoAssignTagMatches:(NSDictionary*)tag pathname:(NSString*)pathname params:(NSDictionary*)params callback:(void(^)(BOOL))callback {
    NSString* path = [tag valueForKey:@"autoAssignPath"];
    if (path != nil) {
        if ([path isEqualToString:@"[EMPTY]"]) {
            path = @"";
        }
        if ([pathname rangeOfString:path options:NSRegularExpressionSearch].location != NSNotFound) {
            callback(YES);
            return;
        }
    }
    
    NSString* function = [tag valueForKey:@"autoAssignFunction"];
    if (function != nil && params != nil) {
        JSContext *context = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
        [context evaluateScript:[NSString stringWithFormat:@"var _cp_autoAssignTagResult = function(params) { return %@ }", function]];
        BOOL result = [[context[@"_cp_autoAssignTagResult"] callWithArguments:@[params]] toBool];
        
        if (result) {
            callback(YES);
        } else {
            callback(NO);
        }
        return;
    }
    
    if ([tag valueForKey:@"autoAssignSelector"] != nil) {
        // not implemented
        callback(NO);
        return;
    }
    
    NSLog(@"CleverPush: autoAssignTagMatches - no detection method found %@ %@", pathname, params);
    
    callback(NO);
}

+ (void)checkTags:(NSString*)urlStr params:(NSDictionary*)params {
    NSURL* url = [NSURL URLWithString:urlStr];
    NSString* pathname = [url path];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self getAvailableTags:^(NSArray *tags) {
        for (CPChannelTag *tag in tags) {
            [self autoAssignTagMatches:tag pathname:pathname params:params callback:^(BOOL tagMatches) {
                if (tagMatches) {
                    NSLog(@"CleverPush: checkTags: autoAssignTagMatches:YES %@", [tag name]);
                    
                    NSString* tagId = [tag valueForKey:@"_id"];
                    NSString* visitsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignVisits-%@", tagId];
                    NSString* sessionsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignSessions-%@", tagId];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
                    
                    int autoAssignVisits = [[tag valueForKey:@"autoAssignVisits"] intValue];
                    
                    NSString *dateKey = [dateFormatter stringFromDate:[NSDate date]];
                    
                    NSDate *dateAfter = nil;
                    
                    int autoAssignDays = [[tag valueForKey:@"autoAssignDays"] intValue];
                    if (autoAssignDays > 0) {
                        dateAfter = [[NSDate date] dateByAddingTimeInterval:-1*autoAssignDays*24*60*60];
                    }
                    
                    int visits = 0;
                    NSMutableDictionary* dailyVisits = [[NSMutableDictionary alloc] init];
                    if (autoAssignDays > 0 && dateAfter != nil) {
                        dailyVisits = [userDefaults objectForKey:visitsStorageKey];
                        
                        for (NSString* curDateKey in dailyVisits) {
                            NSDate *currDate = [dateFormatter dateFromString:curDateKey];
                            
                            if ([currDate timeIntervalSinceDate:dateAfter] >= 0) {
                                visits += [[dailyVisits objectForKey:curDateKey] integerValue];
                            } else {
                                [dailyVisits removeObjectForKey:curDateKey];
                            }
                        }
                    } else {
                        visits = (int) [userDefaults integerForKey:visitsStorageKey];
                    }
                    
                    int autoAssignSessions = [[tag valueForKey:@"autoAssignSessions"] intValue];
                    int autoAssignSeconds = [[tag valueForKey:@"autoAssignSeconds"] intValue];
                    
                    int sessions = 0;
                    NSMutableDictionary* dailySessions = [[NSMutableDictionary alloc] init];
                    if (autoAssignDays > 0 && dateAfter != nil) {
                        dailySessions = [userDefaults objectForKey:sessionsStorageKey];
                        
                        for (NSString* curDateKey in dailySessions) {
                            NSDate *currDate = [dateFormatter dateFromString:curDateKey];
                            
                            if ([currDate timeIntervalSinceDate:dateAfter] >= 0) {
                                sessions += [[dailySessions objectForKey:curDateKey] integerValue];
                            } else {
                                [dailySessions removeObjectForKey:curDateKey];
                            }
                        }
                    } else {
                        sessions = (int) [userDefaults integerForKey:sessionsStorageKey];
                    }
                    
                    if (sessions >= autoAssignSessions) {
                        if (visits >= autoAssignVisits) {
                            if (autoAssignSeconds > 0) {
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(autoAssignSeconds * NSEC_PER_SEC));
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                    if ([currentPageUrl isEqualToString:urlStr]) {
                                        [self addSubscriptionTag:tagId];
                                    }
                                });
                            } else {
                                [self addSubscriptionTag:tagId];
                            }
                        } else {
                            if (autoAssignDays > 0) {
                                int dateVisits = 0;
                                if ([dailyVisits objectForKey:dateKey] == nil) {
                                    [dailyVisits setValue:0 forKey:dateKey];
                                } else {
                                    dateVisits = [[dailyVisits valueForKey:dateKey] intValue];
                                }
                                dateVisits += 1;
                                [dailyVisits setObject:[NSNumber numberWithInt:dateVisits] forKey:dateKey];
                                
                                [userDefaults setObject:dailyVisits forKey:visitsStorageKey];
                                [userDefaults synchronize];
                            } else {
                                visits += 1;
                                [userDefaults setInteger:visits forKey:visitsStorageKey];
                                [userDefaults synchronize];
                            }
                        }
                    } else {
                        if (autoAssignDays > 0) {
                            int dateVisits = 0;
                            if ([dailyVisits objectForKey:dateKey] == nil) {
                                [dailyVisits setValue:0 forKey:dateKey];
                            } else {
                                dateVisits = [[dailyVisits objectForKey:dateKey] intValue];
                            }
                            dateVisits += 1;
                            [dailyVisits setValue:[NSNumber numberWithInt:dateVisits] forKey:dateKey];
                            
                            [userDefaults setObject:dailyVisits forKey:visitsStorageKey];
                            [userDefaults synchronize];
                            
                            if ([autoAssignSessionsCounted objectForKey:tagId] == nil) {
                                int dateSessions = 0;
                                if ([dailySessions objectForKey:dateKey] == nil) {
                                    [dailySessions setObject:[NSNumber numberWithInt:0] forKey:dateKey];
                                } else {
                                    dateSessions = [[dailySessions valueForKey:dateKey] intValue];
                                }
                                dateSessions += 1;
                                [dailySessions setObject:[NSNumber numberWithInt:dateSessions] forKey:dateKey];
                                
                                [autoAssignSessionsCounted setValue:false forKey:tagId];
                                
                                [userDefaults setObject:dailySessions forKey:sessionsStorageKey];
                                [userDefaults synchronize];
                            }
                        } else {
                            visits += 1;
                            [userDefaults setInteger:visits forKey:visitsStorageKey];
                            [userDefaults synchronize];
                            
                            if ([autoAssignSessionsCounted objectForKey:tagId] == nil) {
                                sessions += 1;
                                [userDefaults setInteger:visits forKey:sessionsStorageKey];
                                [userDefaults synchronize];
                                
                                [autoAssignSessionsCounted setValue:false forKey:tagId];
                            }
                        }
                    }
                } else {
                    NSLog(@"CleverPush: checkTags: autoAssignTagMatches:NO %@", [tag name]);
                }
            }];
        }
    }];
}

+ (void)trackPageView:(NSString*)url {
    [self trackPageView:url params:nil];
}

+ (void)trackPageView:(NSString*)url params:(NSDictionary*)params {
    currentPageUrl = url;
    
    [self checkTags:url params:params];
}

+ (void)trackSessionStart {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self getChannelConfig:^(NSDictionary* channelConfig) {
                bool trackAppStatistics = [channelConfig valueForKey:@"trackAppStatistics"] != nil && ![[channelConfig valueForKey:@"trackAppStatistics"] isKindOfClass:[NSNull class]] && [[channelConfig valueForKey:@"trackAppStatistics"] boolValue];
                if (trackAppStatistics || subscriptionId) {
                    sessionVisits = 0;
                    sessionStartedTimestamp = [[NSDate date] timeIntervalSince1970];
                    
                    if (!deviceToken) {
                        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"CleverPush_DEVICE_TOKEN"];
                    }
                    
                    NSUserDefaults* groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
                    NSString* lastNotificationId = [groupUserDefaults stringForKey:@"CleverPush_LAST_NOTIFICATION_ID"];
                    
                    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/session/start"];
                    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             channelId, @"channelId",
                                             subscriptionId, @"subscriptionId",
                                             deviceToken, @"apnsToken",
                                             isNil(lastNotificationId), @"lastNotificationId",
                                             nil];
                    
                    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                    [request setHTTPBody:postData];
                    
                    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                        
                    } onFailure:nil];
                }
            }];
        });
    }];
}

+ (void)increaseSessionVisits {
    sessionVisits += 1;
}

+ (void)trackSessionEnd {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self getChannelConfig:^(NSDictionary* channelConfig) {
                bool trackAppStatistics = [channelConfig valueForKey:@"trackAppStatistics"] != nil && ![[channelConfig valueForKey:@"trackAppStatistics"] isKindOfClass:[NSNull class]] && [[channelConfig valueForKey:@"trackAppStatistics"] boolValue];
                if (trackAppStatistics || subscriptionId) {
                    if (!deviceToken) {
                        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"CleverPush_DEVICE_TOKEN"];
                    }
                    
                    if (sessionStartedTimestamp == 0) {
                        return;
                    }
                    
                    long sessionEndedTimestamp = [[NSDate date] timeIntervalSince1970];
                    long sessionDuration = sessionEndedTimestamp - sessionStartedTimestamp;
                    
                    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/session/end"];
                    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             channelId, @"channelId",
                                             subscriptionId, @"subscriptionId",
                                             deviceToken, @"apnsToken",
                                             sessionVisits, @"visits",
                                             sessionDuration, @"duration",
                                             nil];
                    
                    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                    [request setHTTPBody:postData];
                    
                    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                        
                    } onFailure:nil];
                }
            }];
        });
    }];
}

+ (void)setBrandingColor:(UIColor *)color {
    brandingColor = color;
}

+ (void)setTopicsDialogWindow:(UIWindow *)window {
    topicsDialogWindow = window;
}

+ (UIColor*)getBrandingColor {
    return brandingColor;
}

+ (void)setAutoClearBadge:(BOOL)autoClear {
    autoClearBadge = autoClear;
}

+ (void)setIncrementBadge:(BOOL)increment {
    incrementBadge = increment;
    
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [bundle bundleIdentifier]]];
    [userDefaults setBool:increment forKey:@"CleverPush_INCREMENT_BADGE"];
    [userDefaults synchronize];
}

+ (void)setChatBackgroundColor:(UIColor *)color {
    chatBackgroundColor = color;
}

+ (UIColor*)getChatBackgroundColor {
    return chatBackgroundColor;
}

+ (void)addChatView:(CPChatView*)chatView {
    if (currentChatView != nil) {
        [currentChatView removeFromSuperview];
    }
    currentChatView = chatView;
}

+ (void)setApiEndpoint:(NSString*)endpoint {
    apiEndpoint = endpoint;
}

+ (NSString*)getApiEndpoint {
    return apiEndpoint;
}

+ (void)showPendingTopicsDialog {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"CleverPush_TOPICS_DIALOG_PENDING"]) {
        return;
    }
    
    int topicsDialogSessions = (int)[[channelConfig valueForKey:@"topicsDialogMinimumSessions"] integerValue];
    if (!topicsDialogSessions) {
        topicsDialogSessions = 0;
    }
    int topicsDialogDays = (int)[[channelConfig valueForKey:@"topicsDialogMinimumDays"] integerValue];
    if (!topicsDialogDays) {
        topicsDialogDays = 0;
    }
    int topicsDialogSeconds = (int)[[channelConfig valueForKey:@"topicsDialogMinimumSeconds"] integerValue];
    if (!topicsDialogSeconds) {
        topicsDialogSeconds = 0;
    }
    NSInteger currentTopicsDialogDays = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"] ? [self daysBetweenDate:[NSDate date] andDate:[userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_CREATED_AT"]] : 0;
    
    if ([userDefaults integerForKey:@"CleverPush_APP_OPENS"] >= topicsDialogSessions && currentTopicsDialogDays >= topicsDialogDays) {
        NSLog(@"CleverPush: showing pending topics dialog");
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * topicsDialogSeconds);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            if (![userDefaults boolForKey:@"CleverPush_TOPICS_DIALOG_PENDING"]) {
                return;
            }
            
            [userDefaults setBool:NO forKey:@"CleverPush_TOPICS_DIALOG_PENDING"];
            [userDefaults synchronize];
            
            [self showTopicsDialog];
        });
    }
}

+ (UIWindow*)keyWindow {
    UIWindow *foundWindow = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

+ (void)showTopicsDialog {
    if (topicsDialogWindow) {
        [self showTopicsDialog:topicsDialogWindow];
    }
    [self showTopicsDialog:[self keyWindow]];
}

+ (void)showTopicsDialog:(UIWindow *)targetWindow {
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        if ([channelTopics count] == 0) {
            NSLog(@"CleverPush: showTopicsDialog: No topics found. Create some first in the CleverPush channel settings.");
        }
        
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSString* headerTitle = [CPTranslate translate:@"subscribedTopics"];
            
            if (channelConfig != nil && [channelConfig valueForKey:@"confirmAlertSelectTopicsLaterTitle"] != nil && ![[channelConfig valueForKey:@"confirmAlertSelectTopicsLaterTitle"] isEqualToString:@""]) {
                headerTitle = [channelConfig valueForKey:@"confirmAlertSelectTopicsLaterTitle"];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CPTopicsViewController *topicsController = [[CPTopicsViewController alloc] initWithAvailableTopics:channelTopics selectedTopics:[self getSubscriptionTopics] hasSubscriptionTopics:[self hasSubscriptionTopics]];
                
                channelTopicsPicker = [DWAlertController alertControllerWithContentController:topicsController];
                topicsController.title = headerTitle;
                
                DWAlertAction *okAction = [DWAlertAction actionWithTitle:[CPTranslate translate:@"save"]
                                                                   style:DWAlertActionStyleCancel
                                                                 handler:^(DWAlertAction* action) {
                    if (topicsController.deselectedAll == YES) {
                        [self setSubscriptionTopics:[topicsController getSelectedTopics]];
                        [self unsubscribe];
                    }else{
                        [self subscribe];
                        NSLog(@"%@", [topicsController getSelectedTopics]);
                        [self setSubscriptionTopics:[topicsController getSelectedTopics]];
                    }
                    [topicsController dismissViewControllerAnimated:YES completion:nil];
                    
                }];
                [channelTopicsPicker addAction:okAction];
                
                UIViewController* topViewController = [CleverPush topViewController];
                
                [topViewController presentViewController:channelTopicsPicker animated:YES completion:nil];
            });
        }];
    }];
    
}


+ (void)showAppBanners {
    NSLog(@"CleverPush: showAppBanners does not have to be called, app banners are initialized automatically");
}

+ (void)showAppBanners:(void(^)(NSString *))urlOpenedCallback {
    [CleverPush showAppBanners];
}

+ (void)reLayoutAppBanner {
    NSLog(@"CleverPush: reLayoutAppBanner is deprecated");
}

+ (void)showAppBanner:(NSString *)bannerId {
    [CPAppBannerModule showBanner:channelId bannerId:bannerId];
}

+ (void)triggerAppBannerEvent:(NSString *)key value:(NSString *)value {
    [CPAppBannerModule triggerEvent:key value:value];
}

+ (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    [CPAppBannerModule setBannerOpenedCallback:callback];
}

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    NSLog(@"CleverPush: didReceiveNotificationExtensionRequest");
    
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    NSDictionary* payload = request.content.userInfo;
    NSDictionary* notification = [payload valueForKey:@"notification"];
    
    [self handleNotificationReceived:payload isActive:NO];
    
    // badge count
    [self updateBadge:replacementContent];
    
    // rich notifications
    if (notification != nil) {
        bool isCarousel = [notification valueForKey:@"carouselEnabled"] != nil && ![[notification valueForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification valueForKey:@"carouselItems"] != nil && ![[notification valueForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification valueForKey:@"carouselEnabled"] boolValue];
        
        [self addActionButtonsToNotificationRequest:request
                                        withPayload:payload
                     withMutableNotificationContent:replacementContent];
        
        if (isCarousel) {
            NSLog(@"CleverPush: appending carousel medias");
            [self addCarouselAttachments:notification toContent:replacementContent];
        } else {
            NSString* mediaUrl = [notification valueForKey:@"mediaUrl"];
            if (![mediaUrl isKindOfClass:[NSNull class]]) {
                NSLog(@"CleverPush: appending media: %@", mediaUrl);
                [self addAttachments:mediaUrl toContent:replacementContent];
            }
        }
    }
    
    return replacementContent;
}

+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    NSLog(@"CleverPush: serviceExtensionTimeWillExpireRequest");
    
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    // badge count
    [self updateBadge:replacementContent];
    
    NSDictionary* payload = request.content.userInfo;
    
    [self addActionButtonsToNotificationRequest:request
                                    withPayload:payload
                 withMutableNotificationContent:replacementContent];
    
    return replacementContent;
}

+ (void)addActionButtonsToNotificationRequest:(UNNotificationRequest*)request
                                  withPayload:(NSDictionary*)payload
               withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    if (request.content.categoryIdentifier && ![request.content.categoryIdentifier isEqualToString:@""]) {
        return;
    }
    
    NSDictionary* notification = [payload valueForKey:@"notification"];
    bool isCarousel = notification != nil && [notification valueForKey:@"carouselEnabled"] != nil && ![[notification valueForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification valueForKey:@"carouselItems"] != nil && ![[notification valueForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification valueForKey:@"carouselEnabled"] boolValue];
    
    NSArray* actions = [notification objectForKey:@"actions"];
    
    NSMutableArray* actionArray = [NSMutableArray new];
    
    NSMutableSet<UNNotificationCategory*>* allCategories = CPNotificationCategoryController.sharedInstance.existingCategories;
    
    if (isCarousel) {
        replacementContent.categoryIdentifier = @"carousel";
        [[CPNotificationCategoryController sharedInstance] carouselCategory];
        
    } else if ([actions isKindOfClass:[NSNull class]] || !actions || [actions count] == 0) {
        return;
        
    } else {
        [actions enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
            UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:[NSString stringWithFormat: @"%@", @(idx)]
                                                                                title:item[@"title"]
                                                                              options:UNNotificationActionOptionForeground];
            [actionArray addObject:action];
        }];
        
        NSString* newCategoryIdentifier = [CPNotificationCategoryController.sharedInstance registerNotificationCategoryForNotificationId:[payload valueForKeyPath:@"notification._id"]];
        
        UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:newCategoryIdentifier
                                                                                  actions:actionArray
                                                                        intentIdentifiers:@[]
                                                                                  options:UNNotificationCategoryOptionCustomDismissAction];
        
        replacementContent.categoryIdentifier = newCategoryIdentifier;
        
        if (allCategories) {
            NSMutableSet<UNNotificationCategory*>* newCategorySet = [NSMutableSet new];
            for (UNNotificationCategory *existingCategory in allCategories) {
                if (![existingCategory.identifier isEqualToString:newCategoryIdentifier])
                    [newCategorySet addObject:existingCategory];
            }
            
            [newCategorySet addObject:category];
            allCategories = newCategorySet;
        } else {
            allCategories = [[NSMutableSet alloc] initWithArray:@[category]];
        }
    }
    
    [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:allCategories];
    
    allCategories = CPNotificationCategoryController.sharedInstance.existingCategories;
}

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
    if ([[processInfo processName] isEqualToString:@"IBDesignablesAgentCocoaTouch"] || [[processInfo processName] isEqualToString:@"IBDesignablesAgent-iOS"]) {
        return;
    }
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.0")) {
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    BOOL existing = injectSelector([CleverPushAppDelegate class], @selector(cleverPushLoadedTagSelector:), self, @selector(cleverPushLoadedTagSelector:));
    if (existing) {
        return;
    }
    
    injectToProperClass(@selector(setCleverPushDelegate:), @selector(setDelegate:), @[], [CleverPushAppDelegate class], [UIApplication class]);
    
#pragma clang diagnostic pop
    
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



