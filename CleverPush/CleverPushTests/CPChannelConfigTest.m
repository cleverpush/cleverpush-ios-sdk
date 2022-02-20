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

@interface CPChannelConfigTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic, strong) CPHandleSubscribedBlock handleSubscribed;
@property (nonatomic) id cleverPush;

@end

@implementation CPChannelConfigTest
{
    CPHandleNotificationOpenedBlock handleNotificationOpened;
    CPNotificationOpenedResult* openResult;
}

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
    self.handleSubscribed = ^(NSString *result) {
        NSLog(@"Subscribed to CleverPush with ID: %@", result);
    };
}

- (void)testInitWhenChannleIdIsNull {
    OCMStub([self.cleverPush channelId]).andReturn(nil);
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    OCMExpect([self.cleverPush getChannelIdFromUserDefault]);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    OCMVerify([self.cleverPush getChannelIdFromUserDefault]);
}

- (void)testInitWhenChannelIdIsNullAndAlsoNoChannelIdInPrefrence {
    OCMStub([self.cleverPush channelId]).andReturn(nil);
    OCMStub([self.cleverPush getBundleName]).andReturn(@"com.test");
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    NSString *configPath = [NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", [self.cleverPush getBundleName]];
    OCMVerify([self.cleverPush getChannelConfigFromBundleId:configPath]);
}

- (void)testInitWhenChannelIdIsNotNull {
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(false);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", [self.cleverPush channelId]];
    OCMVerify([self.cleverPush getChannelConfigFromChannelId:configPath]);
}

- (void)testInitWhenChannelIdIsNotNullButChannelIdIsChanged {
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush isChannelIdChanged:@"channelId"]).andReturn(true);
    OCMStub([self.cleverPush addOrUpdateChannelId:@"channelIdChanged"]).andDo(nil);
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelIdChanged" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [[self.cleverPush verify] clearSubscriptionData];
}

- (void)testInItWhenNotificationOpenedhandlerIsNullDonotExecuteHandlerAndClearList {
    OCMStub([self.cleverPush channelId]).andReturn(nil);
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    [[self.cleverPush reject] handleNotificationOpened:nil isActive:nil actionIdentifier:nil];
}

- (void)testIsSubscribed {
    OCMStub([self.cleverPush isSubscribed]).andReturn(YES);
    BOOL result = [self.cleverPush isSubscribed];
    NSNumber *expectedoutput = [NSNumber numberWithBool:result];
    NSNumber *staticOutput = [NSNumber numberWithBool:YES];
    XCTAssertEqual(expectedoutput, staticOutput);
    [[self.cleverPush verify] isSubscribed];
}

- (void)testIncrementAppOpens {
    OCMStub([self.cleverPush isSubscribed]).andReturn(YES);
    NSInteger beforeExpectation = [self.cleverPush getAppOpens];
    [self.cleverPush incrementAppOpens];
    NSInteger afterExpectation = [self.cleverPush getAppOpens];
    XCTAssertNotEqual(beforeExpectation, afterExpectation);
}

- (void)testSubscribeOrSyncForOldSubscriptionAndAutoRegisterTrue {
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    OCMVerify([self.cleverPush subscribe]);
}

- (void)testSubscribeOrSyncForOldSubscriptionAndAutoRegisterFalse {
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    [[self.cleverPush reject] subscribe];
}

- (void)testAutoclearBadge {
    OCMStub([self.cleverPush getAutoClearBadge]).andReturn(true);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    OCMVerify([self.cleverPush clearBadge:false]);
}

- (void)testSubscriptionIdIsNotNilAndNotificationNotEnableThanVerifyUnsubscribe {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush notificationsEnabled]).andReturn(false);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush unsubscribe]);
}

- (void)testSubscriptionIdIsNilAndNotificationEnableThanVerifySubscribe {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush shouldSync]).andReturn(true);
    OCMStub([self.cleverPush notificationsEnabled]).andReturn(true);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    [_testUtilInstance performSelector:@selector(syncSubscription) withObject:self.cleverPush afterDelay:10.0f];
}

