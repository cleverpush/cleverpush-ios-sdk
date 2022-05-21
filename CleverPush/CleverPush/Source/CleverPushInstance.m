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
#import <UIKit/UIKit.h>

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
#import "CPChannelTag.h"
#import "NSDictionary+SafeExpectations.h"
#endif

@implementation CPNotificationReceivedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [CPNotification initWithJson:[[_payload dictionaryForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload dictionaryForKey:@"subscription"] mutableCopy]];
    }
    return self;
}

@end

@implementation CPNotificationOpenedResult

- (instancetype)initWithPayload:(NSDictionary *)inPayload action:(NSString*)action {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [CPNotification initWithJson:[[_payload dictionaryForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload dictionaryForKey:@"subscription"] mutableCopy]];
        _action = action;
    }
    return self;
}

@end
@class CPChannelTag;

@interface CPPendingCallbacks : NSObject
@property CPResultSuccessBlock successBlock;
@property CPFailureBlock failureBlock;

@end

@implementation CPPendingCallbacks

@end

@implementation CleverPushInstance

NSString * const CLEVERPUSH_SDK_VERSION = @"1.18.0";

static BOOL registeredWithApple = NO;
static BOOL startFromNotification = NO;
static BOOL autoClearBadge = YES;
static BOOL incrementBadge = NO;
static BOOL showNotificationsInForeground = YES;
static BOOL autoRegister = YES;
static BOOL registrationInProgress = false;
static BOOL ignoreDisabledNotificationPermission = NO;
static const int secDifferenceAtVeryFirstTime = 0;
static const int validationSeconds = 3600;
static const int maximumNotifications = 100;


static NSString* channelId;
static NSString* lastNotificationReceivedId;
static NSString* lastNotificationOpenedId;
static NSDictionary* channelConfig;
static CleverPushInstance* singleInstance = nil;

NSDate* lastSync;
NSString* subscriptionId;
NSString* deviceToken;
NSString* currentPageUrl;
NSString* apiEndpoint = @"https://api.cleverpush.com";
NSArray* appBanners;
NSArray* channelTopics;

NSMutableArray* pendingChannelConfigListeners;
NSMutableArray* pendingSubscriptionListeners;
NSMutableArray* pendingTrackingConsentListeners;
NSMutableArray* subscriptionTags;

NSMutableDictionary* autoAssignSessionsCounted;
UIBackgroundTaskIdentifier mediaBackgroundTask;
WKWebView* currentAppBannerWebView;
UIColor* brandingColor;
UIColor* normalTintColor = nil;
UIColor* chatBackgroundColor;
UIWindow* topicsDialogWindow;

CPChatView* currentChatView;
CPStoryView* currentStoryView;
CPResultSuccessBlock cpTokenUpdateSuccessBlock;
CPFailureBlock cpTokenUpdateFailureBlock;
CPHandleNotificationOpenedBlock handleNotificationOpened;
CPHandleNotificationReceivedBlock handleNotificationReceived;
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
DWAlertController *channelTopicsPicker;
CPNotificationOpenedResult* pendingOpenedResult = nil;
CPNotificationReceivedResult* pendingDeliveryResult = nil;

BOOL pendingChannelConfigRequest = NO;
BOOL pendingAppBannersRequest = NO;
BOOL channelTopicsPickerVisible = NO;
BOOL developmentMode = NO;
BOOL trackingConsentRequired = NO;
BOOL hasTrackingConsent = NO;
BOOL hasWebViewOpened = NO;
BOOL hasTrackingConsentCalled = NO;
BOOL handleSubscribedCalled = NO;

int sessionVisits;
long sessionStartedTimestamp;
double channelTopicsPickerShownAt;
id currentAppBannerUrlOpenedCallback;

static id isNil(id object) {
    return object ?: [NSNull null];
}

- (NSString*)channelId {
    return channelId;
}

- (NSString*)subscriptionId {
    return subscriptionId;
}

- (void)setTrackingConsentRequired:(BOOL)required {
    trackingConsentRequired = required;
}

- (void)setTrackingConsent:(BOOL)consent {
    hasTrackingConsentCalled = YES;
    hasTrackingConsent = consent;

    if (hasTrackingConsent) {
        [self fireTrackingConsentListeners];
    } else {
        pendingTrackingConsentListeners = [NSMutableArray new];
    }
}

- (void)enableDevelopmentMode {
    developmentMode = YES;
    NSLog(@"CleverPush: ! SDK is running in development mode. Only use this while testing !");
}

- (BOOL)isDevelopmentModeEnabled {
    return developmentMode;
}

- (BOOL)startFromNotification {
    BOOL val = startFromNotification;
    startFromNotification = NO;
    return val;
}

#pragma mark - methods to initialize SDK
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    return [self initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

#pragma mark - Common function to initialize SDK and sync data to NSUserDefaults
- (id)initWithLaunchOptions:(NSDictionary*)launchOptions
                  channelId:(NSString*)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback
               autoRegister:(BOOL)autoRegisterParam {
    [self setSubscribeHandler:subscribedCallback];
    handleNotificationReceived = receivedCallback;
    handleNotificationOpened = openedCallback;
    autoRegister = autoRegisterParam;
    brandingColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    channelConfig = nil;
    pendingChannelConfigListeners = [[NSMutableArray alloc] init];
    pendingSubscriptionListeners = [[NSMutableArray alloc] init];
    pendingTrackingConsentListeners = [[NSMutableArray alloc] init];
    autoAssignSessionsCounted = [[NSMutableDictionary alloc] init];
    subscriptionTags = [[NSMutableArray alloc] init];

    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
        if (pendingOpenedResult && handleNotificationOpened) {
            handleNotificationOpened(pendingOpenedResult);
        }
        if (pendingDeliveryResult && handleNotificationReceived) {
            handleNotificationReceived(pendingDeliveryResult);
        }
    }

    if (self) {
        if (newChannelId) {
            channelId = newChannelId;
        } else {
            channelId = [self getChannelIdFromBundle];
        }
        
        if (channelId == nil) {
            channelId  = [self getChannelIdFromUserDefault];
        } else if ([self isChannelIdChanged:channelId]) {
            [self addOrUpdateChannelId:channelId];
            [self clearSubscriptionData];
        }
        
        if (!channelId) {
            NSLog(@"CleverPush: Channel ID not specified, trying to fetch config via Bundle Identifier...");
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self getChannelConfig:^(NSDictionary* channelConfig) {
                    if (!channelId) {
                        NSLog(@"CleverPush: Initialization stopped - No Channel ID available");
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self initWithChannelId];
                    });
                }];
            });
            NSLog(@"CleverPush: Got Channel ID, initializing");
        } else {
            [self initWithChannelId];
        }
    }

    if ([self getAutoClearBadge]) {
        [self clearBadge:false];
    }

    return self;
}

