#import <XCTest/XCTest.h>
#import "CleverPush/CleverPush.h"
#import "CleverPush.h"
#import <OCMock/OCMock.h>

@interface CPNotificationsTest : XCTestCase
@property (nonatomic, strong) CPNotification *notification1;
@property (nonatomic, strong) CPNotification *notification2;
@end

@implementation CPNotificationsTest

- (void)testGetNotificationsWithSuccess {
    NSArray<CPNotification *> *testNotifications = @[self.notification1, self.notification2];
    
    BOOL combineWithApi = YES;
    int limit = 10;
    int skip = 0;

    OCMStub([CleverPush getNotifications:combineWithApi limit:limit skip:skip callback:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            void (^callback)(NSArray<CPNotification *> *) = nil;
            [invocation getArgument:&callback atIndex:5];
            if (callback != nil) {
                callback(testNotifications);
            }
        });

    [CleverPush getNotifications:combineWithApi limit:limit skip:skip callback:^(NSArray<CPNotification *> *notifications) {
        XCTAssertEqualObjects(notifications, testNotifications, @"Retrieved notifications should match the test notifications");
    }];
}

- (void)testGetNotificationsWithFailure {
    NSArray<CPNotification *> *expectedNotifications = @[self.notification1, self.notification2];
    BOOL combineWithApi = NO;
    int limit = 5;
    int skip = 0;

    OCMStub([CleverPush getNotifications:combineWithApi limit:limit skip:skip callback:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            void (^callback)(NSArray<CPNotification *> *) = nil;
            [invocation getArgument:&callback atIndex:5];
            if (callback != nil) {
                callback(expectedNotifications);
            }
        });

    [CleverPush getNotifications:combineWithApi limit:limit skip:skip callback:^(NSArray<CPNotification *> *notifications) {
        XCTAssertNotEqualObjects(notifications, expectedNotifications, @"Retrieved notifications should not match the expected notifications");
    }];
}


- (void)setUp {
    OCMStub([CleverPush channelId]).andReturn(@"YOUR_CHANNEL_ID_HERE");
    OCMStub([CleverPush getSubscriptionId]).andReturn(@"subscriptionId");
    [CleverPush getChannelConfig:^(NSDictionary *channelConfig) {
        NSLog(@"%@", channelConfig);
    }];
    (void)[CleverPush initWithLaunchOptions:nil channelId:@"YOUR_CHANNEL_ID_HERE" handleNotificationReceived:nil handleNotificationOpened:nil autoRegister:true];

    self.notification1 = [[CPNotification alloc] init];
    self.notification1.id = @"123";
    self.notification1.tag = @"announcement";
    self.notification1.title = @"New Update Available";
    self.notification1.text = @"A new update is available for your app!";
    self.notification1.url = @"https://example.com/update";
    self.notification1.iconUrl = @"https://example.com/icons/update_icon.png";
    self.notification1.mediaUrl = @"https://example.com/media/video.mp4";
    self.notification1.soundFilename = @"notification_sound.mp3";
    self.notification1.appBanner = @"https://example.com/banners/app_banner.png";
    self.notification1.inboxAppBanner = @"https://example.com/banners/inbox_banner.png";
    self.notification1.actions = @[@"Open", @"Dismiss"];
    self.notification1.customData = @{@"key1": @"value1", @"key2": @"value2"};
    self.notification1.carouselItems = @{@"item1": @"image1", @"item2": @"image2"};
    self.notification1.chatNotification = YES;
    self.notification1.carouselEnabled = NO;
    self.notification1.silent = NO;
    self.notification1.createdAt = [NSDate date];
    self.notification1.expiresAt = [NSDate dateWithTimeIntervalSinceNow:3600];

    self.notification2 = [[CPNotification alloc] init];
    self.notification2.id = @"456";
    self.notification2.tag = @"promotion";
    self.notification2.title = @"Flash Sale!";
    self.notification2.text = @"Hurry up! Flash sale happening now!";
    self.notification2.url = @"https://example.com/sale";
    self.notification2.iconUrl = @"https://example.com/icons/sale_icon.png";
    self.notification2.mediaUrl = @"https://example.com/media/image.jpg";
    self.notification2.soundFilename = @"sale_sound.mp3";
    self.notification2.appBanner = @"https://example.com/banners/sale_banner.png";
    self.notification2.inboxAppBanner = @"https://example.com/banners/inbox_sale_banner.png";
    self.notification2.actions = @[@"Shop Now", @"Remind Me"];
    self.notification2.customData = @{@"key3": @"value3", @"key4": @"value4"};
    self.notification2.carouselItems = @{@"item3": @"image3", @"item4": @"image4"};
    self.notification2.chatNotification = NO;
    self.notification2.carouselEnabled = YES;
    self.notification2.silent = YES;
    self.notification2.createdAt = [NSDate dateWithTimeIntervalSinceNow:-3600];
    self.notification2.expiresAt = [NSDate dateWithTimeIntervalSinceNow:7200];
}

- (void)testGetNotificationsReturnsExpectedData {
    NSArray<CPNotification *> *expectedNotifications = @[self.notification1, self.notification2];
    OCMStub([CleverPush getNotifications]).andReturn(expectedNotifications);
    NSArray<CPNotification *> *retrievedNotifications = [CleverPush getNotifications];
    XCTAssertEqualObjects(retrievedNotifications, expectedNotifications, @"Retrieved notifications should match the expected notifications");
}

- (void)testGetNotificationsReturnsUnexpectedData {
    NSArray<CPNotification *> *expectedNotifications = @[self.notification1, self.notification2];
    OCMStub([CleverPush getNotifications]).andReturn(expectedNotifications);
    NSArray<CPNotification *> *retrievedNotifications = [CleverPush getNotifications];
    XCTAssertNotEqualObjects(retrievedNotifications, expectedNotifications, @"Retrieved notifications should not match the expected notifications");
}

- (void)tearDown {
}

- (void)testExample {
}

- (void)testPerformanceExample {
    [self measureBlock:^{
    }];
}

@end
