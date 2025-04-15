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
#import "CPLog.h"
#import "CPAppBannerModule.h"
#import "DWAlertController/DWAlertController.h"
#import "DWAlertController/DWAlertAction.h"
#import "CPChannelTag.h"
#import "NSDictionary+SafeExpectations.h"
#import "NSMutableArray+ContainsString.h"
#import "NSString+VersionComparator.h"
#import "CPSQLiteManager.h"
#import "CPIabTcfMode.h"
#endif

@implementation CPNotificationReceivedResult

- (instancetype _Nullable)initWithPayload:(NSDictionary* _Nullable)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [CPNotification initWithJson:[[_payload cleverPushDictionaryForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload cleverPushDictionaryForKey:@"subscription"] mutableCopy]];
    }
    return self;
}

@end

@implementation CPNotificationOpenedResult

- (instancetype _Nullable)initWithPayload:(NSDictionary* _Nullable)inPayload action:(NSString* _Nullable)action {
    self = [super init];
    if (self) {
        _payload = inPayload;
        _notification = [CPNotification initWithJson:[[_payload cleverPushDictionaryForKey:@"notification"] mutableCopy]];
        _subscription = [CPSubscription initWithJson:[[_payload cleverPushDictionaryForKey:@"subscription"] mutableCopy]];
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

NSString* const CLEVERPUSH_SDK_VERSION = @"1.34.5";

static BOOL startFromNotification = NO;
static BOOL autoClearBadge = YES;
static BOOL autoResubscribe = NO;
static BOOL isShowDraft = NO;
static BOOL isSubscriptionChanged = NO;
static BOOL incrementBadge = NO;
static BOOL showNotificationsInForeground = YES;
static BOOL isDisplayAlertEnabledForNotifications = YES;
static BOOL isSoundEnabledForNotifications = YES;
static BOOL isBadgeCountEnabledForNotifications = YES;
static BOOL autoRegister = YES;
static BOOL registrationInProgress = false;
static BOOL ignoreDisabledNotificationPermission = NO;
static BOOL autoRequestNotificationPermission = YES;
static BOOL keepTargetingDataOnUnsubscribe = NO;
static BOOL hasCalledSubscribe = NO;
static BOOL isSessionStartCalled = NO;
static BOOL confirmAlertShown = NO;
static BOOL hasInitialized = NO;
static BOOL hasRequestedDeviceToken = NO;
static const int secDifferenceAtVeryFirstTime = 0;
static const int validationSeconds = 3600;
static const NSInteger httpRequestRetryCount = 3;
static const NSInteger httpRequestRetryBackoffMultiplier = 2;
int maximumNotifications = 100;
int iabtcfVendorConsentPosition = 1139;
static UIViewController*customTopViewController = nil;
int localEventTrackingRetentionDays = 90;
NSInteger subscriptionTopicsVersion = 0;

static NSString* channelId;
static NSString* lastNotificationReceivedId;
static NSString* lastNotificationOpenedId;
static NSString* iabtcfVendorConsents = @"IABTCF_VendorConsents";
static NSString* detectDeviceMigrationFile = @"CleverPush_SHOULD_SYNC_FILE.txt";
static NSDictionary* channelConfig;
static CleverPushInstance* singleInstance = nil;

NSDate* lastSync;
NSString* subscriptionId;
NSString* deviceToken;
NSString* currentPageUrl;
NSString* apiEndpoint = @"https://api-mobile.cleverpush.com";
NSString* appGroupIdentifier = @".cleverpush";
NSString* authorizationToken;
NSArray* appBanners;
NSArray* channelTopics;
NSArray* handleUniversalLinksInApp;

NSMutableArray* pendingChannelConfigListeners;
NSMutableArray* pendingSubscriptionListeners;
NSMutableArray* pendingDeviceTokenListeners;
NSMutableArray* pendingTrackingConsentListeners;
NSMutableArray* pendingSubscribeConsentListeners;
NSMutableArray* subscriptionTags;
NSMutableArray* subscriptionTopics;

NSMutableDictionary* autoAssignSessionsCounted;
UIBackgroundTaskIdentifier mediaBackgroundTask;
WKWebView* currentAppBannerWebView;
UIColor* brandingColor;
UIColor* normalTintColor = nil;
UIModalPresentationStyle appBannerModalPresentationStyle = UIModalPresentationOverCurrentContext;

UIWindow* topicsDialogWindow;

CPChatView* currentChatView;
CPStoryView* currentStoryView;
CPHandleNotificationOpenedBlock handleNotificationOpened;
CPHandleNotificationReceivedBlock handleNotificationReceived;
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
CPInitializedBlock handleInitialized;
CPTopicsChangedBlock topicsChangedBlock;
DWAlertController*channelTopicsPicker;
CPNotificationOpenedResult* pendingOpenedResult = nil;
CPNotificationReceivedResult* pendingDeliveryResult = nil;
CPSQLiteManager* databaseManager;
CPIabTcfMode currentIabTcfMode;

BOOL pendingChannelConfigRequest = NO;
BOOL pendingAppBannersRequest = NO;
BOOL channelTopicsPickerVisible = NO;
BOOL developmentMode = NO;
BOOL trackingConsentRequired = NO;
BOOL hasTrackingConsent = NO;
BOOL subscribeConsentRequired = NO;
BOOL hasSubscribeConsent = NO;
BOOL hasWebViewOpened = NO;
BOOL hasTrackingConsentCalled = NO;
BOOL hasSubscribeConsentCalled = NO;
BOOL handleSubscribedCalled = NO;
BOOL handleUrlFromSceneDelegate = NO;
BOOL handleUrlFromAppDelegate = NO;

int sessionVisits;
long sessionStartedTimestamp;
double channelTopicsPickerShownAt;
id currentAppBannerUrlOpenedCallback;

static id isNil(id object) {
    return object ?: [NSNull null];
}

- (NSString* _Nullable)channelId {
    return channelId;
}

- (NSString* _Nullable)subscriptionId {
    return subscriptionId;
}

- (void)setTrackingConsentRequired:(BOOL)required {
    trackingConsentRequired = required;
}

- (void)setTrackingConsent:(BOOL)consent {
    BOOL previousTrackingConsent = hasTrackingConsent;
    hasTrackingConsentCalled = YES;
    hasTrackingConsent = consent;

    if (!hasTrackingConsent && previousTrackingConsent) {
        [self removeSubscriptionTagsAndAttributes];
        [self stopCampaigns];
    }

    if ([CleverPush getIabTcfMode] != CPIabTcfModeDisabled && !previousTrackingConsent && hasTrackingConsent) {
        pendingTrackingConsentListeners = [NSMutableArray new];
    }

    if (hasTrackingConsent) {
        [self fireTrackingConsentListeners];
    } else {
        if (trackingConsentRequired && !hasTrackingConsent && [pendingTrackingConsentListeners count] > 0) {
            return;
        }
        pendingTrackingConsentListeners = [NSMutableArray new];
    }
}

- (void)setSubscribeConsentRequired:(BOOL)required {
    subscribeConsentRequired = required;
}

- (void)setSubscribeConsent:(BOOL)consent {
    BOOL previousSubscribeConsent = hasSubscribeConsent;
    hasSubscribeConsentCalled = YES;
    hasSubscribeConsent = consent;

    if ([CleverPush getIabTcfMode] != CPIabTcfModeDisabled && !previousSubscribeConsent && hasSubscribeConsent) {
        pendingSubscribeConsentListeners = [NSMutableArray new];
    }

    if (hasSubscribeConsent) {
        [self fireSubscribeConsentListeners];
    } else {
        if (subscribeConsentRequired && !hasSubscribeConsent && [pendingSubscribeConsentListeners count] > 0) {
            return;
        }
        pendingSubscribeConsentListeners = [NSMutableArray new];
    }
}

- (void)enableDevelopmentMode {
    developmentMode = YES;
    [CPLog setLogLevel:CP_LOGLEVEL_VERBOSE];
    [CPLog warn:@"! SDK is running in development mode. Only use this while testing !"];
}

- (BOOL)isDevelopmentModeEnabled {
    return developmentMode;
}

- (BOOL)startFromNotification {
    BOOL val = startFromNotification;
    startFromNotification = NO;
    return val;
}

#pragma mark - methods to initialize SDK with launch options
- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

- (id)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

- (id _Nullable)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions channelId:(NSString* _Nullable)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    return [self initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam];
}

- (id)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions
                  channelId:(NSString* _Nullable)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback
               autoRegister:(BOOL)autoRegisterParam {
    return [self initWithLaunchOptions:launchOptions channelId:newChannelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam handleInitialized:NULL];
}

#pragma mark - methods to initialize SDK with UISceneConnectionOptions
- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback autoRegister:(BOOL)autoRegister  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  autoRegister:(BOOL)autoRegister  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:autoRegister handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)channelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
                 handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:NULL handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES handleInitialized:NULL];
}

- (id _Nullable)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions channelId:(NSString* _Nullable)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback autoRegister:(BOOL)autoRegisterParam  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:newChannelId handleNotificationReceived:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam handleInitialized:NULL];
}

- (id)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions
                  channelId:(NSString* _Nullable)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback
                   autoRegister:(BOOL)autoRegisterParam  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:newChannelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam handleInitialized:NULL];
}

- (id)initWithConnectionOptions:(UISceneConnectionOptions* _Nullable)connectionOptions
                  channelId:(NSString* _Nullable)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback
               autoRegister:(BOOL)autoRegisterParam
              handleInitialized:(CPInitializedBlock  _Nullable)initializedCallback  API_AVAILABLE(ios(13.0)){
    return [self initWithConnectionOptionsInternal:connectionOptions channelId:newChannelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegisterParam handleInitialized:initializedCallback];
}

- (id _Nullable)initWithConnectionOptionsInternal:(UISceneConnectionOptions* _Nullable)connectionOptions
                                        channelId:(NSString* _Nullable)channelId
                       handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
                         handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
                                 handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback
                                     autoRegister:(BOOL)autoRegister
                                handleInitialized:(CPInitializedBlock _Nullable)initializedCallback API_AVAILABLE(ios(13.0)) {
    NSDictionary *launchOptions = [CPUtils convertConnectionOptionsToLaunchOptions:connectionOptions];
    handleUrlFromSceneDelegate = YES;
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationReceived:receivedCallback handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:autoRegister handleInitialized:initializedCallback];
}

#pragma mark - Common function to initialize SDK and sync data to NSUserDefaults
- (id)initWithLaunchOptions:(NSDictionary* _Nullable)launchOptions
                  channelId:(NSString* _Nullable)newChannelId
 handleNotificationReceived:(CPHandleNotificationReceivedBlock _Nullable)receivedCallback
   handleNotificationOpened:(CPHandleNotificationOpenedBlock _Nullable)openedCallback
           handleSubscribed:(CPHandleSubscribedBlock _Nullable)subscribedCallback
               autoRegister:(BOOL)autoRegisterParam
          handleInitialized:(CPInitializedBlock _Nullable)initializedCallback {
    [self setSubscribeHandler:subscribedCallback];
    handleNotificationReceived = receivedCallback;
    handleNotificationOpened = openedCallback;
    handleInitialized = initializedCallback;
    autoRegister = autoRegisterParam;
    brandingColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    channelConfig = nil;
    pendingChannelConfigListeners = [[NSMutableArray alloc] init];
    pendingSubscriptionListeners = [[NSMutableArray alloc] init];
    pendingDeviceTokenListeners = [[NSMutableArray alloc] init];
    pendingTrackingConsentListeners = [[NSMutableArray alloc] init];
    pendingSubscribeConsentListeners = [[NSMutableArray alloc] init];
    autoAssignSessionsCounted = [[NSMutableDictionary alloc] init];
    subscriptionTags = [[NSMutableArray alloc] init];
    subscriptionTopics = [[NSMutableArray alloc] init];
    hasInitialized = NO;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *installationDate = [userDefaults objectForKey:CLEVERPUSH_APP_INSTALLATION_DATE_KEY];

    if (installationDate == nil || [installationDate isKindOfClass:[NSNull class]]) {
        NSDate *subscriptionCreatedAt = [userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY];
        if (subscriptionCreatedAt != nil && ![subscriptionCreatedAt isKindOfClass:[NSNull class]]) {
            [userDefaults setObject:subscriptionCreatedAt forKey:CLEVERPUSH_APP_INSTALLATION_DATE_KEY];
        } else {
            [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_APP_INSTALLATION_DATE_KEY];
        }

        [userDefaults synchronize];
    }

    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
    }

    if (pendingOpenedResult && handleNotificationOpened) {
        handleNotificationOpened(pendingOpenedResult);
    }
    if (pendingDeliveryResult && handleNotificationReceived) {
        handleNotificationReceived(pendingDeliveryResult);
    }

    if (self) {
        if (newChannelId) {
            channelId = newChannelId;
        } else {
            channelId = [self getChannelIdFromBundle];
        }

        if (channelId == nil) {
            channelId  = [self getChannelIdFromUserDefaults];
        } else if ([self isChannelIdChanged:channelId]) {
            [self addOrUpdateChannelId:channelId];
            [self clearSubscriptionData];
            [CPAppBannerModule resetInitialization];
        }

        if (!channelId) {
            [CPLog info:@"CleverPush: Channel ID not specified, trying to fetch config via Bundle Identifier..."];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self getChannelConfig:^(NSDictionary* channelConfig) {
                    if (!channelId) {
                        [CPLog error:@"Initialization stopped - No Channel ID available"];
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self initWithChannelId];
                    });
                }];
            });
            [CPLog info:@"Got Channel ID, initializing"];
        } else {
            [self initWithChannelId];
        }
    }

	[self clearBadge];

    if (!handleUrlFromSceneDelegate) {
        handleUrlFromAppDelegate = YES;
    }

    return self;
}