#pragma mark - Define the rootview controller of the UINavigation-Stack
- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)getTopViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)viewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navContObj = (UINavigationController*)viewController;
        return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
    } else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        UIViewController* presentedViewController = viewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        for (UIView *view in [viewController.view subviews]) {
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]]) {
                if ([(UIViewController *)subViewController presentedViewController] && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

#pragma mark - syncSubscription by calling initWithChannelId.
- (void)initWithChannelId {
    NSLog(@"CleverPush: initializing SDK %@ with channelId: %@", CLEVERPUSH_SDK_VERSION, channelId);
    
    UIApplication* sharedApp = [UIApplication sharedApplication];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    subscriptionId = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
    deviceToken = [userDefaults stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
    if (([sharedApp respondsToSelector:@selector(currentUserNotificationSettings)])) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        registeredWithApple = [sharedApp currentUserNotificationSettings].types != (NSUInteger)nil;
#pragma clang diagnostic pop
    } else {
        registeredWithApple = deviceToken != nil;
    }

    [self incrementAppOpens];

    if (autoRegister && ![self getUnsubscribeStatus]) {
        [self autoSubscribeWithDelays];
    }

    if (subscriptionId != nil) {
        if (![self notificationsEnabled] && !ignoreDisabledNotificationPermission) {
            NSLog(@"CleverPush: notification authorization revoked, unsubscribing");
            [self unsubscribe];
        } else if ([self shouldSync]) {
            NSLog(@"CleverPush: syncSubscription called from initWithChannelId");
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:10.0f];
        } else {
            if ([self getSubscribeHandler] && ![self getHandleSubscribedCalled]) {
                [self getSubscribeHandler](subscriptionId);
                [self setHandleSubscribedCalled:YES];
            }
            if (handleSubscribedInternal) {
                handleSubscribedInternal(subscriptionId);
            }
        }
    }

    [self initFeatures];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)initTopicsDialogData:(NSDictionary*)config syncToBackend:(BOOL)syncToBackend {
    NSLog(@"initTopicsDialogData");
    NSArray* channelTopics = [config arrayForKey:@"channelTopics"];
    if (channelTopics != nil && [channelTopics count] > 0) {
        NSArray* topics = [self getSubscriptionTopics];
        
        if (!topics || [topics count] == 0) {
            NSMutableArray* selectedTopicIds = [[NSMutableArray alloc] init];
            for (id channelTopic in channelTopics) {
                if (channelTopic != nil && ([channelTopic objectForKey:@"defaultUnchecked"] == nil || ![[channelTopic objectForKey:@"defaultUnchecked"] boolValue])) {
                    [selectedTopicIds addObject:[channelTopic objectForKey:@"_id"]];
                }
            }
            if ([selectedTopicIds count] > 0) {
                if (syncToBackend) {
                    [self setSubscriptionTopics:selectedTopicIds];
                } else {
                    [self setDefaultCheckedTopics:selectedTopicIds];
                }
            }
        }
    }
}

#pragma mark - update the user defaults value of selected Topics Dialog.
- (void)setDefaultCheckedTopics:(NSMutableArray*)topics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger topicsVersion = [userDefaults integerForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
    if (!topicsVersion) {
        topicsVersion = 1;
    } else {
        topicsVersion += 1;
    }
    [userDefaults setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [userDefaults setInteger:topicsVersion forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
    [userDefaults synchronize];
}

#pragma mark - reset 'CleverPush_APP_BANNER_VISIBLE' value of user default when application goint to terminate.
- (void)applicationWillTerminate {
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - clear Badge count and start tracking the session when application goes to the Foreground.
- (void)applicationWillEnterForeground API_AVAILABLE(ios(10.0)) {
    [self updateBadge:nil];
    [self trackSessionStart];
    [CPAppBannerModule initSession:channelId afterInit:YES];

    if (subscriptionId != nil && ![self notificationsEnabled] && !ignoreDisabledNotificationPermission) {
        NSLog(@"CleverPush: notification authorization revoked, unsubscribing");
        [self unsubscribe];
    }
}

#pragma mark - clear Badge count and start tracking the session when application goes to the Background.
- (void)applicationDidEnterBackground API_AVAILABLE(ios(10.0)) {
    [self updateBadge:nil];
    [self trackSessionEnd];
}

#pragma mark - Initialised Features.
- (void)initFeatures {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self showTopicDialogOnNewAdded];
        [self initAppReview];
        
        [CPAppBannerModule initBannersWithChannel:channelId showDrafts:developmentMode fromNotification:NO];
        [CPAppBannerModule initSession:channelId afterInit:NO];
    });
}

#pragma mark - Initialised AppReviews.
- (void)initAppReview {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil && [channelConfig objectForKey:@"appReviewEnabled"]) {
            NSString* iosStoreId = [channelConfig stringForKey:@"iosStoreId"];
            
            if ([userDefaults objectForKey:CLEVERPUSH_APP_REVIEW_SHOWN_KEY]) {
                // already shown
                return;
            }
            
            int appReviewOpens = (int)[[channelConfig objectForKey:@"appReviewOpens"] integerValue];
            if (!appReviewOpens) {
                appReviewOpens = 0;
            }
            int appReviewDays = (int)[[channelConfig objectForKey:@"appReviewDays"] integerValue];
            if (!appReviewDays) {
                appReviewDays = 0;
            }
            int appReviewSeconds = (int)[[channelConfig objectForKey:@"appReviewSeconds"] integerValue];
            if (!appReviewSeconds) {
                appReviewSeconds = 0;
            }
            NSInteger currentAppDays = [userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY] ? [self daysBetweenDate:[userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY] andDate:[NSDate date]] : 0;
            
            NSString *appReviewTitle = [channelConfig stringForKey:@"appReviewTitle"];
            if (!appReviewTitle) {
                appReviewTitle = @"Do you like our app?";
            }
            
            NSString *appReviewYes = [channelConfig stringForKey:@"appReviewYes"];
            if (!appReviewYes) {
                appReviewYes = @"Yes";
            }
            
            NSString *appReviewNo = [channelConfig stringForKey:@"appReviewNo"];
            if (!appReviewNo) {
                appReviewNo = @"No";
            }
            
            NSString *appReviewFeedbackTitle = [channelConfig stringForKey:@"appReviewFeedbackTitle"];
            if (!appReviewFeedbackTitle) {
                appReviewFeedbackTitle = @"Do you want to tell us what you do not like?";
            }
            
            NSString *appReviewEmail = [channelConfig stringForKey:@"appReviewEmail"];
            
            if ([self getAppOpens] >= appReviewOpens && currentAppDays >= appReviewDays) {
                NSLog(@"CleverPush: showing app review alert");
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * appReviewSeconds);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    if ([userDefaults objectForKey:CLEVERPUSH_APP_REVIEW_SHOWN_KEY]) {
                        return;
                    }
                    
                    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_APP_REVIEW_SHOWN_KEY];
                    [userDefaults synchronize];
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:appReviewTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:appReviewYes style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
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
                                NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
                                NSString* model = [CPUtils deviceName];
                                NSString *bodyData = [NSString stringWithFormat:@"• OS: %@ • OS Version: %@ • Manufacturer: %@ • Device: %@ • Model: %@", UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion, @"Apple", UIDevice.currentDevice.systemName, model];
                                NSString *recipients = [NSString stringWithFormat:@"mailto:%@?subject=%@", appReviewEmail,appName];
                                NSString *body = [NSString stringWithFormat:@"&body=%@", bodyData];
                                NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
                                email = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                
                                if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
                                    if (@available(iOS 10.0, *)) {
                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email] options:@{} completionHandler:^(BOOL success) {
                                            if (!success) {
                                                NSLog(@"CleverPush: failed to open mail app: %@", email);
                                            }
                                        }];
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
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

#pragma mark - daysBetweenDate(instance method and class method)
- (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    NSDate *fromDate;
    NSDate *toDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:NULL forDate:toDateTime];
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
    return [difference day];
}

#pragma mark - determine the last sync and update the data on the next sync date
- (BOOL)shouldSync {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    lastSync = [userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY];
    NSDate* nextSync = [NSDate date];
    if (lastSync) {
        nextSync = [lastSync dateByAddingTimeInterval:3*24*60*60]; // 3 days after last sync
    }
    NSLog(@"CleverPush: next sync: %@", nextSync);
    return [nextSync compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark - fireChannelConfigListeners.
- (void)fireChannelConfigListeners {
    pendingChannelConfigRequest = NO;
    
    for (void (^listener)(NSDictionary *) in pendingChannelConfigListeners) {
        // check if listener and channelConfig are non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener && channelConfig) {
            __strong void (^callbackBlock)(NSDictionary *) = listener;
            callbackBlock(channelConfig);
        }
    }
    pendingChannelConfigListeners = [NSMutableArray new];
}

#pragma mark - API call and get the data of the specific Channel.
- (void)getChannelConfig:(void(^)(NSDictionary *))callback {
    if (channelConfig) {
        callback(channelConfig);
        return;
    }
    
    [pendingChannelConfigListeners addObject:callback];
    if (pendingChannelConfigRequest) {
        return;
    }
    pendingChannelConfigRequest = YES;
    
    NSString *configPath = @"";
    if ([self channelId] != NULL) {
        configPath = [NSString stringWithFormat:@"channel/%@/config?platformName=iOS", channelId];
        if ([self isDevelopmentModeEnabled]) {
            configPath = [NSString stringWithFormat:@"%@&t=%f", configPath, NSDate.date.timeIntervalSince1970];
        }
        [self getChannelConfigFromChannelId:configPath];
    } else {
        configPath = [NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", [self getBundleName]];
        [self getChannelConfigFromBundleId:configPath];
    }
}
- (NSString*)getBundleName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark - getSubscriptionId.
- (void)getSubscriptionId:(void(^)(NSString *))callback {
    if (subscriptionId) {
        callback(subscriptionId);
    } else {
        [pendingSubscriptionListeners addObject:[callback copy]];
    }
}

- (void)setSubscriptionId:(NSString *)newSubscriptionId {
    subscriptionId = newSubscriptionId;
}

- (NSString*)getSubscriptionId {
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

#pragma mark - perform on main thread.
- (void)ensureMainThreadSync:(dispatch_block_t) onMainBlock {
    if ([NSThread isMainThread]) {
        onMainBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), onMainBlock);
    }
}

#pragma mark - Based on the trackingConsentRequired and hasTrackingConsent Triggered this method
- (void)fireTrackingConsentListeners {
    for (void (^listener)(void *) in pendingTrackingConsentListeners) {
        // check if listener is non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener) {
#pragma clang diagnostic ignored "-Wstrict-prototypes"
            __strong void (^callbackBlock)() = listener;
#pragma clang diagnostic pop
            callbackBlock();
        }
    }
    pendingTrackingConsentListeners = [NSMutableArray new];
}

- (void)waitForTrackingConsent:(void(^)(void))callback {
    if (![self getTrackingConsentRequired] || [self getHasTrackingConsent]) {
        callback();
        return;
    }
    
    if (![self getHasTrackingConsentCalled]) {
        [self addCallbacksToTrackingConsentListeners:callback];
    }
}

- (void)addCallbacksToTrackingConsentListeners:(void(^)(void))callback {
    [pendingTrackingConsentListeners addObject:callback];
}

- (BOOL)getTrackingConsentRequired {
    return trackingConsentRequired;
}

- (BOOL)getHasTrackingConsent {
    return hasTrackingConsent;
}

