#import <XCTest/XCTest.h>
#import "CleverPush.h"
#import "CPAppBannerViewController.h"
#import "CPAppBannerModule.h"
#import "CPAppBannerModuleInstance.h"
#import "TestUtils.h"

#import <OCMock/OCMock.h>
@import XCTest;
@interface CPAppBannerTest : XCTestCase
@property (nonatomic) CPAppBannerViewController *bannerTestController;
@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic) id cleverPush;
@property (nonatomic, retain) CPAppBannerModuleInstance *bannerInstance;
@property (nonatomic) id appBanner;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic, strong) NSMutableArray<CPAppBanner*> *banners;
@property (nonatomic, strong) NSMutableArray<CPAppBannerBlock*> *blocks;
@property (nonatomic, strong) NSMutableArray<CPAppBannerTrigger*> *triggers;
@property (nonatomic, strong) NSMutableArray<CPAppBannerCarouselBlock*> *screens;
@property (nonatomic, strong) CPAppBannerBackground *background;
@property (nonatomic, strong) CPAppBannerButtonBlock *buttonBlock;
@property (nonatomic, strong) CPAppBannerTextBlock *textBlock;
@property (nonatomic, strong) CPAppBannerImageBlock *imageBlock;
@property (nonatomic, strong) CPAppBannerHTMLBlock *htmlBlock;
@property (nonatomic, strong) CPAppBannerAction *action;


@end

@implementation CPAppBannerTest
dispatch_queue_t dispatchQueue = nil;

- (void)setUp {
    [super setUp];
    self.background = [[CPAppBannerBackground alloc]init];
    self.background.imageUrl = @"";
    self.background.color = @"#ffffff";
    self.background.dismiss = true;
    
    NSArray *tags =  [[NSArray alloc]initWithObjects:@"TagId", @"TagId2", nil];
    NSArray *excludedTags =  [[NSArray alloc]initWithObjects:@"TagId3", @"TagId4", nil];

    NSArray *topics =  [[NSArray alloc]initWithObjects:@"TopicId", @"TopicId2", nil];
    NSArray *excludedTopics =  [[NSArray alloc]initWithObjects:@"TopicId3", @"TopicId4", nil];

    NSArray *attributes =  [[NSArray alloc]initWithObjects:@"attribute1", @"attribute2", nil];

    self.action = [[CPAppBannerAction alloc]init];
    self.action.url = [NSURL URLWithString:@"url"];
    self.action.urlType = @"";
    self.action.name = @"action name";
    self.action.type = @"";
    self.action.tags = tags;
    self.action.topics = topics;
    self.action.attributeId = @"";
    self.action.attributeValue = @"";
    self.action.dismiss = YES;
    self.action.openInWebview = YES;
    
    self.buttonBlock = [[CPAppBannerButtonBlock alloc]init];
    self.buttonBlock.alignment =  CPAppBannerAlignmentCenter;
    self.buttonBlock.action = self.action;
    self.buttonBlock.text = @"testing";
    self.buttonBlock.color = @"#ffffff";
    self.buttonBlock.family = @"avenir";
    self.buttonBlock.background = @"07AWDE";
    self.buttonBlock.size = 20;
    self.buttonBlock.radius = 20;

    self.textBlock = [[CPAppBannerTextBlock alloc]init];
    self.textBlock.alignment = CPAppBannerAlignmentCenter;
    self.textBlock.text = @"testing";
    self.textBlock.color = @"#ffffff";
    self.textBlock.family = @"avenir";
    self.textBlock.size = 20;

    self.imageBlock = [[CPAppBannerImageBlock alloc]init];
    self.imageBlock.action = self.action;
    self.imageBlock.imageUrl = @"https://www.google.com";
    self.imageBlock.scale = 20;
    
    self.htmlBlock = [[CPAppBannerHTMLBlock alloc]init];
    self.htmlBlock.action = self.action;
    self.htmlBlock.height = 300;
    self.htmlBlock.scale = 20;
    self.blocks = [[NSMutableArray alloc]initWithObjects:self.buttonBlock,self.textBlock,self.imageBlock,self.htmlBlock,  nil];
    
    CPAppBannerCarouselBlock *screenBlock = [[CPAppBannerCarouselBlock alloc]init];
    screenBlock.id = 0;
    screenBlock.blocks = self.blocks;
    self.screens = [[NSMutableArray alloc]initWithObjects:screenBlock, nil];

    CPAppBanner *bannerObject1 = [[CPAppBanner alloc]init];
    bannerObject1.type = CPAppBannerTypeFull;
    bannerObject1.status = CPAppBannerStatusPublished;
    bannerObject1.background = self.background;
    bannerObject1.stopAtType = CPAppBannerStopAtTypeForever;
    bannerObject1.dismissType = CPAppBannerDismissTypeTillDismissed;
    bannerObject1.frequency = CPAppBannerFrequencyOncePerSession;
    bannerObject1.triggerType = CPAppBannerTriggerTypeConditions;
    bannerObject1.blocks = self.blocks;
    bannerObject1.screens = self.screens;
    bannerObject1.triggers = [NSMutableArray new];
    bannerObject1.id = @"xuMpMKmoKhAZ8XRKr";
    bannerObject1.testId = @"132";
    bannerObject1.channel = @"hrPmxqynN7NJ7qtAz";
    bannerObject1.name = @"Testing";
    bannerObject1.HTMLContent = @"dummy";
    bannerObject1.contentType = @"block";
    bannerObject1.startAt = [CPUtils getLocalDateTimeFromUTC:@"2021-08-27T08:10:11.713Z"];
    bannerObject1.stopAt = [CPUtils getLocalDateTimeFromUTC:@"2022-08-27T08:10:11.713Z"];
    bannerObject1.tags = tags;
    bannerObject1.topics = topics;
    bannerObject1.excludeTags = excludedTags;
    bannerObject1.excludeTopics = excludedTopics;
    bannerObject1.attributes = attributes;
    bannerObject1.dismissTimeout = 300;
    bannerObject1.delaySeconds = 0;
    bannerObject1.carouselEnabled = YES;
    bannerObject1.marginEnabled = YES;
    bannerObject1.closeButtonEnabled = YES;
    
    CPAppBanner *bannerObject2 = [[CPAppBanner alloc]init];
    bannerObject2 = bannerObject1;
    self.banners = [[NSMutableArray alloc] initWithObjects:bannerObject1, bannerObject2, nil];
    
    self.bannerTestController = [[CPAppBannerViewController alloc] init];
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
    self.bannerInstance = [[CPAppBannerModuleInstance alloc] init];
    self.appBanner = OCMPartialMock(self.bannerInstance);

}

