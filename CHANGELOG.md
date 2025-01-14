## 1.32.1 (14.01.2025)
* In app banner action “Open URL” is now always be the last executed action.
* Implemented `goToScreen`, `nextScreen`, and `previousScreen` functions for app banner HTML blocks.
* Added `every X days` frequency and `Days since installation` trigger feature in app banners.
* Implemented functionality of app banners should be displayed while the application is in foreground mode and the push notification type is a silent push.

## 1.32.0 (19.12.2024)
* Optimised notification service extension service methods by creating separate sub-pods to prevent crashes.

## 1.31.22 (28.11.2024)
* Fixed crash for `StoryView`
* Improved opened tracking for `StoryView`
* Allow passing of empty array to `setSubscriptionTopics`

## 1.31.21 (22.11.2024)
* Added `copyToClipboard` method to HTML app banners

## 1.31.20 (22.11.2024)
* Optimised `getChannelConfigFromChannelId` for preventing crash.
* Call trackStoryShown() when widget is visible.

## 1.31.19 (18.11.2024)
* Fixed `notificationOpened` callback for notification action buttons when `initWithLaunchOptions` has been called delayed (e.g. not in `AppDelegate`)

## 1.31.18 (15.11.2024)
* Add story loading animation in widget (border_color_loading, border_color_loading_dark_mode).
* To remove white load html content, click on the widget once it is loaded, then display the detail screen.

## 1.31.17 (25.10.2024)
* Optimised SDK functions for performance improvements.
* Resolved issue of `setSubscriptionTopics` function for callback was not working. 

## 1.31.16 (23.10.2024) 
* Optimised SDK functions for performance improvements.
* Added optional successBlock and failureBlock callbacks for `setSubscriptionTopics`, `setSubscriptionAttribute` (Array), `pushSubscriptionAttributeValue` and `pullSubscriptionAttributeValue`

## 1.31.15 (21.10.2024) 
* Optimised `trackStoryOpened` function for passing parameters in API.

## 1.31.14 (14.10.2024) 
* Optimized `CPStoryView` statistic tracking.

## 1.31.13 (09.10.2024) 
* Optimized `CPStoryView` URL opened listener and provide a finished callback block.

## 1.31.12 (05.10.2024) 
* Optimized `CPStoryView` to make resuming work better after opening a URL inside a story

## 1.31.11 (04.10.2024) 
* Added more customization options to `CPStoryView` to support dark mode UI.
* Optimised `getChannelConfig`.

## 1.31.10 (26.09.2024) 
* Track confirm-alerts also on denied notification permissions.

## 1.31.9 (24.09.2024) 
* Added more customization options, including support for group story categories for `CPStoryView`.

## 1.31.8 (18.09.2024) 
* Optimisation of the app banner UI for not displaying close button in iPad.

## 1.31.7 (13.09.2024) 
* More customization options for `CPStoryView`.

## 1.31.6 (10.09.2024)
* Optimised `trackSessionEnd` to prevent crash.

## 1.31.5 (04.09.2024)
* Resolved issue of when setTrackingConsent(false) is not removing attributes and tags.
* Resolved issue of story view `setOpenedCallback` function is not working
* implemented API `track-opened` and `track-shown` for the story widget.

## 1.31.4 (30.08.2024)
* Fixed latest release for deployment target

## 1.31.3 (29.08.2024)
* Fixed latest release for deployment target

## 1.31.2 (29.08.2024)
* Added the functionality of `trackEvent` in the app banner action.
* Optimised Xcode deployment target warnings

## 1.31.1 (21.08.2024)
* More customization options for `CPStoryView` with sorting order for displaying stories.

## 1.31.0 (20.08.2024)
* More customization options for `CPStoryView` with unread story count

## 1.30.26 (19.08.2024)
* Optimised `enqueueFailedRequest` function for the failure case.

## 1.30.25 (09.08.2024)
* Optimisation of the app banner UI.
* Optimised `handleSubscribeActionWithCallback` function.
* implemented `setModalPresentationStyle ` and `getModalPresentationStyle ` to display the style of the topViewController (the presented app banner controller).
* Resolved the issue of `removeSubscriptionTopic` and `addSubscriptionTopic` functions not working properly while the internet connection is not available.

## 1.30.24 (24.07.2024)
* Optimisation of the app banner UI.
* Optimised `makeSyncSubscriptionRequest` function for `setSubscriptionInProgress`.
* Resolved the issue of app-banner targeting not working from push notifications.
* Resolved the issue of app banner filtering and targeting not working if the notification type is silent.

