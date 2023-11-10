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
    void (^consentHandlerBlock)(void) = ^{
        [self.cleverPush addSubscriptionTag:@"tagId"];
        OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
    };

    if ([CleverPush getIabTcfMode] != CPIabTcfModeSubscribeWaitForConsent) {
        OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
        OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
        [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
            void (^handler)(void);
            [invocation getArgument:&handler atIndex:2];
            handler();
            consentHandlerBlock();
        }];
        OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    } else {
        OCMStub([self.cleverPush getSubscribeConsentRequired]).andReturn(false);
        OCMStub([self.cleverPush getHasSubscribeConsent]).andReturn(true);
        [OCMStub([self.cleverPush waitForSubscribeConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
            void (^handler)(void);
            [invocation getArgument:&handler atIndex:2];
            handler();
            consentHandlerBlock();
        }];
        OCMVerify([self.cleverPush waitForSubscribeConsent:[OCMArg any]]);
    }
}

- (void)testVerifyApiCallRemoveTags {
    void (^consentHandlerBlock)(void) = ^{
        [self.cleverPush removeSubscriptionTag:@"tagId"];
        OCMVerify([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
    };

    if ([CleverPush getIabTcfMode] != CPIabTcfModeSubscribeWaitForConsent) {
        OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
        OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
        [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
            void (^handler)(void);
            [invocation getArgument:&handler atIndex:2];
            handler();
            consentHandlerBlock();
        }];
        OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    } else {
        OCMStub([self.cleverPush getSubscribeConsentRequired]).andReturn(false);
        OCMStub([self.cleverPush getHasSubscribeConsent]).andReturn(true);
        [OCMStub([self.cleverPush waitForSubscribeConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
            void (^handler)(void);
            [invocation getArgument:&handler atIndex:2];
            handler();
            consentHandlerBlock();
        }];
        OCMVerify([self.cleverPush waitForSubscribeConsent:[OCMArg any]]);
    }
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

