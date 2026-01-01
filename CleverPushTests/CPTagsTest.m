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
#import "CleverPushUserDefaults.h"

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

- (void)testVerifyApiCallAddTags {
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

- (void)testAddSubscriptionTagSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"add tag callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"add tag failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove tag callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove tag failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil];
    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagsBulkCallbackReturnsSubscriptionTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk add callback"];

    NSArray *expected = @[ @"t1", @"t2" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);
    
    [OCMStub([self.cleverPush addSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush addSubscriptionTags:@[ @"t1", @"t2" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagsBulkCallbackReturnsSubscriptionTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk remove callback"];

    NSArray *expected = @[ @"t1" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [OCMStub([self.cleverPush removeSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush removeSubscriptionTags:@[ @"t1", @"t2" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagWhenAlreadyPresentDoesNotCallApiAndStillCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"duplicate tag callback"];

    [[NSUserDefaults standardUserDefaults] setObject:@[ @"tagId" ] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [[self.cleverPush reject] addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
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

