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
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:@"value",@"key", nil];
    NSDictionary *finalResponseObject = responseObject;
    
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(finalResponseObject);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray *configAttributes) {
        XCTAssertEqual(configAttributes, finalResponseObject);
    }];
    OCMVerify([self.cleverPush getAvailableAttributes:[OCMArg any]]);
}

- (void)testGetAvailableAttributesFromConfigWhenChannelConfigIsNull {
    NSDictionary *finalResponseObject = [[NSDictionary alloc]init];
    
    [OCMStub([self.cleverPush getAvailableAttributes:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(finalResponseObject);
    }];
    [self.cleverPush getAvailableAttributes:^(NSMutableArray *configAttributes) {
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
        NSDictionary *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
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
        NSDictionary *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
        XCTAssert(mockResult.count == 0);
    }];
}

- (void)testGetAvailableAttributesFromConfigWhenThereIsException {
    NSDictionary *responseObject = [[NSDictionary alloc]initWithObjectsAndKeys:nil,@"customAttributes", nil];
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(responseObject);
    }];
    [self.cleverPush getChannelConfig:^(NSDictionary *ChannelConfig) {
        NSDictionary *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
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
        NSDictionary *mockResult = [self.cleverPush getAvailableAttributesFromConfig:ChannelConfig];
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

- (void)testSetSubscriptionAttributeSuccess {
    NSString *attributeId = @"attributeId";
    NSString *value = @"attributeValue";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute set successfully"];

    [self.cleverPush setSubscriptionAttribute:attributeId value:value callback:^{
        [expectation fulfill];
    }];

    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testSetSubscriptionAttributeFailure {
    NSString *attributeId = @"attributeId";
    NSString *value = @"attributeValue";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute failed to set"];

    [self.cleverPush setSubscriptionAttribute:attributeId value:value callback:^{
        XCTFail(@"Callback should not be invoked for failure");
    }];

    NSTimeInterval timeout = 10;
       [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
           if (error != nil) {
               NSLog(@"Error: %@", error.localizedDescription);
           }
       }];
}

- (void)testSetSubscriptionAttributeArrayValueWithCallbackSuccess {
    NSString *attributeId = @"attributeId";
    NSArray *value = @[@"value1", @"value2", @"value3"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute set successfully"];

    [self.cleverPush setSubscriptionAttribute:attributeId arrayValue:value callback:^{
        [expectation fulfill];
    }];

    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Expectation failed with error: %@", error.localizedDescription);
        }
    }];
}

- (void)testSetSubscriptionAttributeArrayValueWithCallbackFailure {
    NSString *attributeId = @"attributeId";
    NSArray *value = @[@"value1", @"value2", @"value3"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute failed to set"];

    [self.cleverPush setSubscriptionAttribute:attributeId arrayValue:value callback:^{
        XCTFail(@"Callback should not be invoked for failure");
    }];

    NSTimeInterval timeout = 10;
       [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
           if (error != nil) {
               NSLog(@"Error: %@", error.localizedDescription);
           }
       }];
}

- (void)testPushSubscriptionAttributeValueSuccess {
    NSString *attributeId = @"attributeId";
    NSString *value = @"attributeValue";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute pushed successfully"];

    OCMStub([self.cleverPush waitForTrackingConsent:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(void) = nil;
        [invocation getArgument:&completion atIndex:2];
        if (completion) {
            completion();
        }
    });

    OCMStub([self.cleverPush getSubscriptionId:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSString *) = nil;
        [invocation getArgument:&completion atIndex:2];
        if (completion) {
            completion(@"subscriptionId");
        }
    });

    [self.cleverPush pushSubscriptionAttributeValue:attributeId value:value];

    [expectation fulfill];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPushSubscriptionAttributeValueFailure {
    NSString *attributeId = @"attributeId";
    NSString *value = @"attributeValue";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscription attribute failed to push"];

    OCMStub([self.cleverPush waitForTrackingConsent:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(void) = nil;
        [invocation getArgument:&completion atIndex:2];
        if (completion) {
            completion();
        }
    });

    OCMStub([self.cleverPush getSubscriptionId:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSString *) = nil;
        [invocation getArgument:&completion atIndex:2];
        if (completion) {
            completion(nil);
        }
    });

    [self.cleverPush pushSubscriptionAttributeValue:attributeId value:value];

    [expectation fulfill];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
