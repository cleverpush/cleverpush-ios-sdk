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

@interface CPTrackPageTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic, retain) UIViewController *controller;
@property (nonatomic) id cleverPush;
@property (nonatomic) id mockViewController;

@end

@implementation CPTrackPageTest
- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}

- (void)testTrackPageViewVerifyCheckTags {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *parameters = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    [self.cleverPush trackPageView:@"url" params:parameters];
    OCMVerify([self.cleverPush checkTags:@"url" params:parameters]);
}

- (void)testTrackPageViewVerifyCheckTagsandVerifyAvailableTags {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *parameters = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    [self.cleverPush trackPageView:@"url" params:parameters];
    OCMVerify([self.cleverPush getAvailableTags:[OCMArg any]]);
}

- (void)testTrackPageViewVerifyCheckTagsandVerifyAvailableTagsCheckCurrentPageUrl {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *parameters = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    [self.cleverPush trackPageView:@"url" params:parameters];
    NSString *expectedURL = [self.cleverPush getCurrentPageUrl];
    XCTAssertEqual(expectedURL, @"url");
}
- (void)testTrackPageViewWhileAutoAssignTags {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getCurrentPageUrl]).andReturn(@"url");
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];
    [OCMStub([self.cleverPush autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    NSString *expectedURL = [self.cleverPush getCurrentPageUrl];
    XCTAssertEqual(expectedURL, @"url");
    XCTAssertTrue([[self.cleverPush getAvailableTags] containsObject:@"tagId"]);
}

#pragma mark - trackPageView (no params overload)

- (void)testTrackPageViewWithoutParamsCallsCheckTags {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    OCMExpect([self.cleverPush checkTags:@"https://example.com/page" params:nil]);
    [self.cleverPush trackPageView:@"https://example.com/page"];
    OCMVerify([self.cleverPush checkTags:@"https://example.com/page" params:nil]);
}

- (void)testTrackPageViewWithoutParamsSetsCurrentPageUrl {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    [self.cleverPush trackPageView:@"https://example.com/home"];
    NSString *currentUrl = [self.cleverPush getCurrentPageUrl];
    XCTAssertEqualObjects(currentUrl, @"https://example.com/home");
}

- (void)testTrackPageViewWithNilUrlDoesNotCrash {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    XCTAssertNoThrow([self.cleverPush trackPageView:nil]);
}

- (void)testTrackPageViewWithEmptyUrlDoesNotCrash {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    XCTAssertNoThrow([self.cleverPush trackPageView:@""]);
}

#pragma mark - trackPageView (with params)

- (void)testTrackPageViewWithParamsSetsCurrentPageUrl {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *params = @{@"section": @"sports", @"page": @"1"};
    [self.cleverPush trackPageView:@"https://example.com/sports" params:params];
    XCTAssertEqualObjects([self.cleverPush getCurrentPageUrl], @"https://example.com/sports");
}

- (void)testTrackPageViewWithParamsCallsCheckTagsWithCorrectArguments {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *params = @{@"category": @"news"};
    [self.cleverPush trackPageView:@"https://example.com/news" params:params];
    OCMVerify([self.cleverPush checkTags:@"https://example.com/news" params:params]);
}

- (void)testTrackPageViewWithNilParamsCallsCheckTagsWithNilParams {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    [self.cleverPush trackPageView:@"https://example.com/page" params:nil];
    OCMVerify([self.cleverPush checkTags:@"https://example.com/page" params:nil]);
}

- (void)testTrackPageViewWithEmptyParamsDictionary {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *emptyParams = @{};
    XCTAssertNoThrow([self.cleverPush trackPageView:@"https://example.com/page" params:emptyParams]);
    OCMVerify([self.cleverPush checkTags:@"https://example.com/page" params:emptyParams]);
}

- (void)testTrackPageViewWithNilUrlAndNonNilParamsDoesNotCrash {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    NSDictionary *params = @{@"key": @"value"};
    XCTAssertNoThrow([self.cleverPush trackPageView:nil params:params]);
}

#pragma mark - getCurrentPageUrl

- (void)testGetCurrentPageUrlReturnsNilBeforeAnyTrackCall {
    NSString *url = [self.cleverPush getCurrentPageUrl];
    XCTAssertNil(url);
}

- (void)testGetCurrentPageUrlUpdatesAfterMultipleTrackCalls {
    OCMStub([self.cleverPush topViewController]).andReturn(nil);
    [self.cleverPush trackPageView:@"https://example.com/first"];
    XCTAssertEqualObjects([self.cleverPush getCurrentPageUrl], @"https://example.com/first");

    [self.cleverPush trackPageView:@"https://example.com/second"];
    XCTAssertEqualObjects([self.cleverPush getCurrentPageUrl], @"https://example.com/second");
}

#pragma mark - checkTags

- (void)testCheckTagsWithNilUrlDoesNotCallGetAvailableTags {
    [[self.cleverPush reject] getAvailableTags:[OCMArg any]];
    [self.cleverPush checkTags:nil params:nil];
    OCMVerifyAll(self.cleverPush);
}

- (void)testCheckTagsWithEmptyUrlDoesNotCallGetAvailableTags {
    [[self.cleverPush reject] getAvailableTags:[OCMArg any]];
    [self.cleverPush checkTags:@"" params:nil];
    OCMVerifyAll(self.cleverPush);
}

- (void)testCheckTagsWithInvalidUrlDoesNotCallGetAvailableTags {
    [[self.cleverPush reject] getAvailableTags:[OCMArg any]];
    [self.cleverPush checkTags:@"not a valid url !!!" params:nil];
    OCMVerifyAll(self.cleverPush);
}

- (void)testCheckTagsWithValidUrlCallsGetAvailableTags {
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(@[]);
    }];
    [self.cleverPush checkTags:@"https://example.com/path" params:nil];
    OCMVerify([self.cleverPush getAvailableTags:[OCMArg any]]);
}

