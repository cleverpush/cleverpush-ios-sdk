# Usage
1. Add CleverPush to your Podfile

   ```
   pod 'CleverPush'
   ```

2. Enable the required capabilities

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

4. Create your iOS push certificate

   * Open Keychain Access on your Mac. (Application > Utilities > Keychain Access).
   * Select Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority...
   * Select the "Save to disk" option and enter any information in the required fields
   * Go to the (Apple developer portal)[https://developer.apple.com/account/ios/identifier/bundle], select your app and press "Edit"
   * Enable "Push notifications" and press "Done"
   * Go to the (Create new certificate page)[https://developer.apple.com/account/ios/certificate/create], select "Apple Push Notification service SSL" and press "Continue"
   * Select your Application Bundle ID and press "Continue"
   * Press "Choose File...", select the previously generated "certSigningRequest" file and then press "Generate"
   * Press "Download" and save your certificate
   * Click on the downloaded .cer file, Keychain Access should open
   * Select Login > My Certificates then right click on your key and click "Export (Apple Production iOS Push Services: com.your.bundle)..."
   * Give the file a unique name and press save, be sure to leave the password field blank!
   * Upload your certificate in the CleverPush channel settings under the iOS tab




