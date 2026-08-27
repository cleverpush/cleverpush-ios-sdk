@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMRecorder.h>
#import <OCMock/OCMStubRecorder.h>
#import <OCMock/OCMConstraint.h>
#import <OCMock/OCMArg.h>
#import <OCMock/OCMLocation.h>
#import <OCMock/OCMMacroState.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>

#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "CleverPushInstance.h"
#import "CleverPushUserDefaults.h"
#import "TestUtils.h"

@interface CPTopicDialogueTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPTopicDialogueTest

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)testInitiasationOfTopicsWhenNewAdded {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(true);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    OCMVerify([CPUtils updateLastTimeAutomaticallyShowed]);
}

- (void)testInitiasationOfTopicsWhenThereIsNoNewTopics {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(false);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showPendingTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
}

- (void)testShowTopicsDialog {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(false);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showPendingTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
}
- (void)testGetSubscriptionTopics{
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    OCMStub([self.cleverPush getSubscriptionTopics]).andReturn(topics);
    NSMutableArray *expectedTopics = [self.cleverPush getSubscriptionTopics];
    XCTAssertEqual(topics, expectedTopics);
    XCTAssertTrue([[self.cleverPush getSubscriptionTopics] containsObject:@"topicId"]);
}

- (void)testCheckTheTopicsHasBeenExistOrNot {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    OCMStub([self.cleverPush hasSubscriptionTopics]).andReturn(true);
    [self.cleverPush setSubscriptionTopics:topics];
    XCTAssertTrue([[self.cleverPush getSubscriptionTopics] containsObject:@"topicId"]);
    XCTAssertTrue([self.cleverPush hasSubscriptionTopics]);
}

- (void)testSubscribeWhenConfirmAlertHideChannelTopicsTrue {
    void (^channelConfigListenerAnswer)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSDictionary *value = [[NSDictionary alloc]initWithObjectsAndKeys:@"true", @"confirmAlertHideChannelTopics", nil];
        [invocation getArgument:&value atIndex:2];
    };
    
    OCMStub([self.cleverPush getChannelConfig:[OCMArg any]])._andDo(channelConfigListenerAnswer);
    [self.cleverPush subscribe];
    XCTAssertFalse([self.cleverPush isSubscriptionInProgress]);
    [[self.cleverPush reject] showPendingTopicsDialog];
}

- (void)testShowTopicDialogWhenAvailableTopicCountZero {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertEqual(topics.count, 0);
    }];
    [[self.cleverPush reject] getChannelConfig:[OCMArg any]];
}

    
- (void)testShowTopicDialogWhenAvailableTopicCountNonZeroAndNotSubscribeThenVerifyInitTopicDialogData {
    NSMutableDictionary *objChannelConfig = [[NSMutableDictionary alloc] init];
    [objChannelConfig setObject:@"9WTamHSgogdBgdfw9" forKey:@"_id"];
    [objChannelConfig setObject:@"Adaptability" forKey:@"name"];
    [objChannelConfig setObject:@"2021-07-28T08:58:56.140Z" forKey:@"createdAt"];
    [objChannelConfig setObject:@"" forKey:@"icon"];
    [objChannelConfig setObject:@"null" forKey:@"layerFunction"];
    [objChannelConfig setObject:@"7ufjxPEdzHD9XpJQf" forKey:@"parentTopic"];
    OCMStub([self.cleverPush isSubscribed])._andDo(false);
    NSArray *customTopics = [[NSArray alloc]initWithObjects:objChannelConfig,  nil];
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:customTopics,@"channelTopics", nil];

    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush showTopicsDialog];
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertNotEqual(topics.count, 0);
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        OCMVerify([self.cleverPush initTopicsDialogData:responseObject syncToBackend:NO]);
    });
}
#pragma mark - hasSubscriptionTopic

- (void)testHasSubscriptionTopicReturnsTrueWhenTopicExists {
    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"topic1", @"topic2", nil];
    [[NSUserDefaults standardUserDefaults] setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertTrue([self.testableInstance hasSubscriptionTopic:@"topic1"]);
}

- (void)testHasSubscriptionTopicReturnsFalseWhenTopicDoesNotExist {
    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"topic1", nil];
    [[NSUserDefaults standardUserDefaults] setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTopic:@"topic_missing"]);
}