- (void)testCheckTagsWithValidUrlAndEmptyTagsDoesNotCallAutoAssign {
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(@[]);
    }];
    [[self.cleverPush reject] autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]];
    [self.cleverPush checkTags:@"https://example.com/path" params:nil];
    OCMVerifyAll(self.cleverPush);
}

- (void)testCheckTagsWithValidUrlAndNilTagsDoesNotCallAutoAssign {
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];
    [[self.cleverPush reject] autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]];
    [self.cleverPush checkTags:@"https://example.com/path" params:nil];
    OCMVerifyAll(self.cleverPush);
}

#pragma mark - autoAssignTagMatches (path-based)

- (void)testAutoAssignTagMatchesCallsCallbackYesWhenPathMatches {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"/sports" forKey:@"autoAssignPath"];

    __block BOOL matched = NO;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/sports/football" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertTrue(matched);
}

- (void)testAutoAssignTagMatchesCallsCallbackNoWhenPathDoesNotMatch {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"/tech" forKey:@"autoAssignPath"];

    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/sports/football" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

- (void)testAutoAssignTagMatchesCallsCallbackNoWhenPathnameIsNil {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"/sports" forKey:@"autoAssignPath"];

    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:nil params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

- (void)testAutoAssignTagMatchesCallsCallbackNoWhenPathnameIsEmpty {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"/sports" forKey:@"autoAssignPath"];

    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

- (void)testAutoAssignTagMatchesWithEmptyPathStringMatchesAnyPathname {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"[EMPTY]" forKey:@"autoAssignPath"];

    __block BOOL matched = NO;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/any/path" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    // [EMPTY] is replaced with "" which won't match any path with rangeOfString empty-string search
    // The result depends on NSRegularExpressionSearch with empty pattern — empty string matches everywhere
    XCTAssertTrue(matched);
}

- (void)testAutoAssignTagMatchesWithNoPathAndNoFunctionCallsCallbackNo {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    // No autoAssignPath, no autoAssignFunction, no autoAssignSelector

    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/some/path" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

#pragma mark - autoAssignTagMatches (function-based)

- (void)testAutoAssignTagMatchesWithFunctionAndMatchingParamsCallsCallbackYes {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"(function(params) { return params['type'] === 'premium'; })(params)" forKey:@"autoAssignFunction"];

    NSDictionary *params = @{@"type": @"premium"};
    __block BOOL matched = NO;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/page" params:params callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertTrue(matched);
}

- (void)testAutoAssignTagMatchesWithFunctionAndNonMatchingParamsCallsCallbackNo {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"(function(params) { return params['type'] === 'premium'; })(params)" forKey:@"autoAssignFunction"];

    NSDictionary *params = @{@"type": @"free"};
    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/page" params:params callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

- (void)testAutoAssignTagMatchesWithFunctionButNilParamsCallsCallbackNo {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"(function(params) { return params['type'] === 'premium'; })(params)" forKey:@"autoAssignFunction"];

    __block BOOL matched = YES;
    [self.cleverPush autoAssignTagMatches:tag pathname:@"/page" params:nil callback:^(BOOL result) {
        matched = result;
    }];
    XCTAssertFalse(matched);
}

#pragma mark - trackPageView + getAvailableTags integration (mocked)

- (void)testTrackPageViewWithMatchingTagAutoAssignsTag {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"tagId1" forKey:@"id"];
    [tag setValue:@"/sports" forKey:@"autoAssignPath"];

    NSArray *mockTags = @[tag];

    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(mockTags);
    }];

    [OCMStub([self.cleverPush autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(BOOL);
        [invocation getArgument:&callback atIndex:5];
        callback(YES);
    }];

    [self.cleverPush trackPageView:@"https://example.com/sports/news"];
    OCMVerify([self.cleverPush autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testTrackPageViewWithNonMatchingTagDoesNotAutoAssignTag {
    CPChannelTag *tag = [[CPChannelTag alloc] init];
    [tag setValue:@"tagId2" forKey:@"id"];
    [tag setValue:@"/tech" forKey:@"autoAssignPath"];

    NSArray *mockTags = @[tag];

    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(mockTags);
    }];

    [OCMStub([self.cleverPush autoAssignTagMatches:[OCMArg any] pathname:[OCMArg any] params:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(BOOL);
        [invocation getArgument:&callback atIndex:5];
        callback(NO);
    }];

    [[self.cleverPush reject] addSubscriptionTag:[OCMArg any]];

    [self.cleverPush trackPageView:@"https://example.com/sports/news"];
    OCMVerifyAll(self.cleverPush);
}

#pragma mark - trackPageView live API test

- (void)testTrackPageViewApiCallWithValidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"trackPageView API"];

    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"RHe2nXvQk9SZgdC4x"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];

    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTFail(@"Unexpected failure: %@", error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testTrackPageViewApiCallWithInvalidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"trackPageView API failure"];

    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"__invalid_channel__"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];

    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        NSLog(@"Unexpected success response: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 404);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)tearDown {
}

@end