#pragma mark - Define the rootview controller of the UINavigation-Stack
- (UIViewController* _Nullable)topViewController {
    if ([CleverPush getCustomTopViewController] != nil) {
        return [CleverPush getCustomTopViewController];
    } else {
        return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
    }
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
        for (UIView*view in [viewController.view subviews]) {
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]]) {
                if ([(UIViewController*)subViewController presentedViewController] && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController*)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

#pragma mark - syncSubscription by calling initWithChannelId.
- (void)initWithChannelId {
    [CPLog info:@"Initializing SDK %@ with channelId: %@ and autoRegister: %@", CLEVERPUSH_SDK_VERSION, channelId, autoRegister ? @"YES": @"NO"];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    subscriptionId = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
    deviceToken = [userDefaults stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];

    [self incrementAppOpens];

    if (autoRegister && ![self getUnsubscribeStatus]) {
        [self autoSubscribeWithDelays];
    }

    databaseManager = [CPSQLiteManager sharedManager];
    if (![databaseManager databaseExists]) {
        if ([databaseManager createDatabase] && [databaseManager createTable]) {
            [self setDatabaseInfo];
        }
    } else {
        if ([databaseManager createTable]) {
            NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
            BOOL databaseCreated = [defaults objectForKey:CLEVERPUSH_DATABASE_CREATED_KEY] != nil;

            if (!databaseCreated) {
                [self setDatabaseInfo];
            } else {
                NSDateFormatter*dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSDate*retentionDay = [[dateFormatter dateFromString:[[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_DATABASE_CREATED_TIME_KEY]] dateByAddingTimeInterval:(60* 60* 24* [CleverPush getLocalEventTrackingRetentionDays])];

                if (retentionDay != nil) {
                    if ([[NSDate date] compare:retentionDay] == NSOrderedDescending || [[NSDate date] compare:retentionDay] == NSOrderedSame) {
                       [databaseManager deleteDataBasedOnRetentionDays:[CleverPush getLocalEventTrackingRetentionDays]];
                    }
                }
            }
        }
    }

    if (subscriptionId != nil) {
        hasCalledSubscribe = YES;
        [self areNotificationsEnabled:^(BOOL notificationsEnabled) {
            if (!notificationsEnabled && !ignoreDisabledNotificationPermission) {
                [CPLog info:@"notification authorization revoked, unsubscribing"];
                [self unsubscribe];
            } else if ([self shouldSync]) {
                [CPLog debug:@"syncSubscription called from initWithChannelId"];
                [self ensureMainThreadSync:^{
                    [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:10.0f];
                }];
            } else {
                [self requestDeviceToken];

                if ([self getSubscribeHandler] && ![self getHandleSubscribedCalled]) {
                    [self getSubscribeHandler](subscriptionId);
                    [self setHandleSubscribedCalled:YES];
                }
                if (handleSubscribedInternal) {
                    handleSubscribedInternal(subscriptionId);
                }
            }
        }];
    } else {
        [CPLog debug:@"There is no subscription for CleverPush SDK."];
    }

    [self initFeatures];

    if ([CleverPush getIabTcfMode] != CPIabTcfModeDisabled) {
        [self initIabTcf];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)initTopicsDialogData:(NSDictionary* _Nullable)config syncToBackend:(BOOL)syncToBackend {
    NSArray* channelTopics = [config cleverPushArrayForKey:@"channelTopics"];
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
    subscriptionTopics = [topics mutableCopy];
    subscriptionTopicsVersion = topicsVersion;
}

#pragma mark - reset 'CleverPush_APP_BANNER_VISIBLE' value of user default when application is going to terminate.
- (void)applicationWillTerminate {
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - clear Badge count and start tracking the session when application in the active state 
- (void)applicationDidBecomeActive {
    [self updateBadge:nil];
    [self trackSessionStart];

	[self clearBadge];

    [CPAppBannerModule initSession:channelId afterInit:YES];

    [self areNotificationsEnabled:^(BOOL notificationsEnabled) {
        if (subscriptionId == nil) {
            if (autoResubscribe && notificationsEnabled) {
                [self subscribe];
            } else {
                [CPLog debug:@"CleverPushInstance: applicationWillEnterForeground: There is no subscription for CleverPush SDK."];
            }
        } else {
            if (!notificationsEnabled && !ignoreDisabledNotificationPermission) {
                [CPLog info:@"notification authorization revoked, unsubscribing"];
                [self unsubscribe];
            }
        }
    }];
}

#pragma mark - clear Badge count and start tracking the session when application goes to the Background.
- (void)applicationDidEnterBackground {
    [self updateBadge:nil];
    [self trackSessionEnd];
}

#pragma mark - Initialised Features.
- (void)initFeatures {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self showTopicDialogOnNewAdded];
        [self initAppReview];

        [CPAppBannerModule initBannersWithChannel:channelId showDrafts:isShowDraft fromNotification:NO];
        [CPAppBannerModule initSession:channelId afterInit:NO];
    });
}

#pragma mark - Initialised Iab Tcf Functionality.
- (void)initIabTcf {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableIabTcfMode:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)enableIabTcfMode:(NSNotification*)notification {
    CPIabTcfMode tcfMode = [self getIabTcfMode];

    if (tcfMode == CPIabTcfModeTrackingWaitForConsent) {
        [self setTrackingConsentRequired:YES];
    }

    if (tcfMode == CPIabTcfModeSubscribeWaitForConsent) {
        [self setSubscribeConsentRequired:YES];
    }

    NSDictionary*notificationObject = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    if (notificationObject.count > 0) {
        NSString*vendorConsents = notificationObject[iabtcfVendorConsents];

        if (vendorConsents != nil && ![vendorConsents isKindOfClass:[NSNull class]] && ![vendorConsents isEqualToString:@""] && vendorConsents.length > iabtcfVendorConsentPosition - 1) {
            unichar consentStatus = [vendorConsents characterAtIndex:iabtcfVendorConsentPosition - 1];
            BOOL hasConsent = (consentStatus == '1');

            if (tcfMode == CPIabTcfModeTrackingWaitForConsent) {
                [self setTrackingConsent:hasConsent];
            }

            if (tcfMode == CPIabTcfModeSubscribeWaitForConsent) {
                [self setSubscribeConsent:hasConsent];
            }

            if (!hasConsent) {
                [CPLog debug:@"The vendor does not have consent."];
            }
        } else {
            [CPLog debug:@"The vendor consents that the string is too short to get a character at the provided index, or the vendor consents that the value is not found."];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

#pragma mark - Initialised AppReviews.
- (void)initAppReview {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil && [channelConfig objectForKey:@"appReviewEnabled"]) {
            NSString* iosStoreId = [channelConfig cleverPushStringForKey:@"iosStoreId"];

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

            NSString*appReviewTitle = [channelConfig cleverPushStringForKey:@"appReviewTitle"];
            if (!appReviewTitle) {
                appReviewTitle = @"Do you like our app?";
            }

            NSString*appReviewYes = [channelConfig cleverPushStringForKey:@"appReviewYes"];
            if (!appReviewYes) {
                appReviewYes = @"Yes";
            }

            NSString*appReviewNo = [channelConfig cleverPushStringForKey:@"appReviewNo"];
            if (!appReviewNo) {
                appReviewNo = @"No";
            }

            NSString*appReviewFeedbackTitle = [channelConfig cleverPushStringForKey:@"appReviewFeedbackTitle"];
            if (!appReviewFeedbackTitle) {
                appReviewFeedbackTitle = @"Do you want to tell us what you do not like?";
            }

            NSString*appReviewEmail = [channelConfig cleverPushStringForKey:@"appReviewEmail"];

            if ([self getAppOpens] >= appReviewOpens && currentAppDays >= appReviewDays) {
                [CPLog info:@"showing app review alert"];

                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC* appReviewSeconds);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    if ([userDefaults objectForKey:CLEVERPUSH_APP_REVIEW_SHOWN_KEY]) {
                        return;
                    }

                    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_APP_REVIEW_SHOWN_KEY];
                    [userDefaults synchronize];

                    UIAlertController*alertController = [UIAlertController alertControllerWithTitle:appReviewTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction*actionYes = [UIAlertAction actionWithTitle:appReviewYes style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                        if (iosStoreId == nil || [iosStoreId isKindOfClass:[NSNull class]]) {
                            return;
                        }

                        NSURL*storeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@?action=write-review", iosStoreId]];
                        [[UIApplication sharedApplication] openURL:storeUrl options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:actionYes];

                    UIAlertAction*actionNo = [UIAlertAction actionWithTitle:appReviewNo style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                        if (appReviewEmail) {
                            UIAlertController*alertFeedbackController = [UIAlertController alertControllerWithTitle:appReviewFeedbackTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];

                            UIAlertAction*actionFeedbackYes = [UIAlertAction actionWithTitle:appReviewYes style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                                NSString*appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
                                NSString* model = [CPUtils deviceName];
                                NSString*bodyData = [NSString stringWithFormat:@"• OS: %@ • OS Version: %@ • Manufacturer: %@ • Device: %@ • Model: %@", UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion, @"Apple", UIDevice.currentDevice.systemName, model];
                                NSString*recipients = [NSString stringWithFormat:@"mailto:%@?subject=%@", appReviewEmail, appName];
                                NSString*body = [NSString stringWithFormat:@"&body=%@", bodyData];
                                NSString*email = [NSString stringWithFormat:@"%@%@", recipients, body];
                                email = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email] options:@{} completionHandler:^(BOOL success) {
                                    if (!success) {
                                        [CPLog error:@"failed to open mail app: %@", email];
                                    }
                                }];
                            }];
                            [alertFeedbackController addAction:actionFeedbackYes];

                            UIAlertAction*actionFeedbackNo = [UIAlertAction actionWithTitle:appReviewNo
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
    NSDate*fromDate;
    NSDate*toDate;
    NSCalendar*calendar = [NSCalendar currentCalendar];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:NULL forDate:toDateTime];
    NSDateComponents*difference = [calendar components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
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
    [CPLog info:@"next sync: %@", nextSync];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:detectDeviceMigrationFile];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error = nil;
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        BOOL fileWritten = [[NSData data] writeToFile:filePath options:NSDataWritingAtomic error:&error];
        BOOL success = [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];

        if (!fileWritten || !success) {
            [CPLog debug:@"Failed to write sync file or Error excluding file from backup: %@", error];
        }

        [self requestDeviceToken];

        return YES;
    }

    return [nextSync compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark - fireChannelConfigListeners.
- (void)fireChannelConfigListeners {
    pendingChannelConfigRequest = NO;

    for (void(^listener)(NSDictionary*) in pendingChannelConfigListeners) {
        // check if listener and channelConfig are non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener && channelConfig) {
            __strong void(^callbackBlock)(NSDictionary*) = listener;
            callbackBlock(channelConfig);
        }
    }
    pendingChannelConfigListeners = [NSMutableArray new];
}

#pragma mark - API call and get the data of the specific Channel.
- (void)getChannelConfig:(void(^ _Nullable)(NSDictionary* _Nullable))callback {
    @synchronized(self) {
        if (channelConfig) {
            if (callback) {
                callback(channelConfig);
            }
            return;
        }

        if (!pendingChannelConfigListeners) {
            pendingChannelConfigListeners = [NSMutableArray new];
        }
        
        [pendingChannelConfigListeners addObject:callback];
        if (pendingChannelConfigRequest) {
            return;
        }
        pendingChannelConfigRequest = YES;
    }

    NSString *configPath = @"";
    NSString *channelId = [self channelId];
    if (channelId != NULL) {
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

- (NSString* _Nullable)getBundleName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark - Set maximum notification count.
- (void)setMaximumNotificationCount:(int)limit {
    maximumNotifications = limit;

    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    [userDefaults setInteger:limit forKey:CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT];
    [userDefaults synchronize];
}

#pragma mark - getDeviceToken.
- (void)getDeviceToken:(void(^ _Nullable)(NSString* _Nullable))callback {
    if (deviceToken) {
        callback(deviceToken);
    } else {
        [pendingDeviceTokenListeners addObject:[callback copy]];
    }
}

- (NSString* _Nullable)getDeviceToken {
    return deviceToken;
}

#pragma mark - getSubscriptionId.
- (void)getSubscriptionId:(void(^ _Nullable)(NSString* _Nullable))callback {
    if (subscriptionId) {
        callback(subscriptionId);
    } else {
        [pendingSubscriptionListeners addObject:[callback copy]];
    }
}

- (void)setSubscriptionId:(NSString* _Nullable)newSubscriptionId {
    subscriptionId = newSubscriptionId;
}

- (NSString* _Nullable)getSubscriptionId {
    if (subscriptionId) {
        return subscriptionId;
    }

    __block NSString *result = nil;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        handleSubscribedInternal = ^(NSString *subscriptionIdNew) {
            result = subscriptionIdNew;
            dispatch_semaphore_signal(sema);
        };

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    });

    return result;
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
    for (void(^listener)(void*) in pendingTrackingConsentListeners) {
        // check if listener is non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener) {
#pragma clang diagnostic ignored "-Wstrict-prototypes"
            __strong void(^callbackBlock)() = listener;
#pragma clang diagnostic pop
            callbackBlock();
        }
    }
    pendingTrackingConsentListeners = [NSMutableArray new];
}

- (void)waitForTrackingConsent:(void(^ _Nullable)(void))callback {
    if (![self getTrackingConsentRequired] || [self getHasTrackingConsent]) {
        callback();
        return;
    }

    if (![self getHasTrackingConsentCalled] || ([self getHasTrackingConsentCalled] && ![self getHasTrackingConsent])) {
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

#pragma mark - Based on the subscribeConsentRequired and hasSubscribeConsent Triggered this method
- (void)fireSubscribeConsentListeners {
    for (void(^listener)(void*) in pendingSubscribeConsentListeners) {
        // check if listener is non-nil (otherwise: EXC_BAD_ACCESS)
        if (listener) {
#pragma clang diagnostic ignored "-Wstrict-prototypes"
            __strong void(^callbackBlock)() = listener;
#pragma clang diagnostic pop
            callbackBlock();
        }
    }
    pendingSubscribeConsentListeners = [NSMutableArray new];
}

- (void)waitForSubscribeConsent:(void(^ _Nullable)(void))callback {
    if (![self getSubscribeConsentRequired] || [self getHasSubscribeConsent]) {
        callback();
        return;
    }

    if (![self getHasSubscribeConsentCalled] || ([self getHasSubscribeConsentCalled] && ![self getHasSubscribeConsent])) {
        [self addCallbacksToSubscribeConsentListeners:callback];
    }
}

- (void)addCallbacksToSubscribeConsentListeners:(void(^)(void))callback {
    [pendingSubscribeConsentListeners addObject:callback];
}

- (BOOL)getSubscribeConsentRequired {
    return subscribeConsentRequired;
}

- (BOOL)getHasSubscribeConsent {
    return hasSubscribeConsent;
}

- (BOOL)getHasSubscribeConsentCalled {
    return hasSubscribeConsentCalled;
}

#pragma mark - Returns if the user has currently given the notification permission
- (void)areNotificationsEnabled:(void(^ _Nullable)(BOOL))callback {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull notificationSettings) {
        BOOL isEnabled = (notificationSettings.authorizationStatus == UNAuthorizationStatusAuthorized);
        if (callback) {
            callback(isEnabled);
        }
    }];
}

#pragma mark - channel subscription
- (void)setConfirmAlertShown {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        confirmAlertShown = YES;
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:[NSString stringWithFormat:@"channel/confirm-alert"]];

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
            [CPLog error:@"/channel/confirm-alert request error %@", error];
        }];
    }];
}