## 1.30.23 (23.07.2024)
* Optimised `setConfirmAlertShown` function.

## 1.30.22 (17.07.2024)
* implemented `sethandleuniversallinksinapp` function for domain list array.

## 1.30.21 (17.07.2024)
* Optimised `tryOpenURL` function for universal link.

## 1.30.20 (11.07.2024)
* Added a feature to support event property filters for the app banners.
* Added a feature of app banner trigger has push permission via system ios.
* Optimised `tryOpenURL` function for universal link.

## 1.30.19 (21.06.2024)
* Resolved issue of app banner should not be closed if we don't select dismiss on the click checkbox.
* Resolved issue of track page view assigns all the tags if we pass the blank url.
* Resolved issue of handleinitialized callback is not working with initwithconnectionoptions

## 1.30.18 (17.06.2024)
* Added storyIconCornerRadius, storyIconSpacing, storyIconShadow, storyIconBorderVisibility customisation options for story view.

## 1.30.17 (12.06.2024)
* implemented `initWithConnectionOptions` methods for scene delegate support.
* Added a feature in `AppBanner` to support the geolocation request.

## 1.30.16 (29.05.2024)
* Optimised `ClassGetSubclasses` objects prevent crashes.
* For NON-HTML Banners the Content needs to be centred vertically.

## 1.30.15 (10.05.2024)
* Optimised `shouldSync` function to fix issues after device migration.

## 1.30.14 (01.05.2024)
* Optimised `setSubscriptionInProgress` function.
* Pass the `lastClickedNotificationId` in `trackEvent` if it was within 60 minutes of the `trackEvent` call.
* Added a feature in the app banners with subscribe action: if notification permission has been blocked, then notification settings should be redirected.

## 1.30.13 (24.04.2024)
* Optimised `CPAppBannerActionBlock` callback function for HTML app banners.

## 1.30.12 (19.04.2024)
* Resolved the issue of the transparent background not working if we use the html block in-app banners.
* Optimised close button position for HTML Banner.
* Optimised `setsubscriptionchanged` function for chatview.

## 1.30.11 (05.04.2024)
* Added a feature in `AppBanner` to support multiple actions on buttons and images.
* Optimised for app banner image scaling.

## 1.30.10 (02.04.2024)
* Resolved the issue of app banners still swiping if the carousel is disabled.
* Resolved the issue of opt-ins are higher than opt-in prompts.
* Resolved the issue of the track session start maybe not working correctly.
* Added privacy manifests files.
* Optimised banner objects prevent crashes.
* Added support for app banner displaying by deep-link. 
* Optimised subscribe function for async await-subscribe block called multiple times.

## 1.30.9 (21.03.2024)
* Optimized banner objects prevent crashes.

## 1.30.8 (14.03.2024)
* Optimized removing of tags and attributes after revoking tracking consent.
* Optimized TCF2 API, do not replay queued events after consent is given.
* Resolved the image resizing issue in the app banner.
* Optimised the `setNotificationClicked` method for displaying wrong parameter values.

## 1.30.7 (28.02.2024)
* Added a feature to support in-app banners for silent push notifications.

## 1.30.6 (21.02.2024)
* Optimised the showBanner method for always saving banner IDs in preferences.
* Resolved the issue of the wrong screen ID passing in the app banner for buttons.
* Added a `silent` field in the notification payload model
* Resolved the issue of set subscription attributes not working with AND conditions in-app banners.
* implemented `setBadgeCount` and `getBadgeCount` methods for updating the notification badge count.
 
## 1.30.5 (14.02.2024)
* Optimised `subscribe` method for calling multiple times
* Optimised `waitForTrackingConsent` method for tracking events
* Optimised `getSubscriptionId` method

## 1.30.4 (23.01.2024)
* Added missing SPM header files
* Optimised `handleNotificationReceived` listener
* Optimized Xcode build warnings

## 1.30.3 (04.01.2024)
* Fixed latest release for SPM
* Added `handleInitialized` listener

## 1.30.2 (03.01.2024)
* Fixed previous release

## 1.30.1 (03.01.2024)
* Added a feature to support GIFs in-app banners
* Optimised behaviour for the URL open handler
* Improved `syncsubscription` behaviour

## 1.30.0 (20.12.2023)
* Support app banner targeting from previously tracked events
* Support every time on trigger app banner trigger type

