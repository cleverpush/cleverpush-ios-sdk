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
#import "CPAppBannerSubscribedType.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerType.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPUtils.h"
#import "CPAppBannerCarouselBlock.h"
@interface CPAppBanner : NSObject

@property (nonatomic) CPAppBannerType type;
@property (nonatomic) CPAppBannerStatus status;
@property (nonatomic, strong) CPAppBannerBackground *background;
@property (nonatomic) CPAppBannerStopAtType stopAtType;
@property (nonatomic) CPAppBannerDismissType dismissType;
@property (nonatomic) CPAppBannerFrequency frequency;
@property (nonatomic) CPAppBannerTriggerType triggerType;
@property (nonatomic) CPAppBannerSubscribedType subscribedType;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (nonatomic, strong) NSMutableArray<CPAppBannerTrigger*> *triggers;
@property (nonatomic, strong) NSMutableArray<CPAppBannerCarouselBlock*> *screens;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *testId;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *HTMLContent;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSDate *startAt;
@property (nonatomic, strong) NSDate *stopAt;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *topics;
@property (nonatomic, strong) NSArray *excludeTags;
@property (nonatomic, strong) NSArray *excludeTopics;
@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic) int dismissTimeout;
@property (nonatomic) int delaySeconds;
@property (nonatomic) BOOL carouselEnabled;
@property (nonatomic) BOOL marginEnabled;
@property (nonatomic) BOOL closeButtonEnabled;

- (id)initWithJson:(NSDictionary*)json;

@end
