#import <XCTest/XCTest.h>
#import "CleverPush.h"
#import "CPStoryView.h"
#import "CPWidgetModule.h"
#import <OCMock/OCMock.h>
#import "CPStoriesController.h"

@interface CPStoryWidgetTest : XCTestCase

@end

@implementation CPStoryWidgetTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCollectionView{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [[app.collectionViews.cells elementBoundByIndex:0] tap];
}


- (void)testWidgetStories {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WidgetStories"];
    [CPWidgetModule getWidgetsStories:@"o76RepCskiS9QiHsy" completion:^(CPWidgetsStories *Widget){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            XCTAssertNotNil(Widget);
            XCTAssertNotNil(Widget.widgets);
            XCTAssertNotNil(Widget.stories);
            [expectation fulfill];
        });
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
