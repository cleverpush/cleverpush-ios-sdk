@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CleverPushHTTPClient.h"
#import "CleverPushUserDefaults.h"
#import "CPNotification.h"
#import "CPUtils.h"

@interface CPNotificationsTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *testableInstance;
@property (nonatomic) id cleverPush;

@end

@implementation CPNotificationsTest

- (void)setUp {
    [super setUp];
    self.testableInstance = [[CleverPushInstance alloc] init];
    self.cleverPush = OCMPartialMock(self.testableInstance);
    [self clearNotificationDefaults];
}

- (void)tearDown {
    [self.cleverPush stopMocking];
    [self clearNotificationDefaults];
    [super tearDown];
}

- (void)clearNotificationDefaults {
    NSUserDefaults *userDefaults = [CPUtils getUserDefaultsAppGroup];
    [userDefaults removeObjectForKey:CLEVERPUSH_NOTIFICATIONS_KEY];
    [userDefaults removeObjectForKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
    [userDefaults removeObjectForKey:CLEVERPUSH_LAST_NOTIFICATION_ID_KEY];
    [userDefaults removeObjectForKey:CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT];
    [userDefaults synchronize];
}

- (NSDictionary *)sampleNotificationDictionaryWithId:(NSString *)notificationId {
    return @{
        @"_id": notificationId,
        @"title": @"Test Title",
        @"text": @"Test Text",
        @"tag": notificationId,
        @"url": @"https://cleverpush.com",
        @"createdAt": @"2024-01-01T00:00:00.000Z",
        @"notificationIdentifier": [NSString stringWithFormat:@"ident-%@", notificationId]
    };
}

- (void)storeLocalNotifications:(NSArray *)notifications {
    NSUserDefaults *userDefaults = [CPUtils getUserDefaultsAppGroup];
    [userDefaults setObject:notifications forKey:CLEVERPUSH_NOTIFICATIONS_KEY];
    [userDefaults synchronize];
}

#pragma mark - CPNotification model

- (void)testNotificationInitWithJsonSetsProperties {
    CPNotification *notification = [CPNotification initWithJson:[self sampleNotificationDictionaryWithId:@"n1"]];
    XCTAssertEqualObjects(notification.id, @"n1");
    XCTAssertEqualObjects(notification.title, @"Test Title");
    XCTAssertEqualObjects(notification.text, @"Test Text");
    XCTAssertEqualObjects(notification.tag, @"n1");
    XCTAssertEqualObjects(notification.url, @"https://cleverpush.com");
    XCTAssertFalse(notification.read);
}

- (void)testNotificationInitWithNilJsonReturnsNil {
    XCTAssertNil([CPNotification initWithJson:nil]);
}

- (void)testNotificationInitWithEmptyJsonDoesNotCrash {
    CPNotification *notification = [CPNotification initWithJson:@{}];
    XCTAssertNotNil(notification);
    XCTAssertNil(notification.id);
}

- (void)testNotificationSetReadAndGetRead {
    CPNotification *notification = [CPNotification initWithJson:[self sampleNotificationDictionaryWithId:@"n-read"]];
    [notification setRead:YES];
    XCTAssertTrue([notification getRead]);
    [notification setRead:NO];
    XCTAssertFalse([notification getRead]);
}

#pragma mark - getNotifications (local)

- (void)testGetNotificationsReturnsEmptyArrayWhenNothingStored {
    NSArray *notifications = [self.testableInstance getNotifications];
    XCTAssertNotNil(notifications);
    XCTAssertEqual(notifications.count, 0);
}

- (void)testGetNotificationsReturnsStoredNotifications {
    [self storeLocalNotifications:@[
        [self sampleNotificationDictionaryWithId:@"n1"],
        [self sampleNotificationDictionaryWithId:@"n2"]
    ]];
    NSArray<CPNotification *> *notifications = [self.testableInstance getNotifications];
    XCTAssertEqual(notifications.count, 2);
    XCTAssertEqualObjects(notifications.firstObject.id, @"n1");
}

- (void)testGetNotificationsFiltersDuplicateIds {
    [self storeLocalNotifications:@[
        [self sampleNotificationDictionaryWithId:@"dup"],
        [self sampleNotificationDictionaryWithId:@"dup"]
    ]];
    NSArray<CPNotification *> *notifications = [self.testableInstance getNotifications];
    XCTAssertEqual(notifications.count, 1);
}

#pragma mark - getNotifications callback (local / remote)

- (void)testGetNotificationsCallbackWithoutApiReturnsLocalNotifications {
    XCTestExpectation *exp = [self expectationWithDescription:@"getNotifications local callback"];
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"local-1"]]];

    [self.testableInstance getNotifications:NO callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        XCTAssertEqual(notifications.count, 1);
        XCTAssertEqualObjects(notifications.firstObject.id, @"local-1");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetNotificationsCallbackWithEmptyLocalReturnsEmptyArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"getNotifications empty callback"];
    [self.testableInstance getNotifications:NO callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        XCTAssertNotNil(notifications);
        XCTAssertEqual(notifications.count, 0);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetNotificationsCombineWithApiWithEmptyChannelIdReturnsLocalOnly {
    XCTestExpectation *exp = [self expectationWithDescription:@"getNotifications api skipped"];
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"local-only"]]];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];

    [self.testableInstance getNotifications:YES callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        XCTAssertEqual(notifications.count, 1);
        XCTAssertEqualObjects(notifications.firstObject.id, @"local-only");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetNotificationsWithLimitAndSkipCallsCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"getNotifications limit/skip"];
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"n1"]]];
    [self.testableInstance getNotifications:NO limit:10 skip:5 callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        XCTAssertNotNil(notifications);
        XCTAssertEqual(notifications.count, 1);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - removeNotification / removeAllNotifications

- (void)testRemoveNotificationRemovesMatchingNotification {
    [self storeLocalNotifications:@[
        [self sampleNotificationDictionaryWithId:@"keep"],
        [self sampleNotificationDictionaryWithId:@"remove-me"]
    ]];
    [self.testableInstance removeNotification:@"remove-me"];
    NSArray<CPNotification *> *remaining = [self.testableInstance getNotifications];
    XCTAssertEqual(remaining.count, 1);
    XCTAssertEqualObjects(remaining.firstObject.id, @"keep");
}

- (void)testRemoveNotificationWithUnknownIdLeavesListUnchanged {
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"keep"]]];
    [self.testableInstance removeNotification:@"unknown"];
    XCTAssertEqual([self.testableInstance getNotifications].count, 1);
}

