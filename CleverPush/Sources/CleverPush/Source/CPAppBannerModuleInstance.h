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
#import "CPAppBannerViewController.h"

@class CPAppBannerViewController;

@interface CPAppBannerModuleInstance : NSObject

#pragma mark - Class Methods
- (long)getSessions;
- (void)saveSessions;
- (void)setBannerOpenedCallback:(CPAppBannerActionBlock)callback;
- (void)triggerEvent:(NSString *)key value:(NSString *)value;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId;
- (void)startup;
- (NSMutableArray*)shownAppBanners;
- (BOOL)isBannerShown:(NSString*)bannerId;
- (void)setBannerIsShown:(NSString*)bannerId;
- (void)initSession:(NSString*)channelId afterInit:(BOOL)afterInit;
- (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam fromNotification:(BOOL)fromNotification;
- (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback;
- (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback;
- (BOOL)bannerTargetingAllowed:(CPAppBanner*)banner;
- (void)createBanners:(NSMutableArray*)banners;
- (void)scheduleBanners;
- (void)showBanner:(CPAppBanner*)banner;
- (void)presentAppBanner:(CPAppBannerViewController*)appBannerViewController  banner:(CPAppBanner*)banner;
- (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner;
- (void)loadBannersDisabled;
- (void)saveBannersDisabled;
- (void)disableBanners;
- (void)enableBanners;

#pragma mark - refactor for testcases
- (void)setBanners:(NSMutableArray*)appBanner;
- (NSMutableArray *)getListOfBanners;
- (NSMutableArray *)getActiveBanners;
- (long)getMinimumSessionLength;
- (void)setSessions:(long)sessionsCount;
- (BOOL)getPendingBannerRequest;
- (void)setPendingBannerRequest:(BOOL)value;
- (long)getLastSessionTimestamp;
- (void)setLastSessionTimestamp:(long)timeStamp;
- (NSMutableArray *)getPendingBannerListeners;
- (void)setPendingBannerListeners:(NSMutableArray*)listeners;
- (void)setActiveBanners:(NSMutableArray*)banners;
- (void)setPendingBanners:(NSMutableArray*)banners;
- (void)setEvents:(NSMutableDictionary*)event;
- (void)updateShowDraftsFlag:(BOOL)value;
- (void)updateInitialisedFlag:(BOOL)value;
- (BOOL)isInitialized;
- (void)setFromNotification:(BOOL)value;
- (BOOL)isFromNotification;
- (void)setBannersDisabled:(BOOL)value;
- (BOOL)getBannersDisabled;

@end
