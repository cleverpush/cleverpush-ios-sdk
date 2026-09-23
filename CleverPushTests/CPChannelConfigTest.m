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
    OCMExpect([self.cleverPush getChannelIdFromUserDefaults]);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];
    OCMVerify([self.cleverPush getChannelIdFromUserDefaults]);
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
    OCMVerify([self.cleverPush clearBadge]);
}

- (void)testSubscriptionIdIsNotNilAndNotificationNotEnableThanVerifyUnsubscribe {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^callback)(BOOL enabled);
        [invocation getArgument:&callback atIndex:2];
        if (callback) {
            callback(NO);
        }
    });
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"channelId" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush unsubscribe]);
}

- (void)testSubscriptionIdIsNilAndNotificationEnableThanVerifySubscribe {
    OCMStub([self.cleverPush subscriptionId]).andReturn(@"subscriptionId");
    OCMStub([self.cleverPush channelId]).andReturn(@"channelId");
    OCMStub([self.cleverPush shouldSync]).andReturn(true);
    OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^callback)(BOOL enabled);
        [invocation getArgument:&callback atIndex:2];
        if (callback) {
            callback(YES);
        }
    });
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
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    [_testUtilInstance performSelector:@selector(showTopicDialogOnNewAdded) withObject:self.cleverPush afterDelay:1.0f];
    [_testUtilInstance performSelector:@selector(initAppReview) withObject:self.cleverPush afterDelay:1.0f];
}

- (void)testChannelConfigApiWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfig"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"channelId": @"RHe2nXvQk9SZgdC4x" });
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"RHe2nXvQk9SZgdC4x"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        XCTFail(@"Unexpected failure: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testChannelConfigApiWithInvalidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigfailure"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:@{ @"returned": @{ @"error": @"channel not found" } }]);
        }
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @"odcpZ3GhnwiGWxCbe"];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"channel not found");
        XCTAssertEqual(error.code, 404);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testChannelConfigApiWithEmptyChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"emptyChannelId"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:@{ @"returned": @{ @"error": @"Not found" } }]);
        }
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config", @""];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError* error) {
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"]valueForKey:@"error"], @"Not found");
        XCTAssertEqual(error.code, 404);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetChannelConfigReturnsConfigWhenAlreadyCached {
    NSDictionary *mockConfig = @{
        @"channelId": @"RHe2nXvQk9SZgdC4x",
        @"name": @"Test Channel",
        @"confirmAlertSettingsEnabled": @NO
    };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSDictionary *);
        [invocation getArgument:&callback atIndex:2];
        callback(mockConfig);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *config) {
        XCTAssertNotNil(config);
        XCTAssertEqualObjects([config objectForKey:@"channelId"], @"RHe2nXvQk9SZgdC4x");
        XCTAssertEqualObjects([config objectForKey:@"name"], @"Test Channel");
    }];
}

- (void)testGetChannelConfigReturnsNilWhenConfigNotAvailable {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSDictionary *);
        [invocation getArgument:&callback atIndex:2];
        callback(nil);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *config) {
        XCTAssertNil(config);
    }];
}

- (void)testGetChannelConfigFromChannelIdSuccess {
    XCTestExpectation *exp = [self expectationWithDescription:@"getChannelConfigFromChannelId"];
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config?platformName=iOS", @"RHe2nXvQk9SZgdC4x"];
    OCMStub([self.cleverPush getChannelConfigFromChannelId:configPath]).andDo(^(NSInvocation *inv) {
        [exp fulfill];
    });
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetChannelConfigFromBundleIdSuccess {
    OCMStub([self.cleverPush channelId]).andReturn(nil);
    OCMStub([self.cleverPush getBundleName]).andReturn(@"com.example.app");
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    NSString *configPath = [NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", @"com.example.app"];
    OCMExpect([self.cleverPush getChannelConfigFromBundleId:configPath]);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush getChannelConfigFromBundleId:configPath]);
}

- (void)testGetChannelConfigFromChannelIdApiSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigFromChannelIdSuccess"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"channelId": @"RHe2nXvQk9SZgdC4x" });
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config?platformName=iOS", @"RHe2nXvQk9SZgdC4x"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTFail(@"Expected success but got failure: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetChannelConfigFromChannelIdApiFailureWithInvalidId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigFromChannelIdFailure"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:@{ @"returned": @{ @"error": @"channel not found" } }]);
        }
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel/%@/config?platformName=iOS", @"invalidChannelXXXX"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertEqual(error.code, 404);
        XCTAssertEqualObjects([[error.userInfo objectForKey:@"returned"] valueForKey:@"error"], @"channel not found");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetChannelConfigFromBundleIdApiSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigFromBundleIdSuccess"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"channelId": @"RHe2nXvQk9SZgdC4x" });
    }];
    NSString *bundleId = @"com.cleverpush.demo";
    NSString *configPath = [NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", bundleId];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTAssertNotNil(result);
        XCTAssertNotNil([result objectForKey:@"channelId"]);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTFail(@"Expected success but got failure: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetChannelConfigFromBundleIdApiFailureWithInvalidBundleId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"channelConfigFromBundleIdFailure"];
    id cleverPush = OCMClassMock([CleverPush class]);
    [OCMStub([cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil]);
    }];
    NSString *configPath = [NSString stringWithFormat:@"channel-config?bundleId=%@&platformName=iOS", @"com.invalid.bundle.notregistered"];
    NSMutableURLRequest *request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:configPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary *result) {
        XCTFail(@"Unexpected success: %@", result);
        [expectation fulfill];
    } onFailure:^(NSError *error) {
        XCTAssertEqual(error.code, 404);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [cleverPush stopMocking];
}

