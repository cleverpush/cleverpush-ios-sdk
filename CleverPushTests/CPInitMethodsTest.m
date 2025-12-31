@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"

@interface CleverPush (CPInitMethodsTest_Private)
+ (CleverPushInstance*)CPSharedInstance;
@end

@interface CleverPushInstance (CPInitMethodsTest_Private)
- (void)initWithChannelId;
- (void)handleInitialization:(BOOL)success error:(NSString* _Nullable)error;
@end

@interface CPInitMethodsTest : XCTestCase
@end

@implementation CPInitMethodsTest

static NSString * const kCPSuccessChannelId = @"RHe2nXvQk9SZgdC4x";
static NSString * const kCPFailureChannelId = @"__invalid_channel_id__";

#pragma mark - CleverPush (class wrappers) forwarding tests

- (void)testCleverPushInitWithLaunchOptionsChannelIdForwardsToInstanceWithDefaults {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    id cleverPushClassMock = OCMClassMock([CleverPush class]);
    OCMStub([cleverPushClassMock CPSharedInstance]).andReturn(instanceMock);

    NSDictionary *launchOptions = @{ @"k": @"v" };

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES]);

    (void)[CleverPush initWithLaunchOptions:launchOptions channelId:@"cid"];
    OCMVerifyAll(instanceMock);
}

- (void)testCleverPushInitWithLaunchOptionsOpenedAutoRegisterFalseForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    id cleverPushClassMock = OCMClassMock([CleverPush class]);
    OCMStub([cleverPushClassMock CPSharedInstance]).andReturn(instanceMock);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationOpened:opened handleSubscribed:NULL autoRegister:NO]);

    (void)[CleverPush initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationOpened:opened autoRegister:NO];
    OCMVerifyAll(instanceMock);
}

- (void)testCleverPushInitWithLaunchOptionsReceivedOpenedForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    
    id cleverPushClassMock = OCMClassMock([CleverPush class]);
    OCMStub([cleverPushClassMock CPSharedInstance]).andReturn(instanceMock);
    
    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationReceivedBlock received = ^(CPNotificationReceivedResult * _Nullable result) {};
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};
    
    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:NULL autoRegister:YES]);

    (void)[CleverPush initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:received handleNotificationOpened:opened];
    OCMVerifyAll(instanceMock);
}

- (void)testCleverPushInitWithLaunchOptionsSubscribedForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    id cleverPushClassMock = OCMClassMock([CleverPush class]);
    OCMStub([cleverPushClassMock CPSharedInstance]).andReturn(instanceMock);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationOpened:NULL handleSubscribed:subscribed autoRegister:YES]);

    (void)[CleverPush initWithLaunchOptions:launchOptions channelId:@"cid" handleSubscribed:subscribed];
    OCMVerifyAll(instanceMock);
}

- (void)testCleverPushInitWithLaunchOptionsHandleInitializedForwardsToInstanceCoreInitializer {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    id cleverPushClassMock = OCMClassMock([CleverPush class]);
    OCMStub([cleverPushClassMock CPSharedInstance]).andReturn(instanceMock);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:initialized]);

    (void)[CleverPush initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:initialized];
    OCMVerifyAll(instanceMock);
}

#pragma mark - CleverPushInstance overload forwarding tests

- (void)testInstanceInitWithLaunchOptionsChannelIdForwardsToCoreInitializerWithDefaults {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions channelId:@"cid"];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithLaunchOptionsOpenedForwardsToCoreInitializer {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:opened handleSubscribed:NULL autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationOpened:opened];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithLaunchOptionsReceivedOpenedAutoRegisterFalseForwardsToCoreInitializer {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationReceivedBlock received = ^(CPNotificationReceivedResult * _Nullable result) {};
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:NULL autoRegister:NO handleInitialized:NULL]);
    
    (void)[instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:received handleNotificationOpened:opened autoRegister:NO];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithLaunchOptionsSubscribedForwardsToCoreInitializer {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:subscribed autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleSubscribed:subscribed];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithLaunchOptionsHandleInitializedForwardsToCoreInitializer {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:initialized]);

    (void)[instanceMock initWithLaunchOptions:launchOptions channelId:@"cid" handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:initialized];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithLaunchOptions_AllOtherOverloadsForwardToCoreInitializer_ValidAndInvalidChannelId {
    NSDictionary *launchOptions = @{ @"k": @"v" };
    NSString *validCid = @"cid";
    NSString *invalidCid = @"__invalid__";
    
    CPHandleNotificationReceivedBlock received = ^(CPNotificationReceivedResult * _Nullable result) {};
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};
    CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};
    
    
    void (^assertCoreCall)(NSString *cid, BOOL autoRegister) = ^(NSString *cid, BOOL autoRegister) {
        CleverPushInstance *instance = [CleverPushInstance new];
        id m = OCMPartialMock(instance);
        OCMExpect([m initWithLaunchOptions:launchOptions channelId:cid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:autoRegister handleInitialized:NULL]).andReturn(m);
        
        (void)[m initWithLaunchOptions:launchOptions channelId:cid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:autoRegister];
        OCMVerifyAll(m);
    };
    
    assertCoreCall(validCid, YES);
    assertCoreCall(invalidCid, YES);
    assertCoreCall(validCid, NO);
    assertCoreCall(invalidCid, NO);
}

