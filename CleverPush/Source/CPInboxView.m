#import <UIKit/UIKit.h>
#import "CleverPush.h"
#import "CPInboxView.h"
#import "CPInboxCell.h"
#import "CPTranslate.h"
#import "NSDictionary+SafeExpectations.h"
#import "CPLog.h"
#import "CPInboxDetailView.h"

@implementation CPInboxView

CPNotificationClickBlock handleClick;

#pragma mark - Initialise the Widgets with UICollectionView frame
- (id)initWithFrame:(CGRect)frame combine_with_api:(BOOL)combine_with_api read_color:(UIColor *)read_color unread_color:(UIColor *)unread_color notification_text_color:(UIColor *)notification_text_color notification_text_font_family:(NSString *)notification_text_font_family notification_text_size:(int)notification_text_size date_text_color:(UIColor *)date_text_color date_text_font_family:(NSString *)date_text_font_family date_text_size:(int)date_text_size divider_colour:(UIColor *)divider_colour {
    self = [super initWithFrame:frame];
    if (self) {
        if ([CleverPush channelId] != nil && [CleverPush channelId].length != 0) {
            [CleverPush getNotifications:combine_with_api callback:^(NSArray *notificationsList) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    self.notifications = [[NSMutableArray alloc]initWithArray:notificationsList];
                    self.readNotifications = [[NSMutableArray alloc]initWithArray:[self getReadNotifications]];
                    if (combine_with_api) {
                        self.combine_with_api = combine_with_api;
                    }

                    if (read_color != nil) {
                        self.read_color = read_color;
                    } else {
                        self.read_color = [UIColor whiteColor];
                    }

                    if (unread_color != nil) {
                        self.unread_color = unread_color;
                    } else {
                        self.unread_color = [UIColor lightGrayColor];
                    }

                    if (notification_text_color != nil) {
                        self.notification_text_color = notification_text_color;
                    } else {
                        self.notification_text_color = [UIColor blackColor];
                    }

                    if (notification_text_font_family != nil && notification_text_font_family.length != 0) {
                        self.notification_text_font_family = notification_text_font_family;
                    } else {
                        self.notification_text_font_family = @"AppleSDGothicNeo-Regular";
                    }

                    if (notification_text_size != 0) {
                        self.notification_text_size = notification_text_size;
                    } else {
                        self.notification_text_size = 15.0;
                    }

                    if (date_text_color != nil) {
                        self.date_text_color = date_text_color;
                    } else {
                        self.date_text_color = [UIColor darkGrayColor];
                    }

                    if (date_text_font_family != nil && date_text_font_family.length != 0) {
                        self.date_text_font_family = date_text_font_family;
                    } else {
                        self.date_text_font_family = @"AppleSDGothicNeo-Regular";
                    }

                    if (date_text_size != 0) {
                        self.date_text_size = date_text_size;
                    } else {
                        self.date_text_size = 12.0;
                    }

                    if (divider_colour != nil) {
                        self.divider_colour = divider_colour;
                    } else {
                        self.divider_colour = [UIColor lightGrayColor];
                    }

                    [CleverPush getChannelConfig:^(NSDictionary *config) {
                        NSString *channelIcon = [config cleverPushStringForKey:@"channelIcon"];
                        if (channelIcon != nil && ![channelIcon isKindOfClass:[NSNull class]]) {
                            self.notificationThumbnail = channelIcon;
                        }
                    }];
                    self.messageList = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
                    NSBundle *bundle = [CPUtils getAssetsBundle];
                    if (bundle) {
                        UINib *nib = [UINib nibWithNibName:@"CPInboxCell" bundle:bundle];
                        [[self messageList] registerNib:nib forCellReuseIdentifier:@"CPInboxCell"];
                    }
                    self.messageList.backgroundColor = UIColor.clearColor;
                    self.messageList.directionalLockEnabled = YES;
                    [self.messageList setSeparatorColor:self.divider_colour];
                    [self.messageList setDataSource:self];
                    [self.messageList setDelegate:self];
                    [self addSubview:self.messageList];
                    if (self.notifications.count == 0) {
                        [self presentEmptyView:frame];
                    }
                });

            }];
        } else {
            [self presentEmptyView:frame];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(getCurrentAppBannerPageIndex:)
                                                             name:@"getCurrentAppBannerPageIndexValue"
                                                           object:nil];
    }
    return self;
}