- (void)subscribe {
    [self subscribe:nil];
}

- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock {
    [self subscribe:subscribedBlock failure:nil skipTopicsDialog:NO];
}

- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock {
    [self subscribe:subscribedBlock failure:failureBlock skipTopicsDialog:NO];
}

- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    [self subscribe:subscribedBlock failure:nil skipTopicsDialog:skipTopicsDialog];
}

- (void)subscribe:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    if ([CleverPush getIabTcfMode] == CPIabTcfModeSubscribeWaitForConsent) {
        void(^consentBlock)(void) = ^{
            [self handleSubscription:subscribedBlock failure:failureBlock skipTopicsDialog:skipTopicsDialog];
        };
        [self waitForSubscribeConsent:consentBlock];
    } else {
        [self handleSubscription:subscribedBlock failure:failureBlock skipTopicsDialog:skipTopicsDialog];
    }
}

- (void)handleSubscription:(CPHandleSubscribedBlock _Nullable)subscribedBlock failure:(CPFailureBlock _Nullable)failureBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    [self handleSubscriptionWithCompletion:^(NSString * _Nullable subscriptionId, NSError * _Nullable error) {
        if (error) {
            if (failureBlock) {
                failureBlock(error);
            }
        } else {
            if (subscribedBlock) {
                subscribedBlock(subscriptionId);
            }
        }
    } failure:failureBlock skipTopicsDialog:skipTopicsDialog];
}

- (void)requestNotificationPermission:(BOOL)shouldShowAlert playSound:(BOOL)shouldPlaySound setBadge:(BOOL)shouldSetBadge
    completionHandler:(void (^)(BOOL granted, NSError* error))completionHandler {
    UNAuthorizationOptions options = 0;
    if (shouldShowAlert) {
        options |= UNAuthorizationOptionAlert;
    }
    if (shouldPlaySound) {
        options |= UNAuthorizationOptionSound;
    }
    if (shouldSetBadge) {
        options |= UNAuthorizationOptionBadge;
    }

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:options completionHandler:completionHandler];
}

- (void)requestDeviceToken {
    if (hasRequestedDeviceToken) {
        return;
    }

    hasRequestedDeviceToken = YES;
    [self ensureMainThreadSync:^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }];
}

- (void)handleSubscriptionWithCompletion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion failure:(CPFailureBlock _Nullable)failureBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    hasCalledSubscribe = YES;

	[self requestDeviceToken];

    [self getDeviceToken:^(NSString * _Nullable deviceToken) {
        [self proceedWithSubscription:completion failure:failureBlock skipTopicsDialog:skipTopicsDialog];
    }];
}

- (void)proceedWithSubscription:(void (^)(NSString * _Nullable, NSError * _Nullable))completion failure:(CPFailureBlock _Nullable)failureBlock skipTopicsDialog:(BOOL)skipTopicsDialog {
    [self areNotificationsEnabled:^(BOOL hasPermission) {
        if (!hasPermission && autoRequestNotificationPermission) {
            [self requestNotificationPermission:isDisplayAlertEnabledForNotifications playSound:isSoundEnabledForNotifications setBadge:isBadgeCountEnabledForNotifications completionHandler:^(BOOL granted, NSError* error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted && !ignoreDisabledNotificationPermission) {
                        [self handleSubscriptionWithCompletion:completion failure:failureBlock skipTopicsDialog:skipTopicsDialog];
                    }

                    if (!granted && !ignoreDisabledNotificationPermission) {
                        if (completion) {
                            completion(nil, [NSError errorWithDomain:@"com.cleverpush" code:410 userInfo:@{NSLocalizedDescriptionKey:@"Cannot subscribe because notifications have been disabled by the user."}]);
                        }

                        [self setConfirmAlertShown];
                    }
                });
            }];

            if (!ignoreDisabledNotificationPermission) {
                return;
            }
        }

        if (!hasPermission && !ignoreDisabledNotificationPermission) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"com.cleverpush" code:410 userInfo:@{NSLocalizedDescriptionKey:@"Cannot subscribe because notifications have been disabled by the user."}]);
            }
            return;
        }

        if (subscriptionId != nil) {
            if (completion) {
                completion(subscriptionId, nil);
            }
            return;
        }

        [CPLog debug:@"syncSubscription called from subscribe"];
        if (failureBlock) {
            [self performSelector:@selector(syncSubscription:) withObject:failureBlock];
        } else {
            [self performSelector:@selector(syncSubscription) withObject:nil];
        }

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

        if (completion) {
            [self getSubscriptionId:^(NSString *subscriptionId) {
                if (subscriptionId != nil && ![subscriptionId isKindOfClass:[NSNull class]] && ![subscriptionId isEqualToString:@""]) {
                    completion(subscriptionId, nil);
                } else {
                    completion(nil, [NSError errorWithDomain:@"com.cleverpush" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Subscription ID is nil or empty"}]);
                }
            }];
        }
    }];
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
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC* milliseconds),  dispatch_get_main_queue(), ^(void) {
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
    if (!keepTargetingDataOnUnsubscribe) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setHandleSubscribedCalled:NO];
    [self setSubscriptionId:nil];
    isSessionStartCalled = NO;
    confirmAlertShown = NO;
}

#pragma mark - unsubscribe
- (void)unsubscribe {
    [self unsubscribe:^(BOOL success) {
        if (success) {
            [CPLog info:@"unsubscribe success"];

            [CPAppBannerModule triggerEvent:CLEVERPUSH_APP_BANNER_UNSUBSCRIBE_EVENT properties:nil];
        }
    } onFailure:^(NSError* error) {
        [CPLog info:@"unsubscribe failure: %@", error];
    }];
}

- (void)unsubscribe:(void(^ _Nullable)(BOOL))callback {
    [self unsubscribe:callback onFailure:nil];
}

- (void)unsubscribe:(void(^ _Nullable)(BOOL))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription:) object:nil];

    if (subscriptionId) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/unsubscribe"];
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
            if (failureBlock) {
                failureBlock(error);
            }
        }];

    } else {
        [self clearSubscriptionData];
        callback(YES);
    }
}

#pragma mark - identify the channels being subscribed or not
- (BOOL)isSubscribed {
    if (subscriptionId) {
        return YES;
    }
    return NO;
}

#pragma mark - handle the notification failed
- (void)handleDidFailRegisterForRemoteNotification:(NSError* _Nullable)err {
    if (err.code == 3000) {
        if ([((NSString*)[err.userInfo objectForKey:NSLocalizedDescriptionKey]) rangeOfString:@"no valid 'aps-environment'"].location != NSNotFound) {
            [CPLog error:@"'Push Notification' capability not turned on! Enable it in Xcode under 'Project Target' -> Capabilities."];
        } else {
            [CPLog error:@"Unkown 3000 error returned from APNs when getting a push token: %@", err];
        }
    } else if (err.code == 3010) {
        [CPLog error:@"iOS Simulator does not support push! Please test on a real iOS device. Error: %@", err];
    } else {
        [CPLog error:@"Error registering for Apple push notifications! Error: %@", err];
    }

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY]) {
        [userDefaults setBool:NO forKey:CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY];
        [userDefaults synchronize];
    }
}

#pragma mark - register Device Token
- (void)registerDeviceToken:(id)newDeviceToken {
    deviceToken = newDeviceToken;

    for (id(^listener)() in pendingDeviceTokenListeners) {
        listener(deviceToken);
    }
    pendingDeviceTokenListeners = [NSMutableArray new];

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
    [self syncSubscription:nil];
}

- (void)syncSubscription:(CPFailureBlock _Nullable)failureBlock {
    if (!hasCalledSubscribe) {
        [CPLog debug:@"CleverPushInstance: syncSubscription: Cleverpush SDK not initialised"];
        return;
    }

    if ([self isSubscriptionInProgress]) {
        [CPLog debug:@"syncSubscription aborted - registration already in progress"];
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription:) object:nil];

    [self setSubscriptionInProgress:true];

    [self makeSyncSubscriptionRequest:^(NSError* error) {
        [CPLog error:@"syncSubscription error: %@", [error localizedDescription]];
        if (failureBlock) {
            failureBlock(error);
        }
    } successBlock:^() {
        if (topicsChangedBlock) {
            topicsChangedBlock();
        }
    }];
}

- (void)setSyncSubscriptionRequestData:(NSMutableURLRequest*)request notificationsEnabled:(BOOL)notificationsEnabled {
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
    } else {
        [CPLog debug:@"CleverPushInstance: setSyncSubscriptionRequestData: There is no subscription for CleverPush SDK."];
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

    if ([channelConfig objectForKey:@"preventDuplicatePushesEnabled"] != nil && [[channelConfig objectForKey:@"preventDuplicatePushesEnabled"] boolValue] == YES) {
          [dataDic setObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"deviceId"];
        }

    NSMutableArray* topics = [[NSMutableArray alloc] init];
    topics = [subscriptionTopics mutableCopy];
    if (topics != nil && [topics count] >= 0) {
        [dataDic setObject:topics forKey:@"topics"];
        if (subscriptionTopicsVersion) {
            [dataDic setObject:[NSNumber numberWithInteger:subscriptionTopicsVersion] forKey:@"topicsVersion"];
        } else {
            [dataDic setObject:@"1" forKey:@"topicsVersion"];
        }
    }

    [dataDic setObject:@(notificationsEnabled) forKey:@"hasNotificationPermission"];

    [CPLog info:@"syncSubscription request data:%@ id:%@", dataDic, subscriptionId];

    NSData*postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
}

#pragma mark - add Subcription API call
- (void)makeSyncSubscriptionRequest:(CPFailureBlock)failureBlock successBlock:(void(^)())successBlock {
    if (!deviceToken) {
        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
    }

    if (!deviceToken && !subscriptionId) {
        [self setSubscriptionInProgress:false];
        if (failureBlock) {
            failureBlock([NSError errorWithDomain:@"com.cleverpush" code:400 userInfo:@{NSLocalizedDescriptionKey:@"No deviceToken or subscriptionId available"}]);
        }
        return;
    }

    if (channelId == nil) {
        channelId = [self getChannelIdFromUserDefaults];
    }

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];

    [self areNotificationsEnabled:^(BOOL notificationsEnabled) {
        [self setSyncSubscriptionRequestData:request notificationsEnabled:notificationsEnabled];

        [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
            [self setUnsubscribeStatus:NO];
            [self updateDeselectFlag:NO];
            [self setSubscriptionInProgress:false];

            if ([results objectForKey:@"topics"] != nil) {
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                NSMutableArray*arrTopics = [[NSMutableArray alloc] init];
                [[results objectForKey:@"topics"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                    if (![obj isKindOfClass:[NSNull class]]) {
                        [arrTopics addObject:obj];
                    }
                }];

                [userDefaults setObject:arrTopics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
                if ([results objectForKey:@"topicsVersion"] != nil) {
                    [userDefaults setInteger:[[results objectForKey:@"topicsVersion"] integerValue] forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY];
                }
                subscriptionTopics = nil;
                subscriptionTopicsVersion = 0;
                [userDefaults synchronize];
            }

            if ([results objectForKey:@"id"] != nil) {
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                if (!subscriptionId) {
                    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY];
                }

                NSString*newSubscriptionId = [results objectForKey:@"id"];
                NSString*oldSubscriptionId;
                if ([userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY] != nil) {
                    oldSubscriptionId = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
                }
                BOOL isSubscriptionChanged = ![newSubscriptionId isEqualToString:oldSubscriptionId];
                [CleverPush setSubscriptionChanged:isSubscriptionChanged];

                subscriptionId = [results objectForKey:@"id"];
                [userDefaults setObject:subscriptionId forKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
                [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY];
                [userDefaults synchronize];

                if (handleSubscribed && ![self getHandleSubscribedCalled]) {
                    handleSubscribed(subscriptionId);
                    [self setHandleSubscribedCalled:YES];
                }
                if (handleSubscribedInternal) {
                    handleSubscribedInternal(subscriptionId);
                }
                for (id(^listener)() in pendingSubscriptionListeners) {
                    listener(subscriptionId);
                }
                pendingSubscriptionListeners = [NSMutableArray new];

                if (!isSessionStartCalled) {
                    [self trackSessionStart];
                }

                if (isSubscriptionChanged && ![self isConfirmAlertShown]) {
                    [self setConfirmAlertShown];
                }

                if (successBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock();
                    });
                }
            }
        } onFailure:^(NSError* error) {
            [self setSubscriptionInProgress:false];
            subscriptionTopics = nil;
            subscriptionTopicsVersion = 0;
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    }];
}

#pragma mark - add Attachments to content
- (void)addAttachments:(NSString*)mediaUrl toContent:(UNMutableNotificationContent*)content {
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

    content.attachments = unAttachments;
}

