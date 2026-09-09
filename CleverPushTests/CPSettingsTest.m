@import XCTest;
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "CleverPush.h"
#import "CleverPushInstance.h"
#import "CleverPushUserDefaults.h"
#import "CPIabTcfMode.h"
#import "CPGroupNotificationSoundMode.h"

@interface CPSettingsTest : XCTestCase

@property (nonatomic, retain) CleverPushInstance *instance;

@end

@implementation CPSettingsTest

- (void)setUp {
    [super setUp];
    self.instance = [[CleverPushInstance alloc] init];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SUBSCRIPTION_PIANO_SEGMENTS_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_UNSUBSCRIBED_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_DESELECT_ALL_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SEEN_STORIES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.instance setApiEndpoint:@"https://api-mobile.cleverpush.com"];
    [super tearDown];
}

#pragma mark - API endpoint / app group

- (void)testSetAndGetApiEndpoint {
    [self.instance setApiEndpoint:@"https://api.example.com"];
    XCTAssertEqualObjects([self.instance getApiEndpoint], @"https://api.example.com");
}

- (void)testSetApiEndpointWithNilDoesNotCrash {
    XCTAssertNoThrow([self.instance setApiEndpoint:nil]);
}

- (void)testSetAndGetAppGroupIdentifierSuffix {
    [self.instance setAppGroupIdentifierSuffix:@".suffix"];
    XCTAssertEqualObjects([self.instance getAppGroupIdentifierSuffix], @".suffix");
}

#pragma mark - branding / tint

- (void)testSetAndGetBrandingColor {
    UIColor *color = [UIColor redColor];
    [self.instance setBrandingColor:color];
    XCTAssertEqualObjects([self.instance getBrandingColor], color);
}

- (void)testSetAndGetNormalTintColor {
    UIColor *color = [UIColor blueColor];
    [self.instance setNormalTintColor:color];
    XCTAssertEqualObjects([self.instance getNormalTintColor], color);
}

#pragma mark - IAB TCF / authorizer / top VC / banner style

- (void)testSetAndGetIabTcfMode {
    [self.instance setIabTcfMode:CPIabTcfModeTrackingWaitForConsent];
    XCTAssertEqual([self.instance getIabTcfMode], CPIabTcfModeTrackingWaitForConsent);
}

- (void)testSetIabTcfModeDisabled {
    [self.instance setIabTcfMode:CPIabTcfModeDisabled];
    XCTAssertEqual([self.instance getIabTcfMode], CPIabTcfModeDisabled);
}

- (void)testSetAuthorizerTokenDoesNotCrash {
    XCTAssertNoThrow([self.instance setAuthorizerToken:@"token-abc"]);
    XCTAssertNoThrow([self.instance setAuthorizerToken:nil]);
}

- (void)testSetAndGetCustomTopViewController {
    UIViewController *controller = [[UIViewController alloc] init];
    [self.instance setCustomTopViewController:controller];
    XCTAssertEqual([self.instance getCustomTopViewController], controller);
}

- (void)testSetCustomTopViewControllerNilClearsValue {
    [self.instance setCustomTopViewController:[[UIViewController alloc] init]];
    [self.instance setCustomTopViewController:nil];
    XCTAssertNil([self.instance getCustomTopViewController]);
}

- (void)testSetAndGetAppBannerModalPresentationStyle {
    [self.instance setAppBannerModalPresentationStyle:UIModalPresentationOverFullScreen];
    XCTAssertEqual([self.instance getAppBannerModalPresentationStyle], UIModalPresentationOverFullScreen);
}

#pragma mark - local event tracking retention

- (void)testSetAndGetLocalEventTrackingRetentionDays {
    [self.instance setLocalEventTrackingRetentionDays:14];
    XCTAssertEqual([self.instance getLocalEventTrackingRetentionDays], 14);
}

#pragma mark - language / country

- (void)testSetSubscriptionLanguageStoresValue {
    id mock = OCMPartialMock(self.instance);
    OCMStub([mock syncSubscription]);
    [mock setSubscriptionLanguage:@"de"];
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY], @"de");
    [mock stopMocking];
}

- (void)testSetSubscriptionCountryStoresValue {
    id mock = OCMPartialMock(self.instance);
    OCMStub([mock syncSubscription]);
    [mock setSubscriptionCountry:@"DE"];
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY], @"DE");
    [mock stopMocking];
}

#pragma mark - piano segments

