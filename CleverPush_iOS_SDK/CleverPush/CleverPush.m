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

-(instancetype)initWithPayload:(NSDictionary *)inPayload {
    self = [super init];
    if (self) {
        _payload = inPayload;
    }
    return self;
}

@end

@implementation CleverPush

static BOOL registeredWithApple = NO;
static BOOL waitingForApnsResponse = false;
static BOOL startFromNotification = NO;

static NSString* channelId;
NSString* subscriptionId;
NSString* deviceToken;
CleverPushHTTPClient *httpClient;
CPResultSuccessBlock tokenUpdateSuccessBlock;
CPFailureBlock tokenUpdateFailureBlock;
CPHandleNotificationOpenedBlock handleNotificationOpened;

BOOL subscriptionSet;

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
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:NULL settings:@{@"autoPrompt":@YES}];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)channelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)actionCallback {
    return [self initWithLaunchOptions:launchOptions channelId:channelId handleNotificationOpened:actionCallback settings:@{@"autoPrompt":@YES}];
}

+ (id)initWithLaunchOptions:(NSDictionary*)launchOptions channelId:(NSString*)newChannelId handleNotificationOpened:(CPHandleNotificationOpenedBlock)actionCallback settings:(NSDictionary*)settings {
    
    if (self) {
        UIApplication* sharedApp = [UIApplication sharedApplication];
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        httpClient = [[CleverPushHTTPClient alloc] init];
        
        if (newChannelId)
            channelId = newChannelId;
        else {
            channelId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CleverPush_CHANNEL_ID"];
        }
        
        if (channelId == nil)
            channelId  = [userDefaults stringForKey:@"CleverPush_CHANNEL_ID"];
        else if (![channelId isEqualToString:[userDefaults stringForKey:@"CleverPush_CHANNEL_ID"]]) {
            [userDefaults setObject:channelId forKey:@"CleverPush_CHANNEL_ID"];
            [userDefaults setObject:nil forKey:@"CleverPush_SUBSCRIPTION_ID"];
            [userDefaults synchronize];
        }
        
        if (!channelId) {
            return self;
        }
        
        subscriptionId = [userDefaults stringForKey:@"CleverPush_SUBSCRIPTION_ID"];
        deviceToken = [userDefaults stringForKey:@"CleverPush_DEVICE_TOKEN"];
        if (([sharedApp respondsToSelector:@selector(currentUserNotificationSettings)]))
            registeredWithApple = [sharedApp currentUserNotificationSettings].types != (NSUInteger)nil;
        else
            registeredWithApple = deviceToken != nil || [userDefaults boolForKey:@"GT_REGISTERED_WITH_APPLE"];
        subscriptionSet = [userDefaults objectForKey:@"CleverPush_SUBSCRIPTION"] == nil;
        
        BOOL autoPrompt = YES;
        if (settings[@"autoPromt"] && [settings[@"autoPrompt"] isKindOfClass:[NSNumber class]])
            autoPrompt = [settings[@"autoPrompt"] boolValue];
        if (autoPrompt || registeredWithApple)
            [self registerForPushNotifications];
        else if ([sharedApp respondsToSelector:@selector(registerForRemoteNotifications)]) {
            waitingForApnsResponse = true;
            [sharedApp registerForRemoteNotifications];
        }
        
        if (subscriptionId != nil)
            [self registerUser];
        else
            [self performSelector:@selector(registerUser) withObject:nil afterDelay:30.0f];
    }
    
    // cold start from tap on a notification
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        startFromNotification = YES;
    }
    
    [self clearBadge:false];
    
    return self;
}