- (void)testInitSession {
    [self.appBanner initSession:@"channel_id" afterInit:NO];
    XCTAssertEqual([self.appBanner getListOfBanners].count, 0);
    XCTAssertEqual([self.appBanner getPendingBannerListeners].count, 0);
    [[self.appBanner verify] saveSessions];
    [[self.appBanner verify] startup];
    [[self.appBanner verify] setBanners:[OCMArg any]];
}

- (void)testInitBannerWithChannelIdWhenBannerIsAlreadyInitialised{
    OCMStub([self.appBanner isInitialized]).andReturn(true);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:true fromNotification:true];
    [[self.appBanner reject] setBanners:[OCMArg any]];
    [[self.appBanner reject] setPendingBannerListeners:[OCMArg any]];
    [[self.appBanner reject] setActiveBanners:[OCMArg any]];
    [[self.appBanner reject] setPendingBanners:[OCMArg any]];
    [[self.appBanner reject] setEvents:[OCMArg any]];
    [[self.appBanner reject] loadBannersDisabled];
    [[self.appBanner reject] updateShowDraftsFlag:[OCMArg any]];
    [[self.appBanner reject] updateInitialisedFlag:[OCMArg any]];
}

- (void)testInitBannerWithChannelIdWhenBannerIsNotInitialised{
    OCMStub([self.appBanner isInitialized]).andReturn(false);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:true fromNotification:false];
    [[self.appBanner verify] setPendingBannerListeners:[NSMutableArray new]];
    [[self.appBanner verify] setActiveBanners:[NSMutableArray new]];
    [[self.appBanner verify] setPendingBanners:[NSMutableArray new]];
    [[self.appBanner verify] setEvents:[NSMutableArray new]];
    [[self.appBanner verify] loadBannersDisabled];
    [[self.appBanner verify] updateShowDraftsFlag:true];
    [[self.appBanner verify] updateInitialisedFlag:true];
}
- (void)testInitBannerWithChannelIdWhenBannerIsNotInitialisedandNotFromNotificaion{
    OCMStub([self.appBanner isInitialized]).andReturn(false);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:true fromNotification:false];
    [[self.appBanner verify] setFromNotification:false];
}

