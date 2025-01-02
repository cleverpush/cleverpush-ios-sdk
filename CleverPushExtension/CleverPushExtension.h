#import <UserNotifications/UserNotifications.h>

@interface CleverPushExtension : UNNotificationServiceExtension

+ (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent;

+ (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent;

@end
