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

@interface CPTopicDialogueTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPTopicDialogueTest

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInitiasationOfTopicsWhenNewAdded {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(true);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    OCMVerify([CPUtils updateLastTimeAutomaticallyShowed]);
}

- (void)testInitiasationOfTopicsWhenThereIsNoNewTopics {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(false);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showPendingTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
}

- (void)testShowTopicsDialog {
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    [self.cleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
        OCMStub([self.cleverPush hasNewTopicAfterOneHour:channelConfig initialDifference:0 displayDialogDifference:3600]).andReturn(false);
    }];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"64ipj2EG2gGNGkEr7" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(showPendingTopicsDialog) withObject:self.cleverPush afterDelay:1.0f];
}
- (void)testGetSubscriptionTopics{
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    OCMStub([self.cleverPush getSubscriptionTopics]).andReturn(topics);
    NSMutableArray *expectedTopics = [self.cleverPush getSubscriptionTopics];
    XCTAssertEqual(topics, expectedTopics);
    XCTAssertTrue([[self.cleverPush getSubscriptionTopics] containsObject:@"topicId"]);
}

- (void)testCheckTheTopicsHasBeenExistOrNot {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    OCMStub([self.cleverPush hasSubscriptionTopics]).andReturn(true);
    [self.cleverPush setSubscriptionTopics:topics];
    XCTAssertTrue([[self.cleverPush getSubscriptionTopics] containsObject:@"topicId"]);
    XCTAssertTrue([self.cleverPush hasSubscriptionTopics]);
}

- (void)testSubscribeWhenConfirmAlertHideChannelTopicsTrue {
    void (^channelConfigListenerAnswer)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSDictionary *value = [[NSDictionary alloc]initWithObjectsAndKeys:@"true", @"confirmAlertHideChannelTopics", nil];
        [invocation getArgument:&value atIndex:2];
    };
    
    OCMStub([self.cleverPush getChannelConfig:[OCMArg any]])._andDo(channelConfigListenerAnswer);
    [self.cleverPush subscribe];
    XCTAssertFalse([self.cleverPush isSubscriptionInProgress]);
    [[self.cleverPush reject] showPendingTopicsDialog];
}

- (void)testShowTopicDialogWhenAvailableTopicCountZero {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertEqual(topics.count, 0);
    }];
    [[self.cleverPush reject] getChannelConfig:[OCMArg any]];
}

    
- (void)testShowTopicDialogWhenAvailableTopicCountNonZeroAndNotSubscribeThenVerifyInitTopicDialogData {
    NSMutableDictionary *objChannelConfig = [[NSMutableDictionary alloc] init];
    [objChannelConfig setObject:@"9WTamHSgogdBgdfw9" forKey:@"_id"];
    [objChannelConfig setObject:@"Adaptability" forKey:@"name"];
    [objChannelConfig setObject:@"2021-07-28T08:58:56.140Z" forKey:@"createdAt"];
    [objChannelConfig setObject:@"" forKey:@"icon"];
    [objChannelConfig setObject:@"null" forKey:@"layerFunction"];
    [objChannelConfig setObject:@"7ufjxPEdzHD9XpJQf" forKey:@"parentTopic"];
    OCMStub([self.cleverPush isSubscribed])._andDo(false);
    NSArray *customTopics = [[NSArray alloc]initWithObjects:objChannelConfig,  nil];
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:customTopics,@"channelTopics", nil];

    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush showTopicsDialog];
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertNotEqual(topics.count, 0);
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        OCMVerify([self.cleverPush initTopicsDialogData:responseObject syncToBackend:NO]);
    });
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