- (void)testRemoveNotificationWithNilIdDoesNotCrash {
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"keep"]]];
    XCTAssertNoThrow([self.testableInstance removeNotification:nil]);
    XCTAssertEqual([self.testableInstance getNotifications].count, 1);
}

- (void)testRemoveAllNotificationsClearsStoredNotifications {
    [self storeLocalNotifications:@[
        [self sampleNotificationDictionaryWithId:@"n1"],
        [self sampleNotificationDictionaryWithId:@"n2"]
    ]];
    [self.testableInstance removeAllNotifications];
    XCTAssertEqual([self.testableInstance getNotifications].count, 0);
}

- (void)testRemoveAllNotificationsWhenEmptyDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance removeAllNotifications]);
}

#pragma mark - setNotificationRead / getNotificationRead

- (void)testSetNotificationReadTrueThenGetReturnsTrue {
    [self.testableInstance setNotificationRead:@"n-read" read:YES];
    XCTAssertTrue([self.testableInstance getNotificationRead:@"n-read"]);
}

- (void)testSetNotificationReadFalseThenGetReturnsFalse {
    [self.testableInstance setNotificationRead:@"n-unread" read:YES];
    [self.testableInstance setNotificationRead:@"n-unread" read:NO];
    XCTAssertFalse([self.testableInstance getNotificationRead:@"n-unread"]);
}

- (void)testGetNotificationReadReturnsFalseForUnknownId {
    XCTAssertFalse([self.testableInstance getNotificationRead:@"never-read"]);
}

- (void)testGetNotificationReadReturnsFalseForNilId {
    XCTAssertFalse([self.testableInstance getNotificationRead:nil]);
}

- (void)testSetNotificationReadWithNilIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance setNotificationRead:nil read:YES]);
}

#pragma mark - trackInboxClicked / trackNotificationDelivered / trackNotificationClicked

- (void)testTrackInboxClickedWithEmptyIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackInboxClicked:@""]);
}

- (void)testTrackInboxClickedWithNilIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackInboxClicked:nil]);
}

- (void)testTrackInboxClickedWithEmptyChannelIdDoesNotCrash {
    OCMStub([self.cleverPush channelId]).andReturn(@"");
    XCTAssertNoThrow([self.cleverPush trackInboxClicked:@"n1"]);
}

- (void)testTrackNotificationDeliveredWithEmptyIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackNotificationDelivered:@""]);
}

- (void)testTrackNotificationDeliveredWithNilIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackNotificationDelivered:nil]);
}

- (void)testTrackNotificationClickedWithEmptyIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackNotificationClicked:@""]);
}

- (void)testTrackNotificationClickedWithNilIdDoesNotCrash {
    XCTAssertNoThrow([self.testableInstance trackNotificationClicked:nil]);
}

- (void)testTrackInboxClickedCallsEnqueueWhenChannelIdPresent {
    OCMStub([self.cleverPush channelId]).andReturn(@"RHe2nXvQk9SZgdC4x");
    OCMExpect([self.cleverPush trackInboxClicked:@"n1"]);
    [self.cleverPush trackInboxClicked:@"n1"];
    OCMVerify([self.cleverPush trackInboxClicked:@"n1"]);
}

#pragma mark - setMaximumNotificationCount

- (void)testSetMaximumNotificationCountStoresValue {
    [self.testableInstance setMaximumNotificationCount:25];
    NSInteger stored = [[CPUtils getUserDefaultsAppGroup] integerForKey:CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT];
    XCTAssertEqual(stored, 25);
}

#pragma mark - handleNotificationOpened / handleNotificationReceived (mocked)

