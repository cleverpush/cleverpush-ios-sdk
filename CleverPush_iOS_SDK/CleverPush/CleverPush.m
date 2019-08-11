#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "UNUserNotificationCenter+CleverPush.h"
#import "UIApplicationDelegate+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CZPickerView.h"

#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

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

NSString * const CLEVERPUSH_SDK_VERSION = @"0.1.4";

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
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
NSDictionary* channelConfig;
NSArray* channelTopics;
UIBackgroundTaskIdentifier mediaBackgroundTask;
CZPickerView *channelTopicsPicker;
BOOL channelTopicsPickerVisible = NO;

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

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback autoRegister:(BOOL)autoRegister {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:autoRegister];
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

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:NULL autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:NULL handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback {
    return [self initWithLaunchOptions:launchOptions channelId:NULL handleNotificationOpened:openedCallback handleSubscribed:subscribedCallback autoRegister:YES];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegisterParam {
    handleNotificationOpened = openedCallback;
    handleSubscribed = subscribedCallback;
    autoRegister = autoRegisterParam;

    if (self) {
        UIApplication* sharedApp = [UIApplication sharedApplication];
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
    
    lastSync = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION_LAST_SYNC"];
    NSDate* nextSync = [NSDate date];
    if (lastSync) {
        // 3 days after last sync
        nextSync = [lastSync dateByAddingTimeInterval:3*24*60*60];
    }
    
    if (subscriptionId != nil) {
        if (nextSync < [NSDate date]) {
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
                dispatch_semaphore_signal(sema);
            }
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
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
                
                dispatch_semaphore_signal(sema);
            }
        } onFailure:^(NSError* error) {
            NSLog(@"CleverPush Error: Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error);
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

+ (BOOL)notificationsEnabled {
    BOOL isEnabled = NO;
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
    return isEnabled;
}

+ (void)subscribe {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
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

+ (void)registerDeviceToken:(id)inDeviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    [self updateDeviceToken:inDeviceToken onSuccess:successBlock onFailure:failureBlock];

    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"CleverPush_DEVICETOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)updateDeviceToken:(NSString*)newDeviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    if (subscriptionId == nil) {
        deviceToken = newDeviceToken;
        cpTokenUpdateSuccessBlock = successBlock;
        cpTokenUpdateFailureBlock = failureBlock;

        [self performSelector:@selector(syncSubscription) withObject:nil afterDelay:1.0f];
        return;
    }

    if ([deviceToken isEqualToString:newDeviceToken]) {
        if (successBlock)
            successBlock(nil);
        return;
    }

    deviceToken = newDeviceToken;
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
    [self handleNotificationReceived:messageDict isActive:isActive wasOpened:NO];
}

+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive wasOpened:(BOOL)wasOpened {
    if (!channelId) {
        return;
    }
    
    [self handleNotificationOpened:messageDict isActive:isActive];
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

    NSDictionary* notification = [messageDict valueForKey:@"notification"];
    
    if (application.applicationState != UIApplicationStateBackground) {
        [CleverPush handleNotificationReceived:messageDict isActive:NO wasOpened:YES];
    } else {
        [CleverPush setNotificationDelivered:notification];
    }
    
    return startedBackgroundJob;
}

+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive {
    NSString* notificationId = [payload valueForKeyPath:@"notification._id"];

    // [CleverPush setNotificationDelivered:notificationId];
    
    if (!isActive) {
        [CleverPush setNotificationClicked:notificationId];
    }

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
    
    BOOL isActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    [self handleNotificationReceived:notification.userInfo isActive:isActive wasOpened:YES];
    
    if (!isActive) {
        [self handleNotificationOpened:notification.userInfo
                              isActive:isActive];
    }
}

+ (void)setNotificationDelivered:(NSDictionary*)notification {
    [self setNotificationDelivered:notification withChannelId:channelId withSubscriptionId:[self getSubscriptionId]];
}

+ (void)setNotificationDelivered:(NSDictionary*)notification withChannelId:(NSString*)channelId withSubscriptionId:(NSString*)subscriptionId {
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
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"notification/clicked"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             notificationId, @"notificationId",
                             [self getSubscriptionId], @"subscriptionId",
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

+ (void)didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken {
    NSString* trimmedDeviceToken = [[inDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString* parsedDeviceToken = [[trimmedDeviceToken componentsSeparatedByString:@" "] componentsJoinedByString:@""];
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

+ (void)showTopicsDialog {
    if (channelTopicsPickerVisible) {
        return;
    }
    channelTopicsPickerVisible = YES;
    
    channelTopics = [self getAvailableTopics];
    if ([channelTopics count] == 0) {
        NSLog(@"CleverPush: showTopicsDialog: No topics found. Create some first in the CleverPush channel settings.");
    }
    
    channelTopicsPicker = [[CZPickerView alloc] initWithHeaderTitle:@"Abonnierte Themen"
                                                  cancelButtonTitle:@"Abbrechen"
                                                 confirmButtonTitle:@"Speichern"];
    channelTopicsPicker.allowMultipleSelection = YES;
    channelTopicsPicker.delegate = self;
    channelTopicsPicker.dataSource = self;
    channelTopicsPicker.headerBackgroundColor = [UIColor whiteColor];
    channelTopicsPicker.headerTitleColor = [UIColor darkGrayColor];
    channelTopicsPicker.confirmButtonBackgroundColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    
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

+ (UNMutableNotificationContent*)didReceiveNotificationExtensionRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    NSDictionary* payload = request.content.userInfo;
    NSDictionary* notification = [payload valueForKey:@"notification"];
    NSString* channelId = [payload valueForKeyPath:@"channel._id"];
    NSString* subscriptionId = [payload valueForKeyPath:@"subscription._id"];
    
    [self setNotificationDelivered:notification withChannelId:channelId withSubscriptionId:subscriptionId];
    
    NSString* mediaUrl = [payload valueForKeyPath:@"notification.mediaUrl"];
    if (![mediaUrl isKindOfClass:[NSNull class]]) {
        NSLog(@"CleverPush: appending media: %@", mediaUrl);
        [self addAttachments:mediaUrl toContent:replacementContent];
    }
    
    return replacementContent;
}

+ (UNMutableNotificationContent*)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest*)request withMutableNotificationContent:(UNMutableNotificationContent*)replacementContent {
    if (!replacementContent) {
        replacementContent = [request.content mutableCopy];
    }
    
    return replacementContent;
}

@end

@implementation UIApplication (CleverPush)

#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
+ (void)load {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([[processInfo processName] isEqualToString:@"IBDesignablesAgentCocoaTouch"] || [[processInfo processName] isEqualToString:@"IBDesignablesAgent-iOS"])
        return;
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.0")) {
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
    
    UNUserNotificationCenter* curNotifCenter = [UNUserNotificationCenter currentNotificationCenter];
    
    if (!curNotifCenter.delegate) {
        curNotifCenter.delegate = (id)self;
    }
}

@end
