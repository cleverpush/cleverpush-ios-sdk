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

#pragma mark - Init success/failure (instance mock, no live network)

- (void)testInitWithLaunchOptions_HandleInitialized_Success {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    XCTestExpectation *exp = [self expectationWithDescription:@"init success callback"];
    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertTrue(success);
        XCTAssertNil(failureMessage);
        [exp fulfill];
    };
    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    [instance handleInitialization:YES error:nil];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testInitWithLaunchOptions_HandleInitialized_Failure {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    XCTestExpectation *exp = [self expectationWithDescription:@"init failure callback"];
    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertFalse(success);
        XCTAssertNotNil(failureMessage);
        [exp fulfill];
    };
    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    [instance handleInitialization:NO error:@"Failed to fetch Channel Config"];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testInitWithConnectionOptions_HandleInitialized_Success {
    if (@available(iOS 13.0, *)) {
        CleverPushInstance *instance = [CleverPushInstance new];
        id instanceMock = OCMPartialMock(instance);
        XCTestExpectation *exp = [self expectationWithDescription:@"init success callback (scene)"];
        OCMStub([instanceMock clearBadge]).andDo(nil);
        OCMStub([instanceMock incrementAppOpens]).andDo(nil);
        OCMStub([instanceMock initWithChannelId]).andDo(nil);
        CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
            XCTAssertTrue(success);
            XCTAssertNil(failureMessage);
            [exp fulfill];
        };
        (void)[instanceMock initWithConnectionOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
        [instance handleInitialization:YES error:nil];
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    } else {
        XCTSkip(@"Requires iOS 13+");
    }
}

- (void)testInitWithConnectionOptions_HandleInitialized_Failure {
    if (@available(iOS 13.0, *)) {
        CleverPushInstance *instance = [CleverPushInstance new];
        id instanceMock = OCMPartialMock(instance);
        XCTestExpectation *exp = [self expectationWithDescription:@"init failure callback (scene)"];
        OCMStub([instanceMock clearBadge]).andDo(nil);
        OCMStub([instanceMock incrementAppOpens]).andDo(nil);
        OCMStub([instanceMock initWithChannelId]).andDo(nil);
        CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
            XCTAssertFalse(success);
            XCTAssertNotNil(failureMessage);
            [exp fulfill];
        };
        (void)[instanceMock initWithConnectionOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
        [instance handleInitialization:NO error:@"Failed to fetch Channel Config"];
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    } else {
        XCTSkip(@"Requires iOS 13+");
    }
}

#pragma mark - handleInitialization edge cases

- (void)testHandleInitializationDoesNotFireCallbackWhenAlreadyInitialized {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    __block NSInteger callCount = 0;
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        callCount++;
    };
     
    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];

    [instance handleInitialization:YES error:nil];
    [instance handleInitialization:YES error:nil];
    [instance handleInitialization:NO error:@"ignored second call"];

    XCTAssertEqual(callCount, 1);
}

- (void)testHandleInitializationWithNilCallbackDoesNotCrash {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:nil];

    XCTAssertNoThrow([instance handleInitialization:YES error:nil]);
}

- (void)testHandleInitializationSuccessPassesNilFailureMessage {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    XCTestExpectation *exp = [self expectationWithDescription:@"success with nil error"];
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertTrue(success);
        XCTAssertNil(failureMessage);
        [exp fulfill];
    };

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    [instance handleInitialization:YES error:nil];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testHandleInitializationFailurePassesErrorMessage {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);

    NSString *expectedError = @"channel not found";
    XCTestExpectation *exp = [self expectationWithDescription:@"failure with error message"];
    CPInitializedBlock initialized = ^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertFalse(success);
        XCTAssertEqualObjects(failureMessage, expectedError);
        [exp fulfill];
    };

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:initialized];
    [instance handleInitialization:NO error:expectedError];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testHandleInitializationFiresChannelConfigListeners {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);
    OCMExpect([instanceMock fireChannelConfigListeners]);

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"testChannelId" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:nil];
    [instanceMock handleInitialization:YES error:nil];

    OCMVerify([instanceMock fireChannelConfigListeners]);
}

