#import "CPAppBannerDismissType.h"
#import "CPAppBannerFrequency.h"
#import "CPAppBannerStatus.h"
#import "CPAppBannerStopAtType.h"
#import "CPAppBannerType.h"
#import "CPAppBannerBackground.h"
#import "CPAppBannerBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerCarouselBlock.h"
#import "CPAppBannerSubscribedType.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerType.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPFilterRelationType.h"
#import "CPAppBannerEventFilters.h"
#import "CPAppBannerNotificationPermission.h"
#import "CPAppBannerAttributeLogicType.h"
#import "CPUtils.h"

@interface CPAppBanner : NSObject

@property (nonatomic) CPAppBannerType type;
@property (nonatomic) CPAppBannerStatus status;
@property (nonatomic, strong) CPAppBannerBackground *background;
@property (nonatomic) CPAppBannerStopAtType stopAtType;
@property (nonatomic) CPAppBannerDismissType dismissType;
@property (nonatomic) CPAppBannerFrequency frequency;
@property (nonatomic) CPAppBannerTriggerType triggerType;
@property (nonatomic) CPAppBannerSubscribedType subscribedType;
@property (nonatomic) CPAppBannerNotificationPermission notificationPermission;
@property (nonatomic) CPAppBannerAttributeLogicType attributesLogic;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (nonatomic, strong) NSMutableArray<CPAppBannerTrigger*> *triggers;
@property (nonatomic, strong) NSMutableArray<CPAppBannerCarouselBlock*> *screens;
@property (nonatomic, strong) NSMutableArray<CPAppBannerEventFilters*> *eventFilters;
@property (nonatomic, strong) NSMutableArray<NSString*> *languages;
@property (nonatomic, strong) NSMutableArray<NSString*> *connectedBanners;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *testId;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *HTMLContent;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSString *appVersionFilterRelation;
@property (nonatomic, strong) NSString *appVersionFilterValue;
@property (nonatomic, strong) NSString *fromVersion;
@property (nonatomic, strong) NSString *toVersion;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *bannerDescription;
@property (nonatomic, strong) NSString *mediaUrl;
@property (nonatomic, strong) NSDate *startAt;
@property (nonatomic, strong) NSDate *stopAt;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *topics;
@property (nonatomic, strong) NSArray *excludeTags;
@property (nonatomic, strong) NSArray *excludeTopics;
@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic) int dismissTimeout;
@property (nonatomic) int delaySeconds;
@property (nonatomic) int everyXDays;
@property (nonatomic) BOOL multipleScreensEnabled;
@property (nonatomic) BOOL carouselEnabled;
@property (nonatomic) BOOL marginEnabled;
@property (nonatomic) BOOL closeButtonEnabled;
@property (nonatomic) BOOL closeButtonPositionStaticEnabled;
@property (nonatomic) BOOL darkModeEnabled;

- (id)initWithJson:(NSDictionary*)json;
- (BOOL)darkModeEnabled:(UITraitCollection*)traitCollection;

@end