- (void)testHandleNotificationReceivedDoesNotCrashWithNilPayload {
    XCTAssertNoThrow([self.testableInstance handleNotificationReceived:nil isActive:NO]);
}

- (void)testHandleNotificationOpenedDoesNotCrashWithNilPayload {
    XCTAssertNoThrow([self.testableInstance handleNotificationOpened:nil isActive:NO actionIdentifier:nil]);
}

- (void)testHandleNotificationOpenedCallsVerify {
    NSDictionary *payload = @{ @"notification": @{ @"_id": @"n1", @"title": @"Hi" } };
    OCMExpect([self.cleverPush handleNotificationOpened:payload isActive:YES actionIdentifier:@"default"]);
    [self.cleverPush handleNotificationOpened:payload isActive:YES actionIdentifier:@"default"];
    OCMVerify([self.cleverPush handleNotificationOpened:payload isActive:YES actionIdentifier:@"default"]);
}

- (void)testHandleNotificationReceivedCallsVerify {
    NSDictionary *payload = @{ @"notification": @{ @"_id": @"n1" } };
    OCMExpect([self.cleverPush handleNotificationReceived:payload isActive:NO]);
    [self.cleverPush handleNotificationReceived:payload isActive:NO];
    OCMVerify([self.cleverPush handleNotificationReceived:payload isActive:NO]);
}

#pragma mark - getDeviceToken / getSubscriptionId

- (void)testGetDeviceTokenReturnsNilInitially {
    XCTAssertNil([self.testableInstance getDeviceToken]);
}

- (void)testGetDeviceTokenCallbackInvokedWhenTokenIsSet {
    XCTestExpectation *exp = [self expectationWithDescription:@"device token callback"];
    OCMStub([self.cleverPush getDeviceToken]).andReturn(@"device-token");
    [OCMStub([self.cleverPush getDeviceToken:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(NSString *);
        [invocation getArgument:&handler atIndex:2];
        handler(@"device-token");
    }];
    [self.cleverPush getDeviceToken:^(NSString * _Nullable token) {
        XCTAssertEqualObjects(token, @"device-token");
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetSubscriptionIdCallbackInvokedWhenIdIsSet {
    XCTestExpectation *exp = [self expectationWithDescription:@"subscription id callback"];
    [self.testableInstance setSubscriptionId:@"sub-123"];
    [self.testableInstance getSubscriptionId:^(NSString * _Nullable subscriptionId) {
        XCTAssertEqualObjects(subscriptionId, @"sub-123");
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetSubscriptionIdCallbackWithNilIdDoesNotCallImmediately {
    [self.testableInstance setSubscriptionId:nil];
    __block BOOL called = NO;
    [self.testableInstance getSubscriptionId:^(NSString * _Nullable subscriptionId) {
        called = YES;
    }];
    XCTAssertFalse(called);
}

#pragma mark - areNotificationsEnabled

- (void)testAreNotificationsEnabledCallbackIsInvoked {
    XCTestExpectation *exp = [self expectationWithDescription:@"areNotificationsEnabled"];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(YES);
    }];
    [self.cleverPush areNotificationsEnabled:^(BOOL enabled) {
        XCTAssertTrue(enabled);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testAreNotificationsEnabledFailurePathReturnsFalse {
    XCTestExpectation *exp = [self expectationWithDescription:@"areNotificationsEnabled false"];
    [OCMStub([self.cleverPush areNotificationsEnabled:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL);
        [invocation getArgument:&handler atIndex:2];
        handler(NO);
    }];
    [self.cleverPush areNotificationsEnabled:^(BOOL enabled) {
        XCTAssertFalse(enabled);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - getNotifications combineWithApi (mocked transport)

- (void)testGetNotificationsApiWithValidChannelId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getNotifications mocked"];
    [self storeLocalNotifications:@[[self sampleNotificationDictionaryWithId:@"local-1"]]];
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"RHe2nXvQk9SZgdC4x" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPResultSuccessBlock success = nil;
        [invocation getArgument:&success atIndex:3];
        if (success) success(@{ @"notifications": @[ [self sampleNotificationDictionaryWithId:@"remote-1"] ] });
    }];

    [self.cleverPush getNotifications:YES callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        XCTAssertNotNil(notifications);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetNotificationsApiWithInvalidChannelIdDoesNotInvokeSuccessCallback {
    XCTestExpectation *noSuccess = [self expectationWithDescription:@"getNotifications invalid no success"];
    noSuccess.inverted = YES;
    (void)[self.testableInstance initWithLaunchOptions:nil channelId:@"__invalid_channel__" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:NO];
    [OCMStub([self.cleverPush enqueueRequest:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any] withRetry:YES]) andDo:^(NSInvocation *invocation) {
        CPFailureBlock failure = nil;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure([NSError errorWithDomain:@"CleverPushError" code:404 userInfo:nil]);
        }
    }];

    [self.cleverPush getNotifications:YES callback:^(NSArray<CPNotification *> * _Nullable notifications) {
        [noSuccess fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.4 handler:nil];
}

@end
