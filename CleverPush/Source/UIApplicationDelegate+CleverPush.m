#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "UIApplicationDelegate+CleverPush.h"
#import "UISceneDelegate+CleverPush.h"
#import "CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CleverPushSwizzlingForwarder.h"
#import "CPDeepLinkTracker.h"
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
static NSMutableSet<Class>* swizzledClasses;

+ (Class)delegateClass {
    return delegateClass;
}

+ (BOOL)classDefinesSelector:(SEL)sel directlyOnClass:(Class)cls {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == sel) {
            found = YES;
            break;
        }
    }
    free(methods);
    return found;
}

+ (void)injectSilentNotificationHandlerInto:(Class)delegateClass {
    SEL targetSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    SEL cpSel     = @selector(cleverPushReceivedSilentRemoteNotification:UserInfo:fetchCompletionHandler:);
    Class cpClass = [CleverPushAppDelegate class];

    if ([CleverPushAppDelegate classDefinesSelector:targetSel directlyOnClass:delegateClass]) {
        injectSelector(delegateClass, targetSel, cpClass, cpSel);
        return;
    }

    Method inheritedMeth = class_getInstanceMethod(delegateClass, targetSel);
    if (inheritedMeth) {
        class_addMethod(delegateClass,
                        targetSel,
                        method_getImplementation(inheritedMeth),
                        method_getTypeEncoding(inheritedMeth));
    }
    injectSelector(delegateClass, targetSel, cpClass, cpSel);
}

+ (void)injectLaunchOptionsHandlerInto:(Class)delegateClass {
    SEL targetSel = @selector(application:didFinishLaunchingWithOptions:);
    SEL cpSel     = @selector(cleverPushReceivedDidFinishLaunching:launchOptions:);
    Class cpClass = [CleverPushAppDelegate class];

    if ([CleverPushAppDelegate classDefinesSelector:targetSel directlyOnClass:delegateClass]) {
        injectSelector(delegateClass, targetSel, cpClass, cpSel);
        return;
    }

    Method inheritedMeth = class_getInstanceMethod(delegateClass, targetSel);
    if (inheritedMeth) {
        class_addMethod(delegateClass,
                        targetSel,
                        method_getImplementation(inheritedMeth),
                        method_getTypeEncoding(inheritedMeth));
    }
    injectSelector(delegateClass, targetSel, cpClass, cpSel);
}

- (void)setCleverPushDelegate:(id<UIApplicationDelegate>)delegate {
    if (swizzledClasses == nil) {
        swizzledClasses = [NSMutableSet new];
    }
    Class delegateClass = [delegate class];
    
    if (delegate == nil || [CleverPushAppDelegate swizzledClassInHierarchy:delegateClass]) {
        [self setCleverPushDelegate:delegate];
        return;
    }
    [swizzledClasses addObject:delegateClass];
    
    Class newClass = [CleverPushAppDelegate class];
    delegateClass = [delegate class];

    [CleverPushAppDelegate injectSilentNotificationHandlerInto:delegateClass];
    [CleverPushAppDelegate injectLaunchOptionsHandlerInto:delegateClass];
    [CleverPushAppDelegate injectDeepLinkHandlersInto:delegateClass];

    [CleverPushAppDelegate injectPreiOS10MethodsPhase1];

    injectSelector(delegateClass, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), newClass, @selector(cleverPushDidFailRegisterForRemoteNotification:error:));
    injectSelector(delegateClass, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), newClass, @selector(cleverPushDidRegisterForRemoteNotifications:deviceToken:));

    [CleverPushAppDelegate injectPreiOS10MethodsPhase2];

    [CleverPushSceneDelegate injectSelectors];
    
    [self setCleverPushDelegate:delegate];
}

+ (void)injectDeepLinkHandlersInto:(Class)delegateClass {
    [self injectExistingSelector:@selector(application:openURL:options:)
              intoDelegateClass:delegateClass
                   replacement:@selector(cleverPushApplication:openURL:options:)];
    [self injectExistingSelector:@selector(application:continueUserActivity:restorationHandler:)
              intoDelegateClass:delegateClass
                   replacement:@selector(cleverPushApplication:continueUserActivity:restorationHandler:)];
}

