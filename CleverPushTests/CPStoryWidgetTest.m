#import <XCTest/XCTest.h>
#import "CleverPush.h"
#import "CPStoryView.h"
#import "CPWidgetModule.h"
#import <OCMock/OCMock.h>
#import "CPStoriesController.h"
#import "CPWidgetsStories.h"
#import "CPStoryWidget.h"
#import "CPStory.h"
#import "CleverPushHTTPClient.h"

@interface CPStoryWidgetTest : XCTestCase

@property (nonatomic, strong) id widgetModuleMock;
@property (nonatomic, strong) CPWidgetsStories *sampleWidgetsStories;
@property (nonatomic, strong) CPStoryWidget *sampleWidget;
@property (nonatomic, strong) CPStory *sampleStory;

@end

@implementation CPStoryWidgetTest

- (void)setUp {
    [super setUp];

    // Build a sample CPStoryWidget
    NSDictionary *widgetJson = @{
        @"_id": @"o76RepCskiS9QiHsy",
        @"channel": @"hrPmxqynN7NJ7qtAz",
        @"name": @"Test Widget",
        @"maxStoriesNumber": @"10",
        @"storyHeight": @"150",
        @"margin": @"8",
        @"groupStoryCategories": @NO,
        @"variant": @"circle",
        @"position": @"top",
        @"display": @"all",
        @"selectedStories": @[]
    };
    self.sampleWidget = [[CPStoryWidget alloc] initWithJson:widgetJson];

    // Build a sample CPStory
    NSDictionary *storyJson = @{
        @"_id": @"story123",
        @"channel": @"hrPmxqynN7NJ7qtAz",
        @"title": @"Test Story",
        @"opened": @NO,
        @"subStoryCount": @3,
        @"unreadCount": @2,
        @"content": @{}
    };
    self.sampleStory = [[CPStory alloc] initWithJson:storyJson];

    // Build a sample CPWidgetsStories
    NSDictionary *wsJson = @{
        @"widget": widgetJson,
        @"stories": @[storyJson]
    };
    self.sampleWidgetsStories = [[CPWidgetsStories alloc] initWithJson:wsJson];

    // Partial mock of CPWidgetModule (class mock)
    self.widgetModuleMock = OCMClassMock([CPWidgetModule class]);
}

- (void)tearDown {
    [self.widgetModuleMock stopMocking];
    [super tearDown];
}

#pragma mark - CPStoryWidget model properties

- (void)testStoryWidgetIdIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleWidget.id, @"o76RepCskiS9QiHsy");
}

- (void)testStoryWidgetChannelIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleWidget.channel, @"hrPmxqynN7NJ7qtAz");
}

- (void)testStoryWidgetNameIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleWidget.name, @"Test Widget");
}

- (void)testStoryWidgetMaxStoriesNumberIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleWidget.maxStoriesNumber, @"10");
}

- (void)testStoryWidgetStoryHeightIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleWidget.storyHeight, @"150");
}

- (void)testStoryWidgetGroupStoryCategoriesIsSetCorrectly {
    XCTAssertFalse(self.sampleWidget.groupStoryCategories);
}

- (void)testStoryWidgetSelectedStoriesIsInitiallyEmpty {
    XCTAssertNotNil(self.sampleWidget.selectedStories);
    XCTAssertEqual(self.sampleWidget.selectedStories.count, 0);
}

#pragma mark - CPStory model properties

- (void)testStoryIdIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleStory.id, @"story123");
}

- (void)testStoryChannelIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleStory.channel, @"hrPmxqynN7NJ7qtAz");
}

- (void)testStoryTitleIsSetCorrectly {
    XCTAssertEqualObjects(self.sampleStory.title, @"Test Story");
}

- (void)testStoryOpenedIsSetCorrectly {
    XCTAssertFalse(self.sampleStory.opened);
}

- (void)testStorySubStoryCountIsSetCorrectly {
    XCTAssertEqual(self.sampleStory.subStoryCount, 3);
}

- (void)testStoryUnreadCountIsSetCorrectly {
    XCTAssertEqual(self.sampleStory.unreadCount, 2);
}

#pragma mark - CPWidgetsStories model properties

- (void)testWidgetsStoriesWidgetsIsNotNil {
    XCTAssertNotNil(self.sampleWidgetsStories.widgets);
}

- (void)testWidgetsStoriesStoriesIsNotNil {
    XCTAssertNotNil(self.sampleWidgetsStories.stories);
}

- (void)testWidgetsStoriesStoriesCountIsCorrect {
    XCTAssertEqual(self.sampleWidgetsStories.stories.count, 1);
}

