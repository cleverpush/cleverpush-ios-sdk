#import <XCTest/XCTest.h>
#import "CleverPush.h"
#import "CPStoryView.h"
#import "CPWidgetModule.h"
#import <OCMock/OCMock.h>
#import "CPStoriesController.h"

@interface CPChatViewTest : XCTestCase

@end

@implementation CPChatViewTest

- (void)testGetBrandingColorWithSuccess {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    OCMStub([CleverPush getBrandingColor]).andReturn(testColor);
    [CleverPush setBrandingColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0]];
    UIColor *retrievedColor = [CleverPush getBrandingColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)testGetBrandingColorWithFailure {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    OCMStub([CleverPush getBrandingColor]).andReturn(testColor);
    [CleverPush setBrandingColor:[UIColor colorWithRed:0.1 green:0.5 blue:0.0 alpha:0.1]];
    UIColor *retrievedColor = [CleverPush getBrandingColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
