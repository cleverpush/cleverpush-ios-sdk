#import "AppDelegate.h"
#import <CleverPush/CleverPush.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CleverPush enableDevelopmentMode];
    [CleverPush initWithLaunchOptions:launchOptions
      channelId:@"RHe2nXvQk9SZgdC4x"
      handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        NSLog(@"Received Notification with URL: %@", [result.notification valueForKey:@"url"]);
    } handleSubscribed:^(NSString *subscriptionId) {
        NSLog(@"Subscribed to CleverPush with ID: %@", subscriptionId);
    } autoRegister:YES];
    return YES;
}

@end