- (void)testInitBannerWithChannelIdWhenBannerIsNotInitialisedandFromNotificaion{
    OCMStub([self.appBanner isInitialized]).andReturn(false);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:true fromNotification:true];
    [[self.appBanner verify] setFromNotification:true];
}


- (void)testVerifyGetBannersWhenNotcomeFromNotificationAndShowDraft {
    OCMStub([self.appBanner isFromNotification]).andReturn(false);
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(true);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:true fromNotification:true];
    [self.appBanner updateShowDraftsFlag:true];
    OCMVerify([self.appBanner getBanners:@"channel_id" completion:[OCMArg any]]);
}

- (void)testVerifyGetBannersWhenNotcomeFromNotificationDoNotShowDraft {
    OCMStub([self.appBanner isFromNotification]).andReturn(false);
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(true);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:false fromNotification:true];
    [self.appBanner updateShowDraftsFlag:false];
    OCMVerify([self.appBanner getBanners:@"channel_id" completion:[OCMArg any]]);
}

- (void)testVerifyGetBannersAndGetSetPendingBannerRequest {
    OCMStub([self.appBanner isFromNotification]).andReturn(false);
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(true);
    [self.appBanner initBannersWithChannel:@"channel_id" showDrafts:false fromNotification:true];
    OCMVerify([self.appBanner getBanners:@"channel_id" completion:[OCMArg any]]);
    OCMVerify([self.appBanner getPendingBannerRequest]);
    OCMVerify([self.appBanner setPendingBannerRequest:YES]);

    dispatch_async(dispatch_get_main_queue(), ^{
    });
}
- (void)testVerifyBannerData {
    OCMStub([self.appBanner isFromNotification]).andReturn(false);
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(true);
    
    OCMStub([self.appBanner getBanners:OCMOCK_ANY completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void(^ __unsafe_unretained completionHandler)(NSMutableArray<CPAppBanner*> *banners, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self.banners, nil);
    });
    
    [self.appBanner getBanners:@"channel_id" completion:^(NSMutableArray<CPAppBanner *> *banner) {
        XCTAssert(banner[0].name, @"Testing");
        XCTAssertEqual(banner.count,2);
    }];
}

- (void)testAndVerifyStartUpWithCreateAndScheduleBanners {
    [self.appBanner initSession:@"channel_id" afterInit:NO];
    XCTAssertEqual([self.appBanner getListOfBanners].count, 0);
    XCTAssertEqual([self.appBanner getPendingBannerListeners].count, 0);
    [[self.appBanner verify] saveSessions];
    [[self.appBanner verify] startup];
    [[self.appBanner verify] createBanners:[OCMArg any]];
    [[self.appBanner verify] scheduleBanners];

}
- (void)testShowBannerByIdWhenAppBannerDisabled {
    OCMStub([self.appBanner getBannersDisabled]).andReturn(YES);
    OCMStub([self.appBanner getListOfBanners]).andReturn(self.banners);
    OCMStub([self.appBanner getBanners:OCMOCK_ANY completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void(^ __unsafe_unretained completionHandler)(NSMutableArray<CPAppBanner*> *banners, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self.banners, nil);
    });
    [self.appBanner showBanner:@"hrPmxqynN7NJ7qtAz" bannerId:@"xuMpMKmoKhAZ8XRKr"];
    XCTAssertEqual([self.appBanner getListOfBanners].count, 2);
}

- (void)testGetBanners {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getBanners mocked"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"banners": @[] });
    }];
    NSString* configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @"RHe2nXvQk9SZgdC4x"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTAssertNotNil([result objectForKey:@"banners"]);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        XCTFail(@"Unexpected failure: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetBannersWithWrongId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getBanners wrong id"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:@{ @"returned": @{ @"error": @"channel not found" } }]);
        }
    }];
    NSString* configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @"RHe2nXvQk9SZgdC4xe"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        XCTAssertEqual(error.code, 404);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void) backgroundMethodWithCallback: (void(^)(void)) callback {
    dispatch_queue_t backgroundQueue;
    backgroundQueue = dispatch_queue_create("background.queue", NULL);
    dispatch_async(backgroundQueue, ^(void) {
        callback();
    });
}

#pragma mark - isBannerShown

- (void)testIsBannerShownReturnsFalseForUnseenBanner {
    XCTAssertFalse([self.bannerInstance isBannerShown:@"neverShownBannerId"]);
}

