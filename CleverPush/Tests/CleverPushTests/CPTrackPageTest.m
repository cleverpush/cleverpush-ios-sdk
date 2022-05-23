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
    OCMStub([self.cleverPush getTopViewController]).andReturn(nil);
    NSDictionary *parameters = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    [self.cleverPush trackPageView:@"url" params:parameters];
    OCMVerify([self.cleverPush checkTags:@"url" params:parameters]);
}

- (void)testTrackPageViewVerifyCheckTagsandVerifyAvailableTags {
    OCMStub([self.cleverPush getTopViewController]).andReturn(nil);
    NSDictionary *parameters = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    [self.cleverPush trackPageView:@"url" params:parameters];
    OCMVerify([self.cleverPush getAvailableTags:[OCMArg any]]);
}

- (void)testTrackPageViewVerifyCheckTagsandVerifyAvailableTagsCheckCurrentPageUrl {
    OCMStub([self.cleverPush getTopViewController]).andReturn(nil);
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