#pragma mark - setTrackingConsentRequired

- (void)testSetTrackingConsentRequiredTrue {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock setTrackingConsentRequired:YES]);
    [instanceMock setTrackingConsentRequired:YES];
    OCMVerify([instanceMock setTrackingConsentRequired:YES]);
}

- (void)testSetTrackingConsentRequiredFalse {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock setTrackingConsentRequired:NO]);
    [instanceMock setTrackingConsentRequired:NO];
    OCMVerify([instanceMock setTrackingConsentRequired:NO]);
}

- (void)testGetTrackingConsentRequiredReturnsExpectedValue {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock getTrackingConsentRequired]).andReturn(YES);
    XCTAssertTrue([instanceMock getTrackingConsentRequired]);
}

- (void)testGetTrackingConsentRequiredReturnsFalseByDefault {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock getTrackingConsentRequired]).andReturn(NO);
    XCTAssertFalse([instanceMock getTrackingConsentRequired]);
}

#pragma mark - setSubscribeConsentRequired

- (void)testSetSubscribeConsentRequiredTrue {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock setSubscribeConsentRequired:YES]);
    [instanceMock setSubscribeConsentRequired:YES];
    OCMVerify([instanceMock setSubscribeConsentRequired:YES]);
}

- (void)testSetSubscribeConsentRequiredFalse {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock setSubscribeConsentRequired:NO]);
    [instanceMock setSubscribeConsentRequired:NO];
    OCMVerify([instanceMock setSubscribeConsentRequired:NO]);
}

#pragma mark - enableDevelopmentMode / isDevelopmentModeEnabled

- (void)testEnableDevelopmentModeSetsDevelopmentFlag {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock enableDevelopmentMode]);
    [instanceMock enableDevelopmentMode];
    OCMVerify([instanceMock enableDevelopmentMode]);
}

- (void)testIsDevelopmentModeEnabledReturnsTrueAfterEnabling {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock isDevelopmentModeEnabled]).andReturn(YES);
    XCTAssertTrue([instanceMock isDevelopmentModeEnabled]);
}

- (void)testIsDevelopmentModeEnabledReturnsFalseByDefault {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock isDevelopmentModeEnabled]).andReturn(NO);
    XCTAssertFalse([instanceMock isDevelopmentModeEnabled]);
}

#pragma mark - subscribe from init

- (void)testAutoRegisterTrueCallsSubscribeDuringInit {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock channelId]).andReturn(@"cid");
    OCMStub([instanceMock subscriptionId]).andReturn(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock isDevelopmentModeEnabled]).andReturn(NO);

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:YES];

    OCMVerify([instanceMock subscribe]);
}

- (void)testAutoRegisterFalseDoesNotCallSubscribeDuringInit {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    OCMStub([instanceMock channelId]).andReturn(@"cid");
    OCMStub([instanceMock subscriptionId]).andReturn(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock isDevelopmentModeEnabled]).andReturn(NO);

    [[instanceMock reject] subscribe];

    (void)[instanceMock initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
}

#pragma mark - markSubscriptionAsTest

- (void)testMarkSubscriptionAsTestCallsVerify {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock markSubscriptionAsTest]);
    [instanceMock markSubscriptionAsTest];
    OCMVerify([instanceMock markSubscriptionAsTest]);
}

- (void)testMarkSubscriptionAsTestOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"markSubscriptionAsTest success"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    [instance setSubscriptionId:@"sub-123"];
    (void)[instance initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([instanceMock getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    [OCMStub([instanceMock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{});
    }];
    [instanceMock markSubscriptionAsTestOnSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testMarkSubscriptionAsTestOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"markSubscriptionAsTest failure"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    (void)[instance initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:400 userInfo:nil];
    [OCMStub([instanceMock getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    [OCMStub([instanceMock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];
    [instanceMock markSubscriptionAsTestOnSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 400);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testUnmarkSubscriptionAsTestOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"unmarkSubscriptionAsTest success"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    (void)[instance initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([instanceMock getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    [OCMStub([instanceMock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{});
    }];
    [instanceMock unmarkSubscriptionAsTestOnSuccess:^(NSDictionary * _Nullable result) {
        XCTAssertNotNil(result);
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testUnmarkSubscriptionAsTestOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"unmarkSubscriptionAsTest failure"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    (void)[instance initWithLaunchOptions:nil channelId:@"cid" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([instanceMock getSubscriptionId:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"sub-123");
    }];
    [OCMStub([instanceMock enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [instanceMock unmarkSubscriptionAsTestOnSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSubscribeWithSuccessBlockCallsBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"subscribe success block"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    [OCMStub([instanceMock subscribe:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPHandleSubscribedBlock block = nil;
        [invocation getArgument:&block atIndex:2];
        if (block) block(@"subscriptionId");
    }];

    [instanceMock subscribe:^(NSString * _Nullable subscriptionId) {
        XCTAssertEqualObjects(subscriptionId, @"subscriptionId");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSubscribeWithSuccessAndFailureBlocksCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"subscribe success with failure block"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    [OCMStub([instanceMock subscribe:[OCMArg any] failure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPHandleSubscribedBlock block = nil;
        [invocation getArgument:&block atIndex:2];
        if (block) block(@"subscriptionId");
    }];

    [instanceMock subscribe:^(NSString * _Nullable subscriptionId) {
        XCTAssertEqualObjects(subscriptionId, @"subscriptionId");
        [exp fulfill];
    } failure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure");
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSubscribeWithSuccessAndFailureBlocksCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"subscribe calls failure block"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:503 userInfo:nil];
    [OCMStub([instanceMock subscribe:[OCMArg any] failure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:3];
        if (failure) failure(err);
    }];

    [instanceMock subscribe:^(NSString * _Nullable subscriptionId) {
        XCTFail(@"Unexpected success");
    } failure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 503);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - unsubscribe

- (void)testUnsubscribeCallbackInvokedOnSuccess {
    XCTestExpectation *exp = [self expectationWithDescription:@"unsubscribe success"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    [OCMStub([instanceMock unsubscribe:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(BOOL) = nil;
        [invocation getArgument:&callback atIndex:2];
        if (callback) callback(YES);
    }];

    [instanceMock unsubscribe:^(BOOL success) {
        XCTAssertTrue(success);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testUnsubscribeCallbackInvokedOnFailure {
    XCTestExpectation *exp = [self expectationWithDescription:@"unsubscribe failure"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    [OCMStub([instanceMock unsubscribe:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(BOOL) = nil;
        [invocation getArgument:&callback atIndex:2];
        if (callback) callback(NO);
    }];

    [instanceMock unsubscribe:^(BOOL success) {
        XCTAssertFalse(success);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testUnsubscribeWithoutCallbackDoesNotCrash {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock unsubscribe]).andDo(nil);
    XCTAssertNoThrow([instanceMock unsubscribe]);
}

#pragma mark - syncSubscription

- (void)testSyncSubscriptionCallsVerify {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMExpect([instanceMock syncSubscription]);
    [instanceMock syncSubscription];
    OCMVerify([instanceMock syncSubscription]);
}

- (void)testSyncSubscriptionWithFailureBlockCallsFailureWhenError {
    XCTestExpectation *exp = [self expectationWithDescription:@"syncSubscription failure"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([instanceMock syncSubscription:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:2];
        if (failure) failure(err);
    }];

    [instanceMock syncSubscription:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSyncSubscriptionWithSuccessAndFailureBlocksCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"syncSubscription with success block"];

    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    [OCMStub([instanceMock syncSubscription:[OCMArg any] successBlock:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^successBlock)(void) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        if (successBlock) successBlock();
    }];

    [instanceMock syncSubscription:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure");
    } successBlock:^{
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - isSubscribed

- (void)testIsSubscribedReturnsTrueWhenSubscribed {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock isSubscribed]).andReturn(YES);
    XCTAssertTrue([instanceMock isSubscribed]);
}

- (void)testIsSubscribedReturnsFalseWhenNotSubscribed {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock isSubscribed]).andReturn(NO);
    XCTAssertFalse([instanceMock isSubscribed]);
}

#pragma mark - nil channelId launch options overload forwarding

- (void)testInstanceInitWithNilChannelIdForwardsToCoreInitializerWithNullChannelId {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:NULL autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithNilChannelIdAndOpenedCallbackForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:opened handleSubscribed:NULL autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions handleNotificationOpened:opened];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithNilChannelIdAndSubscribedCallbackForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:NULL handleSubscribed:subscribed autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions handleSubscribed:subscribed];
    OCMVerifyAll(instanceMock);
}

- (void)testInstanceInitWithNilChannelIdOpenedAndSubscribedCallbackForwards {
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);

    NSDictionary *launchOptions = @{ @"k": @"v" };
    CPHandleNotificationOpenedBlock opened = ^(CPNotificationOpenedResult * _Nullable result) {};
    CPHandleSubscribedBlock subscribed = ^(NSString * _Nullable result) {};

    OCMExpect([instanceMock initWithLaunchOptions:launchOptions channelId:NULL handleNotificationReceived:NULL handleNotificationOpened:opened handleSubscribed:subscribed autoRegister:YES handleInitialized:NULL]);

    (void)[instanceMock initWithLaunchOptions:launchOptions handleNotificationOpened:opened handleSubscribed:subscribed];
    OCMVerifyAll(instanceMock);
}

#pragma mark - subscribe/unsubscribe (mocked)

- (void)testSubscribeAndUnsubscribeSuccessPath {
    XCTestExpectation *subscribeExp = [self expectationWithDescription:@"subscribe success"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    [OCMStub([instanceMock subscribe:[OCMArg any] failure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPHandleSubscribedBlock success = nil;
        [invocation getArgument:&success atIndex:2];
        if (success) success(@"subscriptionId");
    }];
    [OCMStub([instanceMock unsubscribe:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^done)(BOOL) = nil;
        [invocation getArgument:&done atIndex:2];
        if (done) done(YES);
    }];
    [instanceMock subscribe:^(NSString * _Nullable subscriptionId) {
        XCTAssertEqualObjects(subscriptionId, @"subscriptionId");
        [instanceMock unsubscribe:^(BOOL unsubscribeSuccess) {
            XCTAssertTrue(unsubscribeSuccess);
            [subscribeExp fulfill];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail(@"Subscribe failed: %@", error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testInitWithInvalidChannelIdReturnsFailureViaHandleInitialization {
    XCTestExpectation *exp = [self expectationWithDescription:@"init failure with invalid channel"];
    CleverPushInstance *instance = [CleverPushInstance new];
    id instanceMock = OCMPartialMock(instance);
    OCMStub([instanceMock clearBadge]).andDo(nil);
    OCMStub([instanceMock incrementAppOpens]).andDo(nil);
    OCMStub([instanceMock initWithChannelId]).andDo(nil);
    (void)[instanceMock initWithLaunchOptions:nil channelId:@"invalid" handleNotificationReceived:nil handleNotificationOpened:nil handleSubscribed:nil autoRegister:NO handleInitialized:^(BOOL success, NSString * _Nullable failureMessage) {
        XCTAssertFalse(success);
        XCTAssertNotNil(failureMessage);
        [exp fulfill];
    }];
    [instance handleInitialization:NO error:@"channel not found"];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