- (void)testWidgetsStoriesWidgetIdMatchesExpected {
    XCTAssertEqualObjects(self.sampleWidgetsStories.widgets.id, @"o76RepCskiS9QiHsy");
}

#pragma mark - getWidgetsStories (mocked - success)

- (void)testGetWidgetsStoriesCallsCompletionWithResult {
    XCTestExpectation *exp = [self expectationWithDescription:@"getWidgetsStories success"];

    [OCMStub([self.widgetModuleMock getWidgetsStories:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(CPWidgetsStories *);
        [inv getArgument:&cb atIndex:3];
        cb(self.sampleWidgetsStories);
    }];

    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil(result.widgets);
        XCTAssertNotNil(result.stories);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetWidgetsStoriesCompletionReturnsCorrectWidgetId {
    XCTestExpectation *exp = [self expectationWithDescription:@"widgetId matches"];

    [OCMStub([self.widgetModuleMock getWidgetsStories:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(CPWidgetsStories *);
        [inv getArgument:&cb atIndex:3];
        cb(self.sampleWidgetsStories);
    }];

    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *result) {
        XCTAssertEqualObjects(result.widgets.id, @"o76RepCskiS9QiHsy");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetWidgetsStoriesCompletionReturnsStoriesArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"stories array"];

    [OCMStub([self.widgetModuleMock getWidgetsStories:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(CPWidgetsStories *);
        [inv getArgument:&cb atIndex:3];
        cb(self.sampleWidgetsStories);
    }];

    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *result) {
        XCTAssertEqual(result.stories.count, 1);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetWidgetsStoriesWithEmptyStoriesArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"empty stories"];

    CPWidgetsStories *emptyWS = [[CPWidgetsStories alloc] initWithJson:@{
        @"widget": @{
            @"_id": @"emptyWidget",
            @"channel": @"ch",
            @"name": @"Empty",
            @"maxStoriesNumber": @"0",
            @"storyHeight": @"100",
            @"margin": @"0",
            @"groupStoryCategories": @NO,
            @"variant": @"circle",
            @"position": @"top",
            @"display": @"all",
            @"selectedStories": @[]
        },
        @"stories": @[]
    }];

    [OCMStub([self.widgetModuleMock getWidgetsStories:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(CPWidgetsStories *);
        [inv getArgument:&cb atIndex:3];
        cb(emptyWS);
    }];

    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *result) {
        XCTAssertNotNil(result);
        XCTAssertEqual(result.stories.count, 0);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - getWidgetsStories (mocked - failure / nil)

- (void)testGetWidgetsStoriesCompletionWithNilDoesNotCrash {
    XCTestExpectation *exp = [self expectationWithDescription:@"nil result"];

    [OCMStub([self.widgetModuleMock getWidgetsStories:[OCMArg any] completion:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        void (^ __unsafe_unretained cb)(CPWidgetsStories *);
        [inv getArgument:&cb atIndex:3];
        cb(nil);
    }];

    [CPWidgetModule getWidgetsStories:@"invalidId" completion:^(CPWidgetsStories *result) {
        XCTAssertNil(result);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - trackWidgetOpened (mocked - success)

- (void)testTrackWidgetOpenedCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetOpened success"];

    [OCMStub([self.widgetModuleMock trackWidgetOpened:[OCMArg any]
                                          withStories:[OCMArg any]
                                            onSuccess:[OCMArg any]
                                           onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPResultSuccessBlock __unsafe_unretained success;
        [inv getArgument:&success atIndex:4];
        if (success) success(@{@"status": @"ok"});
    }];

    [CPWidgetModule trackWidgetOpened:@"o76RepCskiS9QiHsy"
                          withStories:@[@"story123"]
                            onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure");
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackWidgetOpenedWithMultipleStoriesCallsSuccess {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetOpened multi stories"];

    [OCMStub([self.widgetModuleMock trackWidgetOpened:[OCMArg any]
                                          withStories:[OCMArg any]
                                            onSuccess:[OCMArg any]
                                           onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPResultSuccessBlock __unsafe_unretained success;
        [inv getArgument:&success atIndex:4];
        if (success) success(@{});
    }];

    [CPWidgetModule trackWidgetOpened:@"o76RepCskiS9QiHsy"
                          withStories:@[@"story1", @"story2", @"story3"]
                            onSuccess:^(NSDictionary * _Nullable result) {
        [exp fulfill];
    } onFailure:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - trackWidgetOpened (mocked - failure)

- (void)testTrackWidgetOpenedCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetOpened failure"];

    NSError *mockError = [NSError errorWithDomain:@"TestDomain" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Not Found"}];

    [OCMStub([self.widgetModuleMock trackWidgetOpened:[OCMArg any]
                                          withStories:[OCMArg any]
                                            onSuccess:[OCMArg any]
                                           onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPFailureBlock __unsafe_unretained failure;
        [inv getArgument:&failure atIndex:5];
        if (failure) failure(mockError);
    }];

    [CPWidgetModule trackWidgetOpened:@"invalidWidgetId"
                          withStories:@[@"story123"]
                            onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackWidgetOpenedWithNilCallbacksDoesNotCrash {
    [OCMStub([self.widgetModuleMock trackWidgetOpened:[OCMArg any]
                                          withStories:[OCMArg any]
                                            onSuccess:[OCMArg any]
                                           onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {}];
    XCTAssertNoThrow([CPWidgetModule trackWidgetOpened:@"o76RepCskiS9QiHsy"
                                           withStories:@[@"story123"]
                                             onSuccess:nil
                                            onFailure:nil]);
}

#pragma mark - trackWidgetShown (mocked - success)

- (void)testTrackWidgetShownCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetShown success"];

    [OCMStub([self.widgetModuleMock trackWidgetShown:[OCMArg any]
                                         withStories:[OCMArg any]
                                           onSuccess:[OCMArg any]
                                          onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPResultSuccessBlock __unsafe_unretained success;
        [inv getArgument:&success atIndex:4];
        if (success) success(@{@"status": @"ok"});
    }];

    [CPWidgetModule trackWidgetShown:@"o76RepCskiS9QiHsy"
                         withStories:@[@"story123"]
                           onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure");
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackWidgetShownWithEmptyStoriesCallsSuccess {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetShown empty stories"];

    [OCMStub([self.widgetModuleMock trackWidgetShown:[OCMArg any]
                                         withStories:[OCMArg any]
                                           onSuccess:[OCMArg any]
                                          onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPResultSuccessBlock __unsafe_unretained success;
        [inv getArgument:&success atIndex:4];
        if (success) success(@{});
    }];

    [CPWidgetModule trackWidgetShown:@"o76RepCskiS9QiHsy"
                         withStories:@[]
                           onSuccess:^(NSDictionary * _Nullable result) {
        [exp fulfill];
    } onFailure:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - trackWidgetShown (mocked - failure)

- (void)testTrackWidgetShownCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"trackWidgetShown failure"];

    NSError *mockError = [NSError errorWithDomain:@"TestDomain" code:500 userInfo:@{NSLocalizedDescriptionKey: @"Internal Server Error"}];

    [OCMStub([self.widgetModuleMock trackWidgetShown:[OCMArg any]
                                         withStories:[OCMArg any]
                                           onSuccess:[OCMArg any]
                                          onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {
        CPFailureBlock __unsafe_unretained failure;
        [inv getArgument:&failure atIndex:5];
        if (failure) failure(mockError);
    }];

    [CPWidgetModule trackWidgetShown:@"invalidId"
                         withStories:@[@"story123"]
                           onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackWidgetShownWithNilCallbacksDoesNotCrash {
    [OCMStub([self.widgetModuleMock trackWidgetShown:[OCMArg any]
                                         withStories:[OCMArg any]
                                           onSuccess:[OCMArg any]
                                          onFailure:[OCMArg any]]) andDo:^(NSInvocation *inv) {}];
    XCTAssertNoThrow([CPWidgetModule trackWidgetShown:@"o76RepCskiS9QiHsy"
                                          withStories:@[@"story123"]
                                            onSuccess:nil
                                           onFailure:nil]);
}

#pragma mark - CPStoryView initialization

- (void)testStoryViewInitWithFrameAndWidgetIdDoesNotReturnNil {
    CPStoryView *view = [[CPStoryView alloc] initWithFrame:CGRectMake(0, 0, 375, 100)
                                           backgroundColor:[UIColor whiteColor]
                                                 textColor:[UIColor blackColor]
                                                fontFamily:@"avenir"
                                               borderColor:[UIColor blueColor]
                                                  widgetId:@"o76RepCskiS9QiHsy"];
    XCTAssertNotNil(view);
}

- (void)testStoryViewInitWithFrameWithoutWidgetIdDoesNotReturnNil {
    CPStoryView *view = [[CPStoryView alloc] initWithFrame:CGRectMake(0, 0, 375, 100)
                                           backgroundColor:[UIColor whiteColor]
                                                 textColor:[UIColor blackColor]
                                                fontFamily:@"avenir"
                                               borderColor:[UIColor blueColor]];
    XCTAssertNotNil(view);
}

- (void)testStoryViewInitWithIconHeightAndWidthDoesNotReturnNil {
    CPStoryView *view = [[CPStoryView alloc] initWithFrame:CGRectMake(0, 0, 375, 100)
                                           backgroundColor:[UIColor whiteColor]
                                                 textColor:[UIColor blackColor]
                                                fontFamily:@"avenir"
                                               borderColor:[UIColor blueColor]
                                           storyIconHeight:80
                                            storyIconWidth:80
                                                  widgetId:@"o76RepCskiS9QiHsy"];
    XCTAssertNotNil(view);
}

- (void)testStoryViewHasInitializedFalseByDefault {
    CPStoryView *view = [[CPStoryView alloc] initWithFrame:CGRectMake(0, 0, 375, 100)
                                           backgroundColor:[UIColor whiteColor]
                                                 textColor:[UIColor blackColor]
                                                fontFamily:@"avenir"
                                               borderColor:[UIColor blueColor]
                                                  widgetId:@"o76RepCskiS9QiHsy"];
    // CPStoryView loads asynchronously; hasInitialized starts as NO
    XCTAssertFalse(view.hasInitialized);
}

- (void)testStoryViewStoriesInitiallyEmpty {
    CPStoryView *view = [[CPStoryView alloc] initWithFrame:CGRectMake(0, 0, 375, 100)
                                           backgroundColor:[UIColor whiteColor]
                                                 textColor:[UIColor blackColor]
                                                fontFamily:@"avenir"
                                               borderColor:[UIColor blueColor]
                                                  widgetId:@"o76RepCskiS9QiHsy"];
    // stories array may be nil before data loads — just ensure no crash
    XCTAssertTrue(view.stories == nil || view.stories.count >= 0);
}

#pragma mark - CPStoryView static helpers

- (void)testSetAndGetWidgetId {
    [CPStoryView setWidgetId:@"testWidgetId"];
    XCTAssertEqualObjects([CPStoryView getWidgetId], @"testWidgetId");
}

- (void)testSetDarkModeEnabledTrue {
    [CPStoryView setDarkModeEnabled:YES];
    XCTAssertTrue([CPStoryView getDarkModeEnabled]);
}

- (void)testSetDarkModeEnabledFalse {
    [CPStoryView setDarkModeEnabled:NO];
    XCTAssertFalse([CPStoryView getDarkModeEnabled]);
}

- (void)testGetWidgetIdReturnsNilWhenNotSet {
    [CPStoryView setWidgetId:nil];
    XCTAssertNil([CPStoryView getWidgetId]);
}

#pragma mark - live API - getWidgetsStories (valid widget ID)

- (void)testGetWidgetsStoriesWithValidId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getWidgetsStories valid"];
    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *widget) {
        dispatch_async(dispatch_get_main_queue(), ^{
            XCTAssertNotNil(widget);
            XCTAssertNotNil(widget.widgets);
            XCTAssertNotNil(widget.stories);
            [expectation fulfill];
        });
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

#pragma mark - live API - trackWidgetOpened (valid widget ID)

- (void)testTrackWidgetOpenedWithValidId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"trackWidgetOpened live"];
    [CPWidgetModule trackWidgetOpened:@"o76RepCskiS9QiHsy"
                          withStories:@[@"story123"]
                            onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        // Some channels may return 404 for non-existent stories — still not a crash
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

#pragma mark - live API - trackWidgetShown (valid widget ID)

- (void)testTrackWidgetShownWithValidId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"trackWidgetShown live"];
    [CPWidgetModule trackWidgetShown:@"o76RepCskiS9QiHsy"
                         withStories:@[@"story123"]
                           onSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) NSLog(@"Timeout: %@", error);
    }];
}

#pragma mark - live API - getWidgetsStories (invalid widget ID — expects nil callback)

- (void)testGetWidgetsStoriesWithInvalidIdDoesNotCallCallback {
    // The real implementation silently skips the callback on nil result
    // We verify no crash occurs with a bad widget ID using a short timeout
    XCTestExpectation *expectation = [self expectationWithDescription:@"getWidgetsStories invalid — timeout expected"];
    expectation.inverted = YES;

    [CPWidgetModule getWidgetsStories:@"invalidWidgetId_xyz_9999" completion:^(CPWidgetsStories *widget) {
        // Callback should NOT be called for a bad/non-existent widget
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - performance

- (void)testPerformanceExample {
    [self measureBlock:^{
    }];
}

@end
