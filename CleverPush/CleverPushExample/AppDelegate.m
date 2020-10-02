#import "AppDelegate.h"
#import <CleverPush/CleverPush.h>
#import <CleverPushLocation/CleverPushLocation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // TODO: We can specify the Channel ID here, but do not have to. If we leave it out CleverPush tries to find it via the App's Bundle ID. The Bundle ID has to be set in the CleverPush channel settings.
    
    // [CleverPush enableDevelopmentMode];
    
    [CleverPush initWithLaunchOptions:launchOptions
     channelId:@"LoAJxkuwm3dnZTZgM"
             handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        NSLog(@"Opened Notification with URL: %@ and Action: %@", [result.notification valueForKey:@"actions"], result.action);
    
        // NSLog(@"CleverPush.getNotifications: %@", [CleverPush getNotifications]);
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:[result.notification valueForKey:@"title"]
                                                                       message:@""
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
    } handleSubscribed:^(NSString *subscriptionId) {
        NSLog(@"** handleSubscribed ** Subscribed to CleverPush with ID: %@", subscriptionId);
        
        [CleverPush getAvailableTopics:^(NSArray* channelTopics) {
            NSLog(@"CleverPush CHANNEL TOPICS Callback %@", channelTopics);
        }];
        
        [CleverPush getChannelConfig:^(NSDictionary *config) {
            NSLog(@"** CleverPush getChannelConfig Callback %@", config);
        }];
    }];
    
    [CleverPush setAutoClearBadge:NO];
    
    // [CleverPushLocation init];
    // [CleverPushLocation requestLocationPermission];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