#pragma mark - Release memories of currentAppBanner
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentEmptyView:(CGRect)frame {
    self.emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , 125.0)];
    UILabel *emptyString = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
    self.emptyView.backgroundColor = self.unread_color;
    emptyString.text = [CPTranslate translate:@"notificationsEmpty"];
    [emptyString setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Bold" size:(CGFloat)(17.0)]];
    emptyString.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyString];
    [self addSubview:self.emptyView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CPInboxCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CPInboxCell"];
    cell.imageThumbnail.layer.cornerRadius = 5;
    cell.imageThumbnail.layer.masksToBounds = true;
    NSString *thumbnail;
    cell.activityIndicator.color = self.notification_text_color;
    [cell.activityIndicator startAnimating];
    if (@available(iOS 13.0, *)) {
        cell.activityIndicator.activityIndicatorViewStyle =  UIActivityIndicatorViewStyleMedium;
    } else {
        cell.activityIndicator.activityIndicatorViewStyle =  UIActivityIndicatorViewStyleGray;
    }

    if (self.notifications[indexPath.row].mediaUrl != nil && ![self.notifications[indexPath.row].mediaUrl isKindOfClass:[NSNull class]]) {
        thumbnail = self.notifications[indexPath.row].mediaUrl;
    } else if (self.notifications[indexPath.row].iconUrl != nil && ![self.notifications[indexPath.row].iconUrl isKindOfClass:[NSNull class]]) {
        thumbnail = self.notifications[indexPath.row].iconUrl;
    } else {
        thumbnail = self.notificationThumbnail;
    }

    if (thumbnail != nil) {
        [cell.imageThumbnail setImageWithURL:[NSURL URLWithString:thumbnail] callback:^(BOOL callback) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [cell.activityIndicator stopAnimating];
            });
        }];
    }

    cell.notificationTitle.text = self.notifications[indexPath.row].title;
    cell.notificationTitle.textColor = self.notification_text_color;

    if (self.notification_text_font_family && [self.notification_text_font_family length] > 0 && [CPUtils fontFamilyExists:self.notification_text_font_family] && self.notification_text_size != 0) {
        [cell.notificationTitle setFont:[UIFont fontWithName:self.notification_text_font_family size:(CGFloat)(self.notification_text_size)]];
    } else {
        [CPLog error:@"Font Family not found %@", self.notification_text_font_family];
        [cell.notificationTitle setFont:[UIFont systemFontOfSize:(CGFloat)(10.0) weight:UIFontWeightSemibold]];
    }

    cell.notificationDate.text = [CPUtils timeAgoStringFromDate:self.notifications[indexPath.row].createdAt];
    cell.notificationDate.textColor = self.date_text_color;

    if (self.date_text_font_family && [self.date_text_font_family length] > 0 && [CPUtils fontFamilyExists:self.date_text_font_family] && self.date_text_size != 0) {
        [cell.notificationDate setFont:[UIFont fontWithName:self.date_text_font_family size:(CGFloat)(self.date_text_size)]];
    } else {
        [CPLog error:@"Font Family not found %@", self.date_text_font_family];
        [cell.notificationDate setFont:[UIFont systemFontOfSize:(CGFloat)(10.0) weight:UIFontWeightSemibold]];
    }

    if (![self.readNotifications containsObject:self.notifications[indexPath.row].id]) {
        cell.backgroundColor = self.read_color;
    } else {
        cell.backgroundColor = self.unread_color;
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.notifications == nil || self.notifications.count == 0) {
        return 0;
    }
    return self.notifications.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  UITableViewAutomaticDimension;
}

#pragma mark - Call back while clicked on the notification
- (void)notificationClickCallback:(CPNotificationClickBlock)callback{
    handleClick = callback;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.readNotifications containsObject:self.notifications[indexPath.row].id]) {
        [self.readNotifications addObject:self.notifications[indexPath.row].id];
        [self saveReadNotifications:self.readNotifications];
        [self.messageList reloadData];
    }
    if (handleClick) {
        handleClick(self.notifications[indexPath.row]);
    }

    if (self.notifications[indexPath.row].inboxAppBanner != nil && ![self.notifications[indexPath.row].inboxAppBanner isKindOfClass:[NSNull class]] )  {
        [self showAppBanner:self.notifications[indexPath.row].inboxAppBanner notificationId:self.notifications[indexPath.row].id];
    }
    
    NSString* path = [NSString stringWithFormat:@"/channel/%@/panel/clicked", [CleverPush channelId]];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:path];
    
    NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             [CleverPush channelId], @"channelId",
                             self.notifications[indexPath.row].id, @"notificationId",
                             nil];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    
    [CleverPush enqueueRequest:request onSuccess:nil onFailure:^(NSError* error) {
        [CPLog debug:@"Failed sending notification click event %@", error];
    }];
}

