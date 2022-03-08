#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

#import "UNUserNotificationCenter+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CleverPush.h"
#import "CPUtils.h"

@interface CleverPush (UN_extra)

+ (void)handleNotificationReceived:(NSDictionary*)messageDict isActive:(BOOL)isActive wasOpened:(BOOL)opened;

@end

@implementation CleverPushUNUserNotificationCenter

static Class delegateUNClass = nil;

static NSArray* delegateUNSubclasses = nil;

__weak static id previousDelegate;

#pragma mark - Initialise UNUserNotificationCenter
+ (void)injectSelectors {
    if (@available(iOS 10.0, *)) {
        injectToProperClass(@selector(setCleverPushUNDelegate:), @selector(setDelegate:), @[], [CleverPushUNUserNotificationCenter class], [UNUserNotificationCenter class]);
        injectToProperClass(@selector(cleverPushRequestAuthorizationWithOptions:completionHandler:),
                            @selector(requestAuthorizationWithOptions:completionHandler:), @[],
                            [CleverPushUNUserNotificationCenter class], [UNUserNotificationCenter class]);
        injectToProperClass(@selector(cleverPushGetNotificationSettingsWithCompletionHandler:),
                            @selector(getNotificationSettingsWithCompletionHandler:), @[],
                            [CleverPushUNUserNotificationCenter class], [UNUserNotificationCenter class]);
    }
}

- (void)cleverPushRequestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler  API_AVAILABLE(ios(10.0)) {
    
    id wrapperBlock = ^(BOOL granted, NSError* error) {
        completionHandler(granted, error);
    };

    [self cleverPushRequestAuthorizationWithOptions:options completionHandler:wrapperBlock];
}

- (void)cleverPushGetNotificationSettingsWithCompletionHandler:(void(^)(UNNotificationSettings *settings))completionHandler API_AVAILABLE(ios(10.0)) {
    id wrapperBlock = ^(UNNotificationSettings* settings) {
        completionHandler(settings);
    };

    [self cleverPushGetNotificationSettingsWithCompletionHandler:wrapperBlock];
}

- (void)setCleverPushUNDelegate:(id)delegate {
    if (previousDelegate == delegate) {
        [self setCleverPushUNDelegate:delegate];
        return;
    }

    previousDelegate = delegate;

    delegateUNClass = getClassWithProtocolInHierarchy([delegate class], @protocol(UNUserNotificationCenterDelegate));
    delegateUNSubclasses = ClassGetSubclasses(delegateUNClass);

    injectToProperClass(@selector(cleverPushUserNotificationCenter:willPresentNotification:withCompletionHandler:),
                        @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:), delegateUNSubclasses, [CleverPushUNUserNotificationCenter class], delegateUNClass);

    injectToProperClass(@selector(cleverPushUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:),
                        @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:), delegateUNSubclasses, [CleverPushUNUserNotificationCenter class], delegateUNClass);

    [self setCleverPushUNDelegate:delegate];
}