## 1.29.5 (15.12.2023)
* Fixed a behaviour which prevented the subscription being synchronized automatically every 3 days

## 1.29.4 (05.12.2023)
* Support app banner targeting from previously tracked events

## 1.29.3 (30.11.2023)
* Added new method `setAppGroupIdentifierSuffix` to support customisable app group identifiers
* Optimized `setTrackingConsent` behaviour: If called with `NO` for subscription tags and attributes

## 1.29.2 (28.11.2023)
* Added new method `setSubscriptionAttribute` to support multiple attribute value as array

## 1.29.1 (27.11.2023)
* Automatic handling of URLs in Notification Actions
* Support for `setAutoRequestNotificationPermission(false)` added
* Support for `setAutoResubscribe(true)` added

## 1.29.0 (26.11.2023)
* IAB TCF compatibility added
* Automatic retry of failed API requests
* App banner delegate to show banner on custom view controller

## 1.28.13
* Optimizations for in app banners

## 1.28.12
* Fixed a potential crash for the click event in-app banners

## 1.28.11
* Fixed a potential crash in app banners with multiple screens
* Optimized tracking for app banners

## 1.28.10
* App Banners: Optimized image scaling
* App Banners: Allow buttons to have multiple lines
* Topics Dialog: Optimized layout for long topic lists

## 1.28.9
* Optimized `setAuthorizerToken` method for preventing a crash

## 1.28.8
* Optimized `getAvailableAttributes` method

## 1.28.7
* Fixed App Banner orientation layout issue

## 1.28.6
* Fixed App Banner backgrounds

## 1.28.5
* Implemented `setAppBannerShownCallback`

## 1.28.4
* Resolved the click count issue for app banners.

## 1.28.3
* Optimized `subscribe` method for `CPChatView` with another chanel id.
* Fixed crash issue while opening URLs from notification payload.

## 1.28.2
* Optimized `subscribe` method for `CPChatView`

## 1.28.1
* Added feature for displaying voucher code in app banner comes from notification
* Added feature for set an authorization token that will be used in an API call.
* Added feature for more customization options and `setWidgetId` function for `CPStoryView`
* Added feature for support automatic handling of urls deep links for notification
* App Banners: Fixed layout issue in ipad

## 1.28.0
* Added feature for app banner unsubscribe trigger
* App Banners: Fixed scrolling animation effect
* Optimised StoryView behaviour

## 1.27.13
* App Banners: Fixed a potential crash when the color was empty
* App Banners: Added the ability to place the close (X) button statically

## 1.27.12
* Optimized `showAppBanner` method behaviour

## 1.27.11
* Optimized StoryView behaviour

## 1.27.10
* Fixed potential crash in App Banners

## 1.27.9
* Added callback function to `setSubscriptionAttribute`

## 1.27.8
* Added loading spinner for app banner images

## 1.27.7
* Spacing optimizations for `CPStoryView`

## 1.27.6
* Various optimizations for `CPStoryView`

## 1.27.5
* Fixed app banner sizes when changing rootViewController size
* More customization options for `CPStoryView`

## 1.27.4
* Fixed `bannerDescription` property changes

## 1.27.3
* Fixed `CPChatView` colors

## 1.27.2
* Hotfix: app banners were incorrectly filtered

## 1.27.1
* App Banners: disable animations for images
* Fixed edge case with device token when migrating from old to new device

## 1.27.0
* Optimized `CPChatView` methods
* `getAppBannersByGroup`: filter by targeting and time

## 1.26.15
* Add support for app banners copy to clipboard action

## 1.26.14
* Only return banners with status `published` in `getAppBannersByGroup`

## 1.26.13
* Fixed crash for app banners when tapping buttons

## 1.26.12
* Bug fixes for showing of multiple app banners at the same time

## 1.26.11
* Fixed Swift Package Manager (added missing headers)

## 1.26.10
* Make more headers used by `CPAppBanner` public

## 1.26.9
* Make `CPAppBanner` header public

## 1.26.8
* Fixed crash in `CPStoryView`

## 1.26.7
* Various app banner fixes
* Support color options for `CPChatView`

## 1.26.6
* Changed that HTML banners will not go outside of the safe area

## 1.26.5
* Fixed notification tracking for conversion events

## 1.26.4
* Fixed potential conflict with other `NSDictionary` Obj-C categories which used `stringForKey`
* Renamed app banner `description` property to `bannerDescription` to avoid a conflict with `NSObject` description

