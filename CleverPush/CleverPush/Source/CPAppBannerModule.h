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
#import "CPAppBannerController.h"
#import "CleverPush.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerCondition.h"

@interface CPAppBannerModule : NSObject

+ (void)initBannersWithChannel:(NSString*)channel showDrafts:(BOOL)showDrafts;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId;
+ (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId;
+ (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback;
+ (void)initSession;
+ (void)triggerEvent:(NSString *)key value:(NSString *)value;

@end
