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
#import "CleverPushUserDefaults.h"

@interface CPAttributesTests : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) NSUserDefaults *userDefault;

@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic) id cleverPush;
@property (nonatomic) id defaults;

@end

@implementation CPAttributesTests

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.userDefault = [[NSUserDefaults alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
    self.defaults = OCMPartialMock(self.userDefault);
}
- (void)testGetAvailableAttributes {
    NSMutableDictionary *attr = [@{ @"key": @"value" } mutableCopy];
    NSMutableArray *finalResponseObject = [@[attr] mutableCopy];
    
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSMutableArray * _Nullable myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(finalResponseObject);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray * _Nullable configAttributes) {
        XCTAssertEqual(configAttributes, finalResponseObject);
    }];
    OCMVerify([self.cleverPush getAvailableAttributes:[OCMArg any]]);
}

- (void)testGetAvailableAttributesFromConfigWhenChannelConfigIsNull {
    NSMutableArray *finalResponseObject = [NSMutableArray new];
    
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSMutableArray * _Nullable myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(finalResponseObject);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray * _Nullable configAttributes) {
        XCTAssertEqual(configAttributes, finalResponseObject);
    }];
    OCMVerify([self.cleverPush getAvailableAttributes:[OCMArg any]]);
}

- (void)testGetAvailableAttributesFromConfigWhenChannelConfigDoNotHaveCustomAttributes {
    NSDictionary *finalResponseObject = [[NSDictionary alloc]init];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(finalResponseObject);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *ChannelConfig) {
        NSMutableArray *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
        XCTAssert(mockResult.count == 0);
    }];
    
}

- (void)testGetAvailableAttributesFromConfigWhenChannelConfigHaveZeroCustomAttributes {
    NSArray *customAttributes = [[NSArray alloc]init];
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:customAttributes,@"customAttributes", nil];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *ChannelConfig) {
        NSMutableArray *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
        XCTAssert(mockResult.count == 0);
    }];
}

- (void)testGetAvailableAttributesFromConfigWhenThereIsException {
    NSDictionary *responseObject = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"customAttributes", nil];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *ChannelConfig) {
        NSMutableArray *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
        XCTAssert(mockResult.count == 0);
    }];
}

- (void)testGetAvailableAttributesFromConfigWhenChannelConfigHaveNonZeroCustomAttributes {
    NSMutableDictionary *objAttribute = [[NSMutableDictionary alloc] init];
    [objAttribute setObject:@"attribute_name" forKey:@"name"];
    [objAttribute setObject:@"attribute_id" forKey:@"id"];
    NSArray *customAttributes = [[NSArray alloc]initWithObjects:objAttribute,  nil];
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:customAttributes,@"customAttributes", nil];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *ChannelConfig) {
        NSMutableArray *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        for (id item in mockResult) {
            [attributes addObject:item];
        }
        XCTAssert(mockResult.count != 0);
        XCTAssertEqual(attributes[0][@"name"], @"attribute_name");
        XCTAssertEqual(attributes[0][@"id"], @"attribute_id");
    }];
}

- (void)testGetSubscriptionAttributeWhenThereIsAttributeValueForAttributeId {
    NSMutableDictionary *objAttribute = [[NSMutableDictionary alloc] init];
    [objAttribute setObject:@"attribute_name" forKey:@"name"];
    [objAttribute setObject:@"attribute_id" forKey:@"id"];
    OCMStub([self.cleverPush getSubscriptionAttributes]).andReturn(objAttribute);
    NSString *expectedAttribute = [self.cleverPush getSubscriptionAttribute:@"name"];
    XCTAssertEqual(expectedAttribute, @"attribute_name");
}

