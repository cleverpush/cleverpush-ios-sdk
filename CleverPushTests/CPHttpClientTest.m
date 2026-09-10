@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CleverPushHTTPClient.h"

@interface CPHttpClientTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *instance;

@end

@implementation CPHttpClientTest

- (void)setUp {
    [super setUp];
    self.instance = [[CleverPushInstance alloc] init];
}

- (NSHTTPURLResponse *)responseWithStatus:(NSInteger)status {
    return [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api.cleverpush.com/channel/test"]
                                       statusCode:status
                                      HTTPVersion:@"HTTP/1.1"
                                     headerFields:@{ @"Content-Type": @"application/json" }];
}

- (NSData *)jsonDataFromObject:(id)object {
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
}

#pragma mark - CleverPushHTTPClient

- (void)testSharedClientIsNotNil {
    XCTAssertNotNil([CleverPushHTTPClient sharedClient]);
}

- (void)testSharedClientReturnsSameInstance {
    XCTAssertEqual([CleverPushHTTPClient sharedClient], [CleverPushHTTPClient sharedClient]);
}

- (void)testRequestWithGetMethodBuildsURLRequest {
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/RHe2nXvQk9SZgdC4x/config"];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.HTTPMethod, @"GET");
    XCTAssertNotNil(request.URL);
}

- (void)testRequestWithPostMethodBuildsURLRequest {
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/sync/RHe2nXvQk9SZgdC4x"];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");
}

- (void)testConfigureEndpointUpdatesApiEndpoint {
    CleverPushHTTPClient *client = [CleverPushHTTPClient sharedClient];
    [client configureEndpoint:@"https://custom.cleverpush.com"];
    XCTAssertNotNil(client.apiEndpoint);
    XCTAssertTrue([client.apiEndpoint.absoluteString containsString:@"custom.cleverpush.com"]);
    [client configureEndpoint:@"https://api-mobile.cleverpush.com"];
}

#pragma mark - handleJSONNSURLResponse (success)

- (void)testHandleJSONNSURLResponseSuccessCallsSuccessBlockWithJson {
    XCTestExpectation *exp = [self expectationWithDescription:@"json success"];
    NSData *data = [self jsonDataFromObject:@{ @"ok": @YES }];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:200]
                                      data:data
                                     error:nil
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertEqualObjects(result[@"ok"], @YES);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleJSONNSURLResponseSuccessWithEmptyBodyCallsSuccessWithNil {
    XCTestExpectation *exp = [self expectationWithDescription:@"empty body success"];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:204]
                                      data:[NSData data]
                                     error:nil
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNil(result);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleJSONNSURLResponseSuccessWithNilSuccessBlockDoesNotCrash {
    NSData *data = [self jsonDataFromObject:@{ @"ok": @YES }];
    XCTAssertNoThrow([self.instance handleJSONNSURLResponse:[self responseWithStatus:200]
                                                       data:data
                                                      error:nil
                                                  onSuccess:nil
                                                  onFailure:nil]);
}

#pragma mark - handleJSONNSURLResponse (failure)

- (void)testHandleJSONNSURLResponseInvalidJsonCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"invalid json"];
    NSData *data = [@"not-json" dataUsingEncoding:NSUTF8StringEncoding];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:200]
                                      data:data
                                     error:nil
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, @"CleverPushError");
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleJSONNSURLResponseHttpErrorCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"http 404"];
    NSData *data = [self jsonDataFromObject:@{ @"error": @"not found" }];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:404]
                                      data:data
                                     error:nil
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleJSONNSURLResponseNetworkErrorCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"network error"];
    NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:0]
                                      data:nil
                                     error:networkError
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleJSONNSURLResponseServerErrorWithoutBodyCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"500 no body"];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:500]
                                      data:nil
                                     error:nil
                                 onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - enqueueRequest (success / failure)

- (void)testEnqueueRequestForwardsToRetryVariantOnSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue success"];
    id mock = OCMPartialMock(self.instance);
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/RHe2nXvQk9SZgdC4x/config"];
    [OCMStub([mock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"channelId": @"RHe2nXvQk9SZgdC4x" });
    }];
    [mock enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Expected success: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mock stopMocking];
}

- (void)testEnqueueRequestForwardsToRetryVariantOnFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue failure"];
    id mock = OCMPartialMock(self.instance);
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    [OCMStub([mock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil]);
    }];
    [mock enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mock stopMocking];
}

- (void)testEnqueueRequestWithRetryNoForwardsToInnerFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue no retry"];
    id mock = OCMPartialMock(self.instance);
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    [OCMStub([mock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:NO]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil]);
    }];
    [mock enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    } withRetry:NO];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mock stopMocking];
}

- (void)testEnqueueRequestWithNilCallbacksDoesNotCrash {
    id mock = OCMPartialMock(self.instance);
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/RHe2nXvQk9SZgdC4x/config"];
    OCMStub([mock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]);
    XCTAssertNoThrow([mock enqueueRequest:request onSuccess:nil onFailure:nil]);
    [mock stopMocking];
}

- (void)testEnqueueFailedRequestEventuallyCallsFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueueFailedRequest"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    NSError *error = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [self.instance handleJSONNSURLResponse:[self responseWithStatus:500] data:nil error:error onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable failure) {
        XCTAssertNotNil(failure);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