- (BOOL)getHasTrackingConsentCalled {
    return hasTrackingConsentCalled;
}

#pragma mark - notificationsEnabled
- (BOOL)notificationsEnabled {
    __block BOOL isEnabled = NO;
    
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion) { .majorVersion = 10, .minorVersion = 0, .patchVersion = 0 }]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        if (@available(iOS 10.0, *)) {
            [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull notificationSettings) {
                if (notificationSettings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                    isEnabled = YES;
                }
                dispatch_semaphore_signal(sema);
            }];
        }
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
                } else {
                    isEnabled = NO;
                }
            }
        }];
    }
    
    return isEnabled;
}

#pragma mark - channel subscription

- (void)setConfirmAlertShown {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"channel/confirm-alert"]];
        
        NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 channelId, @"channelId",
                                 @"iOS", @"platformName",
                                 @"SDK", @"browserType",
                                 nil];

        if (
            channelConfig != nil
            && [channelConfig objectForKey:@"confirmAlertTestsEnabled"]
            && [[channelConfig objectForKey:@"confirmAlertTestsEnabled"] boolValue]
            && [channelConfig objectForKey:@"confirmAlertTestId"]
        ) {
            [dataDic setObject:[channelConfig objectForKey:@"confirmAlertTestId"] forKey:@"confirmAlertTestId"];
        }

        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:nil onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: /channel/confirm-alert request error %@", error);
        }];
    }];
}

- (void)subscribe {
    [self subscribe:nil];
}

- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock {
    [self subscribe:subscribedBlock failure:nil skipTopicsDialog:NO];
}

- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock {
    [self subscribe:subscribedBlock failure:failureBlock skipTopicsDialog:NO];
}

- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    [self subscribe:subscribedBlock failure:nil skipTopicsDialog:skipTopicsDialog];
}

- (void)subscribe:(CPHandleSubscribedBlock)subscribedBlock failure:(CPFailureBlock)failureBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    if (@available(iOS 10.0, *)) {
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
                    
                    if (granted || ignoreDisabledNotificationPermission) {
                        if (subscriptionId == nil) {
                            NSLog(@"CleverPush: syncSubscription called from subscribe");
                            [self performSelector:@selector(syncSubscription) withObject:nil];
                            
                            [self getChannelConfig:^(NSDictionary* channelConfig) {
                                if (channelConfig != nil && ([channelConfig objectForKey:@"confirmAlertHideChannelTopics"] == nil || ![[channelConfig objectForKey:@"confirmAlertHideChannelTopics"] boolValue])) {
                                    if (![self isSubscribed]) {
                                        [self initTopicsDialogData:channelConfig syncToBackend:YES];
                                    }
                                    
                                    if (!skipTopicsDialog) {
                                        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                                        [userDefaults setBool:YES forKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY];
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
                    } else if (failureBlock) {
                        failureBlock([NSError errorWithDomain:@"com.cleverpush" code:410 userInfo:@{NSLocalizedDescriptionKey:@"Can not subscribe because notifications have been disabled by the user. You can call CleverPush.setIgnoreDisabledNotificationPermission(true) to still allow subscriptions, e.g. for silent pushes."}]);
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
                
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] registerUserNotificationSettings:[uiUserNotificationSettings settingsForTypes:UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge categories:categories]];
                }
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            } else {
                // iOS < 8.0
            }
        }];
#pragma clang diagnostic pop
    }
}

- (void)autoSubscribeWithDelays {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (
            channelConfig != nil
            && [channelConfig objectForKey:@"confirmAlertSettingsEnabled"] != nil
            && [[channelConfig objectForKey:@"confirmAlertSettingsEnabled"] boolValue]
        ) {
            if (
                [channelConfig objectForKey:@"alertMinimumVisits"]
                && [self getAppOpens] <= [[channelConfig objectForKey:@"alertMinimumVisits"] intValue]
            ) {
                return;
            }
            
            if (
                [channelConfig objectForKey:@"alertTimeout"]
            ) {
                int milliseconds = [[channelConfig objectForKey:@"alertTimeout"] intValue];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * milliseconds),  dispatch_get_main_queue(), ^(void) {
                    [self subscribe];
                });
            } else {
                [self subscribe];
            }
        } else {
            [self subscribe];
        }
    }];
}