- (void)testGetSubscriptionAttributeWhenThereIsNoAttributeValueForAttributeId {
    NSMutableDictionary *objAttribute = [[NSMutableDictionary alloc] init];
    [objAttribute setObject:@"attribute_name" forKey:@"name"];
    [objAttribute setObject:@"attribute_id" forKey:@"id"];
    OCMStub([self.cleverPush getSubscriptionAttributes]).andReturn(objAttribute);
    NSString *expectedAttribute = [self.cleverPush getSubscriptionAttribute:@"attribute_name"];
    XCTAssertNil(expectedAttribute);
}

- (void)testGetSubscriptionAttributeWhenThereIsNoUserDefaultValues {
    OCMStub([self.defaults valueForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]).andReturn(nil);
    XCTAssertEqual([[self.cleverPush getSubscriptionAttributes] count], 0);
}

- (void)testGetSubscriptionAttributeWhenThereIsZeroSubscriptionAttributes {
    NSMutableDictionary *objAttribute = [[NSMutableDictionary alloc] init];
    OCMStub([self.defaults valueForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY]).andReturn(objAttribute);
    XCTAssertEqual([[self.cleverPush getSubscriptionAttributes] count], 0);
}

- (void)testGetSubscriptionAttributeWhenThereIsSubscriptionAttributes {
    NSMutableDictionary *objAttribute = [[NSMutableDictionary alloc] init];
    [objAttribute setObject:@"attribute_name" forKey:@"name"];
    [objAttribute setObject:@"attribute_id" forKey:@"id"];
    OCMStub([self.cleverPush getSubscriptionAttributes]).andReturn(objAttribute);
    NSDictionary *mockResult = [self.cleverPush getSubscriptionAttributes];
    XCTAssert(mockResult.count != 0);
    XCTAssertEqual([mockResult valueForKey:@"name"], @"attribute_name");
    XCTAssertEqual([mockResult valueForKey:@"id"], @"attribute_id");
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - setSubscriptionAttribute (value + callback)

- (void)testSetSubscriptionAttributeValueCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush setSubscriptionAttribute:@"attr_id" value:@"attr_value" callback:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

- (void)testSetSubscriptionAttributeValueCallbackWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    XCTAssertNoThrow([self.cleverPush setSubscriptionAttribute:@"attr_id" value:@"attr_value" callback:nil]);
}

#pragma mark - setSubscriptionAttribute (arrayValue + callback)

- (void)testSetSubscriptionAttributeArrayValueCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush setSubscriptionAttribute:@"attr_id" arrayValue:@[ @"v1", @"v2" ] callback:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - setSubscriptionAttribute (arrayValue + onSuccess/onFailure)

- (void)testSetSubscriptionAttributeArrayValueOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"set array attribute onSuccess"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush setSubscriptionAttribute:[OCMArg any] arrayValue:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:4];
        if (success) success(@{});
    }];

    [self.cleverPush setSubscriptionAttribute:@"attr_id" arrayValue:@[ @"v1" ] onSuccess:^(NSDictionary * _Nullable result) {
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSetSubscriptionAttributeArrayValueOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"set array attribute onFailure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush setSubscriptionAttribute:[OCMArg any] arrayValue:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:5];
        if (failure) failure(err);
    }];

    [self.cleverPush setSubscriptionAttribute:@"attr_id" arrayValue:@[ @"v1" ] onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - setSubscriptionAttributes (bulk dictionary)

- (void)testSetSubscriptionAttributesBulkCallsWaitForTrackingConsentForEachKey {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSDictionary *attrs = @{ @"key1": @"val1", @"key2": @"val2" };
    XCTAssertNoThrow([self.cleverPush setSubscriptionAttributes:attrs]);
}

- (void)testSetSubscriptionAttributesBulkWithEmptyDictionaryDoesNotCrash {
    NSDictionary *emptyAttrs = @{};
    XCTAssertNoThrow([self.cleverPush setSubscriptionAttributes:emptyAttrs]);
}

- (void)testSetSubscriptionAttributesBulkWithNilDictionaryDoesNotCrash {
    XCTAssertNoThrow([self.cleverPush setSubscriptionAttributes:nil]);
}

#pragma mark - removeSubscriptionAttribute (no callback)

- (void)testRemoveSubscriptionAttributeNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush removeSubscriptionAttribute:@"attr_id"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - removeSubscriptionAttribute (callback + onFailure)
- (void)testRemoveSubscriptionAttributeSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove attribute callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush removeSubscriptionAttributeFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *attrId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&attrId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(attrId);
    }];

    [self.cleverPush removeSubscriptionAttribute:@"attr_id" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"attr_id");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionAttributeFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove attribute failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil];
    [OCMStub([self.cleverPush removeSubscriptionAttributeFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush removeSubscriptionAttribute:@"attr_id" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionAttributeSuccessWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush removeSubscriptionAttributeFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"attr_id");
    }];

    XCTAssertNoThrow([self.cleverPush removeSubscriptionAttribute:@"attr_id" callback:nil onFailure:nil]);
}

