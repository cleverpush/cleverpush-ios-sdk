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
#import "CPFilterRelationType.h"
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
- (void)setBannerShownCallback:(CPAppBannerShownBlock)callback;
- (void)setShowAppBannerCallback:(CPAppBannerDisplayBlock)callback;
- (void)triggerEvent:(NSString *)eventId properties:(NSDictionary *)properties;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId force:(BOOL)force;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId;
- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId force:(BOOL)force;
- (void)startup;
- (NSMutableArray*)shownAppBanners;
- (BOOL)isBannerShown:(NSString*)bannerId;
- (void)setBannerIsShown:(CPAppBanner*)banner;
- (void)initSession:(NSString*)channelId afterInit:(BOOL)afterInit;
- (void)initBannersWithChannel:(NSString*)channelId showDrafts:(BOOL)showDraftsParam fromNotification:(BOOL)fromNotification;
- (void)getBanners:(NSString*)channelId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback;
- (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId groupId:(NSString*)groupId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback;
- (BOOL)bannerTargetingAllowed:(CPAppBanner*)banner;
- (BOOL)bannerTargetingWithEventFiltersAllowed:(CPAppBanner*)banner;
- (void)createBanners:(NSMutableArray*)banners;
- (void)scheduleBanners;
- (void)scheduleBannerDisplay:(CPAppBanner *)banner withDelaySeconds:(NSTimeInterval)delay;
- (void)scheduleBannersForEvent:(NSString *)eventId fromActiveBanners:(NSArray<CPAppBanner *> *)activeBanners;
- (void)scheduleBannersForNoEventFromActiveBanners:(NSArray<CPAppBanner *> *)activeBanners;
- (NSTimeInterval)calculateDelayForBanner:(CPAppBanner *)banner;
- (void)showBanner:(CPAppBanner*)banner;
- (void)presentAppBanner:(CPAppBannerViewController*)appBannerViewController  banner:(CPAppBanner*)banner;
- (void)showNextActivePendingBanner:(CPAppBanner*)banner;
- (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner forScreen:(CPAppBannerCarouselBlock*)screen forButtonBlock:(CPAppBannerButtonBlock*)button forImageBlock:(CPAppBannerImageBlock*)image blockType:(NSString*)type;
- (void)loadBannersDisabled;
- (void)saveBannersDisabled;
- (void)disableBanners;
- (void)enableBanners;
- (void)setTrackingEnabled:(BOOL)enabled;
- (void)setCurrentEventId:(NSString*)eventId;

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
- (void)setEvents:(NSMutableArray<NSDictionary*>*)event;
- (void)updateShowDraftsFlag:(BOOL)value;
- (void)updateInitialisedFlag:(BOOL)value;
- (BOOL)isInitialized;
- (void)resetInitialization;
- (void)setFromNotification:(BOOL)value;
- (BOOL)isFromNotification;
- (void)setBannersDisabled:(BOOL)value;
- (BOOL)getBannersDisabled;
+ (void)setCurrentVoucherCodePlaceholder:(NSMutableDictionary*)voucherCode;
+ (NSMutableDictionary*)getCurrentVoucherCodePlaceholder;
+ (void)setSilentPushAppBannersIDs:(NSString*)appBannerID notificationID:(NSString*)notificationID;
+ (NSMutableArray*)getSilentPushAppBannersIDs;

@end