#pragma mark - update the userdefault value for key @"UNSUBSCRIBED" with the dynamic argument named status.
- (void)setUnsubscribeStatus:(BOOL)status {
    [[NSUserDefaults standardUserDefaults] setBool:status forKey:CLEVERPUSH_UNSUBSCRIBED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - get the userdefault value for key @"UNSUBSCRIBED" and prevent subscribe based on the boolean flag.
- (BOOL)getUnsubscribeStatus {
    return [[NSUserDefaults standardUserDefaults] boolForKey:CLEVERPUSH_UNSUBSCRIBED_KEY];
}

#pragma mark - Clear the previous channel data from the NSUserDefaults on a fresh login and session expired.
- (void)clearSubscriptionData {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setHandleSubscribedCalled:NO];
    [self setSubscriptionId:nil];
}

#pragma mark - unsubscribe
- (void)unsubscribe {
    [self unsubscribe:^(BOOL success) {
        if (success) {
            NSLog(@"CleverPush: unsubscribe success");
        } else {
            NSLog(@"CleverPush: unsubscribe failure");
        }
    }];
}

- (void)unsubscribe:(void(^)(BOOL))callback {
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
            [self setUnsubscribeStatus:YES];
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

#pragma mark - identify the channels being subscribed or not
- (BOOL)isSubscribed {
    BOOL isSubscribed = NO;
    if (subscriptionId && [self notificationsEnabled]) {
        isSubscribed = YES;
    }
    return isSubscribed;
}

#pragma mark - handle the notification failed
- (void)handleDidFailRegisterForRemoteNotification:(NSError*)err {
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

#pragma mark - register Device Token
- (void)registerDeviceToken:(id)newDeviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    if (subscriptionId == nil) {
        deviceToken = newDeviceToken;
        cpTokenUpdateSuccessBlock = successBlock;
        cpTokenUpdateFailureBlock = failureBlock;
        
        if (@available(iOS 10.0, *)) {
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
    
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isSubscriptionInProgress {
    return registrationInProgress;
}

- (void)setSubscriptionInProgress:(BOOL)progress {
    registrationInProgress = progress;
}

#pragma mark - Api call and fetch out the subscription data and sync
- (void)syncSubscription {
    if ([self isSubscriptionInProgress]) {
        NSLog(@"CleverPush: syncSubscription aborted - registration already in progress");
        return;
    }

    if (!deviceToken) {
        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
    }

    if (!deviceToken && !subscriptionId) {
        NSLog(@"CleverPush: syncSubscription aborted - no deviceToken and no subscriptionId available");
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];

    [self setSubscriptionInProgress:true];
    NSMutableURLRequest* request;
    request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* language = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
    if (!language) {
        language = [[[NSLocale preferredLanguages] firstObject] substringToIndex:2];
    }
    NSString* country = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
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

    if (
        channelConfig != nil
        && [channelConfig objectForKey:@"confirmAlertTestsEnabled"]
        && [[channelConfig objectForKey:@"confirmAlertTestsEnabled"] boolValue]
        && [channelConfig objectForKey:@"confirmAlertTestId"]
    ) {
        [dataDic setObject:[channelConfig objectForKey:@"confirmAlertTestId"] forKey:@"confirmAlertTestId"];
    }
    
    NSArray* topics = [self getSubscriptionTopics];
    if (topics != nil && [topics count] >= 0) {
        
        [dataDic setObject:topics forKey:@"topics"];
        NSInteger topicsVersion = [userDefaults integerForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
        if (topicsVersion) {
            [dataDic setObject:[NSNumber numberWithInteger:topicsVersion] forKey:@"topicsVersion"];
        } else {
            [dataDic setObject:@"1" forKey:@"topicsVersion"];
        }
    }
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    NSLog(@"CleverPush: syncSubscription Request data:%@ id:%@", dataDic, subscriptionId);
    
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        [self setSubscriptionInProgress:false];

        [self setUnsubscribeStatus:NO];
        [self updateDeselectFlag:NO];

        if ([results objectForKey:@"topics"] != nil) {
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:[results objectForKey:@"topics"] forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
            if ([results objectForKey:@"topicsVersion"] != nil) {
                [userDefaults setInteger:[[results objectForKey:@"topicsVersion"] integerValue] forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
            }
            [userDefaults synchronize];
        }
        
        if ([results objectForKey:@"id"] != nil) {
            if (!subscriptionId) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY];
            }
            subscriptionId = [results objectForKey:@"id"];
            [[NSUserDefaults standardUserDefaults] setObject:subscriptionId forKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if (handleSubscribed && ![self getHandleSubscribedCalled]) {
                handleSubscribed(subscriptionId);
                [self setHandleSubscribedCalled:YES];
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
        
        [self setSubscriptionInProgress:false];
    }];
}

#pragma mark - add Attachments to content
- (void)addAttachments:(NSString*)mediaUrl toContent:(UNMutableNotificationContent*)content  API_AVAILABLE(ios(10.0)) {
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
                if (@available(iOS 10.0, *)) {
                    UNNotificationAttachment* attachment = [UNNotificationAttachment attachmentWithIdentifier:@""
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
    
    content.attachments = unAttachments;
}

#pragma mark - add Carousel Attachments to the content on a rich notification
- (void)addCarouselAttachments:(NSDictionary*)notification toContent:(UNMutableNotificationContent*)content  API_AVAILABLE(ios(10.0)) {
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

#pragma mark - Handle silent notification
- (BOOL)handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)messageDict completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    BOOL startedBackgroundJob = NO;
    NSLog(@"CleverPush: handleSilentNotificationReceived");
    
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        [CleverPush handleNotificationReceived:messageDict isActive:NO];
    }
    
    return startedBackgroundJob;
}

- (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive {
    NSDictionary* notification = [messageDict dictionaryForKey:@"notification"];

    if (!notification) {
        return;
    }

    NSString* notificationId = [notification stringForKey:@"_id"];
    
    if ([CPUtils isEmpty:notificationId] || ([notificationId isEqualToString:lastNotificationReceivedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationReceivedId = notificationId;

    NSLog(@"CleverPush: handleNotificationReceived, isActive %@, Payload %@", @(isActive), messageDict);

    [self setNotificationDelivered:notification
                     withChannelId:[messageDict stringForKeyPath:@"channel._id"]
                withSubscriptionId:[messageDict stringForKeyPath:@"subscription._id"]
    ];

    if (isActive && notification != nil && [notification objectForKey:@"chatNotification"] != nil && ![[notification objectForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"chatNotification"] boolValue]) {
        
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

- (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive actionIdentifier:(NSString*)actionIdentifier {
    NSString* notificationId = [payload stringForKeyPath:@"notification._id"];
    NSDictionary* notification = [payload dictionaryForKey:@"notification"];
    NSString* action = actionIdentifier;

    if (!notification) {
        return;
    }

    if ([CPUtils isEmpty:notificationId] || ([notificationId isEqualToString:lastNotificationOpenedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationOpenedId = notificationId;
    
    if (action != nil && ([action isEqualToString:@"__DEFAULT__"] || [action isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])) {
        action = nil;
    }
    NSLog(@"CleverPush: handleNotificationOpened, %@, %@", action, payload);
    
    [self setNotificationClicked:notificationId
                   withChannelId:[payload stringForKeyPath:@"channel._id"]
              withSubscriptionId:[payload stringForKeyPath:@"subscription._id"]
                      withAction:action
    ];
    
    if ([self getAutoClearBadge]) {
        [self clearBadge:true];
    }
    if (@available(iOS 10.0, *)) {
        [self updateBadge:nil];
    } else {
        // Fallback on earlier versions
    }

    
    if (notification != nil && [notification objectForKey:@"chatNotification"] != nil && ![[notification objectForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"chatNotification"] boolValue]) {
        
        if (currentChatView != nil) {
            [currentChatView loadChat];
        }
    }
    if (notification != nil && [notification objectForKey:@"appBanner"] != nil && ![[notification objectForKey:@"appBanner"] isKindOfClass:[NSNull class]]) {
        [self showAppBanner:[notification valueForKey:@"appBanner"] channelId:[payload stringForKeyPath:@"channel._id"] notificationId:notificationId];
    }
    
    CPNotificationOpenedResult * result = [[CPNotificationOpenedResult alloc] initWithPayload:payload action:action];
    
    if (!channelId) { // not init
        pendingOpenedResult = result;
    }
    if (!handleNotificationOpened) {
        if (hasWebViewOpened) {
            if (notification != nil && [notification objectForKey:@"url"] != nil && [[notification objectForKey:@"url"] length] != 0 && ![[notification objectForKey:@"url"] isKindOfClass:[NSNull class]]) {
                NSURL *url = [NSURL URLWithString:[notification objectForKey:@"url"]];
                [CPUtils openSafari:url];
            }
        }
        return;
    }
    
    handleNotificationOpened(result);
}

#pragma mark - Update counts of the notification badge
- (void)updateBadge:(UNMutableNotificationContent*)replacementContent  API_AVAILABLE(ios(10.0)) {
    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    if ([userDefaults boolForKey:CLEVERPUSH_INCREMENT_BADGE_KEY]) {
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
- (void)processLocalActionBasedNotification:(UILocalNotification*)notification actionIdentifier:(NSString*)actionIdentifier {
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

#pragma mark - Api call to recognise notification has been delivered or not
- (void)setNotificationDelivered:(NSDictionary*)notification {
    [self setNotificationDelivered:notification withChannelId:channelId withSubscriptionId:[self getSubscriptionId]];
}

- (void)setNotificationDelivered:(NSDictionary*)notification withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId {
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
    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    
    [userDefaults setObject:notificationId forKey:CLEVERPUSH_LAST_NOTIFICATION_ID_KEY];
    [userDefaults synchronize];
    
    NSMutableDictionary *notificationMutable = [notification mutableCopy];
    [notificationMutable removeObjectsForKeys:[notification allKeysForObject:[NSNull null]]];
    if (![[notificationMutable objectForKey:@"createdAt"] isKindOfClass:[NSString class]] || [[notificationMutable objectForKey:@"createdAt"] length] == 0) {
        [notificationMutable setObject:[CPUtils getCurrentDateString] forKey:@"createdAt"];
    }
    
    NSMutableArray* notifications = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:CLEVERPUSH_NOTIFICATIONS_KEY]];
    if (!notifications) {
        notifications = [[NSMutableArray alloc] init];
    }
    [notifications addObject:notificationMutable];
    NSArray *notificationsArray = [NSArray arrayWithArray:notifications];
    if (notificationsArray.count > maximumNotifications) {
        notificationsArray = [notificationsArray subarrayWithRange:NSMakeRange(notificationsArray.count - maximumNotifications, maximumNotifications)];
    }
    [userDefaults setObject:notificationsArray forKey:CLEVERPUSH_NOTIFICATIONS_KEY];
    [userDefaults synchronize];
}

#pragma mark - Api call to recognise notification has been clicked or not
- (void)setNotificationClicked:(NSString*)notificationId {
    [self setNotificationClicked:notificationId withChannelId:channelId withSubscriptionId:[self getSubscriptionId] withAction:nil];
}

- (void)setNotificationClicked:(NSString*)notificationId withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId withAction:(NSString*)action {
    
    NSLog(@"CleverPush: setNotificationClicked notification:%@, subscription:%@, channel:%@, action:%@", notificationId, channelId, subscriptionId, action);
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/clicked"];
    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    channelId, @"channelId",
                                    notificationId, @"notificationId",
                                    subscriptionId, @"subscriptionId",
                                    nil];
    
    if (action != nil) {
        [dataDic setObject:action forKey:@"action"];
    }
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
}

#pragma mark - Removed badge count from the app icon while open-up an application by tapped on the notification
- (BOOL)clearBadge:(BOOL)fromNotificationOpened {
    bool wasSet = [UIApplication sharedApplication].applicationIconBadgeNumber > 0;
    if ((!(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) && fromNotificationOpened) || wasSet) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

        NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
        if ([userDefaults objectForKey:CLEVERPUSH_BADGE_COUNT_KEY] != nil) {
            [userDefaults setInteger:0 forKey:CLEVERPUSH_BADGE_COUNT_KEY];
            [userDefaults synchronize];
        }
        
    }
    return wasSet;
}

- (NSString*)getDeviceToken {
    return deviceToken;
}

#pragma mark - Removed space from 32bytes and convert token in to string.
- (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
    // deviceToken = <4618be8f 70f2a10f ce0e7435 5528fac9 86221163 94b282b1 553afc3c e31ec99c>
    NSUInteger length = deviceToken.length;
    if (length == 0) {
        return nil;
    }
    const unsigned char *buffer = deviceToken.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length * 2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    // hexString = 4618be8f70f2a10fce0e74355528fac98622116394b282b1553afc3ce31ec99cc>
    return [hexString copy];
}

#pragma mark - Initialised notification.
- (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)deviceToken {
    NSString* parsedDeviceToken = [self stringFromDeviceToken:deviceToken];
    NSLog(@"CleverPush: %@", [NSString stringWithFormat:@"Device Registered with Apple: %@", parsedDeviceToken]);
    [self registerDeviceToken:parsedDeviceToken onSuccess:^(NSDictionary* results) {
        NSLog(@"CleverPush: %@", [NSString stringWithFormat: @"Device Registered with CleverPush: %@", subscriptionId]);
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush: %@", [NSString stringWithFormat: @"Error in CleverPush Registration: %@", error]);
    }];
}

#pragma mark - Generalised Api call.
- (void)enqueueRequest:(NSURLRequest*)request onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    NSLog(@"CleverPush: HTTP -> %@ %@", [request HTTPMethod], [request URL].absoluteString);
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (successBlock != nil || failureBlock != nil) {
            [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
        }
    }] resume];
}

- (void)handleJSONNSURLResponse:(NSURLResponse*) response data:(NSData*) data error:(NSError*) error onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    NSHTTPURLResponse* HTTPResponse = (NSHTTPURLResponse*)response;
    NSInteger statusCode = [HTTPResponse statusCode];
    NSError* jsonError = nil;
    NSMutableDictionary* innerJson;
    
    if (data != nil && ![CPUtils isEmpty:data]) {
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

- (void)addSubscriptionTags:(NSArray*)tagIds {
    [self addSubscriptionTags:tagIds callback:nil];
}

- (void)removeSubscriptionTags:(NSArray*)tagIds {
    [self removeSubscriptionTags:tagIds callback:nil];
}

- (void)addSubscriptionTags:(NSArray*)tagIds callback:(void(^)(NSArray *))callback {
    dispatch_group_t group = dispatch_group_create();
    for (NSString* tagId in tagIds) {
        dispatch_group_enter(group);
        [self addSubscriptionTag:tagId callback:^(NSString *tagId) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (callback) {
            callback([self getSubscriptionTags]);
        }
    });
}

- (void)removeSubscriptionTags:(NSArray*)tagIds callback:(void(^)(NSArray *))callback{
    dispatch_group_t group = dispatch_group_create();
    for (NSString* tagId in tagIds) {
        dispatch_group_enter(group);
        [self removeSubscriptionTag:tagId callback:^(NSString *tagId) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (callback) {
            callback([self getSubscriptionTags]);
        }
    });
}

- (void)removeSubscriptionTag:(NSString*)tagId {
    [self removeSubscriptionTag:tagId callback:nil];
}

- (void)addSubscriptionTag:(NSString*)tagId {
    [self addSubscriptionTag:tagId callback:nil];
}

- (void)addSubscriptionTag:(NSString*)tagId callback:(void (^)(NSString *))callback {
    [self waitForTrackingConsent:^{
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY]];
        
        if ([subscriptionTags containsObject:tagId]) {
            if (callback) {
                callback(tagId);
            }
            return;
        }
        [self addSubscriptionTagstoServer:tagId callback:^(NSString *tagId) {
            if (callback) {
                callback(tagId);
            }
        }];
    }];
}

- (void)addSubscriptionTagstoServer:(NSString*)tagId callback:(void (^)(NSString *))callback{
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
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:subscriptionTags forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
            [userDefaults synchronize];
            
            if (callback) {
                callback(tagId);
            }
            
        } onFailure:nil];
    });
}

#pragma mark - Remove subscription tag by calling api. subscription/untag
- (void)removeSubscriptionTag:(NSString*)tagId callback:(void (^)(NSString *))callback {
    [self waitForTrackingConsent:^{
        [self removeSubscriptionTagsfromServer:tagId callback:^(NSString *tag) {
            if (callback) {
                callback(tagId);
            }
        }];
    }];
}

- (void)removeSubscriptionTagsfromServer:(NSString *)tagId callback:(void (^)(NSString *))callback {
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
            subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY]];
            
            if (!subscriptionTags) {
                subscriptionTags = [[NSMutableArray alloc] init];
            }
            [subscriptionTags removeObject:tagId];
            
            [userDefaults setObject:subscriptionTags forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
            [userDefaults synchronize];
            
            if (callback) {
                callback(tagId);
            }
            
        } onFailure:nil];
    });
}

#pragma mark - Set subscription attribute tag by calling api. subscription/attribute
- (void)setSubscriptionAttribute:(NSString*)attributeId value:(NSString*)value {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
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
                NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                if (!subscriptionAttributes) {
                    subscriptionAttributes = [[NSMutableDictionary alloc] init];
                }
                [subscriptionAttributes setObject:value forKey:attributeId];
                [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                [userDefaults synchronize];
            } onFailure:nil];
        });
    }];
}