+ (void)injectExistingSelector:(SEL)targetSel
            intoDelegateClass:(Class)delegateClass
                 replacement:(SEL)cpSel {
    if (delegateClass == nil || class_getInstanceMethod(delegateClass, targetSel) == NULL) {
        return;
    }

    Class cpClass = [CleverPushAppDelegate class];

    if (![self classDefinesSelector:targetSel directlyOnClass:delegateClass]) {
        Method inheritedMeth = class_getInstanceMethod(delegateClass, targetSel);
        if (inheritedMeth) {
            class_addMethod(delegateClass,
                            targetSel,
                            method_getImplementation(inheritedMeth),
                            method_getTypeEncoding(inheritedMeth));
        }
    }

    injectSelector(delegateClass, targetSel, cpClass, cpSel);
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
    
    CleverPushSwizzlingForwarder *forwarder = [[CleverPushSwizzlingForwarder alloc]
        initWithTarget:self
        withYourSelector:@selector(cleverPushDidRegisterForRemoteNotifications:deviceToken:)
        withOriginalSelector:@selector(
            application:didRegisterForRemoteNotificationsWithDeviceToken:
        )
    ];
    [forwarder invokeWithArgs:@[app, inDeviceToken]];
}

- (void)cleverPushDidFailRegisterForRemoteNotification:(UIApplication*)app error:(NSError*)err {
    if ([CleverPush channelId]) {
        [CleverPush handleDidFailRegisterForRemoteNotification:err];
    }
    
    CleverPushSwizzlingForwarder *forwarder = [[CleverPushSwizzlingForwarder alloc]
        initWithTarget:self
        withYourSelector:@selector(cleverPushDidFailRegisterForRemoteNotification:error:)
        withOriginalSelector:@selector(
           application:didFailToRegisterForRemoteNotificationsWithError:
        )
    ];
    [forwarder invokeWithArgs:@[app, err]];
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

- (BOOL)cleverPushReceivedDidFinishLaunching:(UIApplication *)application
                               launchOptions:(NSDictionary *)launchOptions {
    BOOL result = YES;
    if ([self respondsToSelector:@selector(cleverPushReceivedDidFinishLaunching:launchOptions:)]) {
        result = [self cleverPushReceivedDidFinishLaunching:application launchOptions:launchOptions];
    }
    [CPDeepLinkTracker captureFromLaunchOptions:launchOptions];
    [CleverPushSceneDelegate injectSelectors];
    NSDictionary *remoteNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif && [CleverPush channelId]) {
        [CleverPush handleSilentNotificationReceived:application
                                            UserInfo:remoteNotif
                                   completionHandler:nil];
    }
    return result;
}

- (BOOL)cleverPushApplication:(UIApplication *)application
                      openURL:(NSURL *)url
                      options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [CPDeepLinkTracker captureFromURL:url requireAllowlist:YES];

    if ([self respondsToSelector:@selector(cleverPushApplication:openURL:options:)]) {
        return [self cleverPushApplication:application openURL:url options:options];
    }
    return NO;
}

- (BOOL)cleverPushApplication:(UIApplication *)application
         continueUserActivity:(NSUserActivity *)userActivity
           restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    [CPDeepLinkTracker captureFromUserActivity:userActivity];

    if ([self respondsToSelector:@selector(cleverPushApplication:continueUserActivity:restorationHandler:)]) {
        return [self cleverPushApplication:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return NO;
}

- (void)cleverPushReceivedSilentRemoteNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult)) completionHandler {
    CleverPushSwizzlingForwarder *forwarder = [[CleverPushSwizzlingForwarder alloc]
        initWithTarget:self
        withYourSelector:@selector(cleverPushReceivedSilentRemoteNotification:UserInfo:fetchCompletionHandler:)
        withOriginalSelector:@selector(
            application:didReceiveRemoteNotification:fetchCompletionHandler:
        )
    ];
    BOOL startedBackgroundJob = false;
    
    if ([CleverPush channelId]) {
        // check if this is not a silent notification
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && userInfo[@"aps"][@"alert"]) {
            [CleverPush handleNotificationReceived:userInfo isActive:YES];
        } else {
            startedBackgroundJob = [CleverPush handleSilentNotificationReceived:application UserInfo:userInfo completionHandler:forwarder.hasReceiver ? nil : completionHandler];
        }
    }
    
    if (forwarder.hasReceiver) {
        [forwarder invokeWithArgs:@[application, userInfo, completionHandler]];
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

+ (BOOL)swizzledClassInHierarchy:(Class)delegateClass {
    if ([swizzledClasses containsObject:delegateClass]) {
        return true;
    }
    Class superClass = class_getSuperclass(delegateClass);
    while(superClass) {
        if ([swizzledClasses containsObject:superClass]) {
            return true;
        }
        superClass = class_getSuperclass(superClass);
    }
    return false;
}

#pragma clang diagnostic pop

@end