#pragma mark - add Carousel Attachments to the content on a rich notification
- (void)addCarouselAttachments:(NSDictionary*)notification toContent:(UNMutableNotificationContent*)content {
    NSMutableArray* unAttachments = [NSMutableArray new];

    NSArray*images = [[NSArray alloc] init];
    images = [notification objectForKey:@"carouselItems"];
    [images enumerateObjectsUsingBlock:
     ^(NSDictionary*image, NSUInteger index, BOOL*stop)
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
- (BOOL)handleSilentNotificationReceived:(UIApplication* _Nullable)application UserInfo:(NSDictionary* _Nullable)messageDict completionHandler:(void(^ _Nullable)(UIBackgroundFetchResult))completionHandler {
    BOOL startedBackgroundJob = NO;
    [CPLog debug:@"handleSilentNotificationReceived"];

    [CleverPush handleNotificationReceived:messageDict isActive:NO];

    return startedBackgroundJob;
}

- (void)handleNotificationReceived:(NSDictionary* _Nullable)messageDict isActive:(BOOL)isActive {
    NSDictionary* notification = [messageDict cleverPushDictionaryForKey:@"notification"];

    if (!notification) {
        return;
    }

    NSString* notificationId = [notification cleverPushStringForKey:@"_id"];

    if ([CPUtils isEmpty:notificationId] || ([notificationId isEqualToString:lastNotificationReceivedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationReceivedId = notificationId;

    [CPLog debug:@"handleNotificationReceived, isActive %@, Payload %@", @(isActive), messageDict];

    [self setNotificationDelivered:notification
                     withChannelId:[messageDict cleverPushStringForKeyPath:@"channel._id"]
                withSubscriptionId:[messageDict cleverPushStringForKeyPath:@"subscription._id"]
    ];

	  [self handleSilentNotificationReceivedWithAppBanner:messageDict];

    if (isActive && notification != nil && [notification objectForKey:@"chatNotification"] != nil && ![[notification objectForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"chatNotification"] boolValue]) {

        if (currentChatView != nil) {
            [currentChatView loadChat];
        }
    }

    if (!handleNotificationReceived) {
        return;
    }

    CPNotificationReceivedResult* result = [[CPNotificationReceivedResult alloc] initWithPayload:messageDict];

    handleNotificationReceived(result);
}

- (void)handleNotificationOpened:(NSDictionary* _Nullable)payload isActive:(BOOL)isActive actionIdentifier:(NSString* _Nullable)actionIdentifier {
    NSMutableDictionary* payloadMutable = [payload mutableCopy];
    NSString* notificationId = [payloadMutable cleverPushStringForKeyPath:@"notification._id"];
    NSDictionary* notification = [payloadMutable cleverPushDictionaryForKey:@"notification"];
    NSString* action = actionIdentifier;

    if (!notification) {
        return;
    }

    if ([CPUtils isEmpty:notificationId] || ([notificationId isEqualToString:lastNotificationOpenedId] && ![notificationId isEqualToString:@"chat"])) {
        return;
    }
    lastNotificationOpenedId = notificationId;

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setObject:notificationId forKey:CLEVERPUSH_LAST_CLICKED_NOTIFICATION_ID_KEY];
    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_LAST_CLICKED_NOTIFICATION_TIME_KEY];
    [userDefaults synchronize];

    if (action != nil && ([action isEqualToString:@"__DEFAULT__"] || [action isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])) {
        action = nil;
    }
    [CPLog debug:@"handleNotificationOpened, %@, %@", action, payloadMutable];

    [self setNotificationClicked:notificationId
                   withChannelId:[payloadMutable cleverPushStringForKeyPath:@"channel._id"]
              withSubscriptionId:[payloadMutable cleverPushStringForKeyPath:@"subscription._id"]
                      withAction:action
    ];

	[self clearBadge];

    [self updateBadge:nil];

    if (notification != nil && [notification objectForKey:@"chatNotification"] != nil && ![[notification objectForKey:@"chatNotification"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"chatNotification"] boolValue]) {

        if (currentChatView != nil) {
            [currentChatView loadChat];
        }
    }
    if (notification != nil && [notification objectForKey:@"appBanner"] != nil && ![[notification objectForKey:@"appBanner"] isKindOfClass:[NSNull class]]) {
        if ([notification objectForKey:@"voucherCode"] != nil && ![[notification objectForKey:@"voucherCode"] isKindOfClass:[NSNull class]] && ![[notification objectForKey:@"voucherCode"] isEqualToString:@""]) {
            NSMutableDictionary*voucherCodesByAppBanner = [[NSMutableDictionary alloc] init];
            if ([CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder] != nil && [CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder].count > 0) {
                voucherCodesByAppBanner = [[CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder] mutableCopy];
            }
            [voucherCodesByAppBanner setObject:[notification objectForKey:@"voucherCode"] forKey:[notification objectForKey:@"appBanner"]];
            [CPAppBannerModuleInstance setCurrentVoucherCodePlaceholder:voucherCodesByAppBanner];
        }

        [self showAppBanner:[notification valueForKey:@"appBanner"] channelId:[payloadMutable cleverPushStringForKeyPath:@"channel._id"] notificationId:notificationId];
    }

    payloadMutable = [self handleActionInNotification:notification withAction:action payloadMutable:payloadMutable];

    if (action != nil) {
        notification = [payloadMutable cleverPushDictionaryForKey:@"notification"];
    }

    if (notification != nil && [notification objectForKey:@"url"] != nil && ![[notification objectForKey:@"url"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"url"] length] != 0) {
        NSURL*url = [NSURL URLWithString:[notification objectForKey:@"url"]];
        if ([notification objectForKey:@"autoHandleDeepLink"] != nil && ![[notification objectForKey:@"autoHandleDeepLink"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"autoHandleDeepLink"] boolValue]) {
            if ([CPUtils isValidURL:url]) {
                [CPAppBannerModuleInstance updateBannersForDeepLinkWithURL:url];
                [CPUtils tryOpenURL:url];
            }
        }
    }

    CPNotificationOpenedResult* result = [[CPNotificationOpenedResult alloc] initWithPayload:payloadMutable action:action];

    if (!channelId) { // not init
        pendingOpenedResult = result;
    }

    if (!handleNotificationOpened) {
        if (hasWebViewOpened) {
            if (notification != nil && [notification objectForKey:@"url"] != nil && ![[notification objectForKey:@"url"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"url"] length] != 0) {
                NSURL*url = [NSURL URLWithString:[notification objectForKey:@"url"]];
                [CPUtils openSafari:url];
            }
        }
        return;
    }

    handleNotificationOpened(result);
}

- (void)handleSilentNotificationReceivedWithAppBanner:(NSDictionary* _Nullable)messageDict {
    NSDictionary* notification = [messageDict cleverPushDictionaryForKey:@"notification"];

    if (!notification) {
        return;
    }

    NSString* notificationId = [notification cleverPushStringForKey:@"_id"];

    if ([CPUtils isEmpty:notificationId]) {
        return;
    }

    NSString* appBanner = [notification cleverPushStringForKey:@"appBanner"];
    bool isSilent = [notification objectForKey:@"silent"] != nil && ![[notification objectForKey:@"silent"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"silent"] boolValue];

    if (![CPUtils isNullOrEmpty:appBanner] && isSilent) {
      BOOL isActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
      if (isActive) {
        [self showAppBanner:appBanner channelId:[messageDict cleverPushStringForKeyPath:@"channel._id"] notificationId:notificationId];
      } else {
        [CPAppBannerModuleInstance addSilentPushAppBannersId:appBanner notificationId:notificationId];
      }
    }
}

#pragma mark - Handle notification actions buttons events
- (NSMutableDictionary* _Nullable)handleActionInNotification:(NSDictionary* _Nullable)notificationPayload
                                        withAction:(NSString* _Nullable)actionIdentifier
                                    payloadMutable:(NSMutableDictionary* _Nullable)payloadMutable {
    NSMutableDictionary* updatedPayloadMutable = [payloadMutable mutableCopy];

    BOOL hasActionIdentifier = actionIdentifier != nil && ![actionIdentifier isKindOfClass:[NSNull class]];
    BOOL hasActionsArray = notificationPayload[@"actions"] != nil &&
                           ![notificationPayload[@"actions"] isKindOfClass:[NSNull class]] &&
                           [notificationPayload[@"actions"] isKindOfClass:[NSArray class]] &&
                            [((NSArray*)notificationPayload[@"actions"]) count] > 0;

    if (hasActionIdentifier && hasActionsArray) {
        NSMutableArray* actionsArray = [notificationPayload[@"actions"] mutableCopy];
        NSInteger actionValue = [actionIdentifier integerValue];

        if (actionValue >= 0 && actionValue < [actionsArray count]) {
            NSDictionary*selectedAction = actionsArray[actionValue];

            NSString* selectedActionURL = selectedAction[@"url"];
            BOOL hasURL = selectedActionURL != nil &&
                          ![selectedActionURL isKindOfClass:[NSNull class]] &&
                          [selectedActionURL length] > 0;

            if (hasURL) {
                NSMutableDictionary*notificationDict = [updatedPayloadMutable[@"notification"] mutableCopy];
                notificationDict[@"url"] = selectedActionURL;
                updatedPayloadMutable[@"notification"] = notificationDict;
            }
        }
    }
    return updatedPayloadMutable;
}

#pragma mark - Update counts of the notification badge
- (void)updateBadge:(UNMutableNotificationContent* _Nullable)replacementContent {
    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    if ([userDefaults boolForKey:CLEVERPUSH_INCREMENT_BADGE_KEY]) {
        if (replacementContent != nil) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);

            [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification*>*notifications) {
                replacementContent.badge = @([notifications count] + 1);

                dispatch_semaphore_signal(sema);
            }];

            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        } else {
            [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification*>*notifications) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (@available(iOS 16.0, *)) {
                        [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:[notifications count] withCompletionHandler:nil];
                    } else {
                        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[notifications count]];
                    }
                });
            }];
        }

    } else {
        [CPLog debug:@"updateBadge - no incrementBadge used"];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)processLocalActionBasedNotification:(UILocalNotification* _Nullable) notification actionIdentifier:(NSString* _Nullable)actionIdentifier {
    if (!notification.userInfo) {
        return;
    }

    [CPLog debug:@"processLocalActionBasedNotification"];

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
    NSString*notificationId = [notification valueForKey:@"_id"];

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"notification/delivered"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             notificationId, @"notificationId",
                             subscriptionId, @"subscriptionId",
                             nil];

    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil withRetry:NO];

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
    notifications = [self filterDuplicateNotifications:notifications];
    NSArray *notificationsArray = [NSArray arrayWithArray:notifications];

    if ([userDefaults objectForKey:CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT] != nil) {
        maximumNotifications = (int) [userDefaults integerForKey:CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT];
    }

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
    [CPLog debug:@"setNotificationClicked notification:%@, subscription:%@, channel:%@, action:%@", notificationId, subscriptionId, channelId, action];

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"notification/clicked"];
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
    [self enqueueRequest:request onSuccess:nil onFailure:nil withRetry:NO];
}

#pragma mark - Removed badge count from the app icon while open-up an application by tapped on the notification
- (void)clearBadge {
	if (![self getAutoClearBadge]) {
		return;
	}

	[self setBadgeCount:0];
}

#pragma mark - Removed space from 32bytes and convert token in to string.
- (NSString*)stringFromDeviceToken:(NSData*)deviceToken {
    // deviceToken = <4618be8f 70f2a10f ce0e7435 5528fac9 86221163 94b282b1 553afc3c e31ec99c>
    NSUInteger length = deviceToken.length;
    if (length == 0) {
        return nil;
    }
    const unsigned char*buffer = deviceToken.bytes;
    NSMutableString*hexString  = [NSMutableString stringWithCapacity:(length* 2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    // hexString = 4618be8f70f2a10fce0e74355528fac98622116394b282b1553afc3ce31ec99cc
    return [hexString copy];
}

#pragma mark - Initialised notification.
- (void)didRegisterForRemoteNotifications:(UIApplication* _Nullable)app deviceToken:(NSData* _Nullable)deviceToken {
    NSString* parsedDeviceToken = [self stringFromDeviceToken:deviceToken];
    [CPLog info:@"Device Registered with Apple: %@", parsedDeviceToken];
    [self registerDeviceToken:parsedDeviceToken];
}

#pragma mark - Generalised Api call.
- (void)enqueueFailedRequest:(NSURLRequest* _Nullable)request withRetryCount:(NSInteger)retryCount onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    NSURLSession*session = [NSURLSession sharedSession];
    NSURLSessionDataTask*task = [session dataTaskWithRequest:request completionHandler:^(NSData*data, NSURLResponse*response, NSError*error) {
        if (successBlock != nil && error == nil) {
            [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
        } else {
            if (retryCount < httpRequestRetryCount) {
                NSTimeInterval httpRequestRetryBackoffSeconds = pow(httpRequestRetryBackoffMultiplier, retryCount);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(httpRequestRetryBackoffSeconds* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self enqueueFailedRequest:request withRetryCount:retryCount + 1 onSuccess:successBlock onFailure:failureBlock];
                });
            } else {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        }
    }];
    [task resume];
}

- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self enqueueRequest:request onSuccess:successBlock onFailure:failureBlock withRetry:YES];
}

- (void)enqueueRequest:(NSURLRequest* _Nullable)request onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock withRetry:(BOOL)retryOnFailure {
    [CPLog info:@"[HTTP] -> %@ %@", [request HTTPMethod], [request URL].absoluteString];
    NSURLRequest*modifiedRequest;
    if (authorizationToken != nil && ![authorizationToken isKindOfClass:[NSNull class]] && ![authorizationToken isEqualToString:@""]) {
        NSMutableURLRequest*urlRequest = [request mutableCopy];
        NSError*error;
        if ([urlRequest.HTTPMethod isEqualToString:@"GET"]) {
            NSURLComponents*components = [NSURLComponents componentsWithURL:urlRequest.URL resolvingAgainstBaseURL:NO];
            NSMutableArray<NSURLQueryItem*>*queryItems = [components.queryItems mutableCopy];
            if (!queryItems) {
                queryItems = [NSMutableArray new];
            }
            [queryItems addObject:[NSURLQueryItem queryItemWithName:@"authorizationToken" value:authorizationToken]];
            components.queryItems = queryItems;
            urlRequest.URL = components.URL;
            modifiedRequest = urlRequest;
        } else {
            NSMutableDictionary*requestParameters = [[NSJSONSerialization JSONObjectWithData:[urlRequest HTTPBody] options:0 error:&error] mutableCopy];
            if (error) {
                return;
            }
            [requestParameters setObject:authorizationToken forKey:@"authorizationToken"];
            NSData*updatedRequestData = [NSJSONSerialization dataWithJSONObject:requestParameters options:0 error:&error];
            if (error) {
                return;
            }
            [urlRequest setHTTPBody:updatedRequestData];
            modifiedRequest = urlRequest;
        }
    } else {
        modifiedRequest = request;
    }

    NSURLSession*session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:modifiedRequest completionHandler:^(NSData*data, NSURLResponse*response, NSError*error) {
        if (successBlock != nil && error == nil) {
            [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
        } else {
            if (retryOnFailure && error != nil) {
                [self enqueueFailedRequest:request withRetryCount:0 onSuccess:successBlock onFailure:failureBlock];
            } else {
                if (failureBlock && error != nil) {
                    failureBlock(error);
                }
            }
        }
    }] resume];
}