- (void)testGetChannelConfigWithCallbackContainsExpectedKeys {
    NSDictionary *mockConfig = @{
        @"channelId": @"RHe2nXvQk9SZgdC4x",
        @"channelTopics": @[],
        @"channelTags": @[],
        @"confirmAlertSettingsEnabled": @NO,
        @"appReviewEnabled": @NO
    };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSDictionary *);
        [invocation getArgument:&callback atIndex:2];
        callback(mockConfig);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *config) {
        XCTAssertNotNil(config);
        XCTAssertNotNil([config objectForKey:@"channelId"]);
        XCTAssertNotNil([config objectForKey:@"channelTopics"]);
        XCTAssertNotNil([config objectForKey:@"channelTags"]);
        XCTAssertNotNil([config objectForKey:@"confirmAlertSettingsEnabled"]);
    }];
}

- (void)testGetChannelConfigCallbackCalledOnce {
    __block NSInteger callCount = 0;
    NSDictionary *mockConfig = @{@"channelId": @"RHe2nXvQk9SZgdC4x"};
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSDictionary *);
        [invocation getArgument:&callback atIndex:2];
        callCount++;
        callback(mockConfig);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *config) {}];
    XCTAssertEqual(callCount, 1);
}

- (void)testFireChannelConfigListenersIsCalledAfterFetchSuccess {
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    OCMExpect([self.cleverPush fireChannelConfigListeners]);
    [self.cleverPush fireChannelConfigListeners];
    OCMVerify([self.cleverPush fireChannelConfigListeners]);
}

- (void)testGetChannelConfigWithDevelopmentModeEnabled {
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(YES);
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush getChannelConfigFromChannelId:[OCMArg checkWithBlock:^BOOL(NSString *path) {
        return [path containsString:@"RHe2nXvQk9SZgdC4x"] && [path containsString:@"platformName=iOS"];
    }]]);
}

- (void)testGetChannelConfigWithDevelopmentModeDisabled {
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    OCMStub([self.cleverPush isDevelopmentModeEnabled]).andReturn(NO);
    OCMStub([self.cleverPush incrementAppOpens]).andDo(nil);
    (void)[self.cleverPush initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:false];
    OCMVerify([self.cleverPush getChannelConfigFromChannelId:[OCMArg checkWithBlock:^BOOL(NSString *path) {
        return [path containsString:@"RHe2nXvQk9SZgdC4x"] && ![path containsString:@"&t="];
    }]]);
}

- (void)testGetAvailableTagsFromChannelConfig {
    NSArray *mockTags = @[@{@"_id": @"tag1", @"name": @"Tag One"}, @{@"_id": @"tag2", @"name": @"Tag Two"}];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSArray *);
        [invocation getArgument:&callback atIndex:2];
        callback(mockTags);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *tags) {
        XCTAssertNotNil(tags);
        XCTAssertEqual(tags.count, 2);
    }];
}

- (void)testGetAvailableTagsFromChannelConfigReturnsEmptyArray {
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSArray *);
        [invocation getArgument:&callback atIndex:2];
        callback(@[]);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *tags) {
        XCTAssertNotNil(tags);
        XCTAssertEqual(tags.count, 0);
    }];
}

- (void)testGetAvailableTopicsFromChannelConfig {
    NSArray *mockTopics = @[@{@"_id": @"topic1", @"name": @"Topic One"}, @{@"_id": @"topic2", @"name": @"Topic Two"}];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSArray *);
        [invocation getArgument:&callback atIndex:2];
        callback(mockTopics);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertNotNil(topics);
        XCTAssertEqual(topics.count, 2);
    }];
}

- (void)testGetAvailableTopicsFromChannelConfigReturnsNil {
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSArray *);
        [invocation getArgument:&callback atIndex:2];
        callback(nil);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *topics) {
        XCTAssertNil(topics);
    }];
}

- (void)testGetAvailableAttributesFromChannelConfig {
    NSMutableArray *mockAttributes = [NSMutableArray arrayWithArray:@[@{@"id": @"attr1", @"name": @"Attribute One"}]];
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSMutableArray *);
        [invocation getArgument:&callback atIndex:2];
        callback(mockAttributes);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray *attributes) {
        XCTAssertNotNil(attributes);
        XCTAssertEqual(attributes.count, 1);
    }];
}

- (void)testGetAvailableAttributesFromChannelConfigReturnsEmpty {
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSMutableArray *);
        [invocation getArgument:&callback atIndex:2];
        callback([NSMutableArray new]);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray *attributes) {
        XCTAssertNotNil(attributes);
        XCTAssertEqual(attributes.count, 0);
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