## 1.26.3
* Added support for `title`, `description` and `mediaUrl` fields for banners

## 1.26.2
* Optimizations for HTML app banners

## 1.26.1
* Fixed logic for app banner conditions when using properties

## 1.26.0
* Removed `triggerAppBannerEvent` method. App banners can now be triggered with the `trackEvent` method.

## 1.25.2
* Introduce `properties` argument for `trackEvents` method
* Ease app banner event tracking by using conversion events

## 1.25.1
* Added optional `onFailure` callbacks for `addSubscriptionTag`, `removeSubscriptionTag`, `addSubscriptionTopic` and `removeSubscriptionTopic`

## 1.25.0
* Support app banner dark mode settings + connected banners (see app banner settings in CleverPush for more information)

## 1.24.4
* Fixes for app banner attribute conditions + small optimizations for an edge case where app banners had screens enabled previously and was then showing the wrong contents.

## 1.24.3
* Fixed the start date option for app banners

## 1.24.2
* Fixed a potential crash when tapping an image in app banners

## 1.24.1
* Fixed app banner text align bug

## 1.24.0
* Added Live Activities Support. See [our docs](https://developers.cleverpush.com/docs/sdks/ios/live-activities) for more information.

## 1.23.0
* Make `areNotificationsEnabled` method public

## 1.22.5
* Optimized app banner behaviour when delays are used

## 1.22.4
* Support calling various methods before a subscription has been created (e.g. call addSubscriptionTag and subscribe at the same time).
* Optimized app banner attribute targeting

## 1.22.3
* Support app banner language filters
* Implement methods to optionally disable app banner statistic tracking

## 1.22.2
* Added `setTopicsChangedListener` to get notified about changed subscription topics

## 1.22.1
* Improved pending topics dialog behaviour when deviceToken is not available
* Improved app banner version filters

## 1.22.0
* Improved folder structure & added example application into SDK
* Released as XCFramework for arm64 simulator support
* Fixed `setLogListener` crash

## 1.21.4
* Added ability to set own log listener via `setLogListener`
* Improved NSArray method signatures

## 1.21.3
* Improved `getNotifications` method
* Implemented `getDeviceToken:callback` method

## 1.21.2
* Improved `setMaximumNotificationCount` method

## 1.21.1
* Added `setMaximumNotificationCount` method for limiting internal data of `getNotifications`

## 1.21.0
* Added support for attribute filter relations

## 1.20.5
* Fixed a potential crash in app banners

## 1.20.4
* Improve app banners

## 1.20.3
* Improved subscription attribute array methods with duplicates

## 1.20.2
* Changed method signature of `getSubscriptionAttribute` to return an object instead of a string

## 1.20.1
* Optimized `pushSubscriptionAttributeValue` and `pullSubscriptionAttributeValue` methods

## 1.20.0
* Improved `isSubscribed` behaviour
* Implemented `setConfirmAlertShown` method to track the confirm alert counts when prompting the push permission before calling `subscribe`
* Implemented `addSubscriptionTopic` and `removeSubscriptionTopic` methods

## 1.19.1
* Implemented `setKeepTargetingDataOnUnsubscribe` method

## 1.19.0
* Added App Banner version filter relation
* Added `layoutSubviews` in `CPChatView` to make sure the contained WebView always has the correct size

## 1.18.0
* Support app banners without carousel and with multiple screens

## 1.17.1
* Implemented callback block for `showTopicsDialog` method

## 1.17.0
* Implemented `triggerFollowUpEvent` method

## 1.16.3
* Implemented `setShowNotificationsInForeground` (enabled by default)

## 1.16.2
* Implemented `setIgnoreDisabledNotificationPermission` to subscribe users, even when the notification permission has not been accepted (disabled by default).

## 1.16.1
* Optimized usage of `NSDictionaries` to prevent crashes

## 1.16.0
* Added optional failure block for `subscribe` function

## 1.15.12
* Optimized "createdAt" field in CPNotification
* Exported all user defaults keys to #defines

## 1.15.11
* Fixed `getNotifications` method in header file

## 1.15.10
* Improved empty `customData` dictionary in `CPNotification`

## 1.15.9
* Fixed duplicate notification filtering in `getNotifications`
* Updated method signatures for `getNotifications` to include type of NSArray (CPNotification)

## 1.15.8
* Implemented pagination for `getNotifications` call with `skip` and `limit`

## 1.15.7
* Filter duplicate notifications in `getNotifications` method

## 1.15.6
* Added `getAppBanners` method

## 1.15.5
* Support opt in delay settings & split tests

## 1.15.4
* App Banner optimizations when re-starting a session

## 1.15.3
* Fixed `removeNotification` method

## 1.15.2
* Added App Banner targeting filter: subscribed state

## 1.15.1
* Fixed unsubscribe behaviour

## 1.15.0
* Added Unit Test cases
* Added `removeNotification(id)` method
* Added CPInboxView

## 1.14.1
* Fixed `createdAt` field in `CPNotification`
* App Banner optimizations

## 1.14.0
* Support for Carousel App Banners
* Optimized `getNotifications` behaviour when filtering out duplicates

## 1.13.3
* Improved `externalId` field mapping in `CPChannelTopic`

## 1.13.2
* Added new getNotifications(true, callback) method which can combine notifications from local storage and from the API

## 1.13.1
* Improved 'autoRegister: true' behaviour when user has unsubscribed.

## 1.13.0
* Added feature to automatically show topics dialog again after new topics have been added. This can optionally be enabled in the CleverPush backend under Channels -> Topics -> Show topics dialog again after new topics have been added.

## 1.12.6
* Updated height calculation in topics dialog

## 1.12.5
* Updated font family in topics dialog

## 1.12.4
* Fixed nib file missing in resources

## 1.12.3
* Fixed Topics Dialog showing when no topics available

## 1.12.2
* Fixed Chat subscribeCallback

## 1.12.1
* Fixed topics dialog with autoRegister: false
* Optimized app review feedback email

## 1.12.0
* Refactor topics dialog
* App Banners: Image callback support
* New Feature: Stories

## 1.11.0
* Added `addSubscriptionTags` and `removeSubscriptionTags` methods

## 1.10.1
* App Banners: prevent showing multiple banners at the same time
* App Banners: Validate "stopAt" field for banners triggered manually or by notification

## 1.10.0
* Added `pushSubscriptionAttribute`, `pullSubscriptionAttribute` and `hasSubscriptionAttributeValue` methods for array attributes

## 1.9.3
* Added ability to specify `normalTintColor` which is being used by Topics Dialog Alert

## 1.9.2
* Optimised App Banners

## 1.9.1
* Optimised App Banners

## 1.9.0
* Optimised & Refactored SDK code
* Improved App Banner Positions (Top, Center, Bottom)
* Improved "Uncheck all topics" behaviour
* Added methods for enabling an disabling App Banners

## 1.8.0
* New App Banner block type: HTML
* Support custom fonts in App Banner
* Open App Banner via Notification

## 1.7.1
* Fixed Notification Opened handler when SDK was initialized delayed
* Improved App Banner Conditions

## 1.7.0
* Introduced optional 'Deselect all' switch in TopicsDialog (can be enabled in your CleverPush topic settings).
* Added support for Close Buttons in HTML app banners

## 1.6.0
* Support HTML content in app banners

## 1.5.0
* Support silent push notifications

## 1.4.7
* Custom Data support for Topics

## 1.4.6
* Added platform name to App Banner path to make filtering by platform possible in the backend.

## 1.4.5
* Fixed `defaultUnchecked` field for topics.

## 1.4.4
* Fixed `subscribe` behaviour when the push permission was already given earlier.

## 1.4.3
* Fixed an issue within `trackPageView` which was caused because the new CPChannelTag model class was missing a key

## 1.4.2
* Fixed `setSubscriptionTopics` behaviour when called immediately inside the `subscribe` callback

## 1.4.1
* Fixed crash in Topics Dialog

## 1.4.0
* Potentially Breaking: Added own Model Classes (CPNotification, CPChannelTags, CPChannelTopics, ..) which are used in NotificationOpened and NotificationReceived listeners, getAvailableTopics and getAvailableTags. Existing implementations should still work but we encourage to use the new getters directly from our classes.

## 1.3.4
* Fixed dismissal of app banners

## 1.3.3
* Fixed a crash when trying to display an app-banner with empty image block

## 1.3.2
* Optimized behaviour when channelId changes

## 1.3.1
* Removed not necessary public headers from Framework

## 1.3.0
* New App Banners

## 1.2.7
* Further optimized generation of badge counts

## 1.2.6
* Further optimized generation of badge counts

## 1.2.5
* Improved generation of badge counts

## 1.2.4
* Fixed a display issue with the topics dialog
* Fixed translations

## 1.2.3
* Decrement badge count when notification is opened

## 1.2.2
* Fixed `subscribe` callback subscriptionId parameter on initial subscribe

## 1.2.1
* Added `setApiEndpoint` method

## 1.2.0
* Added `setIncrementBadge` option to automatically increment the badge count for every received notification

## 1.1.1
* Fixed App Banner crash

## 1.1.0
* Fixed some warnings
* Added completely new Topics Dialog with support for sub-topics

## 1.0.5
* Modified build settings to fix warnings

## 1.0.4
* Allow users to unsubscribe from all topics

## 1.0.3
* Modified `setTrackingConsent` behaviour: If called with `NO` no more future tracking calls will be queued and all recent queued calls will be removed

## 1.0.2
* Added `setTopicsDialogWindow` method

## 1.0.1
* Ability to specify `window` for `showTopicsDialog`

## 1.0.0
* Added `setTrackingConsentRequired` and `setTrackingConsent` methods. If the tracking consent is required, tags, attributes and session tracking will only fire if the user gave his consent.

## 0.6.2
* Added `action` to `NotificationOpenedResult`

## 0.6.1
* Use country from NSLocale

## 0.6.0
* Introduced automatic assignment of tags with `trackPageView` method

## 0.5.11
* Fixed `unsubscribe` edge cases
* Added async unsubscribe callback

## 0.5.10
* Fixed `autoRegister: false` behaviour

## 0.5.9
* Fixed crashes

## 0.5.8
* Fixes

## 0.5.7
* Added ability to show topics dialog after opens / days / seconds
* Minor App Review fix

## 0.5.6
* Changed App Review behaviour

## 0.5.5
* Fixed a crash

## 0.5.4
* Transmit last received notification

## 0.5.3
* Addded Bitcode Compiler Flags

## 0.5.2
* Check if callbacks are not nil before calling them

## 0.5.1
* Fixed getChannelConfig callback

## 0.5.0
* Split Location SDK in new Framework
* Make most blocking internal calls asynchroneous

## 0.4.4
* Build with Xcode 11.3.1

## 0.4.3
* Geo fence fix

## 0.4.2
* Location Prompt fix

## 0.4.1
* Geo fence fix

## 0.4.0
* Added Geo Fences

## 0.3.1
* Sync topics from API to client

## 0.3.0
* Added `trackEvent` method
* Added Carousel Notifications

## 0.2.16
* Minor chat notification fix

## 0.2.15
* Improved ChatView: Show an error when there is no internet connection
* Improved Opt-in rate tracking

## 0.2.14
* Fixed a crash

## 0.2.13
* Optimized Topics Dialog

## 0.2.12
* Fixed crash when opening a notification

## 0.2.11
* Optimized Chat View
* Added ability to disable automatic clearing of badge

## 0.2.10
* Fixed freeze when `unsubscribe` called and user is not subscribed

## 0.2.9
* Optimized TopicsDialog

## 0.2.8
* Do not cache HTTP requests (keeps config up to date)

## 0.2.7
* Fixed `CPChatView.lockChat`

## 0.2.6
* Optimized App Banner behaviour

## 0.2.5
* Added `CPChatView.lockChat`  and `CPChatView.headerCodes`

## 0.2.4
* Chat optimizations

## 0.2.3
* Chat optimizations

## 0.2.2
* added `getAvailableTopics`

## 0.2.1
* track app version
* added `CPChatView`

## 0.2.0

* automatically `unsubscribe` on app start if notification permission has been revoked
* added `handleNotificationReceived` callback
* display in-app notification banners by default
* fixed `isSubscribed` lag

## 0.1.15

* in-app banner fixes

## 0.1.14

* in-app banner fixes

## 0.1.13

* in-app banner fixes

## 0.1.12

* track opt-in rate correctly

## 0.1.11

* added `showAppBanners` method without arguments

## 0.1.10

* optimizations for in-app banners

## 0.1.9

* added app review alerts

## 0.1.8

* added `showAppBanners`
* Do not block main loop when channel does not exist

## 0.1.7

* Run notificationsEnabled in main thread

## 0.1.6

* Show topic selection dialog after accepting notifications (if there are topics available)

## 0.1.5

* Update for iOS 13

## 0.1.4

* Let handleSubscribed be called multiple times when re-subscribing


## 0.1.3

* Always register after remote notifications have been enabled


## 0.1.2

* Fixed some bugs


## 0.1.1

* Added API for retrieving the last received notifications


## 0.1.0

* Crash fixed when internet is not available on first launch