- (void)handleJSONNSURLResponse:(NSURLResponse* _Nullable) response data:(NSData* _Nullable) data error:(NSError* _Nullable) error onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    NSHTTPURLResponse* HTTPResponse = (NSHTTPURLResponse*)response;
    NSInteger statusCode = [HTTPResponse statusCode];
    NSError* jsonError = nil;
    NSMutableDictionary* innerJson;

    if (data != nil && ![CPUtils isEmpty:data]) {
        innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (jsonError) {
            if (failureBlock != nil) {
                failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"returned": jsonError}]);
            }
            return;
        }
    }

    if (error == nil && statusCode >= 200 && statusCode <= 299) {
        if (successBlock != nil) {
            if (innerJson != nil) {
                successBlock(innerJson);
            } else {
                successBlock(nil);
            }
        }
    } else if (failureBlock != nil) {
        if (innerJson != nil && error == nil) {
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"returned": innerJson}]);
        } else if (error != nil) {
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:@{@"error": error}]);
        } else {
            failureBlock([NSError errorWithDomain:@"CleverPushError" code:statusCode userInfo:nil]);
        }
    }
}

- (void)addSubscriptionTags:(NSArray* _Nullable)tagIds {
    [self addSubscriptionTags:tagIds callback:nil];
}

- (void)removeSubscriptionTags:(NSArray* _Nullable)tagIds {
    [self removeSubscriptionTags:tagIds callback:nil];
}

- (void)addSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback {
    dispatch_group_t group = dispatch_group_create();
    for (NSString* tagId in tagIds) {
        dispatch_group_enter(group);
        [self addSubscriptionTag:tagId callback:^(NSString*tagId) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (callback) {
            callback([self getSubscriptionTags]);
        }
    });
}

- (void)removeSubscriptionTags:(NSArray <NSString*>* _Nullable)tagIds callback:(void(^ _Nullable)(NSArray <NSString*>* _Nullable))callback {
    dispatch_group_t group = dispatch_group_create();
    for (NSString* tagId in tagIds) {
        dispatch_group_enter(group);
        [self removeSubscriptionTag:tagId callback:^(NSString*tagId) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (callback) {
            callback([self getSubscriptionTags]);
        }
    });
}

#pragma mark - Remove subscription tag by calling api. subscription/untag
- (void)removeSubscriptionTag:(NSString* _Nullable)tagId {
    [self removeSubscriptionTag:tagId callback:nil];
}

- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self removeSubscriptionTag:tagId callback:callback onFailure:nil];
}

- (void)removeSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self waitForTrackingConsent:^{
        [self removeSubscriptionTagFromApi:tagId callback:^(NSString*tag) {
            if (callback) {
                callback(tagId);
            }
        } onFailure:failureBlock];
    }];
}

- (void)removeSubscriptionTagFromApi:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self getSubscriptionId:^(NSString*subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: removeSubscriptionTagFromApi: There is no subscription for CleverPush SDK."];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/untag"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     tagId, @"tagId",
                                     subscriptionId, @"subscriptionId",
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
            } onFailure:^(NSError* error) {
                [CPLog error:@"Error removing subscription tag: %@", error];
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        });
    }];
}

- (void)addSubscriptionTag:(NSString* _Nullable)tagId {
    [self addSubscriptionTag:tagId callback:nil];
}

- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self addSubscriptionTag:tagId callback:callback onFailure:nil];
}

- (void)addSubscriptionTag:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self waitForTrackingConsent:^{
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        subscriptionTags = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY]];

        if ([subscriptionTags containsObject:tagId]) {
            if (callback) {
                callback(tagId);
            }
            return;
        }
        [self addSubscriptionTagToApi:tagId callback:^(NSString*tagId) {
            if (callback) {
                callback(tagId);
            }
        } onFailure:failureBlock];
    }];
}

- (void)addSubscriptionTagToApi:(NSString* _Nullable)tagId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self getSubscriptionId:^(NSString*subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: addSubscriptionTagToApi: There is no subscription for CleverPush SDK."];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/tag"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     tagId, @"tagId",
                                     subscriptionId, @"subscriptionId",
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
            } onFailure:^(NSError* error) {
                [CPLog error:@"Error adding subscription tag: %@", error];
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        });
    }];
}

- (void)removeSubscriptionTagsAndAttributes {
    [self getSubscriptionId:^(NSString*subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: removeSubscriptionTagsAndAttributes: There is no subscription for CleverPush SDK."];
            return;
        }
        NSArray*subscriptionTags = [CleverPush getSubscriptionTags];
        NSDictionary*attributes = [CleverPush getSubscriptionAttributes];

        if (subscriptionTags != nil && ![subscriptionTags isKindOfClass:[NSNull class]] && subscriptionTags.count > 0) {
            dispatch_group_t group = dispatch_group_create();
            for (NSString* tagId in subscriptionTags) {
                dispatch_group_enter(group);
                [self removeSubscriptionTagFromApi:tagId callback:nil onFailure:nil];
                dispatch_group_leave(group);
            }
        }

        if (attributes != nil && ![attributes isKindOfClass:[NSNull class]] && attributes.count > 0) {
            for (NSString*key in attributes) {
                id value = [attributes objectForKey:key];
                if (value != nil) {
                    if ([value isKindOfClass:[NSString class]]) {
                        [self setSubscriptionAttributeObjectImplementation:key objectValue:@"" callback:nil onSuccess:nil onFailure:nil];
                    } else if ([value isKindOfClass:[NSArray class]]) {
                        [self setSubscriptionAttributeObjectImplementation:key arrayValue:@[]];
                    }
                }
            }
        }
    }];
}

- (void)stopCampaigns {
    if (subscriptionId != nil) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/stop-campaigns"];
        NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        channelId, @"channelId",
                                        subscriptionId, @"subscriptionId",
                                        nil];

        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        } onFailure:^(NSError* error) {
            [CPLog error:@"Failed while doing stopCampaigns request: %@", error.description];
        }];
    }
}

#pragma mark - Live Activity
- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token {
    [self startLiveActivity:activityId pushToken:token onSuccess:nil onFailure:nil];
}

- (void)startLiveActivity:(NSString* _Nullable)activityId pushToken:(NSString* _Nullable)token onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    if (subscriptionId != nil) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];
        NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        channelId, @"channelId",
                                        activityId, @"iosLiveActivityId",
                                        token, @"iosLiveActivityToken",
                                        subscriptionId, @"subscriptionId",
                                        nil];

        [self areNotificationsEnabled:^(BOOL notificationsEnabled) {
            [dataDic setObject:@(notificationsEnabled) forKey:@"hasNotificationPermission"];

            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];
            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
            } onFailure:^(NSError* error) {
                [CPLog error:@"The live activity could not be synchronized because of %@", error.description];
            }];
        }];
    }
}

#pragma mark - Set subscription attribute (single-value) by calling api. subscription/attribute
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value callback:(void(^ _Nullable)(void))callback {
    [self setSubscriptionAttribute:attributeId objectValue:value callback:callback];
}

#pragma mark - Set subscription attribute (multi-value) by calling api. subscription/attribute
- (void)setSubscriptionAttribute:(NSString* _Nullable)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value callback:(void(^ _Nullable)(void))callback {
    [self setSubscriptionAttribute:attributeId objectValue:value callback:callback];
}

- (void)setSubscriptionAttribute:(NSString*)attributeId objectValue:(NSObject*)value callback:(void(^)())callback {
    [self waitForTrackingConsent:^{
        [self setSubscriptionAttributeObjectImplementation:attributeId objectValue:value callback:callback onSuccess:nil onFailure:nil];
    }];
}

- (void)setSubscriptionAttributeObjectImplementation:(NSString*)attributeId arrayValue:(NSArray <NSString*>* _Nullable)value {
    [self setSubscriptionAttributeObjectImplementation:attributeId objectValue:value callback:nil onSuccess:nil onFailure:nil];
}

- (void)setSubscriptionAttribute:(NSString * _Nullable)attributeId arrayValue:(NSArray<NSString *> * _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self setSubscriptionAttribute:attributeId objectValue:value onSuccess:successBlock onFailure:failureBlock];
}

- (void)setSubscriptionAttribute:(NSString*)attributeId objectValue:(NSObject*)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self waitForTrackingConsent:^{
        [self setSubscriptionAttributeObjectImplementation:attributeId objectValue:value callback:nil onSuccess:successBlock onFailure:failureBlock];
    }];
}

- (void)setSubscriptionAttributeObjectImplementation:(NSString*)attributeId arrayValue:(NSArray<NSString *> * _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self setSubscriptionAttributeObjectImplementation:attributeId objectValue:value callback:nil onSuccess:successBlock onFailure:failureBlock];
}

- (void)setSubscriptionAttributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    for (NSString *key in attributes) {
        NSString *value = attributes[key];
        [self setSubscriptionAttributeObjectImplementation:key objectValue:value callback:nil onSuccess:nil onFailure:nil];
    }
}

- (void)setSubscriptionAttributeObjectImplementation:(NSString*)attributeId objectValue:(NSObject*)value callback:(void(^)(void))callback onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self getSubscriptionId:^(NSString *subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: setSubscriptionAttributeObjectImplementation: There is no subscription for CleverPush SDK."];
            if (failureBlock) {
                failureBlock([NSError errorWithDomain:@"com.cleverpush" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Subscription ID is nil or empty"}]);
            }
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/attribute"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     attributeId, @"attributeId",
                                     value, @"value",
                                     subscriptionId, @"subscriptionId",
                                     nil];

            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];
            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                if (!subscriptionAttributes) {
                    subscriptionAttributes = [[NSMutableDictionary alloc] init];
                }
                if (value == nil) {
                    [subscriptionAttributes setObject:@"" forKey:attributeId];
                } else {
                    [subscriptionAttributes setObject:value forKey:attributeId];
                }
                [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                [userDefaults synchronize];

                if (successBlock) {
                    successBlock(results);
                }
                if (callback) {
                    callback();
                }
            } onFailure:^(NSError *error) {
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        });
    }];
}

#pragma mark - Push subscription array attribute value.
- (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self waitForTrackingConsent:^{
        [self getSubscriptionId:^(NSString*subscriptionId) {
            if (subscriptionId == nil) {
                [CPLog debug:@"CleverPushInstance: pushSubscriptionAttributeValue: There is no subscription for CleverPush SDK."];
                if (failureBlock) {
                    failureBlock([NSError errorWithDomain:@"com.cleverpush" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Subscription ID is nil or empty"}]);
                }
                return;
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/attribute/push-value"];
                NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         channelId, @"channelId",
                                         attributeId, @"attributeId",
                                         value, @"value",
                                         subscriptionId, @"subscriptionId",
                                         nil];

                NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                [request setHTTPBody:postData];

                [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                    [CPLog debug:@"Attribute value pushed successfully: %@ %@", attributeId, value];

                    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                    NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                    if (!subscriptionAttributes) {
                        subscriptionAttributes = [[NSMutableDictionary alloc] init];
                    }

                    NSMutableArray*arrayValue = [subscriptionAttributes objectForKey:attributeId];
                    if (!arrayValue) {
                        arrayValue = [NSMutableArray new];
                    } else {
                        arrayValue = [arrayValue mutableCopy];
                    }
                    if (![arrayValue containsString:value]) {
                        [arrayValue addObject:value];
                    }

                    [subscriptionAttributes setObject:arrayValue forKey:attributeId];
                    [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                    [userDefaults synchronize];

                    if (successBlock) {
                        successBlock(results);
                    }
                } onFailure:^(NSError *error) {
                    [CPLog debug:@"Failed to push attribute value: %@", error];
                    if (failureBlock) {
                        failureBlock(error);
                    }
                }];
            });
        }];
    }];
}

- (void)pushSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    [self pushSubscriptionAttributeValue:attributeId value:value onSuccess:nil onFailure:nil];
}

#pragma mark - Pull subscription array attribute value.
- (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self waitForTrackingConsent:^{
        [self getSubscriptionId:^(NSString*subscriptionId) {
            if (subscriptionId == nil) {
                [CPLog debug:@"CleverPushInstance: pullSubscriptionAttributeValue: There is no subscription for CleverPush SDK."];
                if (failureBlock) {
                    failureBlock([NSError errorWithDomain:@"com.cleverpush" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Subscription ID is nil or empty"}]);
                }
                return;
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/attribute/pull-value"];
                NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         channelId, @"channelId",
                                         attributeId, @"attributeId",
                                         value, @"value",
                                         subscriptionId, @"subscriptionId",
                                         nil];

                NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                [request setHTTPBody:postData];

                [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                    [CPLog debug:@"Attribute value pull successfully: %@ %@", attributeId, value];

                    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                    NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
                    if (!subscriptionAttributes) {
                        subscriptionAttributes = [[NSMutableDictionary alloc] init];
                    }

                    NSMutableArray*arrayValue = [subscriptionAttributes objectForKey:attributeId];
                    if (!arrayValue) {
                        arrayValue = [NSMutableArray new];
                    } else {
                        arrayValue = [arrayValue mutableCopy];
                    }
                    [arrayValue removeObject:value];

                    [subscriptionAttributes setObject:arrayValue forKey:attributeId];
                    [userDefaults setObject:subscriptionAttributes forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
                    [userDefaults synchronize];
                    
                    if (successBlock) {
                        successBlock(results);
                    }
                } onFailure:^(NSError *error) {
                    [CPLog debug:@"Failed to pull attribute value: %@", error];
                    if (failureBlock) {
                        failureBlock(error);
                    }
                }];
            });
        }];
    }];
}

- (void)pullSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    [self pullSubscriptionAttributeValue:attributeId value:value onSuccess:nil onFailure:nil];
}

#pragma mark - Check if subscription array attribute has a value.
- (BOOL)hasSubscriptionAttributeValue:(NSString* _Nullable)attributeId value:(NSString* _Nullable)value {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* subscriptionAttributes = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]];
    if (!subscriptionAttributes) {
        return NO;
    }
    NSMutableArray*arrayValue = [subscriptionAttributes objectForKey:attributeId];
    if (!arrayValue) {
        return NO;
    }
    return [arrayValue containsObject:value];
}

