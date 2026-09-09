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

- (void)testEnqueueRequestSuccessWithValidChannelConfig {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue success"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/RHe2nXvQk9SZgdC4x/config"];
    [self.instance enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Expected success: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

- (void)testEnqueueRequestFailureWithInvalidPath {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue failure"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    [self.instance enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

- (void)testEnqueueRequestWithRetryNoDoesNotCrash {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueue no retry"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    [self.instance enqueueRequest:request onSuccess:^(NSDictionary * _Nullable result) {
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    } withRetry:NO];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

- (void)testEnqueueRequestWithNilCallbacksDoesNotCrash {
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/RHe2nXvQk9SZgdC4x/config"];
    XCTAssertNoThrow([self.instance enqueueRequest:request onSuccess:nil onFailure:nil]);
}

- (void)testEnqueueFailedRequestEventuallyCallsFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"enqueueFailedRequest"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:@"channel/__invalid_channel__/config"];
    [self.instance enqueueFailedRequest:request withRetryCount:99 onSuccess:^(NSDictionary * _Nullable result) {
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

@end
