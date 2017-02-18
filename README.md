# Usage
1. Add CleverPush to your Podfile

    pod 'CleverPush'


2. Enable the requiremed capabilities

Go to your root project and switch to the tab "Capabilities"
Enable "Push Notifications"
Enable "Background Modes" and check "Remote notifications"


3. Add this code to your AppDelegate:

```objective-c
#import <CleverPush/CleverPush.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ...

    // Make sure to insert your CleverPush channelId
    [CleverPush initWithLaunchOptions:launchOptions channelId:@"INSERT-YOUR-CHANNEL-ID-HERE"];

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CleverPush didRegisterForRemoteNotifications:application deviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [CleverPush handleDidFailRegisterForRemoteNotification:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [CleverPush handlePushReceived:userInfo isActive:[application applicationState] == UIApplicationStateActive];
}

@end
```


Optionally, you can also add your notification opened callback in your `didFinishLaunchingWithOptions` like this:

```objective-c
// ...

// Make sure to insert your CleverPush channelId
[CleverPush initWithLaunchOptions:launchOptions channelId:@"INSERT-YOUR-CHANNEL-ID-HERE" handleNotificationOpened:^(CPNotificationOpenedResult *result) {
    NSString* title = @"CleverPush Notification";
    if (result.payload.title) {
        title = result.payload.title;
    }

    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
        message:result.payload.body
        delegate:self
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil, nil];
    [alertView show];
}];
```




