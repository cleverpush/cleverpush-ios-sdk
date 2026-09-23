#import "AppDelegate.h"
#import <CleverPush/CleverPush.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CleverPush enableDevelopmentMode];

    [CleverPush initWithLaunchOptions:launchOptions
      channelId:@"7R8nkAxtrY5wy5TsS"
      handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        NSLog(@"Received Notification with URL: %@", [result.notification valueForKey:@"url"]);
    } handleSubscribed:^(NSString *subscriptionId) {
        NSLog(@"Subscribed to CleverPush with ID: %@", subscriptionId);
    } autoRegister:YES];

    [CleverPush setAppBannerShownCallback:^(CPAppBanner *appBanner) {
        NSLog(@"APP BANNER SHOWN: %@", appBanner.name);
    }];

    return YES;
}

@end