- (void)saveReadNotifications:(NSMutableArray *)readNotifications{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:readNotifications forKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
    [defaults synchronize];
}

- (NSArray *)getReadNotifications {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* readNotifications = [userDefaults arrayForKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
    if (!readNotifications) {
        return [[NSArray alloc] init];
    }
    return readNotifications;
}

#pragma mark - Get the value of pageControl from current index
- (void)getCurrentAppBannerPageIndex:(NSNotification *)notification {
    NSDictionary *pagevalue = notification.userInfo;
    self.currentScreenIndex = [pagevalue[@"currentIndex"] integerValue];
    CPAppBanner *appBanner = pagevalue[@"appBanner"];
    [self sendBannerEvent:@"delivered" forBanner:appBanner forScreen:nil forButtonBlock:nil forImageBlock:nil blockType:nil];
}

#pragma mark - Show app banner using the bannerId
- (void)showAppBanner:(NSString *)bannerId notificationId:(NSString*)notificationId {
    [self showBanner:[CleverPush channelId] bannerId:bannerId notificationId:notificationId force:YES];
}

- (void)presentAppBanner:(CPInboxDetailView*)appBannerViewController  banner:(CPAppBanner*)banner {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [appBannerViewController setModalPresentationStyle:[CleverPush getAppBannerModalPresentationStyle]];
    [appBannerViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    appBannerViewController.data = banner;

    UIViewController* topController = [CleverPush topViewController];
    [topController presentViewController:appBannerViewController animated:YES completion:nil];

    if (banner.dismissType == CPAppBannerDismissTypeTimeout) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (long)banner.dismissTimeout), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [appBannerViewController onDismiss];
        });
    }
    [self sendBannerEvent:@"delivered" forBanner:banner forScreen:nil forButtonBlock:nil forImageBlock:nil blockType:nil];
}

- (void)showBanner:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId force:(BOOL)force {
    [self getBanners:channelId bannerId:bannerId notificationId:notificationId groupId:nil completion:^(NSMutableArray<CPAppBanner *> *banners) {
        for (NSDictionary* json in banners) {
            CPAppBanner* banner = [[CPAppBanner alloc] initWithJson:json];
            [self showBanner:banner force:force];
        }
    }];
}