- (void)testSubscriptionIdIsNotNilAndNotificationDisableAndShouldNotSyncThanVerifySubscribeHandler {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush shouldSync]).andReturn(false);
    OCMStub([self.cleverPush getHandleSubscribedCalled]).andReturn(false);
    OCMStub([self.cleverPush getSubscribeHandler]).andReturn(self.handleSubscribed);
    CPHandleSubscribedBlock handler = [self.cleverPush getSubscribeHandler];
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify(handler(@"subscriptionId"));
}

- (void)testSubscriptionIdIsNotNilAndNotificationDisableAndShouldNotSyncThanVerifyInitFeatures {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush shouldSync]).andReturn(false);
    OCMStub([self.cleverPush getHandleSubscribedCalled]).andReturn(false);
    OCMStub([self.cleverPush getSubscribeHandler]).andReturn(self.handleSubscribed);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush initFeatures]);
}

- (void)testSubscriptionIdIsNotNilAndNotificationDisableAndShouldNotSyncThanVerifySetHandleSubscribedCalled {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush shouldSync]).andReturn(false);
    OCMStub([self.cleverPush getHandleSubscribedCalled]).andReturn(false);
    OCMStub([self.cleverPush getSubscribeHandler]).andReturn(self.handleSubscribed);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush setHandleSubscribedCalled:true]);
}

- (void)testInitInternalFeatures {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush shouldSync]).andReturn(false);
    OCMStub([self.cleverPush getHandleSubscribedCalled]).andReturn(false);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"odcpZ3GhnwiGWxCbC" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(initAppReview) withObject:self.cleverPush afterDelay:1.0f];
}

- (void)testChannelConfigApiWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfig"];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"odcpZ3GhnwiGWxCbC"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed to fetch Channel Config via Bundle Identifier. Did you specify the Bundle ID in the CleverPush channel settings? %@", error);
    }];

    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testChannelConfigApiWithInvalidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigfailure"];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"odcpZ3GhnwiGWxCbe"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSLog(@"%@", result);
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        NSLog(@"%@", [[error.userInfo objectForKey:@"returned"]valueForKey:@"error"]);
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"channel not found");
        NSInteger errorCode = error.code;
        int expectedError = 404;
        XCTAssertEqual(errorCode, expectedError);
        XCTAssertNotNil(error);
        [expectation fulfill];
        NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testChannelConfigApiWithEmptyChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"emptyChannelId"];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @""];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSLog(@"%@", result);
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        NSLog(@"%@", [[error.userInfo objectForKey:@"returned"]valueForKey:@"error"]);
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"Not found");
        NSInteger errorCode = error.code;
        int expectedError = 404;
        XCTAssertEqual(errorCode, expectedError);
        XCTAssertNotNil(error);
        [expectation fulfill];
        NSLog(@"CleverPush Error: Failed getting the channel config %@", error);
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testSyncUnsubscribeWhenSubscriptionIdExists{
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"S9cA4fr2doS24d2f6");
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    [self.cleverPush unsubscribe:^(BOOL success) {
        if (success) {
            OCMVerify([self.cleverPush clearSubscriptionData]);
            OCMVerify([self.cleverPush setUnsubscribeStatus:YES]);
        } else {
            OCMVerify([self.cleverPush clearSubscriptionData]);
        }
    }];
}
- (void)testSyncUnsubscribeWhenSubscriptionIdNotExists {
    OCMStub([self.cleverPush subscriptionId]).andReturn(nil);
    OCMStub([self.cleverPush channelId]).andReturn(@"64ipj2EG2gGNGkEr7");
    [self.cleverPush unsubscribe:^(BOOL failed) {
        if (failed) {
            OCMVerify([self.cleverPush clearSubscriptionData]);
        }
    }];
}

- (void)tearDown {
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