#pragma mark - Push subscription array attribute value.
- (void)pushSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/attribute/push-value"];
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
                NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                if (!subscriptionAttributes) {
                    subscriptionAttributes = [[NSMutableDictionary alloc] init];
                }
                
                NSMutableArray *arrayValue = [subscriptionAttributes objectForKey:attributeId];
                if (!arrayValue) {
                    arrayValue = [NSMutableArray new];
                } else {
                    arrayValue = [arrayValue mutableCopy];
                }
                [arrayValue addObject:value];
                
                [subscriptionAttributes setObject:arrayValue forKey:attributeId];
                [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                [userDefaults synchronize];
            } onFailure:nil];
        });
    }];
}

#pragma mark - Pull subscription array attribute value.
- (void)pullSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/attribute/pull-value"];
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
                NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                if (!subscriptionAttributes) {
                    subscriptionAttributes = [[NSMutableDictionary alloc] init];
                }
                
                NSMutableArray *arrayValue = [subscriptionAttributes objectForKey:attributeId];
                if (!arrayValue) {
                    arrayValue = [NSMutableArray new];
                } else {
                    arrayValue = [arrayValue mutableCopy];
                }
                [arrayValue removeObject:value];
                
                [subscriptionAttributes setObject:arrayValue forKey:attributeId];
                [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                [userDefaults synchronize];
            } onFailure:nil];
        });
    }];
}

#pragma mark - Check if subscription array attribute has a value.
- (BOOL)hasSubscriptionAttributeValue:(NSString*)attributeId value:(NSString*)value {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
    if (!subscriptionAttributes) {
        return NO;
    }
    NSMutableArray *arrayValue = [subscriptionAttributes objectForKey:attributeId];
    if (!arrayValue) {
        return NO;
    }
    return [arrayValue containsObject:value];
}