+ (void)registerForPushNotifications {
    waitingForApnsResponse = true;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        Class uiUserNotificationSettings = NSClassFromString(@"UIUserNotificationSettings");
        NSSet* categories = [[[UIApplication sharedApplication] currentUserNotificationSettings] categories];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[uiUserNotificationSettings settingsForTypes:UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge categories:categories]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
        if (!registeredWithApple) {
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"GT_REGISTERED_WITH_APPLE"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
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

+ (void)updateDeviceToken:(NSString*)deviceToken onSuccess:(CPResultSuccessBlock)successBlock onFailure:(CPFailureBlock)failureBlock {
    if (subscriptionId == nil) {
        deviceToken = deviceToken;
        tokenUpdateSuccessBlock = successBlock;
        tokenUpdateFailureBlock = failureBlock;
        
        [CleverPush registerUser];
        return;
    }
    
    if ([deviceToken isEqualToString:deviceToken]) {
        if (successBlock)
            successBlock(nil);
        return;
    }
    
    deviceToken = deviceToken;
    
    NSMutableURLRequest* request;
    request = [httpClient requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];
    
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             deviceToken, @"token",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    [self enqueueRequest:request onSuccess:successBlock onFailure:failureBlock];
}

static BOOL registrationInProgress = false;

+ (void)registerUser {
    if (registrationInProgress)
        return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(registerUser) object:nil];
    
    registrationInProgress = true;
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:[NSString stringWithFormat:@"subscription/sync/%@", channelId]];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel   = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    channelId, @"channelId",
                                    deviceModel, @"deviceModel",
                                    [[UIDevice currentDevice] systemVersion], @"devicePlatform",
                                    [[NSLocale preferredLanguages] objectAtIndex:0], @"language",
                                    [NSNumber numberWithInt:(int)[[NSTimeZone localTimeZone] secondsFromGMT]], @"timezone",
                                    deviceToken, @"token",
                                    nil];
    
    if (subscriptionId == nil) {
        dataDic[@"ios_bundle"] = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    [self enqueueRequest:request onSuccess:^(NSDictionary* results) {
        
        registrationInProgress = false;
        
        if ([results objectForKey:@"id"] != nil) {
            
            subscriptionId = [results objectForKey:@"id"];
            [[NSUserDefaults standardUserDefaults] setObject:subscriptionId forKey:@"CleverPush_SUBSCRIPTION_ID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if (deviceToken) {
                [self updateDeviceToken:deviceToken onSuccess:tokenUpdateSuccessBlock onFailure:tokenUpdateFailureBlock];
            }
        }
    } onFailure:^(NSError* error) {
        registrationInProgress = false;
    }];
}

+(NSString*)getUsableDeviceToken {
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
        return deviceToken;
    
    return ([[UIApplication sharedApplication] currentUserNotificationSettings].types > 0) ? deviceToken : NULL;
}


// entrypoint for: notifications opened, notification received (iOS 9-10 while in focus)
+ (void)handlePushReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive {
    if (!channelId)
        return;
    
    if (isActive) {
        NSString* messageId = [messageDict objectForKey:@"i"];
        [CleverPush setNotificationOpened:messageId];
    } else {
        [self handleNotificationOpened:messageDict isActive:isActive];
    }
}


+ (void)handleNotificationOpened:(NSDictionary*)payload isActive:(BOOL)isActive {
    NSString* notificationId = [payload objectForKey:@"notificationId"];
    [CleverPush setNotificationOpened:notificationId];
    
    [self clearBadge:true];
    
    if (!handleNotificationOpened) {
        return;
    }
    
    CPNotificationOpenedResult * result = [[CPNotificationOpenedResult alloc] initWithPayload:payload];
    
    handleNotificationOpened(result);
}

+ (void)setNotificationOpened:(NSString*)messageId {
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"notifications/%@", messageId]];
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             channelId, @"channelId",
                             subscriptionId, @"subscriptionId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [self enqueueRequest:request onSuccess:nil onFailure:nil];
    [[NSUserDefaults standardUserDefaults] setObject:messageId forKey:@"GT_LAST_MESSAGE_OPENED_"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[[NSOperationQueue alloc] init]
     completionHandler:^(NSURLResponse* response,
                         NSData* data,
                         NSError* error) {
         [self handleJSONNSURLResponse:response data:data error:error onSuccess:successBlock onFailure:failureBlock];
     }];
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
    
    if (error == nil && statusCode == 200) {
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

@end
