#import <UIKit/UIKit.h>
#import "UIImageView+CleverPush.h"
#import "CPNotification.h"
#import "CleverPush.h"

@interface CPInboxView : UIView <UITableViewDelegate, UITableViewDataSource>

typedef void (^CPNotificationClickBlock)(CPNotification* result);

@property (strong, nonatomic) UITableView *messageList;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) NSMutableArray<CPNotification*> *notifications;
@property (strong, nonatomic) NSMutableArray *readNotifications;
@property (nonatomic) BOOL combine_with_api;
@property (nonatomic, strong) UIColor *read_color;
@property (nonatomic, strong) UIColor *unread_color;
@property (nonatomic, strong) UIColor *notification_text_color;
@property (nonatomic, strong) NSString *notification_text_font_family;
@property (nonatomic, strong) UIColor *date_text_color;
@property (nonatomic, strong) NSString *date_text_font_family;
@property (nonatomic, strong) UIColor *divider_colour;
@property (nonatomic) int notification_text_size;
@property (nonatomic) int date_text_size;
@property (nonatomic, copy) CPNotificationClickBlock callback;
@property (nonatomic, strong) NSString *notificationThumbnail;


#pragma mark - Call back while banner has been open-up successfully

- (id)initWithFrame:(CGRect)frame combine_with_api:(BOOL)combine_with_api read_color:(UIColor *)read_color unread_color:(UIColor *)unread_color notification_text_color:(UIColor *)notification_text_color notification_text_font_family:(NSString *)notification_text_font_family notification_text_size:(int)notification_text_size date_text_color:(UIColor *)date_text_color date_text_font_family:(NSString *)date_text_font_family date_text_size:(int)date_text_size divider_colour:(UIColor *)divider_colour;
- (void)notificationClickCallback:(CPNotificationClickBlock)callback;

@end
