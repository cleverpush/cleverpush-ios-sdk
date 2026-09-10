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

- (void)testStartLiveActivityOnSuccessDoesNotInvokeCallerSuccessBlock {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    XCTestExpectation *enqueued = [self expectationWithDescription:@"live activity enqueue"];
    XCTestExpectation *noCallerSuccess = [self expectationWithDescription:@"caller success unused"];
    noCallerSuccess.inverted = YES;
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        [enqueued fulfill];
    }];

    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:^(NSDictionary * _Nullable result) {
        [noCallerSuccess fulfill];
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

- (void)testStartLiveActivityDoesNotInvokeCallerFailureBlockWhenEnqueueFails {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    XCTestExpectation *enqueued = [self expectationWithDescription:@"live activity enqueue failure"];
    XCTestExpectation *noCallerFailure = [self expectationWithDescription:@"caller failure unused"];
    noCallerFailure.inverted = YES;
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock innerFailure = nil;
        [invocation getArgument:&innerFailure atIndex:4];
        if (innerFailure) {
            innerFailure([NSError errorWithDomain:@"CleverPushError" code:400 userInfo:nil]);
        }
        [enqueued fulfill];
    }];

    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        [noCallerFailure fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testStartLiveActivityWithNilSubscriptionIdDoesNotEnqueueRequest {
    [self.testableInstance setSubscriptionId:nil];
    [[self.cleverPush reject] enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES];
    XCTAssertNoThrow([self.testableInstance startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
    OCMVerifyAll(self.cleverPush);
}

- (void)testStartLiveActivityWithEmptyChannelIdDoesNotEnqueueRequest {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [[self.cleverPush reject] enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES];
    XCTAssertNoThrow([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
    OCMVerifyAll(self.cleverPush);
}

- (void)testStartLiveActivityWithNilActivityIdDoesNotCrash {
    [self.testableInstance setSubscriptionId:nil];
    XCTAssertNoThrow([self.testableInstance startLiveActivity:nil pushToken:nil]);
}

- (void)testStartLiveActivityWithNilCallbacksDoesNotCrash {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]);
    XCTAssertNoThrow([self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1" onSuccess:nil onFailure:nil]);
}

#pragma mark - enqueue verification

- (void)testStartLiveActivityEnqueuesSyncRequestWhenSubscriptionExists {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    XCTestExpectation *enqueued = [self expectationWithDescription:@"sync enqueue"];
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        [enqueued fulfill];
    }];
    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testStartLiveActivitySkipsEnqueueWhenChannelIdEmpty {
    [self.testableInstance setSubscriptionId:@"sub-123"];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [[self.cleverPush reject] enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES];
    [self.cleverPush startLiveActivity:@"activity-1" pushToken:@"token-1"];
    OCMVerifyAll(self.cleverPush);
}

@end
