@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CleverPushHTTPClient.h"

@interface CPEventsTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPEventsTest

- (void)setUp {
    [super setUp];
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}

- (void)tearDown {
    [self.cleverPush stopMocking];
    [super tearDown];
}

- (void)stubTrackingConsentGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(NO);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(YES);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
}

- (void)stubEnqueueRequestOnSuccess:(void (^)(void))onEnqueue {
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{});
        if (onEnqueue) onEnqueue();
    }];
}

- (void)stubChannelConfigWithEvents:(NSArray *)events {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        if (events == nil) {
            handler(@{});
        } else {
            handler(@{ @"channelEvents": events });
        }
    }];
}

#pragma mark - trackEvent (success)

- (void)testTrackEventWithNameDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    XCTestExpectation *exp = [self expectationWithDescription:@"trackEvent name enqueue"];
    [self stubEnqueueRequestOnSuccess:^{ [exp fulfill]; }];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase"]);
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackEventWithAmountDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    XCTestExpectation *exp = [self expectationWithDescription:@"trackEvent amount enqueue"];
    [self stubEnqueueRequestOnSuccess:^{ [exp fulfill]; }];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase" amount:@(9.99)]);
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackEventWithPropertiesDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"add_to_cart" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    XCTestExpectation *exp = [self expectationWithDescription:@"trackEvent properties enqueue"];
    [self stubEnqueueRequestOnSuccess:^{ [exp fulfill]; }];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"add_to_cart" properties:@{ @"product": @"shoes" }]);
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackEventCallsGetChannelConfig {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackEvent getChannelConfig"];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(@{ @"channelEvents": @[ @{ @"_id": @"evt1", @"name": @"login" } ] });
        [exp fulfill];
    }];
    [self.cleverPush trackEvent:@"login"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackEventWithValidEventInvokesWaitForTrackingConsent {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackEvent consent"];
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"signup" } ]];
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
        [exp fulfill];
    }];
    [self.cleverPush trackEvent:@"signup" properties:@{ @"source": @"app" }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - trackEvent (failure)

- (void)testTrackEventWhenChannelEventsMissingDoesNotCrash {
    [self stubChannelConfigWithEvents:nil];
    XCTestExpectation *exp = [self expectationWithDescription:@"missing channelEvents"];
    exp.inverted = YES;
    XCTAssertNoThrow([self.cleverPush trackEvent:@"unknown"]);
    [self waitForExpectationsWithTimeout:0.3 handler:nil];
}

- (void)testTrackEventWhenEventNameNotFoundDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"other" } ]];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"missing-event"]);
}

- (void)testTrackEventWithNilNameDoesNotCrash {
    [self stubChannelConfigWithEvents:@[]];
    XCTAssertNoThrow([self.cleverPush trackEvent:nil]);
}

- (void)testTrackEventWithEmptyNameDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    XCTAssertNoThrow([self.cleverPush trackEvent:@""]);
}

- (void)testTrackEventWhenSubscriptionIdNilDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase"]);
}

- (void)testTrackEventWhenChannelIdEmptyDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase"]);
}

#pragma mark - triggerFollowUpEvent (success)

- (void)testTriggerFollowUpEventWithNameDoesNotCrash {
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    XCTAssertNoThrow([self.cleverPush triggerFollowUpEvent:@"abandoned_cart"]);
}

- (void)testTriggerFollowUpEventWithParametersDoesNotCrash {
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    XCTAssertNoThrow([self.cleverPush triggerFollowUpEvent:@"abandoned_cart" parameters:@{ @"cartValue": @"20" }]);
}

- (void)testTriggerFollowUpEventCallsWaitForTrackingConsent {
    XCTestExpectation *exp = [self expectationWithDescription:@"followUp consent"];
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
        [exp fulfill];
    }];
    [self.cleverPush triggerFollowUpEvent:@"follow_up"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - triggerFollowUpEvent (failure)

- (void)testTriggerFollowUpEventWhenSubscriptionIdNilDoesNotCrash {
    [self stubTrackingConsentGranted];
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];
    XCTAssertNoThrow([self.cleverPush triggerFollowUpEvent:@"follow_up"]);
}

- (void)testTriggerFollowUpEventWhenChannelIdEmptyDoesNotCrash {
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"");
    [OCMStub([self.cleverPush getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    XCTAssertNoThrow([self.cleverPush triggerFollowUpEvent:@"follow_up" parameters:@{}]);
}

- (void)testTriggerFollowUpEventWithNilNameDoesNotCrash {
    [self stubTrackingConsentGranted];
    XCTAssertNoThrow([self.cleverPush triggerFollowUpEvent:nil]);
}

#pragma mark - mocked success / failure wrappers

- (void)testTrackEventMockedSuccessPath {
    OCMExpect([self.cleverPush trackEvent:@"purchase" properties:[OCMArg any]]);
    [self.cleverPush trackEvent:@"purchase" properties:@{ @"amount": @"10" }];
    OCMVerify([self.cleverPush trackEvent:@"purchase" properties:[OCMArg any]]);
}

- (void)testTriggerFollowUpEventMockedSuccessPath {
    OCMExpect([self.cleverPush triggerFollowUpEvent:@"winback" parameters:[OCMArg any]]);
    [self.cleverPush triggerFollowUpEvent:@"winback" parameters:@{ @"days": @"3" }];
    OCMVerify([self.cleverPush triggerFollowUpEvent:@"winback" parameters:[OCMArg any]]);
}

#pragma mark - mocked conversion / follow-up HTTP

- (void)testTrackEventEnqueuesConversionRequest {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    XCTestExpectation *exp = [self expectationWithDescription:@"conversion enqueue"];
    [self stubEnqueueRequestOnSuccess:^{ [exp fulfill]; }];
    [self.cleverPush trackEvent:@"purchase" properties:@{ @"amount": @"10" }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTriggerFollowUpEventEnqueuesFailurePath {
    [self stubTrackingConsentGranted];
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    XCTestExpectation *exp = [self expectationWithDescription:@"follow-up enqueue failure"];
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:400 userInfo:nil]);
        }
        [exp fulfill];
    }];
    [self.cleverPush triggerFollowUpEvent:@"follow_up" parameters:@{ @"days": @"3" }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
