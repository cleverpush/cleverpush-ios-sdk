#import "AppDelegate.h"
#import <CleverPush/CleverPush.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CleverPush initWithLaunchOptions:launchOptions
      channelId:@"YOUR_CHANNEL_ID_HERE"
      handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        NSLog(@"Received Notification with URL: %@", [result.notification valueForKey:@"url"]);
    } handleSubscribed:^(NSString *subscriptionId) {
        NSLog(@"Subscribed to CleverPush with ID: %@", subscriptionId);
    } autoRegister:YES];
    return YES;
}

@end