- (void)cleverPushUserNotificationCenter:(UNUserNotificationCenter *)center
                 willPresentNotification:(UNNotification *)notification
                   withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)) {
    NSUInteger completionHandlerOptions = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;

    NSLog(@"CleverPush cleverPushUserNotificationCenter willPresentNotification");

    if ([CleverPush channelId]) {
        [CleverPush handleNotificationReceived:notification.request.content.userInfo isActive:YES];
    }

    if ([self respondsToSelector:@selector(cleverPushUserNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
        [self cleverPushUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    } else {
        [CleverPushUNUserNotificationCenter callLegacyAppDeletegateSelector:notification
                                                                isTextReply:false
                                                           actionIdentifier:nil
                                                                   userText:nil
                                                    fromPresentNotification:true
                                                      withCompletionHandler:^() {}];
    }

    NSUserDefaults* userDefaults = [CPUtils getUserDefaultsAppGroup];
    if ([userDefaults objectForKey:CLEVERPUSH_SHOW_NOTIFICATIONS_IN_FOREGROUND_KEY] != nil) {
        BOOL showInForeground = [userDefaults boolForKey:CLEVERPUSH_SHOW_NOTIFICATIONS_IN_FOREGROUND_KEY];
        if (!showInForeground) {
            completionHandlerOptions = UNNotificationPresentationOptionNone;
        }
    }

    completionHandler(completionHandlerOptions);
}

- (void)cleverPushUserNotificationCenter:(UNUserNotificationCenter *)center
          didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    NSLog(@"CleverPush cleverPushUserNotificationCenter didReceiveNotificationResponse");

    if ([CleverPushUNUserNotificationCenter isDismissEvent:response]) {
        [CleverPush updateBadge:nil];
        return;
    }

    [CleverPush handleNotificationOpened:response.notification.request.content.userInfo isActive:[UIApplication sharedApplication].applicationState == UIApplicationStateActive actionIdentifier:response.actionIdentifier];

    if ([self respondsToSelector:@selector(cleverPushUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        [self cleverPushUserNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];

    } else if (![CleverPushUNUserNotificationCenter isDismissEvent:response]) {
        BOOL isTextReply = [response isKindOfClass:NSClassFromString(@"UNTextInputNotificationResponse")];
        NSString* userText = isTextReply ? [response valueForKey:@"userText"] : nil;

        [CleverPushUNUserNotificationCenter callLegacyAppDeletegateSelector:response.notification
                                                                isTextReply:isTextReply
                                                           actionIdentifier:response.actionIdentifier
                                                                   userText:userText
                                                    fromPresentNotification:false
                                                      withCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

+ (BOOL)isDismissEvent:(UNNotificationResponse *)response  API_AVAILABLE(ios(10.0)) {
    return [@"com.apple.UNNotificationDismissActionIdentifier" isEqual:response.actionIdentifier];
}

+ (void)callLegacyAppDeletegateSelector:(UNNotification *)notification
                            isTextReply:(BOOL)isTextReply
                       actionIdentifier:(NSString*)actionIdentifier
                               userText:(NSString*)userText
                fromPresentNotification:(BOOL)fromPresentNotification
                  withCompletionHandler:(void(^)(void))completionHandler  API_AVAILABLE(ios(10.0)) {
    UIApplication *sharedApp = [UIApplication sharedApplication];

    BOOL isCustomAction = actionIdentifier && ![@"com.apple.UNNotificationDefaultActionIdentifier" isEqualToString:actionIdentifier];
    BOOL isRemote = [notification.request.trigger isKindOfClass:NSClassFromString(@"UNPushNotificationTrigger")];

    if (isRemote) {
        NSDictionary* remoteUserInfo = notification.request.content.userInfo;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        if (isTextReply &&
            [sharedApp.delegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]) {
            NSDictionary* responseInfo = @{UIUserNotificationActionResponseTypedTextKey: userText};
            [sharedApp.delegate application:sharedApp handleActionWithIdentifier:actionIdentifier forRemoteNotification:remoteUserInfo withResponseInfo:responseInfo completionHandler:^() {
                completionHandler();
            }];
        } else if (isCustomAction &&
                   [sharedApp.delegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)]) {
            [sharedApp.delegate application:sharedApp handleActionWithIdentifier:actionIdentifier forRemoteNotification:remoteUserInfo completionHandler:^() {
                completionHandler();
            }];
        } else if ([sharedApp.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)] &&
                   (!fromPresentNotification ||
                    ![[notification.request.trigger valueForKey:@"_isContentAvailable"] boolValue])) {
            [sharedApp.delegate application:sharedApp didReceiveRemoteNotification:remoteUserInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
                completionHandler();
            }];
        } else {
            completionHandler();
        }
#pragma clang diagnostic pop
    } else {
        completionHandler();
    }
}

@end
