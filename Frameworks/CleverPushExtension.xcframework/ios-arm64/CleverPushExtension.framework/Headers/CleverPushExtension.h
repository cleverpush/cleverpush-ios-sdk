#import <UserNotifications/UserNotifications.h>

@interface CleverPushExtension : UNNotificationServiceExtension

+ (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0));

+ (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0));

@end
