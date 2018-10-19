#import "CleverPush.h"
#import "CleverPushHTTPClient.h"

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

@implementation CleverPush

NSString * const CLEVERPUSH_SDK_VERSION = @"0.0.17";

static BOOL registeredWithApple = NO;
static BOOL waitingForApnsResponse = false;
static BOOL startFromNotification = NO;

static NSString* channelId;
NSDate* lastSync;
NSString* subscriptionId;
NSString* deviceToken;
CleverPushHTTPClient *httpClient;
CPResultSuccessBlock cpTokenUpdateSuccessBlock;
CPFailureBlock cpTokenUpdateFailureBlock;
CPHandleNotificationOpenedBlock handleNotificationOpened;
CPHandleSubscribedBlock handleSubscribed;
CPHandleSubscribedBlock handleSubscribedInternal;
NSDictionary* channelConfig;

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

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)openedCallback handleSubscribed:(CPHandleSubscribedBlock)subscribedCallback autoRegister:(BOOL)autoRegister {
    handleNotificationOpened = openedCallback;
    handleSubscribed = subscribedCallback;

    if (self) {
        UIApplication* sharedApp = [UIApplication sharedApplication];
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

        httpClient = [[CleverPushHTTPClient alloc] init];

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
            return self;
        }

        subscriptionId = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_ID"];
        deviceToken = [userDefaults stringForKey:@"CleverPush_DEVICE_TOKEN"];
        if (([sharedApp respondsToSelector:@selector(currentUserNotificationSettings)])) {
            registeredWithApple = [sharedApp currentUserNotificationSettings].types != (NSUInteger)nil;
        } else {
            registeredWithApple = deviceToken != nil;
        }

        if (autoRegister || registeredWithApple) {
            [self subscribe];
        } else if ([sharedApp respondsToSelector:@selector(registerForRemoteNotifications)]) {
            waitingForApnsResponse = true;
            [sharedApp registerForRemoteNotifications];
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

    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
    }

    [self clearBadge:false];

    return self;
}

+ (NSDictionary*)getChannelConfig {
    if (channelConfig) {
        return channelConfig;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getChannelConfig) object:nil];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"GET" path:[NSString stringWithFormat:@"channel/%@/config", channelId]];
    [self enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            channelConfig = result;
            dispatch_semaphore_signal(sema);
        }
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: getChannelConfig failure %@", error);
    }];
    
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

+ (void)subscribe {
    waitingForApnsResponse = true;
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
    NSString* subscriptionId = [self getSubscriptionId];
    if (subscriptionId) {
        NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"subscription/unsubscribe"];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 channelId, @"channelId",
                                 subscriptionId, @"subscriptionId",
                                 nil];
        
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [self enqueueRequest:request onSuccess:nil onFailure:nil];
    }
}

+ (BOOL)isSubscribed {
    BOOL isSubscribed = NO;
    if (subscriptionId) {
        isSubscribed = YES;
    }
    return isSubscribed;
}

+ (void)handleDidFailRegisterForRemoteNotification:(NSError*)err {
    waitingForApnsResponse = false;

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
    waitingForApnsResponse = false;

    [self updateDeviceToken:inDeviceToken onSuccess:successBlock onFailure:failureBlock];

    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"CleverPush_DEVICETOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)updateDeviceToken:(NSString*)newDeviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    if (subscriptionId == nil) {
        deviceToken = newDeviceToken;
        cpTokenUpdateSuccessBlock = successBlock;
        cpTokenUpdateFailureBlock = failureBlock;

        [CleverPush syncSubscription];
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

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncSubscription) object:nil];

    registrationInProgress = true;

    NSMutableURLRequest* request;
    request = [httpClient requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];

    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             deviceToken, @"apnsToken",
                             @"SDK", @"browserType",
                             CLEVERPUSH_SDK_VERSION, @"browserVersion",
                             @"iOS", @"platformName",
                             [[UIDevice currentDevice] systemVersion], @"platformVersion",
                             subscriptionId, @"subscriptionId",
                             nil];

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

+(NSString*)getUsableDeviceToken {
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
        return deviceToken;

    return ([[UIApplication sharedApplication] currentUserNotificationSettings].types > 0) ? deviceToken : NULL;
}

+ (void)handlePushReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive {
    if (!channelId) {
        return;
    }

    [self handleNotificationOpened:messageDict isActive:isActive];
}

+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive {
    NSString* notificationId = [payload valueForKeyPath:@"notification._id"];

    [CleverPush setNotificationDelivered:notificationId];
    [CleverPush setNotificationClicked:notificationId];

    [self clearBadge:true];

    if (!handleNotificationOpened) {
        return;
    }

    CPNotificationOpenedResult * result = [[CPNotificationOpenedResult alloc] initWithPayload:payload];

    handleNotificationOpened(result);
}

+ (void)setNotificationDelivered:(NSString*)notificationId {
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"notification/delivered"];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             notificationId, @"notificationId",
                             [self getSubscriptionId], @"subscriptionId",
                             nil];

    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
}

+ (void)setNotificationClicked:(NSString*)notificationId {
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"notification/clicked"];
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
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
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
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"subscription/tag"];
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
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"subscription/untag"];
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
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:@"subscription/attribute"];
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

@end
