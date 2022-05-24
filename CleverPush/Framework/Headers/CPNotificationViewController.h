#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "CPiCarousel.h"

@interface CPNotificationViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

@property UIImageView *backgroundImageView;
@property CleverPushiCarousel *carousel;
@property UIPageControl *pageControl;

- (void)cleverpushDidReceiveNotification:(UNNotification *)notification API_AVAILABLE(ios(10.0));
- (void)cleverpushDidReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion API_AVAILABLE(ios(10.0));

@end
