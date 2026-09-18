#import "SceneDelegate.h"
#import <CleverPush/CleverPush.h>

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) { return; }
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *rootVC = [storyboard instantiateInitialViewController];

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];


    for (UIOpenURLContext *context in connectionOptions.URLContexts) {
        [CleverPush captureDeepLinkURL:context.URL];
    }
    for (NSUserActivity *userActivity in connectionOptions.userActivities) {
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            [CleverPush captureDeepLinkURL:userActivity.webpageURL];
        }
    }
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    for (UIOpenURLContext *context in URLContexts) {
        [CleverPush captureDeepLinkURL:context.URL];
        NSLog(@"Deep link opened: %@", context.URL.absoluteString);
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        [CleverPush captureDeepLinkURL:userActivity.webpageURL];
        NSLog(@"Universal link opened: %@", userActivity.webpageURL.absoluteString);
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
}

- (void)sceneWillResignActive:(UIScene *)scene {
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
}

@end
