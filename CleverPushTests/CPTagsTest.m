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
- (void)testGetSubscriptionTags {
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    NSMutableArray *expectedTags = [self.cleverPush getSubscriptionTags];
    XCTAssertEqual(tags, expectedTags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);

}
- (void)testHasSubscriptionTagWhenItIsFalse{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertTrue([[self.cleverPush getSubscriptionTags] containsObject:@"tagId"]);
}
- (void)testHasSubscriptionTagWhenItIsTrue{
    NSMutableArray *tags = [[NSMutableArray alloc]init];
    [tags addObject:@"tagId"];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(tags);
    XCTAssertFalse([[self.cleverPush getSubscriptionTags] containsObject:@"tagIdTwo"]);
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
        XCTAssertFalse([Tags containsObject:@"tagIdTwo"]);
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

- (void)testAddSubscriptionTagSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"add tag callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"add tag failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:500 userInfo:nil];
    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 500);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagSuccessCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove tag callback"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagFailureCallsFailureBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove tag failure"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    NSError *err = [NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil];
    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) failure(err);
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTFail(@"Unexpected success: %@", result);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertEqual(error.code, 404);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagsBulkCallbackReturnsSubscriptionTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk add callback"];

    NSArray *expected = @[ @"t1", @"t2" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);
    
    [OCMStub([self.cleverPush addSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush addSubscriptionTags:@[ @"t1", @"t2" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagsBulkCallbackReturnsSubscriptionTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk remove callback"];

    NSArray *expected = @[ @"t1" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [OCMStub([self.cleverPush removeSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush removeSubscriptionTags:@[ @"t1", @"t2" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testAddSubscriptionTagWhenAlreadyPresentDoesNotCallApiAndStillCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"duplicate tag callback"];

    [[NSUserDefaults standardUserDefaults] setObject:@[ @"tagId" ] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [[self.cleverPush reject] addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    } onFailure:^(NSError * _Nullable error) {
        XCTFail(@"Unexpected failure: %@", error);
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - hasSubscriptionTag

- (void)testHasSubscriptionTagReturnsTrueWhenTagExists {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"existingTag" ] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertTrue([self.testableInstance hasSubscriptionTag:@"existingTag"]);
}

- (void)testHasSubscriptionTagReturnsFalseWhenTagDoesNotExist {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"otherTag" ] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTag:@"nonExistentTag"]);
}

- (void)testHasSubscriptionTagReturnsFalseWhenTagsListIsEmpty {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTag:@"anyTag"]);
}

- (void)testHasSubscriptionTagReturnsFalseForNilTagId {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"existingTag" ] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    XCTAssertFalse([self.testableInstance hasSubscriptionTag:nil]);
}

#pragma mark - getSubscriptionTags

- (void)testGetSubscriptionTagsReturnsStoredTags {
    NSArray *stored = @[ @"tag1", @"tag2" ];
    [[NSUserDefaults standardUserDefaults] setObject:stored forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSArray *result = [self.testableInstance getSubscriptionTags];
    XCTAssertEqualObjects(result, stored);
}

- (void)testGetSubscriptionTagsReturnsEmptyArrayWhenNothingStored {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSArray *result = [self.testableInstance getSubscriptionTags];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 0);
}

#pragma mark - getAvailableTags (callback variant)

- (void)testGetAvailableTagsCallbackWithEmptyConfigReturnsEmptyArray {
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(nil);
    }];

    [self.cleverPush getAvailableTags:^(NSArray *tags) {
        XCTAssertNotNil(tags);
        XCTAssertEqual(tags.count, 0);
    }];
}

- (void)testGetAvailableTagsCallbackWithConfigHavingNoTagsReturnsEmptyArray {
    NSDictionary *config = @{ @"channelTags": @[] };
    [OCMStub([self.cleverPush getChannelConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSDictionary *);
        [invocation getArgument:&handler atIndex:2];
        handler(config);
    }];

    [self.cleverPush getAvailableTags:^(NSArray *tags) {
        XCTAssertNotNil(tags);
        XCTAssertEqual(tags.count, 0);
    }];
}

- (void)testGetAvailableTagsCallbackWithValidTagsReturnsTags {
    NSMutableArray *tags = [NSMutableArray arrayWithObject:@"tag1"];
    [OCMStub([self.cleverPush getAvailableTags:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *);
        [invocation getArgument:&handler atIndex:2];
        handler(tags);
    }];

    [self.cleverPush getAvailableTags:^(NSArray *result) {
        XCTAssertEqual(result.count, 1);
        XCTAssertEqualObjects(result.firstObject, @"tag1");
    }];
}

#pragma mark - addSubscriptionTag (no callback)

- (void)testAddSubscriptionTagNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush addSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - addSubscriptionTag (callback only, no onFailure)

- (void)testAddSubscriptionTagWithCallbackOnlyInvokesCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"add tag callback only"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"tagId");
    }];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - removeSubscriptionTag (no callback)

