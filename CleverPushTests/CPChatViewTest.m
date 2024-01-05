#import <XCTest/XCTest.h>
#import "CleverPush.h"
#import "CPStoryView.h"
#import "CPWidgetModule.h"
#import <OCMock/OCMock.h>
#import "CPStoriesController.h"

@interface CPChatViewTest : XCTestCase
@property (nonatomic, strong) CPChatView *chatView;
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
    UIColor *expectedColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    UIColor *differentColor = [UIColor redColor];
    OCMStub([CleverPush getBrandingColor]).andReturn(differentColor);
    UIColor *retrievedColor = [CleverPush getBrandingColor];
    XCTAssertNotEqualObjects(retrievedColor, expectedColor, @"Retrieved color should not match the expected color");
}

- (void)testChatBackgroundColorWithSuccess {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    [self.chatView setChatBackgroundColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0]];
    UIColor *retrievedColor = [self.chatView getChatBackgroundColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)testChatBackgroundColorWithFailure {
    UIColor *expectedColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    UIColor *retrievedColor = [self.chatView getChatBackgroundColor];
    XCTAssertNotEqualObjects(retrievedColor, expectedColor, @"Retrieved color should not match the expected color");
}

- (void)testChatSenderBubbleTextColorWithSuccess {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    [self.chatView setChatSenderBubbleTextColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0]];
    UIColor *retrievedColor = [self.chatView getChatSenderBubbleTextColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)testChatSenderBubbleTextColorWithFailure {
    UIColor *expectedColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    UIColor *retrievedColor = [self.chatView getChatSenderBubbleTextColor];
    XCTAssertNotEqualObjects(retrievedColor, expectedColor, @"Retrieved color should not match the expected color");
}

- (void)testChatSenderBubbleBackgroundColorWithSuccess {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    [self.chatView setChatSenderBubbleBackgroundColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0]];
    UIColor *retrievedColor = [self.chatView getChatSenderBubbleBackgroundColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)testChatSenderBubbleBackgroundColorWithFailure {
    UIColor *expectedColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    UIColor *retrievedColor = [self.chatView getChatSenderBubbleBackgroundColor];
    XCTAssertNotEqualObjects(retrievedColor, expectedColor, @"Retrieved color should not match the expected color");
}

- (void)testChatSendButtonBackgroundColorWithSuccess {
    UIColor *testColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    [self.chatView setChatSendButtonBackgroundColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0]];
    UIColor *retrievedColor = [self.chatView getChatSendButtonBackgroundColor];
    XCTAssertEqualObjects(retrievedColor, testColor, @"Retrieved color should match the test color");
}

- (void)testChatSendButtonBackgroundColorWithFailure {
    UIColor *expectedColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
    UIColor *retrievedColor = [self.chatView getChatSendButtonBackgroundColor];
    XCTAssertNotEqualObjects(retrievedColor, expectedColor, @"Retrieved color should not match the expected color");
}

- (void)setUp {
    self.chatView = [[CPChatView alloc] init];
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