#pragma mark - removeSubscriptionAttributes (bulk)

- (void)testRemoveSubscriptionAttributesBulkCallsRemoveForEachAttributeId {
    [OCMStub([self.cleverPush removeSubscriptionAttribute:[OCMArg any]]) andDo:^(NSInvocation *invocation) {}];

    [self.cleverPush removeSubscriptionAttributes:@[ @"a1", @"a2", @"a3" ]];

    OCMVerify([self.cleverPush removeSubscriptionAttribute:@"a1"]);
    OCMVerify([self.cleverPush removeSubscriptionAttribute:@"a2"]);
    OCMVerify([self.cleverPush removeSubscriptionAttribute:@"a3"]);
}

- (void)testRemoveSubscriptionAttributesBulkWithEmptyArrayDoesNotCrash {
    XCTAssertNoThrow([self.cleverPush removeSubscriptionAttributes:@[]]);
}

#pragma mark - removeSubscriptionAttribute - tracking consent blocked

- (void)testRemoveSubscriptionAttributeDoesNotCallApiWhenTrackingConsentNotGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // consent withheld — do not invoke handler
    }];

    [[self.cleverPush reject] removeSubscriptionAttributeFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]];

    [self.cleverPush removeSubscriptionAttribute:@"attr_id" callback:nil onFailure:nil];

    OCMVerifyAll(self.cleverPush);
}

#pragma mark - pushSubscriptionAttributeValue

- (void)testPushSubscriptionAttributeValueNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush pushSubscriptionAttributeValue:@"attr_id" value:@"v1"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

- (void)testPushSubscriptionAttributeValueOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"push attribute value onSuccess"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush pushSubscriptionAttributeValue:[OCMArg any] value:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:4];
        if (success) success(@{});
    }];

    [self.cleverPush pushSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:^(NSDictionary * _Nullable result) {
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPushSubscriptionAttributeValueOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"push attribute value onFailure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush pushSubscriptionAttributeValue:[OCMArg any] value:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:5];
        if (failure) failure(err);
    }];

    [self.cleverPush pushSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPushSubscriptionAttributeValueTrackingConsentBlockedDoesNotProceed {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // consent withheld
    }];

    [self.cleverPush pushSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:nil onFailure:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - pullSubscriptionAttributeValue

- (void)testPullSubscriptionAttributeValueNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush pullSubscriptionAttributeValue:@"attr_id" value:@"v1"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

- (void)testPullSubscriptionAttributeValueOnSuccessCallsSuccessBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"pull attribute value onSuccess"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush pullSubscriptionAttributeValue:[OCMArg any] value:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:4];
        if (success) success(@{});
    }];

    [self.cleverPush pullSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:^(NSDictionary * _Nullable result) {
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPullSubscriptionAttributeValueOnFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"pull attribute value onFailure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:503 userInfo:nil];
    [OCMStub([self.cleverPush pullSubscriptionAttributeValue:[OCMArg any] value:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:5];
        if (failure) failure(err);
    }];

    [self.cleverPush pullSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:^(NSDictionary * _Nullable result) {
        XCTFail(@"Unexpected success");
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 503);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPullSubscriptionAttributeValueTrackingConsentBlockedDoesNotProceed {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // consent withheld
    }];

    [self.cleverPush pullSubscriptionAttributeValue:@"attr_id" value:@"v1" onSuccess:nil onFailure:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - hasSubscriptionAttributeValue

- (void)testHasSubscriptionAttributeValueReturnsTrueWhenValuePresent {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[@"colors"] = @[ @"red", @"blue" ];
    [[NSUserDefaults standardUserDefaults] setObject:attrs forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertTrue([self.testableInstance hasSubscriptionAttributeValue:@"colors" value:@"red"]);
}

- (void)testHasSubscriptionAttributeValueReturnsFalseWhenValueNotPresent {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[@"colors"] = @[ @"red" ];
    [[NSUserDefaults standardUserDefaults] setObject:attrs forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionAttributeValue:@"colors" value:@"green"]);
}

- (void)testHasSubscriptionAttributeValueReturnsFalseWhenAttributeKeyNotPresent {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[@"colors"] = @[ @"red" ];
    [[NSUserDefaults standardUserDefaults] setObject:attrs forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionAttributeValue:@"sizes" value:@"small"]);
}

- (void)testHasSubscriptionAttributeValueReturnsFalseWhenNoAttributesStored {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionAttributeValue:@"colors" value:@"red"]);
}