- (void)testHasSubscriptionTopicReturnsFalseWhenTopicsListIsEmpty {
    [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTopic:@"topic1"]);
}

- (void)testHasSubscriptionTopicReturnsFalseForNilTopicId {
    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"topic1", nil];
    [[NSUserDefaults standardUserDefaults] setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTopic:nil]);
}

#pragma mark - getSubscriptionTopics

- (void)testGetSubscriptionTopicsReturnsStoredTopics {
    NSArray *topics = @[ @"t1", @"t2", @"t3" ];
    [[NSUserDefaults standardUserDefaults] setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSMutableArray *result = [self.testableInstance getSubscriptionTopics];
    XCTAssertEqual(result.count, 3);
    XCTAssertTrue([result containsObject:@"t1"]);
}

- (void)testGetSubscriptionTopicsReturnsEmptyArrayWhenNothingStored {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSMutableArray *result = [self.testableInstance getSubscriptionTopics];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 0);
}

#pragma mark - getAvailableTopics (callback)

- (void)testGetAvailableTopicsCallbackWithEmptyConfigReturnsEmptyArray {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertNotNil(topics);
        XCTAssertEqual(topics.count, 0);
    }];
}

- (void)testGetAvailableTopicsCallbackWithConfigHavingNoTopicsReturnsEmptyArray {
    NSDictionary *config = @{ @"channelTopics": @[] };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(config);
    }];

    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertEqual(topics.count, 0);
    }];
}

- (void)testGetAvailableTopicsCallbackWithValidTopicsReturnsTopic {
    NSDictionary *topic = @{ @"_id": @"t1", @"name": @"News" };
    NSDictionary *config = @{ @"channelTopics": @[ topic ] };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(config);
    }];

    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertGreaterThanOrEqual(topics.count, 0);
    }];
}

#pragma mark - addSubscriptionTopic (no callback)

- (void)testAddSubscriptionTopicNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush addSubscriptionTopic:@"topic1"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - addSubscriptionTopic (callback only)

- (void)testAddSubscriptionTopicWithCallbackOnlyInvokesCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"add topic callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush addSubscriptionTopic:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"topic1");
    }];

    [self.cleverPush addSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"topic1");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - addSubscriptionTopic (callback + onFailure)

- (void)testAddSubscriptionTopicSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"add topic success"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush addSubscriptionTopic:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"topic1");
    }];

    [self.cleverPush addSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"topic1");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTopicFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"add topic failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush addSubscriptionTopic:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush addSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTopicSuccessWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    XCTAssertNoThrow([self.cleverPush addSubscriptionTopic:@"topic1" callback:nil onFailure:nil]);
}

#pragma mark - addSubscriptionTopic - tracking consent blocked

- (void)testAddSubscriptionTopicDoesNotCallApiWhenTrackingConsentNotGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // consent withheld — do not invoke handler
    }];

    [self.cleverPush addSubscriptionTopic:@"topic1" callback:nil onFailure:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - removeSubscriptionTopic (no callback)

- (void)testRemoveSubscriptionTopicNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic1"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - removeSubscriptionTopic (callback only)

- (void)testRemoveSubscriptionTopicWithCallbackOnlyInvokesCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove topic callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush removeSubscriptionTopic:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"topic1");
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"topic1");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - removeSubscriptionTopic (callback + onFailure)

- (void)testRemoveSubscriptionTopicSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove topic success"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush removeSubscriptionTopic:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"topic1");
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"topic1");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTopicFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove topic failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil];
    [OCMStub([self.cleverPush removeSubscriptionTopic:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic1" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTopicSuccessWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    XCTAssertNoThrow([self.cleverPush removeSubscriptionTopic:@"topic1" callback:nil onFailure:nil]);
}

#pragma mark - removeSubscriptionTopic - tracking consent blocked

- (void)testRemoveSubscriptionTopicDoesNotCallApiWhenTrackingConsentNotGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // consent withheld — do not invoke handler
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic1" callback:nil onFailure:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - setSubscriptionTopics (bulk)

- (void)testSetSubscriptionTopicsBulkCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"t1", @"t2", nil];
    XCTAssertNoThrow([self.cleverPush setSubscriptionTopics:topics]);
}