#pragma mark - Retrieving all the available tags from the channelConfig
- (NSArray<CPChannelTag*>*)getAvailableTags {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    __block NSArray* channelTags = nil;
    [self getAvailableTags:^(NSArray* channelTags_) {
        channelTags = channelTags_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    return channelTags;
}

- (void)getAvailableTags:(void(^ _Nullable)(NSArray <CPChannelTag*>* _Nullable))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTags = [channelConfig cleverPushArrayForKey:@"channelTags"];
            if (channelTags != nil && [channelTags count] > 0) {
                NSMutableArray* channelTagsArray = [NSMutableArray new];
                [channelTags enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL*stop) {
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
- (NSArray <CPChannelTopic*>*)getAvailableTopics {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    __block NSArray* channelTopics = nil;
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    return channelTopics;
}

- (void)getAvailableTopics:(void(^ _Nullable)(NSArray <CPChannelTopic*>* _Nullable))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            NSArray* channelTopics = [channelConfig cleverPushArrayForKey:@"channelTopics"];
            if (channelTopics != nil && [channelTopics count] > 0) {
                NSSortDescriptor*valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sort" ascending:YES];
                NSArray*descriptors = [NSArray arrayWithObject:valueDescriptor];
                NSArray*sortedTopics = [channelTopics sortedArrayUsingDescriptors:descriptors];

                NSMutableArray* channelTopicsArray = [NSMutableArray new];
                [sortedTopics enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL*stop) {
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
- (NSMutableArray* _Nullable)getAvailableAttributes {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    __block NSMutableArray* customAttributes = [[NSMutableArray alloc] init];
    [self getAvailableAttributes:^(NSMutableArray* customAttributes_) {
        customAttributes = customAttributes_;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    return customAttributes;
}

- (void)getAvailableAttributes:(void(^ _Nullable)(NSMutableArray* _Nullable))callback {
    [self getChannelConfig:^(NSDictionary* channelConfig) {
        if (channelConfig != nil) {
            callback([self getAvailableAttributesFromConfig:channelConfig]);
            return;
        }
        callback([[NSMutableArray alloc] init]);
    }];
}

- (NSMutableArray* _Nullable)getAvailableAttributesFromConfig:(NSDictionary* _Nullable)channelConfig{
    NSMutableArray* customAttributes = [[channelConfig cleverPushArrayForKey:@"customAttributes"] mutableCopy];
    if (customAttributes != nil && [customAttributes count] > 0) {
        return customAttributes;
    } else {
        return [[NSMutableArray alloc] init];
    }
}

#pragma mark - Retrieving subscription tag which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TAGS"
- (NSArray<NSString*>* _Nullable)getSubscriptionTags {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* subscriptionTags = [userDefaults arrayForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    if (!subscriptionTags) {
        return [[NSArray alloc] init];
    }
    return subscriptionTags;
}

#pragma mark - check the tagId exists in the subscriptionTags or not
- (BOOL)hasSubscriptionTag:(NSString* _Nullable)tagId {
    return [[self getSubscriptionTags] containsObject:tagId];
}

- (BOOL)hasSubscriptionTopic:(NSString* _Nullable)topicId {
    return [[self getSubscriptionTopics] containsObject:topicId];
}

#pragma mark - Retrieving subscription attributes which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_ATTRIBUTES"
- (NSDictionary* _Nullable)getSubscriptionAttributes {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* subscriptionAttributes = [userDefaults dictionaryForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    if (!subscriptionAttributes) {
        return [[NSDictionary alloc] init];
    }
    return subscriptionAttributes;
}

- (NSObject* _Nullable)getSubscriptionAttribute:(NSString* _Nullable)attributeId {
    return [[self getSubscriptionAttributes] objectForKey:attributeId];
}

#pragma mark - Update/Set subscription language which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_LANGUAGE"
- (void)setSubscriptionLanguage:(NSString* _Nullable)language {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentLanguage = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
    if (!currentLanguage || (language && ![currentLanguage isEqualToString:language])) {
        [userDefaults setObject:language forKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
        [userDefaults synchronize];

        [self ensureMainThreadSync:^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        }];
    }
}

#pragma mark - Update/Set subscription country which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_COUNTRY"
- (void)setSubscriptionCountry:(NSString* _Nullable)country {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* currentCountry = [userDefaults stringForKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
    if (!currentCountry || (country && ![currentCountry isEqualToString:country])) {
        [userDefaults setObject:country forKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
        [userDefaults synchronize];

        [self ensureMainThreadSync:^{
            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        }];
    }
}

#pragma mark - Retrieving subscription topics which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TOPICS"
- (NSArray<NSString*>* _Nullable)getSubscriptionTopics {
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

- (void)addSubscriptionTopic:(NSString* _Nullable)topicId {
    [self addSubscriptionTopic:topicId callback:nil];
}

- (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self addSubscriptionTopic:topicId callback:callback onFailure:nil];
}

- (void)addSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self getSubscriptionId:^(NSString* subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: addSubscriptionTopic: There is no subscription for CleverPush SDK."];
            return;
        }
        NSMutableArray*topics = [[NSMutableArray alloc] initWithArray:[self getSubscriptionTopics]];
        if ([topics containsObject:topicId]) {
            if (callback) {
                callback(topicId);
            }
            return;
        }

        [topics addObject:topicId];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/topic/add"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     topicId, @"topicId",
                                     subscriptionId, @"subscriptionId",
                                     nil];

            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];

            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                [self setSubscriptionTopics:topics];
                if (callback) {
                    callback(topicId);
                }
            } onFailure:^(NSError* error) {
                [CPLog error:@"Failed adding subscription topic %@", error];
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        });
    }];
}

- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId {
    [self removeSubscriptionTopic:topicId callback:nil];
}

- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback {
    [self removeSubscriptionTopic:topicId callback:callback onFailure:nil];
}

- (void)removeSubscriptionTopic:(NSString* _Nullable)topicId callback:(void(^ _Nullable)(NSString* _Nullable))callback onFailure:(CPFailureBlock _Nullable)failureBlock {
    [self getSubscriptionId:^(NSString* subscriptionId) {
        if (subscriptionId == nil) {
            [CPLog debug:@"CleverPushInstance: removeSubscriptionTopic: There is no subscription for CleverPush SDK."];
            return;
        }
        NSMutableArray*topics = [[NSMutableArray alloc] initWithArray:[self getSubscriptionTopics]];
        if (![topics containsObject:topicId]) {
            if (callback) {
                callback(topicId);
            }
            return;
        }

        [topics removeObject:topicId];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/topic/remove"];
            NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     channelId, @"channelId",
                                     topicId, @"topicId",
                                     subscriptionId, @"subscriptionId",
                                     nil];

            NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
            [request setHTTPBody:postData];

            [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                [self setSubscriptionTopics:topics];
                if (callback) {
                    callback(topicId);
                }
            } onFailure:^(NSError* error) {
                [CPLog error:@"Failed removing subscription topic %@", error];
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        });
    }];
}

#pragma mark - Update/Set subscription topics which has been stored in NSUserDefaults by key "CleverPush_SUBSCRIPTION_TOPICS"
- (void)setSubscriptionTopics:(NSMutableArray<NSString*>* _Nullable)topics onSuccess:(void (^ _Nullable)(void))successBlock onFailure:(CPFailureBlock _Nullable)failure {
    [self setDefaultCheckedTopics:topics];
    [self ensureMainThreadSync:^{
        [self makeSyncSubscriptionRequest:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        } successBlock:^{
            if (successBlock) {
                successBlock();
            }
        }];
    }];
}

- (void)setSubscriptionTopics:(NSMutableArray <NSString*>* _Nullable)topics {
    [self setDefaultCheckedTopics:topics];
    [self ensureMainThreadSync:^{
        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
    }];
}

#pragma mark - Retrieving notifications which has been stored in NSUserDefaults by key "CleverPush_NOTIFICATIONS"
- (NSArray<CPNotification*>* _Nullable)getNotifications {
    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    NSArray* notifications = [userDefaults arrayForKey:CLEVERPUSH_NOTIFICATIONS_KEY];
    if (!notifications) {
        return [[NSArray alloc] init];
    }
    return [self convertDictionariesToNotifications:notifications];
}

- (void)removeNotification:(NSString* _Nullable)notificationId {
    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    if ([userDefaults objectForKey:CLEVERPUSH_NOTIFICATIONS_KEY] != nil) {
        NSArray* notifications = [userDefaults arrayForKey:CLEVERPUSH_NOTIFICATIONS_KEY];
        NSMutableArray*tempNotifications = [notifications mutableCopy];
        if ([notifications count] != 0) {
            for (NSDictionary* notification in notifications) {
                if ([[notification cleverPushStringForKey:@"_id"] isEqualToString: notificationId])
                    [tempNotifications removeObject: notification];
            }
        }
        [userDefaults setObject:tempNotifications forKey:CLEVERPUSH_NOTIFICATIONS_KEY];
        [userDefaults synchronize];
    }
}

#pragma mark - Retrieving notifications based on the flag remote/local
- (void)getNotifications:(BOOL)combineWithApi callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback {
    [self getNotifications:combineWithApi limit:50 skip:0 callback:callback];
}

#pragma mark - Retrieving notifications based on the flag remote/local
- (void)getNotifications:(BOOL)combineWithApi limit:(int)limit skip:(int)skip callback:(void(^ _Nullable)(NSArray<CPNotification*>* _Nullable))callback {
    NSMutableArray<CPNotification*>* notifications = [[self getNotifications] mutableCopy];
    if (combineWithApi) {
        NSString*combinedURL = [self generateGetReceivedNotificationsPath:limit skip:skip];
        [self getReceivedNotificationsFromApi:combinedURL callback:^(NSArray*remoteNotifications) {
            for (NSDictionary*remoteNotification in remoteNotifications) {
                BOOL found = NO;
                for (CPNotification*localNotification in notifications) {
                    if (
                        [localNotification.id isEqualToString:[remoteNotification cleverPushStringForKey:@"_id"]]
                        || [localNotification.tag isEqualToString:[remoteNotification cleverPushStringForKey:@"_id"]]
                        ) {
                            found = YES;
                            break;
                        }
                }

                if (!found) {
                    CPNotification*remoteObject = [[CPNotification alloc] init];
                    remoteObject = [CPNotification initWithJson:remoteNotification];
                    [notifications addObject:remoteObject];
                }
            }

            if (callback) {
                NSArray*sortedNotifications = [self sortArrayOfObjectByDates:notifications basedOnKey:@"createdAt"];
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
            callback(notifications);
        }
    }
}

#pragma mark - Creating URL based on the topic dialogue and append the topicId's as a query parameter.
- (NSString*)generateGetReceivedNotificationsPath:(int)limit skip:(int)skip {
    NSString*path = [NSString stringWithFormat:@"channel/%@/received-notifications?limit=%d&skip=%d&", channelId, limit, skip];
    if ([self hasSubscriptionTopics]) {
        NSMutableArray* dynamicQueryParameters = [self getReceivedNotificationsQueryParameters];
        NSString* appendableQueryParameters = [dynamicQueryParameters componentsJoinedByString:@""];
        NSString*concatenatedURL = [NSString stringWithFormat:@"%@%@", path, appendableQueryParameters];
        return concatenatedURL;
    } else {
        return path;
    }
}

#pragma mark - Appending the topicId's as a query parameter.
- (NSMutableArray*)getReceivedNotificationsQueryParameters {
    NSMutableArray* subscriptionTopics = [self getSubscriptionTopics];
    NSMutableArray* dynamicQueryParameter = [NSMutableArray new];
    [subscriptionTopics enumerateObjectsUsingBlock: ^(id topic, NSUInteger index, BOOL*stop) {
        NSString*queryParameter = [NSString stringWithFormat: @"topics[]=%@&", topic];
        [dynamicQueryParameter addObject:queryParameter];
    }];
    return dynamicQueryParameter;
}

#pragma mark - Group array of object by dates.
- (NSArray*)sortArrayOfObjectByDates:(NSArray*)notifications basedOnKey:(NSString*)key {
    NSSortDescriptor*dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES];
    NSArray*sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    NSArray*sortedEventArray = [notifications sortedArrayUsingDescriptors:sortDescriptors];
    return sortedEventArray;
}

#pragma mark - converting objects to CPNotification.
- (NSMutableArray*)filterDuplicateNotifications:(NSArray*)notifications {
    NSMutableArray* resultNotifications = [NSMutableArray new];
    NSMutableArray* notificationIds = [NSMutableArray new];
    [notifications enumerateObjectsUsingBlock: ^(id objNotification, NSUInteger index, BOOL*stop) {
        NSString* notificationId = [objNotification objectForKey:@"_id"];
        if (![notificationIds containsObject:notificationId]) {
            [notificationIds addObject:notificationId];
            [resultNotifications addObject:objNotification];
        }
    }];
    return resultNotifications;
}

#pragma mark - converting objects to CPNotification.
- (NSMutableArray*)convertDictionariesToNotifications:(NSArray*)notifications {
    NSMutableArray* resultNotifications = [NSMutableArray new];
    NSMutableArray* notificationIds = [NSMutableArray new];
    [notifications enumerateObjectsUsingBlock: ^(id objNotification, NSUInteger index, BOOL*stop) {
        CPNotification*notification = [CPNotification initWithJson:objNotification];
        if (![notificationIds containsObject:notification.id]) {
            [notificationIds addObject:notification.id];
            [resultNotifications addObject:notification];
        }
    }];
    return resultNotifications;
}

#pragma mark - Get the Notifications based on the topic dialog Id's.
- (void)getReceivedNotificationsFromApi:(NSString*)path callback:(void(^)(NSArray*))callback {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:path];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            if (callback) {
                if ([result cleverPushArrayForKey:@"notifications"] && [result cleverPushArrayForKey:@"notifications"] != nil && ![[result cleverPushArrayForKey:@"notifications"] isKindOfClass:[NSNull class]]) {
                    callback([result cleverPushArrayForKey:@"notifications"]);
                }
            }
        }
    } onFailure:^(NSError* error) {
        [CPLog error:@"Failed getting the notifications %@", error];
    }];
}

#pragma mark - Retrieving stories which has been seen by user and stored in NSUserDefaults by key "CleverPush_SEEN_STORIES"
- (NSArray<NSString*>* _Nullable)getSeenStories {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* seenStories = [userDefaults arrayForKey:CLEVERPUSH_SEEN_STORIES_KEY];
    if (!seenStories) {
        return [[NSArray alloc] init];
    }
    return seenStories;
}

