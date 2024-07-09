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

@interface CPTagsTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic, retain) TestUtils *testUtilInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPTagsTest

- (void)setUp {
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
}
- (void)testGetSubscriptionTagsSuccess {
    NSArray<NSString *> *tags = @[@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);

    NSArray<NSString *> *expectedTags = [self.cleverPush getSubscriptionTags];
    XCTAssertEqualObjects(tags, expectedTags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}

- (void)testGetSubscriptionTagsFailure {
    NSArray<NSString *> *tags = @[@"tagId", @"tagIdTwo"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);

    NSArray<NSString *> *retrievedTags = [self.cleverPush getSubscriptionTags];
    XCTAssertFalse([retrievedTags containsObject:@"tagIdNotPresent"]);
    XCTAssertFalse([retrievedTags containsObject:@"tagIdTwo"]);
}

- (void)testHasSubscriptionTagWhenItIsFalse{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertFalse([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}

- (void)testHasSubscriptionTagWhenItIsTrue{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}

- (void)testGetAvailableTagsWhenItIsTrue{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get Available Tags"];

    OCMStub([self.cleverPush getChannelConfig:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSDictionary *) = nil;
        [invocation getArgument:&completion atIndex:2];
        completion(nil);
    });

    [self.cleverPush getAvailableTags:^(NSArray<CPChannelTag *> * _Nullable tags) {
        XCTAssertEqual(tags.count, 0);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetAvailableTagsWhenItIsFalse{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get Available Tags"];

    NSDictionary *tag = @{@"id": @"tagId"};

    OCMStub([self.cleverPush getChannelConfig:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSDictionary *) = nil;
        [invocation getArgument:&completion atIndex:2];
        NSDictionary *channelConfig = @{@"channelTags": @[tag]};
        completion(channelConfig);
    });

    [self.cleverPush getAvailableTags:^(NSArray<CPChannelTag *> * _Nullable tags) {
        XCTAssertEqual(tags.count, 1);
        XCTAssertTrue([[tags firstObject].id isEqualToString:@"tagId"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetAvailableTagsContainsTagId {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *Tags) {
        XCTAssertTrue([Tags containsObject:@"tagId"]);
    }];
}

- (void)testGetAvailableTagsNotContainsTagId {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];
    [self.cleverPush getAvailableTags:^(NSArray *Tags) {
        XCTAssertTrue([Tags containsObject:@"tagIdTwo"]);
    }];
}

- (void)testVerifyApiCallAddTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallAddTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccessWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertNotNil(result);
    };

    [self.cleverPush addSubscriptionTag:tagId callback:successCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagFailureWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSString *) = ^(NSString *result) {
        XCTFail("Unexpected callback invocation in failure case");
    };

    [OCMStub([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush addSubscriptionTag:tagId callback:failureCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccessWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertNotNil(result);
    };

    [self.cleverPush addSubscriptionTag:tagId callback:successCallback onFailure:^(NSError *error) {
        XCTFail("Unexpected failure block invocation in success case");
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagFailureWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSString *) = ^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    };

    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];

    [OCMStub([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        onFailure(testError);
    }];

    [self.cleverPush addSubscriptionTag:tagId callback:^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    } onFailure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, @"TestErrorDomain");
        XCTAssertEqual(error.code, 500);
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testRemoveSubscriptionTagSuccessWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertNotNil(result);
    };

    [self.cleverPush removeSubscriptionTag:tagId callback:successCallback onFailure:^(NSError *error) {
        XCTFail("Unexpected failure block invocation in success case");
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testRemoveSubscriptionTagFailureWithCallbacks {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSString *) = ^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    };

    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];

    [OCMStub([self.cleverPush removeSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        onFailure(testError);
    }];

    [self.cleverPush removeSubscriptionTag:tagId callback:^(NSString *result) {
        XCTFail("Unexpected success block invocation in failure case");
    } onFailure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, @"TestErrorDomain");
        XCTAssertEqual(error.code, 500);
    }];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testAddSubscriptionTagSuccess {
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToAdd = @[@"tagIdTwo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags added successfully"];
    [self.cleverPush addSubscriptionTag:@"tagIdTwo"];
    OCMVerify([self.cleverPush addSubscriptionTag:@"tagIdTwo"]);
    [expectation fulfill];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

- (void)testAddSubscriptionTagFailure {
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToAdd = @[@"tagId"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags not added"];
    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush addSubscriptionTag:@"tagId"]);

    NSArray<NSString *> *resultTags = [self.cleverPush getSubscriptionTags];
    XCTAssertFalse([resultTags containsObject:@"tagId"]);

    [expectation fulfill];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

- (void)testVerifyApiCallRemoveTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    [self.cleverPush removeSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallRemoveTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];
        onFailure(error);
    }];

    [self.cleverPush removeSubscriptionTag:tagId];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testRemoveSubscriptionTagsSuccessWithCallback {
    NSMutableArray *tags = [[NSMutableArray alloc] initWithObjects:@"tagId", @"tagIdTwo", nil];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToRemove = @[@"tagIdTwo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags removed successfully"];
    [self.cleverPush removeSubscriptionTags:tagsToRemove callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertFalse([resultTags containsObject:@"tagIdTwo"]);
        [expectation fulfill];
    }];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testRemoveSubscriptionTagsFailureWithCallback {
    NSMutableArray *tags = [[NSMutableArray alloc] initWithObjects:@"tagId", @"tagIdTwo", nil];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToRemove = @[@"tagIdThree"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tags not removed"];
    [self.cleverPush removeSubscriptionTags:tagsToRemove callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertTrue([resultTags containsObject:@"tagIdTwo"]);
        [expectation fulfill];
    }];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testRemoveSubscriptionTagsSuccess {
    NSMutableArray *tags = [[NSMutableArray alloc] initWithObjects:@"tagId", @"tagIdTwo", nil];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToRemove = @[@"tagId"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tag removed successfully"];
    [self.cleverPush removeSubscriptionTags:tagsToRemove callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertFalse([resultTags containsObject:@"tagId"]);
        [expectation fulfill];
    }];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testRemoveSubscriptionTagsFailure {
    NSMutableArray *tags = [[NSMutableArray alloc] initWithObjects:@"tagId", @"tagIdTwo", nil];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSArray<NSString *> *tagsToRemove = @[@"tagIdNotPresent"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tag not removed"];
    [self.cleverPush removeSubscriptionTags:tagsToRemove callback:^(NSArray<NSString *> *resultTags) {
        XCTAssertTrue([resultTags containsObject:@"tagId"]);
        [expectation fulfill];
    }];
    NSTimeInterval timeout = 10;
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testAddSubscriptionTagsSuccessWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSArray<NSString *> *tagIds = @[@"tagId1", @"tagId2"];
    void (^successCallback)(NSArray<NSString *> *) = ^(NSArray<NSString *> *result) {
        XCTAssertNotNil(result);
        XCTAssertEqual(result.count, tagIds.count);
        XCTAssertTrue([result containsObject:@"tagId1"]);
        XCTAssertTrue([result containsObject:@"tagId2"]);
    };

    [self.cleverPush addSubscriptionTags:tagIds callback:successCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    for (NSString *tagId in tagIds) {
        OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
    }
}

- (void)testAddSubscriptionTagsFailureWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSArray<NSString *> *tagIds = @[@"tagId1", @"tagId2"];
    void (^failureCallback)(NSString *) = ^(NSString *error) {
        XCTAssertNotNil(error);
    };

    [self.cleverPush addSubscriptionTags:tagIds];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    for (NSString *tagId in tagIds) {
        OCMVerify([self.cleverPush addSubscriptionTagToApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
    }
}

- (void)testRemoveSubscriptionTagSuccessWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^successCallback)(NSString *) = ^(NSString *result) {
        XCTAssertEqualObjects(result, @"Successfully removed tag");
    };

    [self.cleverPush removeSubscriptionTagFromApi:tagId callback:successCallback onFailure:[OCMArg any]];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testRemoveSubscriptionTagFailureWithCallback {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];

    NSString *tagId = @"tagId";
    void (^failureCallback)(NSError *) = ^(NSError *error) {
        XCTFail("Unexpected callback invocation in failure case");
    };

    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:500 userInfo:nil];

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^onFailure)(NSError *);
        [invocation getArgument:&onFailure atIndex:4];
        onFailure(testError);
    }];

    [self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:failureCallback];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:tagId callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testGetAvailableTagsSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get Available Tags"];

    NSDictionary *tag = @{@"id": @"tagId"};

    OCMStub([self.cleverPush getChannelConfig:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSDictionary *) = nil;
        [invocation getArgument:&completion atIndex:2];
        NSDictionary *channelConfig = @{@"channelTags": @[tag]};
        completion(channelConfig);
    });

    [self.cleverPush getAvailableTags:^(NSArray<CPChannelTag *> * _Nullable tags) {
        XCTAssertEqual(tags.count, 1);
        XCTAssertTrue([[tags firstObject].id isEqualToString:@"tagId"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetAvailableTagsFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get Available Tags"];

    OCMStub([self.cleverPush getChannelConfig:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        void (^completion)(NSDictionary *) = nil;
        [invocation getArgument:&completion atIndex:2];
        completion(nil);
    });

    [self.cleverPush getAvailableTags:^(NSArray<CPChannelTag *> * _Nullable tags) {
        XCTAssertEqual(tags.count, 0);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
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
