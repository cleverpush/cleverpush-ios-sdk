#import "CleverPushExtension.h"
#import "CleverPush.h"
@interface CleverPushExtension ()

@end

@implementation CleverPushExtension


+ (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0)) {
    return [CleverPush didReceiveNotificationExtensionRequest:request withMutableNotificationContent:replacementContent];
}

+ (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent API_AVAILABLE(ios(10.0)) {
    return [CleverPush serviceExtensionTimeWillExpireRequest:request withMutableNotificationContent:replacementContent];
}

@end