#pragma mark - Retrieving all the available tags from the channelConfig
- (NSArray*)getAvailableTags {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSArray* channelTags = nil;
    [self getAvailableTags:^(NSArray* channelTags_) {
        channelTags = channelTags_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return channelTags;
}

- (void)getAvailableTags:(void(^)(NSArray *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTags = [channelConfig arrayForKey:@"channelTags"];
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

#pragma mark - Retrieving all the available topics from the channelConfig
- (NSArray*)getAvailableTopics {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSArray* channelTopics = nil;
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return channelTopics;
}

- (void)getAvailableTopics:(void(^)(NSArray *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTopics = [channelConfig arrayForKey:@"channelTopics"];
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

#pragma mark - Retrieving all the available attributes from the channelConfig
- (NSDictionary*)getAvailableAttributes {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSDictionary* customAttributes = nil;
    [self getAvailableAttributes:^(NSDictionary* customAttributes_) {
        customAttributes = customAttributes_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return customAttributes;
}

- (void)getAvailableAttributes:(void(^)(NSDictionary *))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            callback([self getAvailableAttributesFromConfig:channelConfig]);
            return;
        }
        callback([[NSDictionary alloc] init]);
    }];
}

- (NSDictionary*)getAvailableAttributesFromConfig:(NSDictionary*)channelConfig{
    NSDictionary* customAttributes = [channelConfig dictionaryForKey:@"customAttributes"];
    if (customAttributes != nil) {
        return customAttributes;
    } else {
        return [[NSDictionary alloc] init];
    }
}

#pragma mark - Retrieving subscription tag which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TAGS"
- (NSArray*)getSubscriptionTags {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTags = [userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    if (!subscriptionTags) {
        return [[NSArray alloc] init];
    }
    return subscriptionTags;
}

#pragma mark - check the tagId exists in the subscriptionTags or not
- (BOOL)hasSubscriptionTag:(NSString*)tagId {
    return [[self getSubscriptionTags] containsObject:tagId];
}
- (BOOL)hasSubscriptionTopic:(NSString*)topicId {
    return [[self getSubscriptionTopics] containsObject:topicId];

}

#pragma mark - Retrieving subscription attributes which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_ATTRIBUTES"
- (NSDictionary*)getSubscriptionAttributes {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* subscriptionAttributes = [userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    if (!subscriptionAttributes) {
        return [[NSDictionary alloc] init];
    }
    return subscriptionAttributes;
}

- (NSString*)getSubscriptionAttribute:(NSString*)attributeId {
    return [[self getSubscriptionAttributes] objectForKey:attributeId];
}

#pragma mark - Update/Set subscription language which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_LANGUAGE"
- (void)setSubscriptionLanguage:(NSString *)language {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentLanguage = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
    if (!currentLanguage || (language && ![currentLanguage isEqualToString:language])) {
        [userDefaults setObject:language forKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        });
    }
}

#pragma mark - Update/Set subscription country which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_COUNTRY"
- (void)setSubscriptionCountry:(NSString *)country {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentCountry = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
    if (!currentCountry || (country && ![currentCountry isEqualToString:country])) {
        [userDefaults setObject:country forKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        });
    }
}

#pragma mark - Retrieving subscription topics which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TOPICS"
- (NSArray*)getSubscriptionTopics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTopics = [userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    if (!subscriptionTopics) {
        return [[NSArray alloc] init];
    }
    return subscriptionTopics;
}

#pragma mark - Check if the any topic is exists in the NSUserDefaults or not
- (BOOL)hasSubscriptionTopics {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTopics = [userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    return subscriptionTopics ? YES : NO;
}

#pragma mark - Update/Set subscription topics which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TOPICS"
- (void)setSubscriptionTopics:(NSMutableArray *)topics {
    [self setDefaultCheckedTopics:topics];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
    });
}

#pragma mark - Retrieving notifications which has been stored in NSUserDefaults by key "CleverPush_NOTIFICATIONS"
- (NSArray<CPNotification*>*)getNotifications {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    NSArray* notifications = [userDefaults arrayForKey:CLEVERPUSH_NOTIFICATIONS_KEY];
    if (!notifications) {
        return [[NSArray alloc] init];
    }
    return [self convertDictionariesToNotifications:notifications];
}

- (void)removeNotification:(NSString*)notificationId {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    if ([userDefaults objectForKey:CLEVERPUSH_NOTIFICATIONS_KEY] != nil) {
        NSArray* notifications = [userDefaults arrayForKey:CLEVERPUSH_NOTIFICATIONS_KEY];
        NSMutableArray *tempNotifications = [notifications mutableCopy];
        if ([notifications count] != 0) {
            for (NSDictionary * notification in notifications) {
                if ([[notification stringForKey:@"_id"] isEqualToString: notificationId])
                    [tempNotifications removeObject: notification];
            }
        }
        [userDefaults setObject:tempNotifications forKey:CLEVERPUSH_NOTIFICATIONS_KEY];
        [userDefaults synchronize];
    }
}

#pragma mark - Retrieving notifications based on the flag remote/local
- (void)getNotifications:(BOOL)combineWithApi callback:(void(^)(NSArray<CPNotification*>*))callback {
    [self getNotifications:combineWithApi limit:50 skip:0 callback:callback];
}

#pragma mark - Retrieving notifications based on the flag remote/local
- (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^)(NSArray<CPNotification*>*))callback {
    NSMutableArray<CPNotification*>* notifications = [[self getNotifications] mutableCopy];
    if (combineWithApi) {
        NSString *combinedURL = [self generateGetReceivedNotificationsPath:limit skip:skip];
        [self getReceivedNotificationsFromApi:combinedURL callback:^(NSArray *remoteNotifications) {
            for (NSDictionary *remoteNotification in remoteNotifications) {
                BOOL found = NO;
                for (CPNotification *localNotification in notifications) {
                    if (
                        [localNotification.id isEqualToString:[remoteNotification stringForKey:@"_id"]]
                        || [localNotification.tag isEqualToString:[remoteNotification stringForKey:@"_id"]]
                    ) {
                        found = YES;
                        break;
                    }
                }
                
                if (!found) {
                    CPNotification *remoteObject = [[CPNotification alloc] init];
                    remoteObject = [CPNotification initWithJson:remoteNotification];
                    [notifications addObject:remoteObject];
                }
            }
            
            if (callback) {
                NSArray *sortedNotifications = [self sortArrayOfObjectByDates:notifications basedOnKey:@"createdAt"];
                if (sortedNotifications.count > maximumNotifications) { 
                    sortedNotifications = [sortedNotifications subarrayWithRange:NSMakeRange(sortedNotifications.count - maximumNotifications, maximumNotifications)];
                    callback(sortedNotifications);
                } else {
                    callback(sortedNotifications);
                }
            }
        }];
    } else {
        if (callback) {
            callback([self convertDictionariesToNotifications:notifications]);
        }
    }
}

#pragma mark - Creating URL based on the topic dialogue and append the topicId's as a query parameter.
- (NSString *)generateGetReceivedNotificationsPath:(int)limit skip:(int)skip {
    NSString *path = [NSString stringWithFormat:@"channel/%@/received-notifications?limit=%d&skip=%d&", channelId, limit, skip];
    if ([self hasSubscriptionTopics]) {
        NSMutableArray* dynamicQueryParameters = [self getReceivedNotificationsQueryParameters];
        NSString* appendableQueryParameters = [dynamicQueryParameters componentsJoinedByString:@""];
        NSString *concatenatedURL = [NSString stringWithFormat:@"%@%@", path, appendableQueryParameters];
        return concatenatedURL;
    } else {
        return path;
    }
}

#pragma mark - Appending the topicId's as a query parameter.
- (NSMutableArray*)getReceivedNotificationsQueryParameters {
    NSMutableArray* subscriptionTopics = [self getSubscriptionTopics];
    NSMutableArray* dynamicQueryParameter = [NSMutableArray new];
    [subscriptionTopics enumerateObjectsUsingBlock: ^(id topic, NSUInteger index, BOOL *stop) {
        NSString *queryParameter = [NSString stringWithFormat: @"topics[]=%@&", topic];
        [dynamicQueryParameter addObject:queryParameter];
    }];
    return dynamicQueryParameter;
}

#pragma mark - Group array of object by dates.
- (NSArray*)sortArrayOfObjectByDates:(NSArray*)notifications basedOnKey:(NSString *)key {
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    NSArray *sortedEventArray = [notifications sortedArrayUsingDescriptors:sortDescriptors];
    return sortedEventArray;
}

#pragma mark - converting objects to CPNotification.
- (NSMutableArray*)convertDictionariesToNotifications:(NSArray*)notifications {
    NSMutableArray* resultNotifications = [NSMutableArray new];
    NSMutableArray* notificationIds = [NSMutableArray new];
    [notifications enumerateObjectsUsingBlock: ^(id objNotification, NSUInteger index, BOOL *stop) {
        CPNotification *notification = [CPNotification initWithJson:objNotification];
        if (![notificationIds containsObject:notification.id]) {
            [notificationIds addObject:notification.id];
            [resultNotifications addObject:notification];
        }
    }];
    return resultNotifications;
}

#pragma mark - Get the Notifications based on the topic dialog Id's.
- (void)getReceivedNotificationsFromApi:(NSString*)path callback:(void(^)(NSArray *))callback {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:path];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            if (callback) {
                if ([result arrayForKey:@"notifications"] && [result arrayForKey:@"notifications"] != nil && ![[result arrayForKey:@"notifications"] isKindOfClass:[NSNull class]]) {
                    callback([result arrayForKey:@"notifications"]);
                }
            }
        }
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed getting the notifications %@", error);
    }];
}

#pragma mark - Retrieving stories which has been seen by user and stored in NSUserDefaults by key "CleverPush_SEEN_STORIES"
- (NSArray*)getSeenStories {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* seenStories = [userDefaults arrayForKey:CLEVERPUSH_SEEN_STORIES_KEY];
    if (!seenStories) {
        return [[NSArray alloc] init];
    }
    return seenStories;
}

- (void)trackEvent:(NSString*)eventName {
    return [self trackEvent:eventName amount:nil];
}

- (void)trackEvent:(NSString*)eventName amount:(NSNumber*)amount {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSArray* channelEvents = [channelConfig arrayForKey:@"channelEvents"];
            if (channelEvents == nil) {
                NSLog(@"Event not found");
                return;
            }
            
            NSUInteger eventIndex = [channelEvents indexOfObjectWithOptions:NSEnumerationConcurrent
                                                                passingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *event = (NSDictionary*) obj;
                return event != nil && [[event stringForKey:@"name"] isEqualToString:eventName];
            }];
            if (eventIndex == NSNotFound) {
                NSLog(@"Event not found");
                return;
            }
            
            NSDictionary *event = [channelEvents objectAtIndex:eventIndex];
            NSString *eventId = [event stringForKey:@"_id"];
            
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

- (void)triggerFollowUpEvent:(NSString*)eventName {
    return [self triggerFollowUpEvent:eventName parameters:nil];
}

- (void)triggerFollowUpEvent:(NSString*)eventName parameters:(NSDictionary*)parameters {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self waitForTrackingConsent:^{
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/event"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     eventName, @"name",
                                     isNil(parameters), @"parameters",
                                     [self getSubscriptionId], @"subscriptionId",
                                     nil];
            
            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];
            
            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                
            } onFailure:nil];
        }];
    });
}

#pragma mark - auto Assign Tag Matches
- (void)autoAssignTagMatches:(CPChannelTag*)tag pathname:(NSString*)pathname params:(NSDictionary*)params callback:(void(^)(BOOL))callback {
    NSString* path = [tag autoAssignPath];
    if (path != nil) {
        if ([path isEqualToString:@"[EMPTY]"]) {
            path = @"";
        }
        if ([pathname rangeOfString:path options:NSRegularExpressionSearch].location != NSNotFound) {
            callback(YES);
            return;
        }
    }
    
    NSString* function = [tag autoAssignFunction];
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
    
    if (tag.autoAssignSelector != nil) {
        // not implemented
        callback(NO);
        return;
    }
    
    NSLog(@"CleverPush: autoAssignTagMatches - no detection method found %@ %@", pathname, params);
    
    callback(NO);
}

