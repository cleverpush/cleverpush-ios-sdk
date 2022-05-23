#import <UIKit/UIKit.h>
#import "CleverPush.h"
#import "CPInboxView.h"
#import "CPInboxCell.h"
#import "CPTranslate.h"
#import "NSDictionary+SafeExpectations.h"

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
                        NSString *channelIcon = [config stringForKey:@"channelIcon"];
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
    }
    return self;
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
        NSLog(@"CleverPush: Font Family not found");
        [cell.notificationTitle setFont:[UIFont systemFontOfSize:(CGFloat)(10.0) weight:UIFontWeightSemibold]];
    }
    
    cell.notificationDate.text = [CPUtils timeAgoStringFromDate:self.notifications[indexPath.row].createdAt];
    cell.notificationDate.textColor = self.date_text_color;
    
    if (self.date_text_font_family && [self.date_text_font_family length] > 0 && [CPUtils fontFamilyExists:self.date_text_font_family] && self.date_text_size != 0) {
        [cell.notificationDate setFont:[UIFont fontWithName:self.date_text_font_family size:(CGFloat)(self.date_text_size)]];
    } else {
        NSLog(@"CleverPush: Font Family not found");
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

@end
