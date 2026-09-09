@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CleverPushHTTPClient.h"

@interface CPLiveActivityTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPLiveActivityTest

- (void)setUp {
    [super setUp];
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}

- (void)tearDown {
    [self.cleverPush stopMocking];
    [super tearDown];
}

#pragma mark - startLiveActivity (success)

- (void)testStartLiveActivityWithoutCallbacksDoesNotCrash {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    XCTAssertNoThrow([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1"]);
}

- (void)testStartLiveActivityOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"live activity success"];
    [OCMStub([self.cleverPush startLiveActivity:[OCMArg any] pushToken:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:4];
        if (success) success(@{ @"status": @"ok" });
    }];

    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result[@"status"], @"ok");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testStartLiveActivityConvenienceForwardsToFullMethod {
    OCMExpect([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1"];
    OCMVerify([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
}

#pragma mark - startLiveActivity (failure)

- (void)testStartLiveActivityOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"live activity failure"];
    NSError *mockError = [NSError errorWithDomain:@"CleverPushError" code:400 userInfo:@{ NSLocalizedDescriptionKey: @"Bad Request" }];
    [OCMStub([self.cleverPush startLiveActivity:[OCMArg any] pushToken:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:5];
        if (failure) failure(mockError);
    }];

    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 400);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testStartLiveActivityWithNilSubscriptionIdDoesNotCrash {
    [self.testableInstance setSubscriptionId:nil];
    XCTAssertNoThrow([self.testableInstance startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
}

- (void)testStartLiveActivityWithEmptyChannelIdDoesNotCrash {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    OCMStub([self.cleverPush channelId]).andReturn(@"");
    XCTAssertNoThrow([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
}

- (void)testStartLiveActivityWithNilActivityIdDoesNotCrash {
    [self.testableInstance setSubscriptionId:nil];
    XCTAssertNoThrow([self.testableInstance startLiveActivity:nil pushToken:nil]);
}

- (void)testStartLiveActivityWithNilCallbacksDoesNotCrash {
    [OCMStub([self.cleverPush startLiveActivity:[OCMArg any] pushToken:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {}];
    XCTAssertNoThrow([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
}

#pragma mark - live API

- (void)testStartLiveActivityApiWithValidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"live activity live api"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/sync/RHe2nXvQk9SZgdC4x"];
    NSDictionary *body = @{
        @"channelId": @"RHe2nXvQk9SZgdC4x",
        @"iosLiveActivityId": @"activity-1",
        @"iosLiveActivityToken": @"token-1",
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

- (void)testStartLiveActivityApiWithEmptyChannelIdFails {
    XCTestExpectation *expectation = [self expectationWithDescription:@"live activity empty channel"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/sync/"];
    NSDictionary *body = @{
        @"channelId": @"",
        @"iosLiveActivityId": @"activity-1",
        @"iosLiveActivityToken": @"token-1",
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
