#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "CleverPushUserDefaults.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPNotificationCategoryController : NSObject

+ (CPNotificationCategoryController *)sharedInstance;
- (NSString *)registerNotificationCategoryForNotificationId:(NSString *)notificationId;
- (NSMutableSet<UNNotificationCategory*>*)existingCategories API_AVAILABLE(ios(10.0));
- (UNNotificationCategory *)carouselCategory API_AVAILABLE(ios(10.0));

@end

NS_ASSUME_NONNULL_END