- (void)testRemoveSubscriptionTagNoCallbackCallsWaitForTrackingConsent {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId"];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - removeSubscriptionTag (callback only, no onFailure)

- (void)testRemoveSubscriptionTagWithCallbackOnlyInvokesCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"remove tag callback only"];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"tagId");
    }];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:^(NSString * _Nullable result) {
        XCTAssertEqualObjects(result, @"tagId");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - addSubscriptionTags (no callback)

- (void)testAddSubscriptionTagsNoCallbackCallsAddForEachTag {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush addSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {}];

    [self.cleverPush addSubscriptionTags:@[ @"t1", @"t2" ]];

    OCMVerify([self.cleverPush addSubscriptionTag:@"t1" callback:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTag:@"t2" callback:[OCMArg any]]);
}

#pragma mark - removeSubscriptionTags (no callback)

- (void)testRemoveSubscriptionTagsNoCallbackCallsRemoveForEachTag {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];
    [OCMStub([self.cleverPush removeSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {}];

    [self.cleverPush removeSubscriptionTags:@[ @"t1", @"t2" ]];

    OCMVerify([self.cleverPush removeSubscriptionTag:@"t1" callback:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTag:@"t2" callback:[OCMArg any]]);
}

#pragma mark - addSubscriptionTags bulk - edge cases

- (void)testAddSubscriptionTagsBulkWithEmptyArrayCallsCallbackWithCurrentTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk add empty"];

    NSArray *expected = @[ @"existing" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [self.cleverPush addSubscriptionTags:@[] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRemoveSubscriptionTagsBulkWithEmptyArrayCallsCallbackWithCurrentTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk remove empty"];

    NSArray *expected = @[ @"remaining" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [self.cleverPush removeSubscriptionTags:@[] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - removeSubscriptionTag - not present in stored tags still calls API

- (void)testRemoveSubscriptionTagNotInStoredTagsStillCallsApi {
    [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush removeSubscriptionTag:@"nonExistentTagId"];
    OCMVerify([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

#pragma mark - addSubscriptionTag with nil tagId

- (void)testAddSubscriptionTagWithNilTagIdCallsApiWithNil {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [self.cleverPush addSubscriptionTag:nil];
    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
}

#pragma mark - Tracking consent blocked

- (void)testAddSubscriptionTagDoesNotCallApiWhenTrackingConsentNotGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // do not call the handler — consent not granted
    }];

    [[self.cleverPush reject] addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]];

    [self.cleverPush addSubscriptionTag:@"tagId" callback:nil onFailure:nil];

    OCMVerifyAll(self.cleverPush);
}

- (void)testRemoveSubscriptionTagDoesNotCallApiWhenTrackingConsentNotGranted {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(true);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        // do not call the handler — consent not granted
    }];

    [[self.cleverPush reject] removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]];

    [self.cleverPush removeSubscriptionTag:@"tagId" callback:nil onFailure:nil];

    OCMVerifyAll(self.cleverPush);
}

#pragma mark - addSubscriptionTagSuccessCallsCallback - nil callback safety

- (void)testAddSubscriptionTagSuccessWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"tagId");
    }];

    XCTAssertNoThrow([self.cleverPush addSubscriptionTag:@"tagId" callback:nil onFailure:nil]);
}

- (void)testRemoveSubscriptionTagSuccessWithNilCallbackDoesNotCrash {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        if (handler) handler();
    }];

    [OCMStub([self.cleverPush removeSubscriptionTagFromApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(@"tagId");
    }];

    XCTAssertNoThrow([self.cleverPush removeSubscriptionTag:@"tagId" callback:nil onFailure:nil]);
}

#pragma mark - addSubscriptionTagsBulk - multiple tags all succeed

- (void)testAddSubscriptionTagsBulkAllTagsSucceedCallsCallbackWithFinalTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk add all succeed"];

    NSArray *expected = @[ @"a", @"b", @"c" ];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [OCMStub([self.cleverPush addSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush addSubscriptionTags:@[ @"a", @"b", @"c" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - removeSubscriptionTagsBulk - multiple tags all succeed

- (void)testRemoveSubscriptionTagsBulkAllTagsSucceedCallsCallbackWithFinalTags {
    XCTestExpectation *exp = [self expectationWithDescription:@"bulk remove all succeed"];

    NSArray *expected = @[];
    OCMStub([self.cleverPush getSubscriptionTags]).andReturn(expected);

    [OCMStub([self.cleverPush removeSubscriptionTag:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        NSString *tagId = nil;
        void (^callback)(NSString * _Nullable) = nil;
        [invocation getArgument:&tagId atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        if (callback) callback(tagId);
    }];

    [self.cleverPush removeSubscriptionTags:@[ @"a", @"b" ] callback:^(NSArray<NSString *> * _Nullable result) {
        XCTAssertEqualObjects(result, expected);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