#pragma mark - check Tags
- (void)checkTags:(NSString*)urlStr params:(NSDictionary*)params {
    NSURL* url = [NSURL URLWithString:urlStr];
    NSString* pathname = [url path];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self getAvailableTags:^(NSArray *tags) {
        for (CPChannelTag *tag in tags) {
            [self autoAssignTagMatches:tag pathname:pathname params:params callback:^(BOOL tagMatches) {
                if (tagMatches) {
                    NSLog(@"CleverPush: checkTags: autoAssignTagMatches:YES %@", [tag name]);
                    
                    NSString* tagId = tag.id;
                    NSString* visitsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignVisits-%@", tagId];
                    NSString* sessionsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignSessions-%@", tagId];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
                    
                    int autoAssignVisits = [[tag autoAssignVisits] intValue];
                    
                    NSString *dateKey = [dateFormatter stringFromDate:[NSDate date]];
                    
                    NSDate *dateAfter = nil;
                    
                    int autoAssignDays = [[tag autoAssignDays] intValue];
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
                    
                    int autoAssignSessions = [[tag autoAssignSessions] intValue];
                    int autoAssignSeconds = [[tag autoAssignSeconds] intValue];
                    
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
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                    if ([[self getCurrentPageUrl] isEqualToString:urlStr]) {
                                        [self addSubscriptionTag:tagId callback:nil];
                                    }
                                });
                            } else {
                                [self addSubscriptionTag:tagId callback:nil];
                            }
                        } else {
                            if (autoAssignDays > 0) {
                                int dateVisits = 0;
                                if ([dailyVisits objectForKey:dateKey] == nil) {
                                    [dailyVisits setObject:[NSNumber numberWithInt:0] forKey:dateKey];
                                } else {
                                    dateVisits = [[dailyVisits objectForKey:dateKey] intValue];
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
                                [dailyVisits setObject:[NSNumber numberWithInt:0] forKey:dateKey];
                            } else {
                                dateVisits = [[dailyVisits objectForKey:dateKey] intValue];
                            }
                            dateVisits += 1;
                            [dailyVisits setObject:[NSNumber numberWithInt:dateVisits] forKey:dateKey];
                            
                            [userDefaults setObject:dailyVisits forKey:visitsStorageKey];
                            [userDefaults synchronize];
                            
                            if ([autoAssignSessionsCounted objectForKey:tagId] == nil) {
                                int dateSessions = 0;
                                if ([dailySessions objectForKey:dateKey] == nil) {
                                    [dailySessions setObject:[NSNumber numberWithInt:0] forKey:dateKey];
                                } else {
                                    dateSessions = [[dailySessions objectForKey:dateKey] intValue];
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

#pragma mark - track Page View
- (void)trackPageView:(NSString*)url {
    [self trackPageView:url params:nil];
}

- (void)trackPageView:(NSString*)url params:(NSDictionary*)params {
    currentPageUrl = url;
    [self checkTags:url params:params];
}

- (NSString *)getCurrentPageUrl {
    return currentPageUrl;
}

#pragma mark - track Session Start by api call subscription/session/start
- (void)trackSessionStart {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self getChannelConfig:^(NSDictionary* channelConfig) {
                bool trackAppStatistics = [channelConfig objectForKey:@"trackAppStatistics"] != nil && ![[channelConfig objectForKey:@"trackAppStatistics"] isKindOfClass:[NSNull class]] && [[channelConfig objectForKey:@"trackAppStatistics"] boolValue];
                if (trackAppStatistics || subscriptionId) {
                    sessionVisits = 0;
                    sessionStartedTimestamp = [[NSDate date] timeIntervalSince1970];
                    
                    if (!deviceToken) {
                        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
                    }
                    
                    NSUserDefaults* groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
                    NSString* lastNotificationId = [groupUserDefaults stringForKey:CLEVERPUSH_LAST_NOTIFICATION_ID_KEY];
                    
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

#pragma mark - track the count of session visit
- (void)increaseSessionVisits {
    sessionVisits += 1;
}

#pragma mark - session time gets end by calling this end point subscription/session/end
- (void)trackSessionEnd {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self getChannelConfig:^(NSDictionary* channelConfig) {
                bool trackAppStatistics = [channelConfig objectForKey:@"trackAppStatistics"] != nil && ![[channelConfig objectForKey:@"trackAppStatistics"] isKindOfClass:[NSNull class]] && [[channelConfig objectForKey:@"trackAppStatistics"] boolValue];
                if (trackAppStatistics || subscriptionId) {
                    if (!deviceToken) {
                        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
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

#pragma mark - Display pending topic dialog
- (void)showPendingTopicsDialog {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY]) {
        return;
    }
    
    int topicsDialogSessions = (int)[[channelConfig numberForKey:@"topicsDialogMinimumSessions"] integerValue];
    if (!topicsDialogSessions) {
        topicsDialogSessions = 0;
    }
    int topicsDialogDays = (int)[[channelConfig numberForKey:@"topicsDialogMinimumDays"] integerValue];
    if (!topicsDialogDays) {
        topicsDialogDays = 0;
    }
    int topicsDialogSeconds = (int)[[channelConfig numberForKey:@"topicsDialogMinimumSeconds"] integerValue];
    if (!topicsDialogSeconds) {
        topicsDialogSeconds = 0;
    }
    NSInteger currentTopicsDialogDays = [userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY] ? [self daysBetweenDate:[NSDate date] andDate:[userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY]] : 0;
    
    if ([userDefaults integerForKey:CLEVERPUSH_APP_OPENS_KEY] >= topicsDialogSessions && currentTopicsDialogDays >= topicsDialogDays) {
        NSLog(@"CleverPush: showing pending topics dialog");
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * topicsDialogSeconds);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
            if (![userDefaults boolForKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY]) {
                return;
            }
            
            [userDefaults setBool:NO forKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY];
            [userDefaults synchronize];
            
            [self showTopicsDialog];
        });
    }
}

#pragma mark - Display topic dialog
- (void)showTopicsDialog {
    if (topicsDialogWindow) {
        [self showTopicsDialog:topicsDialogWindow];
        return;
    }
    [self showTopicsDialog:[self keyWindow]];
}

- (void)showTopicsDialog:(UIWindow *)targetWindow {
    [self showTopicsDialog:targetWindow callback:nil];
}

- (void)showTopicsDialog:(UIWindow *)targetWindow callback:(void(^)())callback {
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        if ([channelTopics count] == 0) {
            NSLog(@"CleverPush: showTopicsDialog: No topics found. Create some first in the CleverPush channel settings.");
            return;
        }
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSString* headerTitle = [CPTranslate translate:@"subscribedTopics"];
            
            if (channelConfig != nil && [channelConfig stringForKey:@"confirmAlertSelectTopicsLaterTitle"] != nil && ![[channelConfig stringForKey:@"confirmAlertSelectTopicsLaterTitle"] isEqualToString:@""]) {
                headerTitle = [channelConfig stringForKey:@"confirmAlertSelectTopicsLaterTitle"];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self isSubscribed]) {
                    [self initTopicsDialogData:channelConfig syncToBackend:NO];
                }

                CPTopicsViewController *topicsController = [[CPTopicsViewController alloc] initWithAvailableTopics:channelTopics selectedTopics:[self getSubscriptionTopics] hasSubscriptionTopics:[self hasSubscriptionTopics]];
                channelTopicsPicker = [DWAlertController alertControllerWithContentController:topicsController];
                topicsController.title = headerTitle;
                topicsController.delegate = channelTopicsPicker;
                if (normalTintColor != nil) {
                    channelTopicsPicker.normalTintColor = normalTintColor;
                }
                if (channelConfig != nil && [channelConfig objectForKey:@"topicsDialogShowUnsubscribe"]) {
                    topicsController.topicsDialogShowUnsubscribe = [[channelConfig objectForKey:@"topicsDialogShowUnsubscribe"] boolValue];
                }
                
                if (channelConfig != nil && [channelConfig objectForKey:@"topicsDialogShowWhenNewAdded"]) {
                    topicsController.topicsDialogShowWhenNewAdded = [[channelConfig objectForKey:@"topicsDialogShowWhenNewAdded"] boolValue];
                }
                
                DWAlertAction *okAction = [DWAlertAction actionWithTitle:[CPTranslate translate:@"save"] style:DWAlertActionStyleCancel handler:^(DWAlertAction* action) {
                    if (topicsController.topicsDialogShowUnsubscribe
                        && [self getDeselectValue] == YES) {
                        [self unsubscribe];
                    } else {
                        [self setDefaultCheckedTopics:[topicsController getSelectedTopics]];
                        
                        if (![self isSubscribed]) {
                            [self subscribe:nil skipTopicsDialog:YES];
                        } else {
                            [self syncSubscription];
                        }
                    }
                    [topicsController dismissViewControllerAnimated:YES completion:nil];

                    if (callback) {
                        callback();
                    }
                }];
                [channelTopicsPicker addAction:okAction];
                
                UIViewController* topViewController = [CleverPush topViewController];
                
                [topViewController presentViewController:channelTopicsPicker animated:YES completion:nil];
            });
        }];
    }];
}

- (void)showTopicDialogOnNewAdded {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if ([self hasNewTopicAfterOneHour:channelConfig initialDifference:secDifferenceAtVeryFirstTime displayDialogDifference:validationSeconds]) {
            [self showTopicsDialog];
            [CPUtils updateLastTimeAutomaticallyShowed];
        } else {
            [self showPendingTopicsDialog];
        }
    }];
}