- (void)testInstanceInitWithConnectionOptions_AllOverloadsForwardToCoreInitializer_ValidAndInvalidChannelId {
    if (@available(iOS 13.0, *)) {
        NSString *validCid = @"cid";
        NSString *invalidCid = @"__invalid__";
        
        CPHandleNotificationReceivedBlock received = ^(CPNotificationReceivedResult * _Nullable result) {};
        CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};
        CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};
        
        void (^assertCoreCall)(NSString *cid, BOOL autoRegister) = ^(NSString *cid, BOOL autoRegister) {
            CleverPushInstance *instance = [CleverPushInstance new];
            id m = OCMPartialMock(instance);
            
            OCMExpect([m initWithLaunchOptions:[OCMArg any] channelId:cid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:autoRegister handleInitialized:NULL]).andReturn(m);
            
            (void)[m initWithConnectionOptions:nil channelId:cid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:autoRegister];
            OCMVerifyAll(m);
        };
        
        assertCoreCall(validCid, YES);
        assertCoreCall(invalidCid, YES);
        assertCoreCall(validCid, NO);
        assertCoreCall(invalidCid, NO);
        
        
        {
            CleverPushInstance *instance = [CleverPushInstance new];
            id m = OCMPartialMock(instance);
            CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
                (void)success;
                (void)failureMessage;
            };
            OCMExpect([m initWithLaunchOptions:[OCMArg any] channelId:validCid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:YES handleInitialized:initialized]).andReturn(m);
            
            (void)[m initWithConnectionOptions:nil channelId:validCid handleNotificationReceived:received handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:YES handleInitialized:initialized];
            OCMVerifyAll(m);
        }
    }
}

#pragma mark - Initialization callback success/failure tests (deterministic)

- (void)testInitializedCallbackSuccessWhenChannelConfigFromChannelIdSucceeds {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    XCTestExpectation *expectation = [self expectationWithDescription:@"initialized success"];

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    __block BOOL callbackCalled = NO;
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        callbackCalled = YES;
        XCTAssertTrue(success);
        XCTAssertNil(failureMessage);
        [expectation fulfill];
    };

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];

    [instance handleInitialization:YES error:nil];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(callbackCalled);
}

- (void)testInitializedCallbackFailureWhenChannelConfigFromBundleIdFails {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    XCTestExpectation *expectation = [self expectationWithDescription:@"initialized failure"];
    NSString *expectedFailureMessage = @"Failed to fetch Channel Config via Bundle Identifier. (test)";

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    __block BOOL callbackCalled = NO;
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        callbackCalled = YES;
        XCTAssertFalse(success);
        XCTAssertEqualObjects(failureMessage, expectedFailureMessage);
        [expectation fulfill];
    };

    (void)[instanceMock initWithLaunchOptions:nil channelId:nil handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    
    [instance handleInitialization:NO error:expectedFailureMessage];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(callbackCalled);
}

- (void)testInitializedCallbackOnlyFiresOnce {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    __block NSInteger callCount = 0;
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        (void)success;
        (void)failureMessage;
        callCount += 1;
    };
    
    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    
    [instance handleInitialization:YES error:nil];
    [instance handleInitialization:NO error:@"should be ignored"];

    XCTAssertEqual(callCount, 1);
}

#pragma mark - Init success/failure integration tests (launchOptions + connectionOptions)

- (void)testInitWithLaunchOptions_HandleInitialized_Success {
    XCTestExpectation *exp = [self expectationWithDescription:@"init success callback"];
    
    [CleverPush initWithLaunchOptions:nil channelId:kCPSuccessChannelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertTrue(success);
        XCTAssertNil(failureMessage);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

- (void)testInitWithLaunchOptions_HandleInitialized_Failure {
    XCTestExpectation *exp = [self expectationWithDescription:@"init failure callback"];
    
    [CleverPush initWithLaunchOptions:nil channelId:kCPFailureChannelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertFalse(success);
        XCTAssertNotNil(failureMessage);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

- (void)testInitWithConnectionOptions_HandleInitialized_Success {
    if (@available(iOS 13.0, *)) {
        XCTestExpectation *exp = [self expectationWithDescription:@"init success callback (scene)"];
        
        [CleverPush initWithConnectionOptions:nil channelId:kCPSuccessChannelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:^(BOOL success, NSString * _Nullable failureMessage) {
            XCTAssertTrue(success);
            XCTAssertNil(failureMessage);
            [exp fulfill];
        }];

        [self waitForExpectationsWithTimeout:15.0 handler:nil];
    } else {
        XCTSkip(@"Requires iOS 13+");
    }
}

- (void)testInitWithConnectionOptions_HandleInitialized_Failure {
    if (@available(iOS 13.0, *)) {
        XCTestExpectation *exp = [self expectationWithDescription:@"init failure callback (scene)"];

        [CleverPush initWithConnectionOptions:nil channelId:kCPFailureChannelId handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:NO handleInitialized:^(BOOL success, NSString * _Nullable failureMessage) {
            XCTAssertFalse(success);
            XCTAssertNotNil(failureMessage);
            [exp fulfill];
        }];

        [self waitForExpectationsWithTimeout:15.0 handler:nil];
    } else {
        XCTSkip(@"Requires iOS 13+");
    }
}

@end
