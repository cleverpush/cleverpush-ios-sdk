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
    self.htmlBlock.url = @"https://www.google.com";
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
    [self.appBanner initSession];
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
    [[self.appBanner verify] setEvents:[NSMutableDictionary new]];
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
    [self.appBanner initSession];
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
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigfailure"];
    
    NSString* configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @"odcpZ3GhnwiGWxCbC"];
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSArray *jsonBanners = [result objectForKey:@"banners"];
        if (jsonBanners != nil) {
            self.banners = [NSMutableArray new];
            for (NSDictionary* json in jsonBanners) {
                [self.banners addObject:[[CPAppBanner alloc] initWithJson:json]];
            }
            XCTAssertNotNil(self.banners);
            [expectation fulfill];
            NSLog(@"%@", @"testGetBanners");
            
        }
    } onFailure:^(NSError* error) {
        NSLog(@"%@", [[error.userInfo objectForKey:@"returned"]valueForKey:@"error"]);
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"channel not found");
        NSInteger errorCode = error.code;
        int expectedError = 404;
        XCTAssertEqual(errorCode, expectedError);
        XCTAssertNotNil(error);
        [expectation fulfill];
        NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testGetBannersWithWrongId {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigfailure"];
    NSString* configPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", @"odcpZ3GhnwiGWxCbCe"];
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSArray *jsonBanners = [result objectForKey:@"banners"];
        if (jsonBanners != nil) {
            self.banners = [NSMutableArray new];
            for (NSDictionary* json in jsonBanners) {
                [self.banners addObject:[[CPAppBanner alloc] initWithJson:json]];
            }
            XCTAssertNotNil(self.banners);
            [expectation fulfill];
            NSLog(@"%@", @"testGetBanners");
        }
    } onFailure:^(NSError* error) {
        NSLog(@"%@", [[error.userInfo objectForKey:@"returned"]valueForKey:@"error"]);
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"channel not found");
        NSInteger errorCode = error.code;
        int expectedError = 404;
        XCTAssertEqual(errorCode, expectedError);
        XCTAssertNotNil(error);
        [expectation fulfill];
        NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void) backgroundMethodWithCallback: (void(^)(void)) callback {
    dispatch_queue_t backgroundQueue;
    backgroundQueue = dispatch_queue_create("background.queue", NULL);
    dispatch_async(backgroundQueue, ^(void) {
        callback();
    });
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
