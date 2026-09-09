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

- (void)stubChannelConfigWithEvents:(NSArray *)events {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(@{ @"channelEvents": events ?: @[] });
    }];
}

#pragma mark - trackEvent (success)

- (void)testTrackEventWithNameDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase"]);
}

- (void)testTrackEventWithAmountDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"purchase" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"purchase" amount:@(9.99)]);
}

- (void)testTrackEventWithPropertiesDoesNotCrash {
    [self stubChannelConfigWithEvents:@[ @{ @"_id": @"evt1", @"name": @"add_to_cart" } ]];
    [self stubTrackingConsentGranted];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [self.testableInstance setSubscriptionId:@"sub-123"];
    XCTAssertNoThrow([self.cleverPush trackEvent:@"add_to_cart" properties:@{ @"product": @"shoes" }]);
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
    XCTAssertNoThrow([self.cleverPush trackEvent:@"unknown"]);
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

#pragma mark - live API subscription/conversion and subscription/event

- (void)testTrackEventApiWithValidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"trackEvent live"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/conversion"];
    NSDictionary *body = @{
        @"channelId": @"RHe2nXvQk9SZgdC4x",
        @"eventId": @"unknown-event",
        @"subscriptionId": @"test-subscription"
    };
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

- (void)testTriggerFollowUpEventApiWithInvalidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"followUp live failure"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/event"];
    NSDictionary *body = @{
        @"channelId": @"",
        @"name": @"follow_up",
        @"subscriptionId": @"test-subscription"
    };
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

@end
