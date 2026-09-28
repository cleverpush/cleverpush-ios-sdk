@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CPChatView.h"

@interface CPChatViewTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *instance;
@property (nonatomic, retain) CPChatView *chatView;

@end

@implementation CPChatViewTest

- (void)setUp {
    [super setUp];
    self.instance = [[CleverPushInstance alloc] init];
    self.chatView = [[CPChatView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)
                                    urlOpenedCallback:^(NSURL *url) {}
                                    subscribeCallback:^{}];
}

- (void)tearDown {
    self.chatView = nil;
    [super tearDown];
}

#pragma mark - initialization

- (void)testChatViewInitWithCallbacksIsNotNil {
    XCTAssertNotNil(self.chatView);
}

- (void)testChatViewInitWithHeaderCodesIsNotNil {
    CPChatView *view = [[CPChatView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)
                                       urlOpenedCallback:^(NSURL *url) {}
                                       subscribeCallback:^{}
                                             headerCodes:@"<style></style>"];
    XCTAssertNotNil(view);
}

- (void)testChatViewWebViewIsCreated {
    XCTAssertNotNil(self.chatView.webView);
}

#pragma mark - color setters / getters (success)

- (void)testSetAndGetChatBackgroundColor {
    UIColor *color = [UIColor whiteColor];
    [self.chatView setChatBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatBackgroundColor], color);
}

- (void)testSetAndGetChatSenderBubbleTextColor {
    UIColor *color = [UIColor blackColor];
    [self.chatView setChatSenderBubbleTextColor:color];
    XCTAssertEqualObjects([self.chatView getChatSenderBubbleTextColor], color);
}

- (void)testSetAndGetChatSenderBubbleBackgroundColor {
    UIColor *color = [UIColor blueColor];
    [self.chatView setChatSenderBubbleBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatSenderBubbleBackgroundColor], color);
}

- (void)testSetAndGetChatSendButtonBackgroundColor {
    UIColor *color = [UIColor greenColor];
    [self.chatView setChatSendButtonBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatSendButtonBackgroundColor], color);
}

- (void)testSetAndGetChatInputTextColor {
    UIColor *color = [UIColor darkGrayColor];
    [self.chatView setChatInputTextColor:color];
    XCTAssertEqualObjects([self.chatView getChatInputTextColor], color);
}

- (void)testSetAndGetChatInputBackgroundColor {
    UIColor *color = [UIColor lightGrayColor];
    [self.chatView setChatInputBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatInputBackgroundColor], color);
}

- (void)testSetAndGetChatReceiverBubbleBackgroundColor {
    UIColor *color = [UIColor orangeColor];
    [self.chatView setChatReceiverBubbleBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatReceiverBubbleBackgroundColor], color);
}

- (void)testSetAndGetChatInputContainerBackgroundColor {
    UIColor *color = [UIColor yellowColor];
    [self.chatView setChatInputContainerBackgroundColor:color];
    XCTAssertEqualObjects([self.chatView getChatInputContainerBackgroundColor], color);
}

- (void)testSetAndGetChatTimestampTextColor {
    UIColor *color = [UIColor grayColor];
    [self.chatView setChatTimestampTextColor:color];
    XCTAssertEqualObjects([self.chatView getChatTimestampTextColor], color);
}

- (void)testSetAndGetChatReceiverBubbleTextColor {
    UIColor *color = [UIColor purpleColor];
    [self.chatView setChatReceiverBubbleTextColor:color];
    XCTAssertEqualObjects([self.chatView getChatReceiverBubbleTextColor], color);
}

#pragma mark - load / lock (failure / edge)

- (void)testLoadChatDoesNotCrash {
    XCTAssertNoThrow([self.chatView loadChat]);
}

- (void)testLoadChatWithSubscriptionIdDoesNotCrash {
    XCTAssertNoThrow([self.chatView loadChatWithSubscriptionId:@"preview"]);
}

- (void)testLoadChatWithNilSubscriptionIdDoesNotCrash {
    XCTAssertNoThrow([self.chatView loadChatWithSubscriptionId:nil]);
}

- (void)testLockChatDoesNotCrash {
    XCTAssertNoThrow([self.chatView lockChat]);
}

- (void)testAddChatViewDoesNotCrash {
    XCTAssertNoThrow([self.instance addChatView:self.chatView]);
}

- (void)testAddChatViewWithNilDoesNotCrash {
    XCTAssertNoThrow([self.instance addChatView:nil]);
}

- (void)testColorSettersWithNilDoNotCrash {
    XCTAssertNoThrow([self.chatView setChatBackgroundColor:nil]);
    XCTAssertNoThrow([self.chatView setChatSenderBubbleTextColor:nil]);
    XCTAssertNoThrow([self.chatView setChatInputTextColor:nil]);
}

@end
