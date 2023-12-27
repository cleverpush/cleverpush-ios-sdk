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

- (void)testVerifyApiCallAddTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccessWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertNotNil(result);
    };

    [self.cleverPush addSubscriptionTag:tagId callback:successCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagFailureWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSString *) = ^(NSString *result) {
        XCTFail("Unexpected callback invocation in failure case");
    };

    [OCMStub([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush addSubscriptionTag:tagId callback:failureCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccessWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertNotNil(result);
    };

    [self.cleverPush addSubscriptionTag:tagId callback:successCallback onFailure:^(NSError *error) {
        XCTFail("Unexpected failure block invocation in success case");
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagFailureWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSString *) = ^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    };

    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];

    [OCMStub([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        onFailure(testError);
    }];

    [self.cleverPush addSubscriptionTag:tagId callback:^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    } onFailure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, @"TestErrorDomain");
        XCTAssertEqual(error.code, 500);
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
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
    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush removeSubscriptionTag:tagId];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagsSuccess {
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToAdd = @[@"tagIdTwo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags added successfully"];
    [self.cleverPush addSubscriptionTags:tagsToAdd callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertTrue([resultTags containsObject:@"tagIdTwo"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddSubscriptionTagsFailure {
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToAdd = @[@"tagId"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags not added"];
    [self.cleverPush addSubscriptionTags:tagsToAdd callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertFalse([resultTags containsObject:@"tagId"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
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
