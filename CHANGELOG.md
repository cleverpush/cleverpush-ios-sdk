# 1.3.4
* Fixed dismissal of app banners

# 1.3.3
* Fixed a crash when trying to display an app-banner with empty image block

# 1.3.2
* Optimized behaviour when channelId changes

# 1.3.1
* Removed not necessary public headers from Framework

# 1.3.0
* New App Banners

# 1.2.7
* Further optimized generation of badge counts

# 1.2.6
* Further optimized generation of badge counts

# 1.2.5
* Improved generation of badge counts

# 1.2.4
* Fixed a display issue with the topics dialog
* Fixed translations

# 1.2.3
* Decrement badge count when notification is opened

# 1.2.2
* Fixed `subscribe` callback subscriptionId parameter on initial subscribe

# 1.2.1
* Added `setApiEndpoint` method

# 1.2.0
* Added `setIncrementBadge` option to automatically increment the badge count for every received notification

# 1.1.1
* Fixed App Banner crash

# 1.1.0
* Fixed some warnings
* Added completely new Topics Dialog with support for sub-topics

# 1.0.5
* Modified build settings to fix warnings

# 1.0.4
* Allow users to unsubscribe from all topics

# 1.0.3
* Modified `setTrackingConsent` behaviour: If called with `NO` no more future tracking calls will be queued and all recent queued calls will be removed

# 1.0.2
* Added `setTopicsDialogWindow` method

# 1.0.1
* Ability to specify `window` for `showTopicsDialog`

# 1.0.0
* Added `setTrackingConsentRequired` and `setTrackingConsent` methods. If the tracking consent is required, tags, attributes and session tracking will only fire if the user gave his consent.

# 0.6.2
* Added `action` to `NotificationOpenedResult`

# 0.6.1
* Use country from NSLocale

# 0.6.0
* Introduced automatic assignment of tags with `trackPageView` method

# 0.5.11
* Fixed `unsubscribe` edge cases
* Added async unsubscribe callback

# 0.5.10
* Fixed `autoRegister: false` behaviour

# 0.5.9
* Fixed crashes

# 0.5.8
* Fixes

# 0.5.7
* Added ability to show topics dialog after opens / days / seconds
* Minor App Review fix

# 0.5.6
* Changed App Review behaviour

# 0.5.5
* Fixed a crash

# 0.5.4
* Transmit last received notification

# 0.5.3
* Addded Bitcode Compiler Flags

# 0.5.2
* Check if callbacks are not nil before calling them

# 0.5.1
* Fixed getChannelConfig callback

# 0.5.0
* Split Location SDK in new Framework
* Make most blocking internal calls asynchroneous

# 0.4.4
* Build with Xcode 11.3.1

# 0.4.3
* Geo fence fix

# 0.4.2
* Location Prompt fix

# 0.4.1
* Geo fence fix

# 0.4.0
* Added Geo Fences

# 0.3.1
* Sync topics from API to client

# 0.3.0
* Added `trackEvent` method
* Added Carousel Notifications

# 0.2.16
* Minor chat notification fix

# 0.2.15
* Improved ChatView: Show an error when there is no internet connection
* Improved Opt-in rate tracking

# 0.2.14
* Fixed a crash

# 0.2.13
* Optimized Topics Dialog

# 0.2.12
* Fixed crash when opening a notification

# 0.2.11
* Optimized Chat View
* Added ability to disable automatic clearing of badge

# 0.2.10
* Fixed freeze when `unsubscribe` called and user is not subscribed

# 0.2.9
* Optimized TopicsDialog

# 0.2.8
* Do not cache HTTP requests (keeps config up to date)

# 0.2.7
* Fixed `CPChatView.lockChat`

# 0.2.6
* Optimized App Banner behaviour

# 0.2.5
* Added `CPChatView.lockChat`  and `CPChatView.headerCodes`

# 0.2.4
* Chat optimizations

# 0.2.3
* Chat optimizations

# 0.2.2
* added `getAvailableTopics`

# 0.2.1
* track app version
* added `CPChatView`

# 0.2.0

* automatically `unsubscribe` on app start if notification permission has been revoked
* added `handleNotificationReceived` callback
* display in-app notification banners by default
* fixed `isSubscribed` lag

# 0.1.15

* in-app banner fixes

# 0.1.14

* in-app banner fixes

# 0.1.13

* in-app banner fixes

# 0.1.12

* track opt-in rate correctly

# 0.1.11

* added `showAppBanners` method without arguments

# 0.1.10

* optimizations for in-app banners

# 0.1.9

* added app review alerts

# 0.1.8

* added `showAppBanners`
* Do not block main loop when channel does not exist

# 0.1.7

* Run notificationsEnabled in main thread

# 0.1.6

* Show topic selection dialog after accepting notifications (if there are topics available)

# 0.1.5

* Update for iOS 13

# 0.1.4

* Let handleSubscribed be called multiple times when re-subscribing


# 0.1.3

* Always register after remote notifications have been enabled


# 0.1.2

* Fixed some bugs


# 0.1.1

* Added API for retrieving the last received notifications


# 0.1.0

* Crash fixed when internet is not available on first launch
