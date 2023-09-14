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

- (void)testVerifyApiCallAddTag {
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

- (void)testVerifyApiCallAddTagFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];

    [OCMStub([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^failureHandler)(NSError *error);
        [invocation getArgument:&failureHandler atIndex:3];
        NSError *error = [NSError errorWithDomain:@"com.example" code:123 userInfo:nil];
        failureHandler(error);
    }];

    [self.cleverPush addSubscriptionTag:@"tagId"];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTagToApi:[OCMArg any] callback:[OCMArg any] onFailure:[OCMArg any]]);
}

- (void)testVerifyApiCallAddSubscriptionTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush addSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush addSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testVerifyApiCallAddSubscriptionTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(false);
    [[self.cleverPush reject] waitForTrackingConsent:[OCMArg any]];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush addSubscriptionTags:tags];
    OCMVerifyAll(self.cleverPush);
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

- (void)testVerifyApiCallRemoveSubscriptionTags {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];
    [self.cleverPush removeSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}

- (void)testVerifyApiCallRemoveSubscriptionTagsFailure {
    OCMStub([self.cleverPush getTrackingConsentRequired]).andReturn(false);
    OCMStub([self.cleverPush getHasTrackingConsent]).andReturn(true);
    [OCMStub([self.cleverPush waitForTrackingConsent:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(void);
        [invocation getArgument:&handler atIndex:2];
        handler();
    }];
    NSArray<NSString *> *tags = @[@"tagOne", @"tagTwo", @"tagThree"];

    [OCMStub([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^failureHandler)(NSError *error);
        [invocation getArgument:&failureHandler atIndex:3];
        NSError *error = [NSError errorWithDomain:@"com.example" code:123 userInfo:nil];
        failureHandler(error);
    }];

    [self.cleverPush removeSubscriptionTags:tags];

    OCMVerify([self.cleverPush waitForTrackingConsent:[OCMArg any]]);
    OCMVerify([self.cleverPush removeSubscriptionTags:[OCMArg any] callback:[OCMArg any]]);
}


- (void)testGetAvailableTopicsContainsTopicId {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *Topics) {
        XCTAssertTrue([Topics containsObject:@"topicId"]);
    }];
}

- (void)testGetAvailableTopicsNotContainsTopicId {
    NSMutableArray *topics = [[NSMutableArray alloc]init];
    [topics addObject:@"topicId"];
    [OCMStub([self.cleverPush getAvailableTopics:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSArray *myFirstArgument);
        [invocation getArgument:&handler atIndex:2];
        handler(topics);
    }];
    [self.cleverPush getAvailableTopics:^(NSArray *tTopics) {
        XCTAssertFalse([tTopics containsObject:@"topicIdTwo"]);
    }];
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


/*


 - (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds callback:(void(^)(NSArray <NSString*>*))callback;
 - (void)removeSubscriptionTag:(NSString*)tagId;
 - (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback;
 - (void)removeSubscriptionTag:(NSString*)tagId callback:(void(^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
 - (void)removeSubscriptionTags:(NSArray <NSString*>*)tagIds;

 - (void)getAvailableTags:(void(^)(NSArray <CPChannelTag*>*))callback;

 - (NSArray<NSString*>*)getSubscriptionTags;

 - (NSArray*)getAvailableTags __attribute__((deprecated));

 - (BOOL)hasSubscriptionTag:(NSString*)tagId;

 - (void)checkTags:(NSString*)urlStr params:(NSDictionary*)params;
 - (void)autoAssignTagMatches:(CPChannelTag*)tag pathname:(NSString*)pathname params:(NSDictionary*)params callback:(void(^)(BOOL))callback;

 - (void)addSubscriptionTagToApi:(NSString*)tagId callback:(void (^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;
 - (void)removeSubscriptionTagFromApi:(NSString*)tagId callback:(void (^)(NSString *))callback onFailure:(CPFailureBlock)failureBlock;


 */