- (void)trackEvent:(NSString* _Nullable)eventName {
    return [self trackEvent:eventName properties:nil];
}

- (void)trackEvent:(NSString* _Nullable)eventName amount:(NSNumber* _Nullable)amount {
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                             isNil(amount), @"amount",
                             nil];
    return [self trackEvent:eventName properties:properties];
}

- (void)trackEvent:(NSString* _Nullable)eventName properties:(NSDictionary* _Nullable)properties {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSArray* channelEvents = [channelConfig cleverPushArrayForKey:@"channelEvents"];
            if (channelEvents == nil) {
                [CPLog error:@"Event not found"];
                return;
            }

            NSUInteger eventIndex = [channelEvents indexOfObjectWithOptions:NSEnumerationConcurrent
                                                                passingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                NSDictionary*event = (NSDictionary*) obj;
                return event != nil && [[event cleverPushStringForKey:@"name"] isEqualToString:eventName];
            }];
            if (eventIndex == NSNotFound) {
                [CPLog error:@"Event not found"];
                return;
            }

            NSDictionary*event = [channelEvents objectAtIndex:eventIndex];
            NSString*eventId = [event cleverPushStringForKey:@"_id"];

            [self waitForTrackingConsent:^{
                [self getSubscriptionId:^(NSString* subscriptionId) {
                    if (subscriptionId == nil) {
                        [CPLog debug:@"CleverPushInstance: trackEvent: There is no subscription for CleverPush SDK."];
                        return;
                    }
                    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/conversion"];
                    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    channelId, @"channelId",
                                                    eventId, @"eventId",
                                                    subscriptionId, @"subscriptionId",
                                                    isNil(properties), @"properties",
                                                    nil];

                    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

                    NSString* lastClickedNotificationId = [userDefaults stringForKey:CLEVERPUSH_LAST_CLICKED_NOTIFICATION_ID_KEY];
                    NSDate* lastClickedNotificationTimeStamp = [userDefaults objectForKey:CLEVERPUSH_LAST_CLICKED_NOTIFICATION_TIME_KEY];

                    if (![CPUtils isNullOrEmpty:lastClickedNotificationId] && lastClickedNotificationTimeStamp != nil && [lastClickedNotificationTimeStamp isKindOfClass:[NSDate class]]) {
                        NSTimeInterval secondsSinceLastClick = [[NSDate date] timeIntervalSinceDate:lastClickedNotificationTimeStamp];
                        if (secondsSinceLastClick <= 60 * 60) {
                            [dataDic setObject:lastClickedNotificationId forKey:@"notificationId"];
                        }
                    }

                    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                    [request setHTTPBody:postData];
                    
                    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                        
                    } onFailure:nil];
                }];
            }];

            [CPAppBannerModule setCurrentEventId:eventId];
            [CPAppBannerModule triggerEvent:eventId properties:properties];
            if ([properties count] > 0) {
                for (NSString *key in properties) {
                    id value = [properties objectForKey:key];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [databaseManager updateCountForEventWithId:eventId eventValue:[NSString stringWithFormat:@"%@", value] eventProperty:[NSString stringWithFormat:@"%@", key] updatedDateTime:[CPUtils getCurrentTimestampWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
                    });
                }
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [databaseManager updateCountForEventWithId:eventId eventValue:@"" eventProperty:@"" updatedDateTime:[CPUtils getCurrentTimestampWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
                });
            }
        }];
    });
}

- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName {
    return [self triggerFollowUpEvent:eventName parameters:nil];
}

- (void)triggerFollowUpEvent:(NSString* _Nullable)eventName parameters:(NSDictionary* _Nullable)parameters {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self waitForTrackingConsent:^{
            [self getSubscriptionId:^(NSString* subscriptionId) {
                if (subscriptionId == nil) {
                    [CPLog debug:@"CleverPushInstance: triggerFollowUpEvent: There is no subscription for CleverPush SDK."];
                    return;
                }
                NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/event"];
                NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         channelId, @"channelId",
                                         eventName, @"name",
                                         isNil(parameters), @"parameters",
                                         subscriptionId, @"subscriptionId",
                                         nil];

                NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                [request setHTTPBody:postData];

                [self enqueueRequest:request onSuccess:^(NSDictionary* results) {

                } onFailure:nil];
            }];
        }];
    });
}

#pragma mark - auto Assign Tag Matches
- (void)autoAssignTagMatches:(CPChannelTag* _Nullable)tag pathname:(NSString* _Nullable)pathname params:(NSDictionary* _Nullable)params callback:(void(^ _Nullable)(BOOL))callback {
    NSString* path = [tag autoAssignPath];
    if (path != nil) {
        if ([path isEqualToString:@"[EMPTY]"]) {
            path = @"";
        }

        if ([CPUtils isNullOrEmpty:pathname]) {
            [CPLog debug:@"autoAssignTagMatches - pathname is nil or empty"];
            callback(NO);
            return;
        }

        NSRange range = [pathname rangeOfString:path options:NSRegularExpressionSearch];
        if (range.location == NSNotFound) {
            callback(NO);
            return;
        } else {
            callback(YES);
            return;
        }
    }

    NSString* function = [tag autoAssignFunction];
    if (function != nil && params != nil) {
        JSContext*context = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
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

    [CPLog debug:@"autoAssignTagMatches - no detection method found %@ %@", pathname, params];

    callback(NO);
}

#pragma mark - check Tags
- (void)checkTags:(NSString* _Nullable)urlStr params:(NSDictionary* _Nullable)params {
    NSURL* url = [NSURL URLWithString:urlStr];
    NSString* pathname = [url path];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    [self getAvailableTags:^(NSArray*tags) {
        for (CPChannelTag*tag in tags) {
            [self autoAssignTagMatches:tag pathname:pathname params:params callback:^(BOOL tagMatches) {
                if (tagMatches) {
                    [CPLog debug:@"checkTags: autoAssignTagMatches:YES %@", [tag name]];

                    NSString* tagId = tag.id;
                    NSString* visitsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignVisits-%@", tagId];
                    NSString* sessionsStorageKey = [NSString stringWithFormat:@"CleverPush_TAG-autoAssignSessions-%@", tagId];

                    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"dd-MM-yyyy"];

                    int autoAssignVisits = [[tag autoAssignVisits] intValue];

                    NSString*dateKey = [dateFormatter stringFromDate:[NSDate date]];

                    NSDate*dateAfter = nil;

                    int autoAssignDays = [[tag autoAssignDays] intValue];
                    if (autoAssignDays > 0) {
                        dateAfter = [[NSDate date] dateByAddingTimeInterval:-1*autoAssignDays*24*60*60];
                    }

                    int visits = 0;
                    NSMutableDictionary* dailyVisits = [[NSMutableDictionary alloc] init];
                    if (autoAssignDays > 0 && dateAfter != nil) {
                        dailyVisits = [userDefaults objectForKey:visitsStorageKey];

                        for (NSString* curDateKey in dailyVisits) {
                            NSDate*currDate = [dateFormatter dateFromString:curDateKey];

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
                            NSDate*currDate = [dateFormatter dateFromString:curDateKey];

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
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(autoAssignSeconds* NSEC_PER_SEC));
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
                    [CPLog debug:@"checkTags: autoAssignTagMatches:NO %@", [tag name]];
                }
            }];
        }
    }];
}

#pragma mark - track Page View
- (void)trackPageView:(NSString* _Nullable)url {
    [self trackPageView:url params:nil];
}

- (void)trackPageView:(NSString* _Nullable)url params:(NSDictionary* _Nullable)params {
    currentPageUrl = url;
    [self checkTags:url params:params];
}

- (NSString* _Nullable)getCurrentPageUrl {
    return currentPageUrl;
}

#pragma mark - track Session Start by api call subscription/session/start
- (void)trackSessionStart {
    [self waitForTrackingConsent:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self getChannelConfig:^(NSDictionary* channelConfig) {
                bool trackAppStatistics = [channelConfig objectForKey:@"trackAppStatistics"] != nil && ![[channelConfig objectForKey:@"trackAppStatistics"] isKindOfClass:[NSNull class]] && [[channelConfig objectForKey:@"trackAppStatistics"] boolValue];
                if (trackAppStatistics || subscriptionId) {
                    isSessionStartCalled = YES;
                    sessionVisits = 0;
                    sessionStartedTimestamp = [[NSDate date] timeIntervalSince1970];

                    if (!deviceToken) {
                        deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_DEVICE_TOKEN_KEY];
                    }

                    NSUserDefaults* groupUserDefaults = [CPUtils getUserDefaultsAppGroup];
                    NSString* lastNotificationId = [groupUserDefaults stringForKey:CLEVERPUSH_LAST_NOTIFICATION_ID_KEY];

                    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/session/start"];
                    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             channelId, @"channelId",
                                             subscriptionId, @"subscriptionId",
                                             deviceToken, @"apnsToken",
                                             isNil(lastNotificationId), @"lastNotificationId",
                                             nil];

                    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                    [request setHTTPBody:postData];

                    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
                        if (results != nil) {
                            NSString *syncAfterString = [results objectForKey:@"sdkForceSyncAfter"];

                            if (![CPUtils isNullOrEmpty:syncAfterString]) {
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

                                NSDate *apiDate = [dateFormatter dateFromString:syncAfterString];

                                if (apiDate) {
                                    NSDate *lastUpdatedDate = [[NSUserDefaults standardUserDefaults] objectForKey:CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY];

                                    if (!lastUpdatedDate || [apiDate compare:lastUpdatedDate] == NSOrderedDescending) {
                                        [self ensureMainThreadSync:^{
                                            [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
                                        }];
                                    }
                                }
                            }
                        }
                    } onFailure:nil];
                } else if (subscriptionId == nil) {
                    [CPLog debug:@"CleverPushInstance: trackSessionStart: There is no subscription for CleverPush SDK."];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
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
                    long visits = MAX(sessionVisits, 0);

                    if (channelId == nil || subscriptionId == nil || deviceToken == nil || sessionDuration < 0) {
                        return;
                    }

                    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:@"subscription/session/end"];
                    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             channelId, @"channelId",
                                             subscriptionId, @"subscriptionId",
                                             deviceToken, @"apnsToken",
                                             @(visits), @"visits",
                                             @(sessionDuration), @"duration",
                                             nil];

                    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
                    [request setHTTPBody:postData];

                    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {

                    } onFailure:nil];
                } else if (subscriptionId == nil) {
                    [CPLog debug:@"CleverPushInstance: trackSessionEnd: There is no subscription for CleverPush SDK."];
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

    int topicsDialogSessions = (int)[[channelConfig cleverPushNumberForKey:@"topicsDialogMinimumSessions"] integerValue];
    if (!topicsDialogSessions) {
        topicsDialogSessions = 0;
    }
    int topicsDialogDays = (int)[[channelConfig cleverPushNumberForKey:@"topicsDialogMinimumDays"] integerValue];
    if (!topicsDialogDays) {
        topicsDialogDays = 0;
    }
    int topicsDialogSeconds = (int)[[channelConfig cleverPushNumberForKey:@"topicsDialogMinimumSeconds"] integerValue];
    if (!topicsDialogSeconds) {
        topicsDialogSeconds = 0;
    }
    NSInteger currentTopicsDialogDays = [userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY] ? [self daysBetweenDate:[NSDate date] andDate:[userDefaults objectForKey:CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY]] : 0;

    if ([userDefaults integerForKey:CLEVERPUSH_APP_OPENS_KEY] >= topicsDialogSessions && currentTopicsDialogDays >= topicsDialogDays) {
        [CPLog info:@"showing pending topics dialog"];

        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC* topicsDialogSeconds);
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

- (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow {
    [self showTopicsDialog:targetWindow callback:nil];
}

- (void)showTopicsDialog:(UIWindow* _Nullable)targetWindow callback:(void(^ _Nullable)(void))callback {
    [self getAvailableTopics:^(NSArray* channelTopics_) {
        channelTopics = channelTopics_;
        if ([channelTopics count] == 0) {
            [CPLog info:@"showTopicsDialog: No topics found. Create some first in the CleverPush channel settings."];
            return;
        }
        [self getChannelConfig:^(NSDictionary* channelConfig) {
            NSString* headerTitle = [CPTranslate translate:@"subscribedTopics"];

            if (channelConfig != nil && [channelConfig cleverPushStringForKey:@"confirmAlertSelectTopicsLaterTitle"] != nil && ![[channelConfig cleverPushStringForKey:@"confirmAlertSelectTopicsLaterTitle"] isEqualToString:@""]) {
                headerTitle = [channelConfig cleverPushStringForKey:@"confirmAlertSelectTopicsLaterTitle"];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self isSubscribed]) {
                    [self initTopicsDialogData:channelConfig syncToBackend:NO];
                }

                CPTopicsViewController*topicsController = [[CPTopicsViewController alloc] initWithAvailableTopics:channelTopics selectedTopics:[self getSubscriptionTopics] hasSubscriptionTopics:[self hasSubscriptionTopics]];
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

                DWAlertAction*okAction = [DWAlertAction actionWithTitle:[CPTranslate translate:@"save"] style:DWAlertActionStyleCancel handler:^(DWAlertAction* action) {
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

- (BOOL)hasNewTopicAfterOneHour:(NSDictionary* _Nullable)config initialDifference:(NSInteger)initialDifference displayDialogDifference:(NSInteger)displayAfter {
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

#pragma mark - Notification Display Settings
- (void)setDisplayAlertEnabledForNotifications:(BOOL)enabled {
    isDisplayAlertEnabledForNotifications = enabled;
}

- (void)setSoundEnabledForNotifications:(BOOL)enabled {
    isSoundEnabledForNotifications = enabled;
}

- (void)setBadgeCountEnabledForNotifications:(BOOL)enabled {
    isBadgeCountEnabledForNotifications = enabled;
}

- (UIWindow*)keyWindow {
    UIWindow*foundWindow = nil;
    NSArray*windows = [[UIApplication sharedApplication] windows];
    for (UIWindow*window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

#pragma mark - variable updates and callbacks
- (void)setBrandingColor:(UIColor* _Nullable)color {
    brandingColor = color;
}

- (void)setNormalTintColor:(UIColor* _Nullable)color {
    normalTintColor = color;
}

- (UIColor* _Nullable)getNormalTintColor {
    return normalTintColor;
}

- (void)setTopicsDialogWindow:(UIWindow* _Nullable)window {
    topicsDialogWindow = window;
}

- (void)setTopicsChangedListener:(CPTopicsChangedBlock _Nullable)changedBlock {
    topicsChangedBlock = changedBlock;
}

- (UIColor* _Nullable)getBrandingColor {
    return brandingColor;
}

- (void)setAutoClearBadge:(BOOL)autoClear {
    autoClearBadge = autoClear;
}

- (void)setAutoResubscribe:(BOOL)resubscribe {
    autoResubscribe = resubscribe;
}

- (void)setAppBannerDraftsEnabled:(BOOL)showDraft {
    isShowDraft = showDraft;
}

- (void)setSubscriptionChanged:(BOOL)subscriptionChanged {
    isSubscriptionChanged = subscriptionChanged;
}

- (void)setIgnoreDisabledNotificationPermission:(BOOL)ignore {
    ignoreDisabledNotificationPermission = ignore;
}

- (void)setAutoRequestNotificationPermission:(BOOL)autoRequest {
    autoRequestNotificationPermission = autoRequest;
}

- (void)setKeepTargetingDataOnUnsubscribe:(BOOL)keepData {
    keepTargetingDataOnUnsubscribe = keepData;
}

- (void)addStoryView:(CPStoryView* _Nullable)storyView {
    if (currentStoryView != nil) {
        [currentStoryView removeFromSuperview];
    }
    currentStoryView = storyView;
}

- (void)addChatView:(CPChatView* _Nullable)chatView {
    if (currentChatView != nil) {
        [currentChatView removeFromSuperview];
    }
    currentChatView = chatView;
}

- (void)setApiEndpoint:(NSString* _Nullable)endpoint {
    apiEndpoint = endpoint;
}

- (void)setAppGroupIdentifierSuffix:(NSString* _Nullable)suffix {
    appGroupIdentifier = suffix;
}

- (void)setIabTcfMode:(CPIabTcfMode)mode {
    currentIabTcfMode = mode;
}

- (void)setAuthorizerToken:(NSString* _Nullable)authorizerToken {
    authorizationToken = authorizerToken;
}

- (void)setCustomTopViewController:(UIViewController* _Nullable)viewController {
    customTopViewController = viewController;
}

- (void)setLocalEventTrackingRetentionDays:(int)days {
    localEventTrackingRetentionDays = days;
}

- (void)setBadgeCount:(NSInteger)count {
    if (@available(iOS 16.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:count withCompletionHandler:nil];
    } else {
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;
    }
}

- (NSString* _Nullable)getApiEndpoint {
    return apiEndpoint;
}

- (NSString* _Nullable)getAppGroupIdentifierSuffix {
    return appGroupIdentifier;
}

- (CPIabTcfMode)getIabTcfMode {
    return currentIabTcfMode;
}

- (UIViewController* _Nullable)getCustomTopViewController {
    return customTopViewController;
}

- (int)getLocalEventTrackingRetentionDays {
    return localEventTrackingRetentionDays;
}

- (void)getBadgeCount:(void (^ _Nullable)(NSInteger))completionHandler {
    [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
        NSInteger badgeCount = [notifications count];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(badgeCount);
        });
    }];
}

- (BOOL)isConfirmAlertShown {
    return confirmAlertShown;
}

#pragma mark - App Banner methods
- (void)showAppBanner:(NSString* _Nullable)bannerId {
    [self showAppBanner:bannerId notificationId:nil];
}

- (void)getAppBanners:(NSString* _Nullable)channelId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback {
    [CPAppBannerModule getBanners:channelId bannerId:nil notificationId:nil groupId:nil completion:^(NSMutableArray<CPAppBanner*>*banners) {
        callback(banners);
    }];
}

- (void)getAppBannersByGroup:(NSString* _Nullable)groupId callback:(void(^ _Nullable)(NSMutableArray <CPAppBanner*>* _Nullable))callback {
    [CPAppBannerModule getBanners:channelId bannerId:nil notificationId:nil groupId:groupId completion:^(NSMutableArray<CPAppBanner*>*banners) {
        callback(banners);
    }];
}

- (void)showAppBanner:(NSString*)bannerId notificationId:(NSString*)notificationId {
    [CPAppBannerModule showBanner:channelId bannerId:bannerId notificationId:notificationId force:YES];
}

- (void)showAppBanner:(NSString*)bannerId channelId:(NSString*)channelId notificationId:(NSString*)notificationId {
    BOOL fromNotification = notificationId != nil;
    [CPAppBannerModule initBannersWithChannel:channelId showDrafts:isShowDraft fromNotification:fromNotification];
    [CPAppBannerModule showBanner:channelId bannerId:bannerId notificationId:notificationId force:NO];
}

- (void)setAppBannerOpenedCallback:(CPAppBannerActionBlock _Nullable)callback {
    [CPAppBannerModule setBannerOpenedCallback:callback];
}

- (void)setAppBannerShownCallback:(CPAppBannerShownBlock _Nullable)callback {
    [CPAppBannerModule setBannerShownCallback:callback];
}

- (void)setAppBannerClosedCallback:(CPAppBannerClosedBlock _Nullable)callback {
    [CPAppBannerModule setBannerClosedCallback:callback];
}

- (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock _Nullable)callback {
    [CPAppBannerModule setShowAppBannerCallback:callback];
}

- (void)disableAppBanners {
    [CPAppBannerModule disableBanners];
}

- (void)enableAppBanners {
    [CPAppBannerModule enableBanners];
}

- (void)setAppBannerTrackingEnabled:(BOOL)enabled {
    [CPAppBannerModule setTrackingEnabled:enabled];
}

- (BOOL)getAppBannerDraftsEnabled {
    return isShowDraft;
}

- (BOOL)getSubscriptionChanged {
    return isSubscriptionChanged;
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
- (NSString* _Nullable)getChannelIdFromBundle {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:CLEVERPUSH_CHANNEL_ID_KEY];
}

- (NSString* _Nullable)getChannelIdFromUserDefaults {
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

- (void)getChannelConfigFromBundleId:(NSString* _Nullable)configPath {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:configPath];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            channelId = [result objectForKey:@"channelId"];
            [CPLog info:@"Detected Channel ID from Bundle Identifier: %@", channelId];

            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:channelId forKey:CLEVERPUSH_CHANNEL_ID_KEY];
            [userDefaults setObject:nil forKey:CLEVERPUSH_SUBSCRIPTION_ID_KEY];
            [userDefaults synchronize];

            channelConfig = result;
        }

        [self handleInitialization:YES error:nil];
    } onFailure:^(NSError* error) {
        NSString*failureMessage = [NSString stringWithFormat:@"Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error];
        [CPLog error:@"%@", failureMessage];
        [self handleInitialization:NO error:failureMessage];
    }];
}

- (void)getChannelConfigFromChannelId:(NSString* _Nullable)configPath {
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:configPath];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            channelConfig = result;
        }

        BOOL confirmAlertSettingsEnabled = ([channelConfig objectForKey:@"confirmAlertSettingsEnabled"] != nil) &&
                                                  ![[channelConfig objectForKey:@"confirmAlertSettingsEnabled"] isKindOfClass:[NSNull class]] &&
                                                  [[channelConfig objectForKey:@"confirmAlertSettingsEnabled"] boolValue];
        BOOL confirmAlertTestsEnabled = ([channelConfig objectForKey:@"confirmAlertTestsEnabled"] != nil) &&
                                          ![[channelConfig objectForKey:@"confirmAlertTestsEnabled"] isKindOfClass:[NSNull class]] &&
                                          [[channelConfig objectForKey:@"confirmAlertTestsEnabled"] boolValue];

        if (channelConfig != nil && confirmAlertSettingsEnabled && confirmAlertTestsEnabled) {
            NSString*testsConfigPath = [configPath stringByAppendingString:@"&confirmAlertTestsEnabled=true"];
            NSMutableURLRequest* testsRequest = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:testsConfigPath];
            [self enqueueRequest:testsRequest onSuccess:^(NSDictionary* testsResult) {
                if (testsResult != nil) {
                    channelConfig = testsResult;
                }

                [self handleInitialization:YES error:Nil];
            } onFailure:^(NSError* error) {
                NSString*failureMessage = [NSString stringWithFormat:@"Failed getting the channel config %@", error];
                [CPLog error:@"%@", failureMessage];
                [self handleInitialization:NO error:failureMessage];
                [self fireChannelConfigListeners];
            }];
            return;
        }

        [self handleInitialization:YES error:nil];
    } onFailure:^(NSError* error) {
        NSString*failureMessage = [NSString stringWithFormat:@"Failed getting the channel config %@", error];
        [CPLog error:@"%@", failureMessage];
        [self handleInitialization:NO error:failureMessage];
    }];
}