- (void)showBanner:(CPAppBanner*)banner force:(BOOL)force {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSBundle *bundle = [CPUtils getAssetsBundle];
        CPInboxDetailView *appBannerViewController;
        if (bundle) {
            appBannerViewController = [[CPInboxDetailView alloc] initWithNibName:@"CPInboxDetailView" bundle:bundle];
        } else {
            appBannerViewController = [[CPInboxDetailView alloc] initWithNibName:@"CPInboxDetailView" bundle:[NSBundle mainBundle]];
        }

        __strong CPAppBannerActionBlock callbackBlock = ^(CPAppBannerAction* action) {
            CPAppBannerCarouselBlock *screens = [[CPAppBannerCarouselBlock alloc] init];
            CPAppBannerButtonBlock *buttons = [[CPAppBannerButtonBlock alloc] init];
            CPAppBannerImageBlock *images = [[CPAppBannerImageBlock alloc] init];
            NSMutableArray *buttonBlocks  = [[NSMutableArray alloc] init];
            NSMutableArray *imageBlocks  = [[NSMutableArray alloc] init];
            NSString *type;
            NSString *voucherCode;

            for (CPAppBannerCarouselBlock *screensList in banner.screens) {
                if (!screensList.isScreenClicked) {
                    screens = screensList;
                    break;
                }
            }
            for (CPAppBannerBlock *bannerBlock in screens.blocks) {
                if (bannerBlock.type == CPAppBannerBlockTypeButton) {
                    [buttonBlocks addObject:(CPAppBannerBlock*)bannerBlock];
                } else if (bannerBlock.type == CPAppBannerBlockTypeImage) {
                    [imageBlocks addObject:(CPAppBannerBlock*)bannerBlock];
                }
            }
            for (CPAppBannerButtonBlock *button in buttonBlocks) {
                if ([button.id isEqualToString:action.blockId]) {
                    buttons = (CPAppBannerButtonBlock*)button;
                    type = @"button";
                    break;
                }
            }
            for (CPAppBannerImageBlock *image in imageBlocks) {
                if ([image.id isEqualToString:action.blockId]) {
                    images = (CPAppBannerImageBlock*)image;
                    type = @"image";
                    break;
                }
            }

            if ([type isEqualToString:@"button"]) {
                if (screens != nil && buttons != nil) {
                    [self sendBannerEvent:@"clicked" forBanner:banner forScreen:screens forButtonBlock:buttons forImageBlock:nil blockType:type];
                }
            } else if ([type isEqualToString:@"image"]) {
                if (screens != nil && images != nil) {
                    [self sendBannerEvent:@"clicked" forBanner:banner forScreen:screens forButtonBlock:nil forImageBlock:images blockType:type];
                }
            }

            if (self.handleBannerOpened && action) {
                self.handleBannerOpened(action);
            }

            if (action && [action.type isEqualToString:@"url"] && action.url != nil && action.openBySystem) {
                [[UIApplication sharedApplication] openURL:action.url options:@{} completionHandler:nil];
            }

            if (action && [action.type isEqualToString:@"subscribe"]) {
                [CleverPush subscribe];
            }

            if (action && [action.type isEqualToString:@"addTags"]) {
                [CleverPush addSubscriptionTags:action.tags];
            }

            if (action && [action.type isEqualToString:@"removeTags"]) {
                [CleverPush removeSubscriptionTags:action.tags];
            }

            if (action && [action.type isEqualToString:@"addTopics"]) {
                NSMutableArray *topics = [NSMutableArray arrayWithArray:[CleverPush getSubscriptionTopics]];
                for (NSString *topic in action.topics) {
                    if (![topics containsObject:topic]) {
                        [topics addObject:topic];
                    }
                }
                [CleverPush setSubscriptionTopics:topics];
            }

            if (action && [action.type isEqualToString:@"removeTopics"]) {
                NSMutableArray *topics = [NSMutableArray arrayWithArray:[CleverPush getSubscriptionTopics]];
                for (NSString *topic in action.topics) {
                    if ([topics containsObject:topic]) {
                        [topics removeObject:topic];
                    }
                }
                [CleverPush setSubscriptionTopics:topics];
            }

            if (action && [action.type isEqualToString:@"setAttribute"]) {
                [CleverPush setSubscriptionAttribute:action.attributeId value:action.attributeValue];
            }

            if (action && [action.type isEqualToString:@"copyToClipboard"]) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = action.name;
                voucherCode = [CPUtils valueForKey:banner.id inDictionary:[CPAppBannerModuleInstance getCurrentVoucherCodePlaceholder]];
                if (![CPUtils isNullOrEmpty:voucherCode]) {
                    pasteboard.string = voucherCode;
                }
            }

            if (action && [action.type isEqualToString:@"geoLocation"]) {
                Class cleverPushLocationClass = NSClassFromString(@"CleverPushLocation");

                if (cleverPushLocationClass) {
                    SEL selector = NSSelectorFromString(@"requestLocationPermission");

                    if ([cleverPushLocationClass respondsToSelector:selector]) {
                        [cleverPushLocationClass performSelector:selector withObject:nil afterDelay:0];
                    }
                } else {
                    [CPLog error:@"CleverPushLocation framework not found. Please ensure that CleverPushLocation framework is correctly integrated."];
                }
            }

            if (action && [action.type isEqualToString:@"trackEvent"]) {
                if (action.eventData.count > 0) {
                    if (action.eventProperties.count > 0) {
                        NSMutableDictionary *propertiesDict = [NSMutableDictionary dictionary];
                        for (NSDictionary *obj in action.eventProperties) {
                            NSString *key = [obj objectForKey:@"property"];
                            id value = [obj objectForKey:@"value"];
                            if (key && value) {
                                [propertiesDict setObject:value forKey:key];
                            }
                        }
                        [CleverPush trackEvent:[action.eventData objectForKey:@"name"] properties:propertiesDict];
                    } else {
                        if (![CPUtils isNullOrEmpty:[action.eventData objectForKey:@"name"]]) {
                            [CleverPush trackEvent:[action.eventData objectForKey:@"name"]];
                        }
                    }
                }
            }
        };
        [appBannerViewController setActionCallback:callbackBlock];
        [self presentAppBanner:appBannerViewController banner:banner];
    });
}

