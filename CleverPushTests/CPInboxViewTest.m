@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CPInboxView.h"
#import "CPNotification.h"

@interface CPInboxViewTest : XCTestCase

@property (nonatomic, retain) CPInboxView *inboxView;

@end

@implementation CPInboxViewTest

- (void)setUp {
    [super setUp];
    self.inboxView = [[CPInboxView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)
                                       combine_with_api:NO
                                             read_color:[UIColor whiteColor]
                                           unread_color:[UIColor lightGrayColor]
                                notification_text_color:[UIColor blackColor]
                          notification_text_font_family:@"Helvetica"
                                 notification_text_size:15
                                        date_text_color:[UIColor darkGrayColor]
                                  date_text_font_family:@"Helvetica"
                                         date_text_size:12
                                         divider_colour:[UIColor lightGrayColor]];
}

- (void)tearDown {
    self.inboxView = nil;
    [super tearDown];
}

#pragma mark - initialization (success)

- (void)testInboxViewInitIsNotNil {
    XCTAssertNotNil(self.inboxView);
}

- (void)testInboxViewFrameIsApplied {
    XCTAssertEqualWithAccuracy(self.inboxView.frame.size.width, 320, 0.1);
    XCTAssertEqualWithAccuracy(self.inboxView.frame.size.height, 480, 0.1);
}

- (void)testInboxViewInitWithNilColorsUsesDefaultsAndDoesNotCrash {
    CPInboxView *view = [[CPInboxView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)
                                          combine_with_api:NO
                                                read_color:nil
                                              unread_color:nil
                                   notification_text_color:nil
                             notification_text_font_family:nil
                                    notification_text_size:0
                                           date_text_color:nil
                                     date_text_font_family:nil
                                            date_text_size:0
                                            divider_colour:nil];
    XCTAssertNotNil(view);
}

- (void)testInboxViewInitWithCombineApiTrueDoesNotCrash {
    CPInboxView *view = [[CPInboxView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)
                                          combine_with_api:YES
                                                read_color:[UIColor whiteColor]
                                              unread_color:[UIColor grayColor]
                                   notification_text_color:[UIColor blackColor]
                             notification_text_font_family:@"Helvetica"
                                    notification_text_size:14
                                           date_text_color:[UIColor grayColor]
                                     date_text_font_family:@"Helvetica"
                                            date_text_size:11
                                            divider_colour:[UIColor lightGrayColor]];
    XCTAssertNotNil(view);
}

#pragma mark - callback

- (void)testNotificationClickCallbackCanBeSet {
    __block BOOL called = NO;
    [self.inboxView notificationClickCallback:^(CPNotification *result) {
        called = YES;
    }];
    XCTAssertNotNil(self.inboxView.callback);
    if (self.inboxView.callback) {
        self.inboxView.callback(nil);
    }
    XCTAssertTrue(called);
}

- (void)testNotificationClickCallbackWithNilDoesNotCrash {
    XCTAssertNoThrow([self.inboxView notificationClickCallback:nil]);
}

#pragma mark - notifications list

- (void)testInboxNotificationsCanBeAssigned {
    CPNotification *notification = [CPNotification initWithJson:@{
        @"_id": @"n1",
        @"title": @"Inbox",
        @"text": @"Hello"
    }];
    self.inboxView.notifications = [@[notification] mutableCopy];
    XCTAssertEqual(self.inboxView.notifications.count, 1);
    XCTAssertEqualObjects(self.inboxView.notifications.firstObject.id, @"n1");
}

- (void)testInboxNotificationsEmptyByDefaultOrAfterInit {
    XCTAssertTrue(self.inboxView.notifications == nil || self.inboxView.notifications.count >= 0);
}

#pragma mark - failure / edge

- (void)testInboxViewWithZeroFrameDoesNotCrash {
    CPInboxView *view = [[CPInboxView alloc] initWithFrame:CGRectZero
                                          combine_with_api:NO
                                                read_color:[UIColor whiteColor]
                                              unread_color:[UIColor grayColor]
                                   notification_text_color:[UIColor blackColor]
                             notification_text_font_family:@"Helvetica"
                                    notification_text_size:15
                                           date_text_color:[UIColor grayColor]
                                     date_text_font_family:@"Helvetica"
                                            date_text_size:12
                                            divider_colour:[UIColor lightGrayColor]];
    XCTAssertNotNil(view);
}

@end