- (void)testSetAndGetPianoSegments {
    id mock = OCMPartialMock(self.instance);
    OCMStub([mock syncSubscription]);
    [mock setPianoSegments:@[ @"seg-1", @"seg-2" ]];
    NSArray *segments = [mock getSubscriptionPianoSegments];
    XCTAssertEqual(segments.count, 2);
    XCTAssertTrue([segments containsObject:@"seg-1"]);
    [mock stopMocking];
}

- (void)testSetPianoSegmentsNilReturnsEmptyArray {
    id mock = OCMPartialMock(self.instance);
    OCMStub([mock syncSubscription]);
    [mock setPianoSegments:@[ @"seg-1" ]];
    [mock setPianoSegments:nil];
    XCTAssertEqual([mock getSubscriptionPianoSegments].count, 0);
    [mock stopMocking];
}

- (void)testGetSubscriptionPianoSegmentsReturnsEmptyInitially {
    XCTAssertEqual([self.instance getSubscriptionPianoSegments].count, 0);
}

#pragma mark - flags

- (void)testSetAndGetUnsubscribeStatus {
    [self.instance setUnsubscribeStatus:YES];
    XCTAssertTrue([self.instance getUnsubscribeStatus]);
    [self.instance setUnsubscribeStatus:NO];
    XCTAssertFalse([self.instance getUnsubscribeStatus]);
}

- (void)testSetAndGetSubscriptionChanged {
    [self.instance setSubscriptionChanged:YES];
    XCTAssertTrue([self.instance getSubscriptionChanged]);
    [self.instance setSubscriptionChanged:NO];
    XCTAssertFalse([self.instance getSubscriptionChanged]);
}

- (void)testSetAndGetAppBannerDraftsEnabled {
    [self.instance setAppBannerDraftsEnabled:YES];
    XCTAssertTrue([self.instance getAppBannerDraftsEnabled]);
    [self.instance setAppBannerDraftsEnabled:NO];
    XCTAssertFalse([self.instance getAppBannerDraftsEnabled]);
}

- (void)testSetAndGetHandleUrlFromSceneDelegate {
    [self.instance setHandleUrlFromSceneDelegate:YES];
    XCTAssertTrue([self.instance getHandleUrlFromSceneDelegate]);
    [self.instance setHandleUrlFromSceneDelegate:NO];
    XCTAssertFalse([self.instance getHandleUrlFromSceneDelegate]);
}

- (void)testUpdateDeselectFlagAndGetDeselectValue {
    [self.instance updateDeselectFlag:YES];
    XCTAssertTrue([self.instance getDeselectValue]);
    [self.instance updateDeselectFlag:NO];
    XCTAssertFalse([self.instance getDeselectValue]);
}

- (void)testGetDeselectValueReturnsFalseByDefault {
    XCTAssertFalse([self.instance getDeselectValue]);
}

- (void)testSetAutoClearBadgeAndGetAutoClearBadge {
    [self.instance setAutoClearBadge:YES];
    XCTAssertTrue([self.instance getAutoClearBadge]);
    [self.instance setAutoClearBadge:NO];
    XCTAssertFalse([self.instance getAutoClearBadge]);
}

- (void)testSetOpenWebViewEnabledDoesNotCrash {
    XCTAssertNoThrow([self.instance setOpenWebViewEnabled:YES]);
    XCTAssertNoThrow([self.instance setOpenWebViewEnabled:NO]);
}

- (void)testSetAutoResubscribeDoesNotCrash {
    XCTAssertNoThrow([self.instance setAutoResubscribe:YES]);
    XCTAssertNoThrow([self.instance setAutoResubscribe:NO]);
}

- (void)testSetIgnoreDisabledNotificationPermissionDoesNotCrash {
    XCTAssertNoThrow([self.instance setIgnoreDisabledNotificationPermission:YES]);
}

- (void)testSetAutoRequestNotificationPermissionDoesNotCrash {
    XCTAssertNoThrow([self.instance setAutoRequestNotificationPermission:NO]);
}

- (void)testSetProvisionalNotificationAuthorizationEnabledDoesNotCrash {
    XCTAssertNoThrow([self.instance setProvisionalNotificationAuthorizationEnabled:YES]);
}

- (void)testSetKeepTargetingDataOnUnsubscribeDoesNotCrash {
    XCTAssertNoThrow([self.instance setKeepTargetingDataOnUnsubscribe:YES]);
}

- (void)testSetIncrementBadgeDoesNotCrash {
    XCTAssertNoThrow([self.instance setIncrementBadge:YES]);
}