#pragma mark - getSubscriptionAttributes

- (void)testGetSubscriptionAttributesReturnsStoredDictionary {
    NSDictionary *stored = @{ @"name": @"John", @"plan": @"premium" };
    [[NSUserDefaults standardUserDefaults] setObject:stored forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSDictionary *result = [self.testableInstance getSubscriptionAttributes];
    XCTAssertEqualObjects(result[@"name"], @"John");
    XCTAssertEqualObjects(result[@"plan"], @"premium");
}

- (void)testGetSubscriptionAttributesReturnsEmptyDictionaryWhenNothingStored {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSDictionary *result = [self.testableInstance getSubscriptionAttributes];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 0);
}

#pragma mark - getSubscriptionAttribute

- (void)testGetSubscriptionAttributeReturnsCorrectValueForKey {
    NSDictionary *stored = @{ @"loyalty_id": @"ABC123" };
    [[NSUserDefaults standardUserDefaults] setObject:stored forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSObject *result = [self.testableInstance getSubscriptionAttribute:@"loyalty_id"];
    XCTAssertEqualObjects(result, @"ABC123");
}

- (void)testGetSubscriptionAttributeReturnsNilForMissingKey {
    NSDictionary *stored = @{ @"loyalty_id": @"ABC123" };
    [[NSUserDefaults standardUserDefaults] setObject:stored forKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertNil([self.testableInstance getSubscriptionAttribute:@"nonexistent_key"]);
}

- (void)testGetSubscriptionAttributeReturnsNilWhenStorageEmpty {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertNil([self.testableInstance getSubscriptionAttribute:@"any_key"]);
}

#pragma mark - getAvailableAttributes (callback variant)

- (void)testGetAvailableAttributesCallbackWithNilConfigReturnsEmptyArray {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    [self.cleverPush getAvailableAttributes:^(NSMutableArray * _Nullable result) {
        XCTAssertNotNil(result);
        XCTAssertEqual(result.count, 0);
    }];
}

- (void)testGetAvailableAttributesCallbackWithNonEmptyAttributesReturnsAttributes {
    NSArray *customAttributes = @[ @{ @"id": @"a1", @"name": @"Attr 1" } ];
    NSDictionary *config = @{ @"customAttributes": customAttributes };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(config);
    }];

    [self.cleverPush getAvailableAttributes:^(NSMutableArray * _Nullable result) {
        XCTAssertEqual(result.count, 1);
        XCTAssertEqualObjects(result[0][@"id"], @"a1");
    }];
}

@end