- (void)testIsBannerShownReturnsTrueAfterSetBannerIsShown {
    CPAppBanner *banner = self.banners.firstObject;
    [self.bannerInstance setBannerIsShown:banner];
    XCTAssertTrue([self.bannerInstance isBannerShown:banner.id]);
}

- (void)testIsBannerShownReturnsFalseForNilBannerId {
    XCTAssertFalse([self.bannerInstance isBannerShown:nil]);
}

#pragma mark - getBannersDisabled / setBannersDisabled

- (void)testGetBannersDisabledReturnsFalseByDefault {
    OCMStub([self.appBanner getBannersDisabled]).andReturn(NO);
    XCTAssertFalse([self.appBanner getBannersDisabled]);
}

- (void)testSetBannersDisabledToTrue {
    OCMStub([self.appBanner getBannersDisabled]).andReturn(YES);
    XCTAssertTrue([self.appBanner getBannersDisabled]);
}

- (void)testDisableBannersCallsSetBannersDisabled {
    OCMExpect([self.appBanner disableBanners]);
    [self.appBanner disableBanners];
    OCMVerify([self.appBanner disableBanners]);
}

- (void)testEnableBannersCallsVerify {
    OCMExpect([self.appBanner enableBanners]);
    [self.appBanner enableBanners];
    OCMVerify([self.appBanner enableBanners]);
}

#pragma mark - showBanner overloads