- (void)testSetShowNotificationsInForegroundDoesNotCrash {
    XCTAssertNoThrow([self.instance setShowNotificationsInForeground:NO]);
}

- (void)testSetDisplayAlertEnabledForNotificationsDoesNotCrash {
    XCTAssertNoThrow([self.instance setDisplayAlertEnabledForNotifications:YES]);
}

- (void)testSetSoundEnabledForNotificationsDoesNotCrash {
    XCTAssertNoThrow([self.instance setSoundEnabledForNotifications:NO]);
}

- (void)testSetBadgeCountEnabledForNotificationsDoesNotCrash {
    XCTAssertNoThrow([self.instance setBadgeCountEnabledForNotifications:YES]);
}

- (void)testSetGroupNotificationSoundModeDoesNotCrash {
    XCTAssertNoThrow([self.instance setGroupNotificationSoundMode:CPGroupNotificationSoundModeAllNotifications]);
}

#pragma mark - universal links / seen stories

- (void)testSetAndGetHandleUniversalLinksInAppForDomains {
    NSArray *domains = @[ @"example.com", @"cleverpush.com" ];
    [self.instance setHandleUniversalLinksInAppForDomains:domains];
    XCTAssertEqualObjects([self.instance getHandleUniversalLinksInAppForDomains], domains);
}

- (void)testSetHandleUniversalLinksInAppForDomainsNil {
    [self.instance setHandleUniversalLinksInAppForDomains:@[ @"a.com" ]];
    [self.instance setHandleUniversalLinksInAppForDomains:nil];
    XCTAssertNil([self.instance getHandleUniversalLinksInAppForDomains]);
}

- (void)testGetSeenStoriesReturnsEmptyArrayInitially {
    NSArray *stories = [self.instance getSeenStories];
    XCTAssertNotNil(stories);
    XCTAssertEqual(stories.count, 0);
}

- (void)testGetSeenStoriesReturnsStoredValues {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"story-1", @"story-2" ] forKey:CLEVERPUSH_SEEN_STORIES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSArray *stories = [self.instance getSeenStories];
    XCTAssertEqual(stories.count, 2);
    XCTAssertTrue([stories containsObject:@"story-1"]);
}

#pragma mark - other public setters

- (void)testSetTopicsDialogWindowDoesNotCrash {
    XCTAssertNoThrow([self.instance setTopicsDialogWindow:nil]);
}

- (void)testSetTopicsChangedListenerDoesNotCrash {
    XCTAssertNoThrow([self.instance setTopicsChangedListener:^{}]);
    XCTAssertNoThrow([self.instance setTopicsChangedListener:nil]);
}

- (void)testSetLogListenerDoesNotCrash {
    XCTAssertNoThrow([self.instance setLogListener:^(NSString * _Nullable message) {}]);
    XCTAssertNoThrow([self.instance setLogListener:nil]);
}

- (void)testSetConfirmAlertShownDoesNotCrash {
    XCTAssertNoThrow([self.instance setConfirmAlertShown]);
}

- (void)testIncreaseSessionVisitsDoesNotCrash {
    XCTAssertNoThrow([self.instance increaseSessionVisits]);
}

- (void)testPopupVisibleReturnsBool {
    XCTAssertNoThrow([self.instance popupVisible]);
}

- (void)testIsDevelopmentModeEnabledReturnsBool {
    XCTAssertFalse([self.instance isDevelopmentModeEnabled]);
}

- (void)testIsSubscribedReturnsFalseWithoutSubscription {
    [self.instance setSubscriptionId:nil];
    XCTAssertFalse([self.instance isSubscribed]);
}

- (void)testChannelIdCanBeNilOnFreshInstance {
    XCTAssertTrue([self.instance channelId] == nil || [[self.instance channelId] isKindOfClass:[NSString class]]);
}

- (void)testAddStoryViewWithNilDoesNotCrash {
    XCTAssertNoThrow([self.instance addStoryView:nil]);
}

- (void)testAddChatViewWithNilDoesNotCrash {
    XCTAssertNoThrow([self.instance addChatView:nil]);
}

- (void)testGetBadgeCountCallbackIsInvoked {
    XCTestExpectation *exp = [self expectationWithDescription:@"getBadgeCount"];
    [self.instance getBadgeCount:^(NSInteger count) {
        XCTAssertGreaterThanOrEqual(count, 0);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSetBadgeCountDoesNotCrash {
    XCTAssertNoThrow([self.instance setBadgeCount:0]);
}

@end
