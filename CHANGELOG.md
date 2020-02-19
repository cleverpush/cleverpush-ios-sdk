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
