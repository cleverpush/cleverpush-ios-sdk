#import "AppDelegate.h"
#import <CleverPush/CleverPush.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CleverPush enableDevelopmentMode];
    [CleverPush initWithLaunchOptions:launchOptions channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:^(CPNotificationReceivedResult * _Nullable result) {
        [CleverPush showAppBanner:[result.notification valueForKey:@"appBanner"]];
    } handleNotificationOpened:^(CPNotificationOpenedResult * _Nullable result) {
        NSLog(@"Received Notification with URL: %@", [result.notification valueForKey:@"url"]);
    } autoRegister:true];

    [CleverPush setAppBannerShownCallback:^(CPAppBanner *appBanner) {
        NSLog(@"APP BANNER SHOWN: %@", appBanner.name);
    }];

    return YES;
}

@end
