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
#import "TestUtils.h"

@interface CPTagsTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPTagsTest

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}
- (void)testGetSubscriptionTags {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSMutableArray *expectedTags = [self.cleverPush getSubscriptionTags];
    XCTAssertEqual(tags, expectedTags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}

- (void)testHasSubscriptionTagWhenItIsFalse{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}
- (void)testHasSubscriptionTagWhenItIsTrue{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertFalse([[self.cleverPush getSubscriptionTags] containsObject:@"tagIdTwo"]);
}

- (void)testGetAvailableTagsContainsTagId {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *Tags) {
        XCTAssertTrue([Tags containsObject:@"tagId"]);
    }];
}

- (void)testGetAvailableTagsNotContainsTagId {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *Tags) {
        XCTAssertFalse([Tags containsObject:@"tagIdTwo"]);
    }];
}

- (void)testVerifyApiCallAddTag {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallAddTagFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^failureHandler)(NSError *error);
        [invocation getArgument:&failureHandler atIndex:3];
        NSError *error = [NSError errorWithDomain:@"com.example" code:123 userInfo:nil];
        failureHandler(error);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId"];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallAddSubscriptionTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush addSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testVerifyApiCallAddSubscriptionTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush addSubscriptionTags:tags];
    OCMVerifyAll(self.cleverPush);
}

- (void)testVerifyApiCallRemoveTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    [self.cleverPush removeSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallRemoveTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^failureHandler)(NSError *error);
        [invocation getArgument:&failureHandler atIndex:3];
        NSError *error = [NSError errorWithDomain:@"com.example" code:123 userInfo:nil];
        failureHandler(error);
    }];

    [self.cleverPush removeSubscriptionTag:tagId];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);

    XCTFail("The test should fail because of the simulated error.");
}

- (void)testVerifyApiCallRemoveSubscriptionTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush removeSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testVerifyApiCallRemoveSubscriptionTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];

    [OCMStub([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^failureHandler)(NSError *error);
        [invocation getArgument:&failureHandler atIndex:3];
        NSError *error = [NSError errorWithDomain:@"com.example" code:123 userInfo:nil];
        failureHandler(error);
    }];

    [self.cleverPush removeSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testGetAvailableTopicsContainsTopicId {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *Topics) {
        XCTAssertTrue([Topics containsObject:@"topicId"]);
    }];
}

- (void)testGetAvailableTopicsNotContainsTopicId {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *tTopics) {
        XCTAssertFalse([tTopics containsObject:@"topicIdTwo"]);
    }];
}

- (void)testCheckTags {
    NSString *urlStr = @"https://example.com";
    NSDictionary *params = @{@"key": @"value"};
    [self.cleverPush checkTags:urlStr params:params];
    XCTAssertNoThrow([self.cleverPush checkTags:urlStr params:params]);
}

- (void)testCheckTagsFailure {
    NSString *urlStr = nil;
    NSDictionary *params = @{@"key": @"value"};
    XCTAssertThrows([self.cleverPush checkTags:urlStr params:params], @"Expected an exception to be thrown");
}

- (void)testAutoAssignTagMatchesSuccess {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    NSString *pathname = @"example/path";
    NSDictionary *params = @{@"key": @"value"};

    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback called"];

    [self.cleverPush autoAssignTagMatches:tag pathname:pathname params:params callback:^(BOOL success) {
        XCTAssertTrue(success, @"Expected success for autoAssignTagMatches");
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testAutoAssignTagMatchesFailure {
    CPChannelTag *tag = nil;
    NSString *pathname = @"example/path";
    NSDictionary *params = @{@"key": @"value"};

    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback called"];

    [self.cleverPush autoAssignTagMatches:tag pathname:pathname params:params callback:^(BOOL success) {
        XCTAssertFalse(success, @"Expected failure for autoAssignTagMatches");
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testVerifyApiCallAddSubscriptionTag {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback called"];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString *result) {
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallAddSubscriptionTagFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback called"];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString *result) {
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccess {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Success callback called"];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString *result) {
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTFail(@"Failure block should not be called");
    }];

    [self waitForExpectations:@[expectation] timeout:5.0]; // Adjust timeout as needed

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Failure callback called"];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString *result) {
        XCTFail(@"Callback should not be called");
    } onFailure:^(NSError *error) {
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testDeprecatedGetAvailableTagsSuccess {
    NSArray *expectedTags = @[@"tag1", @"tag2", @"tag3"];
    OCMStub([self.cleverPush getAvailableTags]).andReturn(expectedTags);
    NSArray *retrievedTags = [self.cleverPush getAvailableTags];
    OCMVerify([self.cleverPush getAvailableTags]);
    XCTAssertEqualObjects(retrievedTags, expectedTags, @"Returned tags should match expected tags");
}

- (void)testDeprecatedGetAvailableTagsFailure {
    OCMStub([self.cleverPush getAvailableTags]).andReturn(nil);
    NSArray *retrievedTags = [self.cleverPush getAvailableTags];
    OCMVerify([self.cleverPush getAvailableTags]);
    XCTAssertNil(retrievedTags, @"Returned tags should be nil in case of failure");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