- (BOOL)hasNewTopicAfterOneHour:(NSDictionary*)config initialDifference:(NSInteger)initialDifference displayDialogDifference:(NSInteger)displayAfter {
    NSInteger secondsAfterLastCheck = [self secondsAfterLastCheck];
    if ([CPUtils newTopicAdded:config] && (secondsAfterLastCheck == initialDifference || secondsAfterLastCheck > displayAfter)) {
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger)secondsAfterLastCheck {
    return [CPUtils secondsBetweenDate:[CPUtils getLastTimeAutomaticallyShowed] andDate:[NSDate date]];
}

#pragma mark - update UserDefaults while toggled deselect switch
- (void)updateDeselectFlag:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:CLEVERPUSH_DESELECT_ALL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Automatically a SafariViewController on notification click when no Notification Opened Handler has been provided.
- (void)setOpenWebViewEnabled:(BOOL)opened {
    hasWebViewOpened = opened;
}

#pragma mark - retrieve Deselect value from UserDefaults
- (BOOL)getDeselectValue {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_DESELECT_ALL_KEY] != nil) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:CLEVERPUSH_DESELECT_ALL_KEY]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

#pragma mark - Badge count increment
- (void)setIncrementBadge:(BOOL)increment {
    incrementBadge = increment;

    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    [userDefaults setBool:increment forKey:CLEVERPUSH_INCREMENT_BADGE_KEY];
    [userDefaults synchronize];
}

#pragma mark - Show notifications in foreground
- (void)setShowNotificationsInForeground:(BOOL)show {
    showNotificationsInForeground = show;

    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    [userDefaults setBool:show forKey:CLEVERPUSH_SHOW_NOTIFICATIONS_IN_FOREGROUND_KEY];
    [userDefaults synchronize];
}

- (UIWindow*)keyWindow {
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

#pragma mark - variable updates and callbacks
- (void)setBrandingColor:(UIColor *)color {
    brandingColor = color;
}

- (void)setNormalTintColor:(UIColor *)color {
    normalTintColor = color;
}

- (UIColor*)getNormalTintColor {
    return normalTintColor;
}

- (void)setTopicsDialogWindow:(UIWindow *)window {
    topicsDialogWindow = window;
}

- (UIColor*)getBrandingColor {
    return brandingColor;
}

- (void)setAutoClearBadge:(BOOL)autoClear {
    autoClearBadge = autoClear;
}

- (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore {
    ignoreDisabledNotificationPermission = ignore;
}

- (void)setChatBackgroundColor:(UIColor *)color {
    chatBackgroundColor = color;
}

- (UIColor*)getChatBackgroundColor {
    return chatBackgroundColor;
}

- (void)addStoryView:(CPStoryView*)storyView {
    if (currentStoryView != nil) {
        [currentStoryView removeFromSuperview];
    }
    currentStoryView = storyView;
}

- (void)addChatView:(CPChatView*)chatView {
    if (currentChatView != nil) {
        [currentChatView removeFromSuperview];
    }
    currentChatView = chatView;
}

- (void)setApiEndpoint:(NSString*)endpoint {
    apiEndpoint = endpoint;
}

- (NSString*)getApiEndpoint {
    return apiEndpoint;
}

#pragma mark - App Banner methods
- (void)showAppBanner:(NSString *)bannerId {
    [self showAppBanner:bannerId notificationId:nil];
}

- (void)getAppBanners:(NSString*)channelId callback:(void(^)(NSArray *))callback {
    [CPAppBannerModule getBanners:channelId bannerId:nil notificationId:nil completion:^(NSMutableArray<CPAppBanner *> *banners) {
        callback(banners);
    }];
}

- (void)showAppBanner:(NSString *)bannerId notificationId:(NSString*)notificationId {
    [CPAppBannerModule showBanner:channelId bannerId:bannerId notificationId:notificationId];
}

- (void)showAppBanner:(NSString *)bannerId channelId:(NSString*)channelId notificationId:(NSString*)notificationId {
    BOOL fromNotification = notificationId != nil;
    [CPAppBannerModule initBannersWithChannel:channelId showDrafts:developmentMode fromNotification:fromNotification];
    [CPAppBannerModule showBanner:channelId bannerId:bannerId notificationId:notificationId];
}

- (void)triggerAppBannerEvent:(NSString *)key value:(NSString *)value {
    [CPAppBannerModule triggerEvent:key value:value];
}

- (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock)callback {
    [CPAppBannerModule setBannerOpenedCallback:callback];
}

- (void)disableAppBanners {
    [CPAppBannerModule disableBanners];
}

- (void)enableAppBanners {
    [CPAppBannerModule enableBanners];
}

- (BOOL)popupVisible {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY] != nil) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}
#pragma mark - refactor for testcases
- (NSString*)getChannelIdFromBundle {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:CLEVERPUSH_CHANNEL_ID_KEY];
}

- (NSString*)getChannelIdFromUserDefault {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults stringForKey:CLEVERPUSH_CHANNEL_ID_KEY];
}

- (BOOL)getPendingChannelConfigRequest {
    return pendingChannelConfigRequest;
}

- (NSInteger)getAppOpens {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger appOpens = [userDefaults integerForKey:CLEVERPUSH_APP_OPENS_KEY];
    return appOpens;
}

- (void)incrementAppOpens {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger appOpens = [self getAppOpens];
    appOpens++;
    [userDefaults setInteger:appOpens forKey:CLEVERPUSH_APP_OPENS_KEY];
}

- (void)getChannelConfigFromBundleId:(NSString *)configPath {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            channelId = [result objectForKey:@"channelId"];
            NSLog(@"CleverPush: Detected Channel ID from Bundle Identifier: %@", channelId);
            
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:channelId forKey:CLEVERPUSH_CHANNEL_ID_KEY];
            [userDefaults setObject:nil forKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
            [userDefaults synchronize];
            
            channelConfig = result;
        }
        
        [self fireChannelConfigListeners];
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error);
        
        [self fireChannelConfigListeners];
    }];
}

- (void)getChannelConfigFromChannelId:(NSString *)configPath {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            channelConfig = result;
        }
        
        if (
            channelConfig != nil
            && [channelConfig objectForKey:@"confirmAlertTestsEnabled"]
            && [[channelConfig objectForKey:@"confirmAlertTestsEnabled"] boolValue]
        ) {
            NSString *testsConfigPath = [configPath stringByAppendingString:@"&confirmAlertTestsEnabled=true"];
            NSMutableURLRequest* testsRequest = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:testsConfigPath];
            [self enqueueRequest:testsRequest onSuccess:^(NSDictionary* testsResult) {
                if (testsResult != nil) {
                    channelConfig = testsResult;
                }

                [self fireChannelConfigListeners];
            } onFailure:^(NSError* error) {
                NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
                [self fireChannelConfigListeners];
            }];
            return;
        }
        
        [self fireChannelConfigListeners];
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
        [self fireChannelConfigListeners];
    }];
}

- (BOOL)isChannelIdChanged:(NSString *)channelId; {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if ([channelId isEqualToString:[userDefaults stringForKey:CLEVERPUSH_CHANNEL_ID_KEY]]) {
        return false;
    } else {
        return true;
    }
}

- (void)addOrUpdateChannelId:(NSString *)channelId{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:channelId forKey:CLEVERPUSH_CHANNEL_ID_KEY];
    [userDefaults synchronize];
}

- (BOOL)getAutoClearBadge {
    return autoClearBadge;
}

- (void)setHandleSubscribedCalled:(BOOL)subscribed {
    handleSubscribedCalled = subscribed;
}

- (BOOL)getHandleSubscribedCalled {
    return handleSubscribedCalled;
}

- (CPHandleSubscribedBlock)getSubscribeHandler {
    return handleSubscribed;
}

- (void)setSubscribeHandler:(CPHandleSubscribedBlock)subscribedCallback {
    handleSubscribed = subscribedCallback;
}

#pragma mark - recieved notifications from the Extension.
- (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    NSLog(@"CleverPush: didReceiveNotificationExtensionRequest");
    
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    NSDictionary* payload = request.content.userInfo;
    NSDictionary* notification = [payload dictionaryForKey:@"notification"];
    
    [self handleNotificationReceived:payload isActive:NO];
    
    // badge count
    [self updateBadge:replacementContent];
    
    // rich notifications
    if (notification != nil) {
        bool isCarousel = [notification objectForKey:@"carouselEnabled"] != nil && ![[notification objectForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification arrayForKey:@"carouselItems"] != nil && ![[notification arrayForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"carouselEnabled"] boolValue];
        
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

#pragma mark - service Extension Time Will Expire Request.
- (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
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

#pragma mark - Add actions buttons on the carousel.
- (void)addActionButtonsToNotificationRequest:(UNNotificationRequest*)request
                                  withPayload:(NSDictionary*)payload
               withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent  API_AVAILABLE(ios(10.0)) {
    if (request.content.categoryIdentifier && ![request.content.categoryIdentifier isEqualToString:@""]) {
        return;
    }
    
    NSDictionary* notification = [payload valueForKey:@"notification"];
    bool isCarousel = notification != nil && [notification objectForKey:@"carouselEnabled"] != nil && ![[notification objectForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification arrayForKey:@"carouselItems"] != nil && ![[notification arrayForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"carouselEnabled"] boolValue];
    
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
        
        NSString* newCategoryIdentifier = [CPNotificationCategoryController.sharedInstance registerNotificationCategoryForNotificationId:[payload stringForKeyPath:@"notification._id"]];
        
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

@end