- (BOOL)isChannelIdChanged:(NSString* _Nullable)channelId; {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if ([channelId isEqualToString:[userDefaults stringForKey:CLEVERPUSH_CHANNEL_ID_KEY]]) {
        return false;
    } else {
        return true;
    }
}

- (void)addOrUpdateChannelId:(NSString* _Nullable)channelId{
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

- (CPHandleSubscribedBlock _Nullable)getSubscribeHandler {
    return handleSubscribed;
}

- (void)setSubscribeHandler:(CPHandleSubscribedBlock _Nullable)subscribedCallback {
    handleSubscribed = subscribedCallback;
}

- (void)handleInitialization:(BOOL)success error:(NSString* _Nullable)error {
    if (hasInitialized) {
        return;
    }
    hasInitialized = YES;
    if (handleInitialized) {
        handleInitialized(success, error);
    }
    [self fireChannelConfigListeners];
}

#pragma mark - Handle the universal links from notification tap event
- (void)setHandleUniversalLinksInAppForDomains:(NSArray<NSString *> *_Nullable)domains {
    handleUniversalLinksInApp = domains;
}

- (NSArray<NSString*>* _Nullable)getHandleUniversalLinksInAppForDomains {
    return handleUniversalLinksInApp;
}

- (BOOL)getHandleUrlFromSceneDelegate {
    return handleUrlFromSceneDelegate;
}

#pragma mark - Handle the style of the topViewController (the presented app banner controller).
- (void)setAppBannerModalPresentationStyle:(UIModalPresentationStyle)style {
    appBannerModalPresentationStyle = style;
}

- (UIModalPresentationStyle)getAppBannerModalPresentationStyle {
    return appBannerModalPresentationStyle;
}

- (void)setLogListener:(CPLogListener)listener {
    [CPLog setLogListener:listener];
}

#pragma mark - recieved notifications from the Extension.
- (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    [CPLog debug:@"didReceiveNotificationExtensionRequest"];

    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }

    NSDictionary* payload = request.content.userInfo;
    NSDictionary* notification = [payload cleverPushDictionaryForKey:@"notification"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [self handleNotificationReceived:payload isActive:NO];

    // badge count
    [self updateBadge:replacementContent];
    
    // Ensure badge is set explicitly when incrementBadge is enabled
    if ([userDefaults boolForKey:CLEVERPUSH_INCREMENT_BADGE_KEY] && replacementContent.badge == nil) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification*>*notifications) {
            replacementContent.badge = @([notifications count] + 1);
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }

    // rich notifications
    if (notification != nil) {
        bool isCarousel = [notification objectForKey:@"carouselEnabled"] != nil && ![[notification objectForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification cleverPushArrayForKey:@"carouselItems"] != nil && ![[notification cleverPushArrayForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"carouselEnabled"] boolValue];

        [self addActionButtonsToNotificationRequest:request
                                        withPayload:payload
                     withMutableNotificationContent:replacementContent];

        if (isCarousel) {
            [CPLog debug:@"appending carousel medias"];
            [self addCarouselAttachments:notification toContent:replacementContent];
        } else {
            NSString* mediaUrl = [notification valueForKey:@"mediaUrl"];
            if (![mediaUrl isKindOfClass:[NSNull class]]) {
                [CPLog debug:@"appending media: %@", mediaUrl];
                [self addAttachments:mediaUrl toContent:replacementContent];
            }
        }
    }

    return replacementContent;
}

#pragma mark - service Extension Time Will Expire Request.
- (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    [CPLog debug:@"serviceExtensionTimeWillExpireRequest"];

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
               withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    if (request.content.categoryIdentifier && ![request.content.categoryIdentifier isEqualToString:@""]) {
        return;
    }

    NSDictionary* notification = [payload valueForKey:@"notification"];
    bool isCarousel = notification != nil && [notification objectForKey:@"carouselEnabled"] != nil && ![[notification objectForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]] && [notification cleverPushArrayForKey:@"carouselItems"] != nil && ![[notification cleverPushArrayForKey:@"carouselItems"] isKindOfClass:[NSNull class]] && [[notification objectForKey:@"carouselEnabled"] boolValue];

    NSArray* actions = [notification objectForKey:@"actions"];

    NSMutableArray* actionArray = [NSMutableArray new];

    NSMutableSet<UNNotificationCategory*>* allCategories = CPNotificationCategoryController.sharedInstance.existingCategories;

    if (isCarousel) {
        replacementContent.categoryIdentifier = @"carousel";
        [[CPNotificationCategoryController sharedInstance] carouselCategory];

    } else if ([actions isKindOfClass:[NSNull class]] || !actions || [actions count] == 0) {
        return;

    } else {
        [actions enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL*stop) {
            UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:[NSString stringWithFormat: @"%@", @(idx)]
                                                                                title:item[@"title"]
                                                                              options:UNNotificationActionOptionForeground];
            [actionArray addObject:action];
        }];

        NSString* newCategoryIdentifier = [CPNotificationCategoryController.sharedInstance registerNotificationCategoryForNotificationId:[payload cleverPushStringForKeyPath:@"notification._id"]];

        UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:newCategoryIdentifier
                                                                                  actions:actionArray
                                                                        intentIdentifiers:@[]
                                                                                  options:UNNotificationCategoryOptionCustomDismissAction];

        replacementContent.categoryIdentifier = newCategoryIdentifier;

        if (allCategories) {
            NSMutableSet<UNNotificationCategory*>* newCategorySet = [NSMutableSet new];
            for (UNNotificationCategory*existingCategory in allCategories) {
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

#pragma mark - Cleverpush database information
- (void)setDatabaseInfo {
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [[NSUserDefaults standardUserDefaults] setObject:[dateFormatter stringFromDate:[NSDate date]] forKey:CLEVERPUSH_DATABASE_CREATED_TIME_KEY];
   [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CLEVERPUSH_DATABASE_CREATED_KEY];
   [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
