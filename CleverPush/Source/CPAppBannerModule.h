#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CPAppBanner.h"
#import "CPAppBannerDismissType.h"
#import "CPAppBannerFrequency.h"
#import "CPAppBannerStatus.h"
#import "CPAppBannerStopAtType.h"
#import "CPAppBannerType.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerBlockType.h"
#import "CPAppBannerAction.h"
#import "UIColor+HexString.h"
#import "UIImageView+CleverPush.h"
#import "CPAppBannerViewController.h"
#import "CleverPush.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerCondition.h"
#import "CPAppBannerModuleInstance.h"

@interface CPAppBannerModule : NSObject

#pragma mark - Class Methods
+ (void)initBannersWithChannel:(NSString*)channel showDrafts:(BOOL)showDrafts fromNotification:(BOOL)fromNotification;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId force:(BOOL)force;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId force:(BOOL)force;
+ (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback;
+ (void)setBannerShownCallback:(CPAppBannerShownBlock)callback;
+ (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId groupId:(NSString*)groupId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback;
+ (void)presentAppBanner:(UIViewController*)controller banner:(CPAppBanner*)banner;
+ (void)showNextActivePendingBanner:(CPAppBanner*)banner;
+ (void)initSession:(NSString*)channelId afterInit:(BOOL)afterInit;
+ (void)triggerEvent:(NSString *)eventId properties:(NSDictionary *)properties;
+ (void)disableBanners;
+ (void)enableBanners;
+ (void)setTrackingEnabled:(BOOL)enabled;
+ (void)resetInitialization;
+ (void)setCurrentEventId:(NSString*)eventId;

@end
