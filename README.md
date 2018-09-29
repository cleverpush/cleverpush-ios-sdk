# Usage
1. Add CleverPush to your Podfile

   ```
   pod 'CleverPush'
   ```

2. Enable the required capabilities

   2.1. Go to your root project and switch to the tab "Capabilities"
   
   2.2. Enable "Push Notifications"
   
   2.3. Enable "Background Modes" and check "Remote notifications"
   


3. Add this code to your AppDelegate:


   Objective-C:

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


    Swift:

    ```swift
    import CleverPush
    
    class AppDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {	        // ...
    
            // Make sure to insert your CleverPush channelId
            CleverPush(launchOptions: launchOptions, channelId: "INSERT-YOUR-CHANNEL-ID-HERE")
    
            return true
        }
    
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            CleverPush.didRegister(forRemoteNotifications: application, deviceToken: deviceToken)
        }
    
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            CleverPush.handleDidFailRegister(forRemoteNotification: error)
        }
    
        func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
            CleverPush.handleReceived(userInfo, isActive: application.applicationState == .active)
        }
    }
    ```


   Optionally, you can also add your notification opened callback in your `didFinishLaunchingWithOptions` or the subscribed callback with the subscription ID like this:

   ```objective-c
   // ...

	[CleverPush initWithLaunchOptions:launchOptions channelId:@"INSERT-YOUR-CHANNEL-ID-HERE" handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        NSLog(@"Received Notification with URL: %@", [result.notification valueForKey:@"url"]);
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:[result.notification valueForKey:@"title"]
                                                                       message:[result.notification valueForKey:@"text"]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
    } handleSubscribed:^(NSString *subscriptionId) {
        NSLog(@"Subscribed to CleverPush with ID: %@", subscriptionId);
    }];
   ```

4. Create your iOS push certificate

   * Open Keychain Access on your Mac. (Application > Utilities > Keychain Access).
   * Select Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority...
   * Select the "Save to disk" option and enter any information in the required fields
   * Go to the [Apple developer portal](https://developer.apple.com/account/ios/identifier/bundle), select your app and press "Edit"
   * Enable "Push notifications" and press "Done"
   * Go to the [Create new certificate page](https://developer.apple.com/account/ios/certificate/create), select "Apple Push Notification service SSL" and press "Continue"
   * Select your Application Bundle ID and press "Continue"
   * Press "Choose File...", select the previously generated "certSigningRequest" file and then press "Generate"
   * Press "Download" and save your certificate
   * Click on the downloaded .cer file, Keychain Access should open
   * Select Login > My Certificates then right click on your key and click "Export (Apple Production iOS Push Services: com.your.bundle)..."
   * Give the file a unique name and press save, be sure to leave the password field blank!
   * Upload your certificate in the CleverPush channel settings under the iOS tab


Tag subscriptions and set attributes:

```objective-c
[CleverPush addSubscriptionTag:@"TAG_ID"]
[CleverPush removeSubscriptionTag:@"TAG_ID"]
[CleverPush setSubscriptionAttribute:@"ATTRIBUTE_ID" value:@"ATTRIBUTE_VALUE"] 
```