- (void)testShowBannerByIdCallsCoreShowBanner {
    OCMExpect([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr"]);
    [self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr"];
    OCMVerify([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr"]);
}

- (void)testShowBannerWithForceYesCallsCoreShowBanner {
    OCMExpect([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:YES]);
    [self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:YES];
    OCMVerify([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:YES]);
}

- (void)testShowBannerWithForceNoCallsCoreShowBanner {
    OCMExpect([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:NO]);
    [self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:NO];
    OCMVerify([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" force:NO]);
}

- (void)testShowBannerWithClosedCallbackCallsCoreShowBanner {
    CPAppBannerClosedBlock closedBlock = ^{};
    OCMExpect([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" appBannerClosedCallback:[OCMArg any]]);
    [self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" appBannerClosedCallback:closedBlock];
    OCMVerify([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" appBannerClosedCallback:[OCMArg any]]);
}

- (void)testShowBannerWithNotificationIdAndForceCallsCoreShowBanner {
    OCMExpect([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" notificationId:@"notifId" force:YES]);
    [self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" notificationId:@"notifId" force:YES];
    OCMVerify([self.appBanner showBanner:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" notificationId:@"notifId" force:YES]);
}

- (void)testShowBannerWhenBannersDisabledAddsToPendingBanners {
    [self.bannerInstance setPendingBanners:[NSMutableArray new]];
    OCMStub([self.appBanner getBannersDisabled]).andReturn(YES);
    OCMStub([self.appBanner getBanners:[OCMArg any] bannerId:[OCMArg any] notificationId:[OCMArg any] groupId:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *inv) {
        void(^ __unsafe_unretained cb)(NSMutableArray<CPAppBanner*>*);
        [inv getArgument:&cb atIndex:6];
        if (cb) cb(self.banners);
    });
    [self.appBanner showBanner:@"hrPmxqynN7NJ7qtAz" bannerId:@"xuMpMKmoKhAZ8XRKr"];
    XCTAssertEqual([self.bannerInstance getPendingBanners].count, 1);
}

#pragma mark - triggerEvent

- (void)testTriggerEventWithValidEventIdCallsStartup {
    OCMExpect([self.appBanner startup]);
    [self.appBanner triggerEvent:@"purchase" properties:@{@"amount": @"100"}];
    OCMVerify([self.appBanner startup]);
}

- (void)testTriggerEventWithNilPropertiesDoesNotCrash {
    XCTAssertNoThrow([self.appBanner triggerEvent:@"login" properties:nil]);
}

- (void)testTriggerEventWithEmptyPropertiesDoesNotCrash {
    XCTAssertNoThrow([self.appBanner triggerEvent:@"pageView" properties:@{}]);
}

- (void)testTriggerEventCallsStartupAfterAddingEvent {
    OCMExpect([self.appBanner startup]);
    [self.appBanner triggerEvent:@"add_to_cart" properties:@{@"product": @"shoes"}];
    OCMVerify([self.appBanner startup]);
}

#pragma mark - bannerTargetingAllowed (mocked)

- (void)testBannerTargetingAllowedReturnsTrueWhenMocked {
    OCMStub([self.appBanner bannerTargetingAllowed:[OCMArg any]]).andReturn(YES);
    BOOL result = [self.appBanner bannerTargetingAllowed:self.banners.firstObject];
    XCTAssertTrue(result);
}

- (void)testBannerTargetingAllowedReturnsFalseWhenMocked {
    OCMStub([self.appBanner bannerTargetingAllowed:[OCMArg any]]).andReturn(NO);
    BOOL result = [self.appBanner bannerTargetingAllowed:self.banners.firstObject];
    XCTAssertFalse(result);
}

- (void)testBannerTargetingWithEventFiltersAllowedReturnsTrueWhenMocked {
    OCMStub([self.appBanner bannerTargetingWithEventFiltersAllowed:[OCMArg any]]).andReturn(YES);
    BOOL result = [self.appBanner bannerTargetingWithEventFiltersAllowed:self.banners.firstObject];
    XCTAssertTrue(result);
}

- (void)testBannerTargetingWithEventFiltersAllowedReturnsFalseWhenMocked {
    OCMStub([self.appBanner bannerTargetingWithEventFiltersAllowed:[OCMArg any]]).andReturn(NO);
    BOOL result = [self.appBanner bannerTargetingWithEventFiltersAllowed:self.banners.firstObject];
    XCTAssertFalse(result);
}

#pragma mark - isBannerPerEachSessionAllowed / isBannerPerDayAllowed

- (void)testIsBannerPerEachSessionAllowedReturnsTrueWhenNoLimitSet {
    [CPAppBannerModuleInstance setAppBannerPerEachSessionValue:0];
    XCTAssertTrue([self.bannerInstance isBannerPerEachSessionAllowed]);
}

- (void)testIsBannerPerEachSessionAllowedReturnsFalseWhenLimitExceeded {
    [CPAppBannerModuleInstance setAppBannerPerEachSessionValue:1];
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    XCTAssertFalse([self.bannerInstance isBannerPerEachSessionAllowed]);
    [CPAppBannerModuleInstance setAppBannerPerEachSessionValue:0];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)testIsBannerPerDayAllowedReturnsTrueWhenNoLimitSet {
    [CPAppBannerModuleInstance setAppBannerPerDayValue:0];
    XCTAssertTrue([self.bannerInstance isBannerPerDayAllowed]);
}

- (void)testIsBannerPerDayAllowedMocked {
    OCMStub([self.appBanner isBannerPerDayAllowed]).andReturn(YES);
    XCTAssertTrue([self.appBanner isBannerPerDayAllowed]);
}

- (void)testIsBannerPerDayAllowedFalseMocked {
    OCMStub([self.appBanner isBannerPerDayAllowed]).andReturn(NO);
    XCTAssertFalse([self.appBanner isBannerPerDayAllowed]);
}

#pragma mark - resetSessionBannerCount / incrementSessionBannerCount / incrementDailyBannerCount

- (void)testResetSessionBannerCountSetsCountToZero {
    [self.bannerInstance incrementSessionBannerCount];
    [self.bannerInstance resetSessionBannerCount];
    int count = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    XCTAssertEqual(count, 0);
}

- (void)testIncrementSessionBannerCountIncrementsCount {
    [self.bannerInstance resetSessionBannerCount];
    [self.bannerInstance incrementSessionBannerCount];
    int count = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    XCTAssertEqual(count, 1);
}

- (void)testIncrementSessionBannerCountMultipleTimes {
    [self.bannerInstance resetSessionBannerCount];
    [self.bannerInstance incrementSessionBannerCount];
    [self.bannerInstance incrementSessionBannerCount];
    [self.bannerInstance incrementSessionBannerCount];
    int count = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    XCTAssertEqual(count, 3);
}

- (void)testIncrementDailyBannerCountSetsCountToOne {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_DAY_DATE"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_DAY_COUNT"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.bannerInstance incrementDailyBannerCount];
    int count = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"CleverPush_APP_BANNER_PER_DAY_COUNT"];
    XCTAssertEqual(count, 1);
}

#pragma mark - calculateDelayForBanner

- (void)testCalculateDelayForBannerWithPastStartAtReturnsDelaySeconds {
    CPAppBanner *banner = [[CPAppBanner alloc] init];
    banner.delaySeconds = 5;
    banner.startAt = [NSDate dateWithTimeIntervalSinceNow:-3600]; // 1 hour in the past
    NSTimeInterval delay = [self.bannerInstance calculateDelayForBanner:banner];
    XCTAssertEqual(delay, 5);
}

- (void)testCalculateDelayForBannerWithFutureStartAtReturnsFutureOffset {
    CPAppBanner *banner = [[CPAppBanner alloc] init];
    banner.delaySeconds = 2;
    banner.startAt = [NSDate dateWithTimeIntervalSinceNow:10]; // 10 seconds in future
    NSTimeInterval delay = [self.bannerInstance calculateDelayForBanner:banner];
    XCTAssertGreaterThan(delay, 0);
    XCTAssertGreaterThan(delay, banner.delaySeconds);
}

- (void)testCalculateDelayForBannerWithNilStartAtReturnsDelaySeconds {
    CPAppBanner *banner = [[CPAppBanner alloc] init];
    banner.delaySeconds = 3;
    banner.startAt = nil;
    NSTimeInterval delay = [self.bannerInstance calculateDelayForBanner:banner];
    XCTAssertEqual(delay, 3);
}

- (void)testCalculateDelayForBannerWithZeroDelayReturnZero {
    CPAppBanner *banner = [[CPAppBanner alloc] init];
    banner.delaySeconds = 0;
    banner.startAt = [NSDate dateWithTimeIntervalSinceNow:-60];
    NSTimeInterval delay = [self.bannerInstance calculateDelayForBanner:banner];
    XCTAssertEqual(delay, 0);
}

#pragma mark - getBanners (mocked)

- (void)testGetBannersCompletionCallsCallbackWithBannerArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"getBanners callback"];
    [OCMStub([self.appBanner getBanners:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(NSMutableArray<CPAppBanner*>*);
        [inv getArgument:&cb atIndex:3];
        cb(self.banners);
    }];
    [self.appBanner getBanners:@"channelId" completion:^(NSMutableArray<CPAppBanner*> *banners) {
        XCTAssertNotNil(banners);
        XCTAssertEqual(banners.count, 2);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetBannersCompletionCallsCallbackWithEmptyArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"getBanners empty callback"];
    [OCMStub([self.appBanner getBanners:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(NSMutableArray<CPAppBanner*>*);
        [inv getArgument:&cb atIndex:3];
        cb([NSMutableArray new]);
    }];
    [self.appBanner getBanners:@"channelId" completion:^(NSMutableArray<CPAppBanner*> *banners) {
        XCTAssertNotNil(banners);
        XCTAssertEqual(banners.count, 0);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetBannersWithBannerIdAndGroupIdCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"getBanners by id/group"];
    [OCMStub([self.appBanner getBanners:[OCMArg any] bannerId:[OCMArg any] notificationId:[OCMArg any] groupId:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(NSMutableArray<CPAppBanner*>*);
        [inv getArgument:&cb atIndex:6];
        cb(self.banners);
    }];
    [self.appBanner getBanners:@"channelId" bannerId:@"xuMpMKmoKhAZ8XRKr" notificationId:nil groupId:nil completion:^(NSMutableArray<CPAppBanner*> *banners) {
        XCTAssertNotNil(banners);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - createBanners / scheduleBanners

- (void)testCreateBannersIsCalledWithBannerArray {
    OCMExpect([self.appBanner createBanners:[OCMArg any]]);
    [self.appBanner createBanners:self.banners];
    OCMVerify([self.appBanner createBanners:[OCMArg any]]);
}

- (void)testScheduleBannersIsCalledAfterCreateBanners {
    OCMExpect([self.appBanner scheduleBanners]);
    [self.appBanner scheduleBanners];
    OCMVerify([self.appBanner scheduleBanners]);
}

- (void)testCreateBannersWithEmptyArrayDoesNotCrash {
    XCTAssertNoThrow([self.appBanner createBanners:[NSMutableArray new]]);
}

#pragma mark - sendBannerEvent (mocked)

- (void)testSendBannerEventDeliveredCallsVerify {
    CPAppBannerCarouselBlock *screen = self.screens.firstObject;
    OCMExpect([self.appBanner sendBannerEvent:@"delivered"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:nil
                               forImageBlock:nil
                                   blockType:@"button"]);
    [self.appBanner sendBannerEvent:@"delivered"
                          forBanner:self.banners.firstObject
                          forScreen:screen
                    forButtonBlock:nil
                     forImageBlock:nil
                         blockType:@"button"];
    OCMVerify([self.appBanner sendBannerEvent:@"delivered"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:nil
                               forImageBlock:nil
                                   blockType:@"button"]);
}

- (void)testSendBannerEventClickedCallsVerify {
    CPAppBannerCarouselBlock *screen = self.screens.firstObject;
    OCMExpect([self.appBanner sendBannerEvent:@"clicked"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:self.buttonBlock
                               forImageBlock:nil
                                   blockType:@"button"]);
    [self.appBanner sendBannerEvent:@"clicked"
                          forBanner:self.banners.firstObject
                          forScreen:screen
                    forButtonBlock:self.buttonBlock
                     forImageBlock:nil
                         blockType:@"button"];
    OCMVerify([self.appBanner sendBannerEvent:@"clicked"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:self.buttonBlock
                               forImageBlock:nil
                                   blockType:@"button"]);
}

- (void)testSendBannerEventWithCustomDataCallsVerify {
    CPAppBannerCarouselBlock *screen = self.screens.firstObject;
    NSMutableDictionary *customData = [NSMutableDictionary dictionaryWithObject:@"value" forKey:@"key"];
    OCMExpect([self.appBanner sendBannerEvent:@"clicked"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:self.buttonBlock
                               forImageBlock:nil
                                   blockType:@"button"
                               withCustomData:customData]);
    [self.appBanner sendBannerEvent:@"clicked"
                          forBanner:self.banners.firstObject
                          forScreen:screen
                    forButtonBlock:self.buttonBlock
                     forImageBlock:nil
                         blockType:@"button"
                     withCustomData:customData];
    OCMVerify([self.appBanner sendBannerEvent:@"clicked"
                                    forBanner:self.banners.firstObject
                                    forScreen:screen
                              forButtonBlock:self.buttonBlock
                               forImageBlock:nil
                                   blockType:@"button"
                               withCustomData:customData]);
}

#pragma mark - CPAppBanner model properties

- (void)testBannerObjectPropertiesAreSetCorrectly {
    CPAppBanner *banner = self.banners.firstObject;
    XCTAssertEqualObjects(banner.id, @"xuMpMKmoKhAZ8XRKr");
    XCTAssertEqualObjects(banner.name, @"Testing");
    XCTAssertEqualObjects(banner.channel, @"hrPmxqynN7NJ7qtAz");
    XCTAssertEqualObjects(banner.HTMLContent, @"dummy");
    XCTAssertEqualObjects(banner.contentType, @"block");
    XCTAssertEqual(banner.type, CPAppBannerTypeFull);
    XCTAssertEqual(banner.status, CPAppBannerStatusPublished);
    XCTAssertEqual(banner.dismissTimeout, 300);
    XCTAssertEqual(banner.delaySeconds, 0);
    XCTAssertTrue(banner.carouselEnabled);
    XCTAssertTrue(banner.marginEnabled);
    XCTAssertTrue(banner.closeButtonEnabled);
}

- (void)testBannerBackgroundPropertiesAreSetCorrectly {
    CPAppBanner *banner = self.banners.firstObject;
    XCTAssertEqualObjects(banner.background.color, @"#ffffff");
    XCTAssertTrue(banner.background.dismiss);
}

- (void)testBannerBlocksCountIsCorrect {
    CPAppBanner *banner = self.banners.firstObject;
    XCTAssertEqual(banner.blocks.count, 4);
}

- (void)testBannerScreensCountIsCorrect {
    CPAppBanner *banner = self.banners.firstObject;
    XCTAssertEqual(banner.screens.count, 1);
}

- (void)testBannerTagsAndTopicsAreSetCorrectly {
    CPAppBanner *banner = self.banners.firstObject;
    XCTAssertTrue([banner.tags containsObject:@"TagId"]);
    XCTAssertTrue([banner.topics containsObject:@"TopicId"]);
    XCTAssertTrue([banner.excludeTags containsObject:@"TagId3"]);
    XCTAssertTrue([banner.excludeTopics containsObject:@"TopicId3"]);
}

- (void)testBannerButtonBlockPropertiesAreSetCorrectly {
    XCTAssertEqualObjects(self.buttonBlock.text, @"testing");
    XCTAssertEqualObjects(self.buttonBlock.color, @"#ffffff");
    XCTAssertEqualObjects(self.buttonBlock.family, @"avenir");
    XCTAssertEqual(self.buttonBlock.size, 20);
    XCTAssertEqual(self.buttonBlock.radius, 20);
    XCTAssertEqual(self.buttonBlock.alignment, CPAppBannerAlignmentCenter);
}

- (void)testBannerTextBlockPropertiesAreSetCorrectly {
    XCTAssertEqualObjects(self.textBlock.text, @"testing");
    XCTAssertEqualObjects(self.textBlock.color, @"#ffffff");
    XCTAssertEqualObjects(self.textBlock.family, @"avenir");
    XCTAssertEqual(self.textBlock.size, 20);
    XCTAssertEqual(self.textBlock.alignment, CPAppBannerAlignmentCenter);
}

- (void)testBannerImageBlockPropertiesAreSetCorrectly {
    XCTAssertEqualObjects(self.imageBlock.imageUrl, @"https://www.google.com");
    XCTAssertEqual(self.imageBlock.scale, 20);
    XCTAssertNotNil(self.imageBlock.action);
}

- (void)testBannerHTMLBlockPropertiesAreSetCorrectly {
    XCTAssertEqual(self.htmlBlock.height, 300);
    XCTAssertEqual(self.htmlBlock.scale, 20);
    XCTAssertNotNil(self.htmlBlock.action);
}

- (void)testBannerActionPropertiesAreSetCorrectly {
    XCTAssertEqualObjects(self.action.name, @"action name");
    XCTAssertTrue(self.action.dismiss);
    XCTAssertTrue(self.action.openInWebview);
    XCTAssertTrue([self.action.tags containsObject:@"TagId"]);
    XCTAssertTrue([self.action.topics containsObject:@"TopicId"]);
}

#pragma mark - sessions / getSessions / setSessions

- (void)testGetSessionsReturnsZeroInitially {
    OCMStub([self.appBanner getSessions]).andReturn(0);
    XCTAssertEqual([self.appBanner getSessions], 0);
}

- (void)testSetAndGetSessionsReturnsExpectedValue {
    OCMStub([self.appBanner getSessions]).andReturn(5);
    XCTAssertEqual([self.appBanner getSessions], 5);
}

#pragma mark - getAppBannersNonBlocking

- (void)testGetAppBannersNonBlockingReturnsTrueWhenSet {
    OCMStub([self.appBanner getAppBannersNonBlocking]).andReturn(YES);
    XCTAssertTrue([self.appBanner getAppBannersNonBlocking]);
}

- (void)testGetAppBannersNonBlockingReturnsFalseByDefault {
    OCMStub([self.appBanner getAppBannersNonBlocking]).andReturn(NO);
    XCTAssertFalse([self.appBanner getAppBannersNonBlocking]);
}

#pragma mark - isInitialized / resetInitialization

- (void)testIsInitializedReturnsTrueWhenMocked {
    OCMStub([self.appBanner isInitialized]).andReturn(YES);
    XCTAssertTrue([self.appBanner isInitialized]);
}

- (void)testIsInitializedReturnsFalseByDefault {
    OCMStub([self.appBanner isInitialized]).andReturn(NO);
    XCTAssertFalse([self.appBanner isInitialized]);
}

- (void)testResetInitializationCallsVerify {
    OCMExpect([self.appBanner resetInitialization]);
    [self.appBanner resetInitialization];
    OCMVerify([self.appBanner resetInitialization]);
}

#pragma mark - static helpers - AppBannerPerDayValue / PerSessionValue

- (void)testSetAndGetAppBannerPerDayValue {
    [CPAppBannerModuleInstance setAppBannerPerDayValue:5];
    XCTAssertEqual([CPAppBannerModuleInstance getAppBannerPerDayValue], 5);
    [CPAppBannerModuleInstance setAppBannerPerDayValue:0];
}

- (void)testSetAndGetAppBannerPerEachSessionValue {
    [CPAppBannerModuleInstance setAppBannerPerEachSessionValue:3];
    XCTAssertEqual([CPAppBannerModuleInstance getAppBannerPerEachSessionValue], 3);
    [CPAppBannerModuleInstance setAppBannerPerEachSessionValue:0];
}

#pragma mark - getBanners (mocked transport)

- (void)testGetBannersApiWithValidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getBannersValidChannel"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"banners": @[] });
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @"RHe2nXvQk9SZgdC4x"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"banners"]);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTFail(@"Expected success but got failure: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetBannersApiWithEmptyChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getBannersEmptyChannel"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil]);
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @""];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testPerformanceExample {
    [self measureBlock:^{
    }];
}

- (void)tearDown {
    [super tearDown];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_SESSION_COUNT"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_DAY_COUNT"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CleverPush_APP_BANNER_PER_DAY_DATE"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
