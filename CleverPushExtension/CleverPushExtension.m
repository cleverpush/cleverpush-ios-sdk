#import "CleverPushExtension.h"
#import "CleverPush.h"
@interface CleverPushExtension ()

@end

@implementation CleverPushExtension


+ (UNMutableNotificationContent* _Nullable)didReceiveNotificationExtensionRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    return [CleverPush didReceiveNotificationExtensionRequest:request withMutableNotificationContent:replacementContent];
}

+ (UNMutableNotificationContent* _Nullable)serviceExtensionTimeWillExpireRequest:(UNNotificationRequest* _Nullable)request withMutableNotificationContent:(UNMutableNotificationContent* _Nullable)replacementContent {
    return [CleverPush serviceExtensionTimeWillExpireRequest:request withMutableNotificationContent:replacementContent];
}

@end