#pragma mark - Get the banner details by api call and load the banner data in to class variables
- (void)getBanners:(NSString*)channelId bannerId:(NSString*)bannerId notificationId:(NSString*)notificationId groupId:(NSString*)groupId completion:(void(^)(NSMutableArray<CPAppBanner*>*))callback {
    NSString* bannersPath = [NSString stringWithFormat:@"channel/%@/app-banners?platformName=iOS", channelId];

    if ([CleverPush isDevelopmentModeEnabled]) {
        bannersPath = [NSString stringWithFormat:@"%@&t=%f", bannersPath, NSDate.date.timeIntervalSince1970];
    }

    if (notificationId != nil) {
        bannersPath = [NSString stringWithFormat:@"%@&notificationId=%@", bannersPath, notificationId];
    }

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:bannersPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        NSMutableArray *jsonBanners = [[NSMutableArray alloc] init];

        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF contains '%@'", bannerId]]]];
        jsonBanners = [[[result objectForKey:@"banners"] filteredArrayUsingPredicate:predicate] mutableCopy];


        if (jsonBanners != nil) {
            if (notificationId && callback) {
                callback(jsonBanners);
            }

        }
    } onFailure:^(NSError* error) {
        [CPLog error:@"Failed getting app banners %@", error];
    }];
}

- (void)sendBannerEvent:(NSString*)event forBanner:(CPAppBanner*)banner forScreen:(CPAppBannerCarouselBlock*)screen forButtonBlock:(CPAppBannerButtonBlock*)block forImageBlock:(CPAppBannerImageBlock*)image blockType:(NSString*)type {


    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:[NSString stringWithFormat:@"app-banner/event/%@", event]];

    NSString* subscriptionId = nil;
    if ([CleverPush isSubscribed]) {
        subscriptionId = [CleverPush getSubscriptionId];
    } else {
        [CPLog debug:@"CPInboxView: sendBannerEvent: There is no subscription for CleverPush SDK."];
    }
    NSMutableDictionary* dataDic = [[NSMutableDictionary alloc]init];
    if (banner.testId != nil) {
        dataDic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    banner.id, @"bannerId",
                    banner.channel, @"channelId",
                    banner.testId, @"testId",
                    subscriptionId, @"subscriptionId",
                    nil] mutableCopy];
    } else {
        dataDic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    banner.id, @"bannerId",
                    banner.channel, @"channelId",
                    subscriptionId, @"subscriptionId",
                    nil] mutableCopy];
    }

    if ([event isEqualToString:@"clicked"]) {
        if ([type isEqualToString:@"button"]) {
            if (block != nil) {
                if (block.id != nil) {
                    [dataDic setObject:block.id forKey:@"blockId"];
                }
                if ((banner.screens != nil && banner.screens.count > 0) && banner.multipleScreensEnabled) {
                    [dataDic setObject:banner.screens[self.currentScreenIndex].id forKey:@"screenId"];
                }
                dataDic[@"isElementAlreadyClicked"] = @(block.isButtonClicked);
            }
        } else  if ([type isEqualToString:@"image"]) {
            if (image != nil) {
                if (image.id != nil) {
                    [dataDic setObject:image.id forKey:@"blockId"];
                }
                if ((banner.screens != nil && banner.screens.count > 0) && banner.multipleScreensEnabled) {
                    [dataDic setObject:banner.screens[self.currentScreenIndex].id forKey:@"screenId"];
                }
                dataDic[@"isElementAlreadyClicked"] = @(image.isimageClicked);
            }
        }

        [CPLog info:@"sendBannerEvent: %@ %@", event, dataDic];
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
            ([type isEqualToString:@"button"]) ? (block.isButtonClicked = YES) : (image.isimageClicked = YES);

            if ([dataDic valueForKey:@"screenId"] != nil && ![[dataDic valueForKey:@"screenId"]  isEqual: @""]) {
                    screen.isScreenClicked = true;
            }
        } onFailure:nil withRetry:NO];
    } else {
        if (banner.multipleScreensEnabled) {
            dataDic[@"isScreenAlreadyShown"] = @(banner.screens[self.currentScreenIndex].isScreenAlreadyShown);
            [dataDic setObject:banner.screens[self.currentScreenIndex].id forKey:@"screenId"];
        } else {
            dataDic[@"isScreenAlreadyShown"] = @(false);
        }

        [CPLog info:@"sendBannerEvent: %@ %@", event, dataDic];
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
            if (banner.multipleScreensEnabled) {
                banner.screens[self.currentScreenIndex].isScreenAlreadyShown = true;
            }
        } onFailure:nil];
    }
}

@end