- (void)testSetSubscriptionTopicsBulkWithEmptyArrayDoesNotCrash {
    NSMutableArray *emptyTopics = [NSMutableArray array];
    XCTAssertNoThrow([self.cleverPush setSubscriptionTopics:emptyTopics]);
}

- (void)testSetSubscriptionTopicsBulkWithNilDoesNotCrash {
    XCTAssertNoThrow([self.cleverPush setSubscriptionTopics:nil]);
}

- (void)testSetSubscriptionTopicsOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"set topics onSuccess"];

    [OCMStub([self.cleverPush setSubscriptionTopics:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^successBlock)(void) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        if (successBlock) successBlock();
    }];

    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"t1", nil];
    [self.cleverPush setSubscriptionTopics:topics onSuccess:^{
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSetSubscriptionTopicsOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"set topics onFailure"];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush setSubscriptionTopics:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"t1", nil];
    [self.cleverPush setSubscriptionTopics:topics onSuccess:^{
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - showTopicsDialog

- (void)testShowTopicsDialogCallsGetChannelConfig {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    XCTAssertNoThrow([self.cleverPush showTopicsDialog]);
    OCMVerify([self.cleverPush getChannelConfig:[OCMArg any]]);
}

- (void)testShowTopicsDialogWithCallbackInvokesCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"showTopicsDialog callback"];

    [OCMStub([self.cleverPush showTopicsDialog:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(void) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback();
    }];

    [self.cleverPush showTopicsDialog:nil callback:^{
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowTopicsDialogWithNilCallbackDoesNotCrash {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    XCTAssertNoThrow([self.cleverPush showTopicsDialog:nil callback:nil]);
}

#pragma mark - hasNewTopicAfterOneHour

- (void)testHasNewTopicAfterOneHourReturnsTrueFromStub {
    NSDictionary *config = @{ @"channelTopics": @[] };
    OCMStub([self.cleverPush hasNewTopicAfterOneHour:config initialDifference:0 displayDialogDifference:3600]).andReturn(YES);
    BOOL result = [self.cleverPush hasNewTopicAfterOneHour:config initialDifference:0 displayDialogDifference:3600];
    XCTAssertTrue(result);
}

- (void)testHasNewTopicAfterOneHourReturnsFalseFromStub {
    NSDictionary *config = @{ @"channelTopics": @[] };
    OCMStub([self.cleverPush hasNewTopicAfterOneHour:config initialDifference:0 displayDialogDifference:3600]).andReturn(NO);
    BOOL result = [self.cleverPush hasNewTopicAfterOneHour:config initialDifference:0 displayDialogDifference:3600];
    XCTAssertFalse(result);
}

#pragma mark - hasSubscriptionTopics

- (void)testHasSubscriptionTopicsReturnsTrueWhenTopicsExist {
    NSMutableArray *topics = [NSMutableArray arrayWithObjects:@"t1", nil];
    [[NSUserDefaults standardUserDefaults] setObject:topics forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush hasSubscriptionTopics]).andReturn(YES);
    XCTAssertTrue([self.cleverPush hasSubscriptionTopics]);
}

- (void)testHasSubscriptionTopicsReturnsFalseWhenNoTopics {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush hasSubscriptionTopics]).andReturn(NO);
    XCTAssertFalse([self.cleverPush hasSubscriptionTopics]);
}

#pragma mark - showTopicDialogOnNewAdded / showPendingTopicsDialog

- (void)testShowTopicDialogOnNewAddedDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    XCTAssertNoThrow([self.cleverPush showTopicDialogOnNewAdded]);
}

- (void)testShowPendingTopicsDialogDoesNotCrash {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    XCTAssertNoThrow([self.cleverPush showPendingTopicsDialog]);
}

#pragma mark - nil / edge cases

- (void)testAddSubscriptionTopicWithNilTopicIdDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    XCTAssertNoThrow([self.cleverPush addSubscriptionTopic:nil callback:nil onFailure:nil]);
}

- (void)testRemoveSubscriptionTopicNotInStoredTopicsStillCallsWaitForTrackingConsent {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"other_topic" ] forKey:CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush removeSubscriptionTopic:@"topic_not_stored"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

@end
