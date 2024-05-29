#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UIApplicationDelegate+CleverPush.h"
#import "CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CPLog.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface CleverPush(UN_extra)

+ (void) didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void) handleDidFailRegisterForRemoteNotification:(NSError*)error;
+ (NSString*) channelId;
+ (void) handleNotificationReceived:(NSDictionary *)messageDict isActive:(BOOL)isActive wasOpened:(BOOL)wasOpened;
+ (BOOL) handleSilentNotificationReceived:(UIApplication*)application UserInfo:(NSDictionary*)userInfo completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end


@implementation CleverPushAppDelegate

+ (void) cleverPushLoadedTagSelector {}

static Class delegateClass = nil;

+ (Class)delegateClass {
    return delegateClass;
}

- (void)setCleverPushDelegate:(id<UIApplicationDelegate>)delegate {
    if (delegateClass) {
        [self setCleverPushDelegate:delegate];
        return;
    }
    
    Class newClass = [CleverPushAppDelegate class];
    delegateClass = [delegate class];

    injectSelector(delegateClass, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), newClass, @selector(cleverPushReceivedSilentRemoteNotification:UserInfo:fetchCompletionHandler:));

    [CleverPushAppDelegate injectPreiOS10MethodsPhase1];

    injectSelector(delegateClass, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), newClass, @selector(cleverPushDidFailRegisterForRemoteNotification:error:));
    injectSelector(delegateClass, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), newClass, @selector(cleverPushDidRegisterForRemoteNotifications:deviceToken:));

    [CleverPushAppDelegate injectPreiOS10MethodsPhase2];
    
    [self setCleverPushDelegate:delegate];
}

+ (BOOL)isIOSVersionGreaterOrEqual:(float)version {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= version;
}

#pragma mark - Initialise and register local notification before iOS 10
+ (void)injectPreiOS10MethodsPhase1 {
    if ([self isIOSVersionGreaterOrEqual:10]) {
        return;
    }

    injectSelector(delegateClass, @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:), [CleverPushAppDelegate class], @selector(cleverPushLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:));
}

#pragma mark - Initialise and register remote notification before iOS 10
+ (void)injectPreiOS10MethodsPhase2 {
    if ([self isIOSVersionGreaterOrEqual:10]) {
        return;
    }
    
    injectSelector(delegateClass, @selector(application:didReceiveRemoteNotification:), [CleverPushAppDelegate class], @selector(cleverPushReceivedRemoteNotification:userInfo:));
    injectSelector(delegateClass, @selector(application:didReceiveLocalNotification:), [CleverPushAppDelegate class], @selector(cleverPushLocalNotificationOpened:notification:));

}


- (void)cleverPushDidRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken {
    [CleverPush didRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
    
    if ([self respondsToSelector:@selector(cleverPushDidRegisterForRemoteNotifications:deviceToken:)]) {
        [self cleverPushDidRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
    }
}

- (void)cleverPushDidFailRegisterForRemoteNotification:(UIApplication*)app error:(NSError*)err {
    if ([CleverPush channelId]) {
        [CleverPush handleDidFailRegisterForRemoteNotification:err];
    }
    
    if ([self respondsToSelector:@selector(cleverPushDidFailRegisterForRemoteNotification:error:)]) {
        [self cleverPushDidFailRegisterForRemoteNotification:app error:err];
    }
}

- (void)cleverPushReceivedRemoteNotification:(UIApplication*)application userInfo:(NSDictionary*)userInfo {
    [CPLog info:@"cleverPushReceivedRemoteNotification"];
    
    if ([CleverPush channelId]) {
        [CleverPush handleNotificationReceived:userInfo isActive:[application applicationState] == UIApplicationStateActive];
    }
    
    if ([self respondsToSelector:@selector(cleverPushReceivedRemoteNotification:userInfo:)]) {
        [self cleverPushReceivedRemoteNotification:application userInfo:userInfo];
    }
}

- (void)cleverPushReceivedSilentRemoteNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult)) completionHandler {
    BOOL callExistingSelector = [self respondsToSelector:@selector(cleverPushReceivedSilentRemoteNotification:UserInfo:fetchCompletionHandler:)];
    BOOL startedBackgroundJob = false;
    
    if ([CleverPush channelId]) {
        // check if this is not a silent notification
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && userInfo[@"aps"][@"alert"]) {
            [CleverPush handleNotificationReceived:userInfo isActive:YES];
        } else {
            startedBackgroundJob = [CleverPush handleSilentNotificationReceived:application UserInfo:userInfo completionHandler:callExistingSelector ? nil : completionHandler];
        }
    }
    
    if (callExistingSelector) {
        [self cleverPushReceivedSilentRemoteNotification:application UserInfo:userInfo fetchCompletionHandler:completionHandler];
        return;
    }
    
    if ([self respondsToSelector:@selector(cleverPushReceivedRemoteNotification:userInfo:)]
        && ![[CleverPush valueForKey:@"startFromNotification"] boolValue]) {
        [self cleverPushReceivedRemoteNotification:application userInfo:userInfo];
    }

    if (!startedBackgroundJob) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (void)cleverPushLocalNotificationOpened:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forLocalNotification:(UILocalNotification*)notification completionHandler:(void(^)(void)) completionHandler {
    if ([CleverPush channelId]) {
        [CleverPush processLocalActionBasedNotification:notification actionIdentifier:identifier];
    }
    
    if ([self respondsToSelector:@selector(cleverPushLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:)]) {
        [self cleverPushLocalNotificationOpened:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
    
    completionHandler();
}

- (void)cleverPushLocalNotificationOpened:(UIApplication*)application notification:(UILocalNotification*)notification {
    if ([CleverPush channelId])
        [CleverPush processLocalActionBasedNotification:notification actionIdentifier:@"__DEFAULT__"];
    
    if ([self respondsToSelector:@selector(cleverPushLocalNotificationOpened:notification:)]) {
        [self cleverPushLocalNotificationOpened:application notification:notification];
    }
}

#pragma clang diagnostic pop

@end
