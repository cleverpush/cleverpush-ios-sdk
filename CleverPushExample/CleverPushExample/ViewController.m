#import "ViewController.h"
#import <CleverPush/CleverPush.h>
#import "CleverPushExample-Swift.h"
@interface ViewController () <UITextFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doneButtonPressed)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.txtLiveActivityName.inputAccessoryView = keyboardToolbar;
}

#pragma mark - Button Actions
- (IBAction)btnHandlerStartLiveActivity:(id)sender {
    if (@available(iOS 13.0, *)) {
        NSString *activityName = [_txtLiveActivityName text];
        if (activityName && activityName.length) {
            [CPLiveActivityVC createActivityWithCompletionHandler:^(NSDictionary * liveActivityData) {
                if (liveActivityData != nil) {
                    [CleverPush startLiveActivity:[liveActivityData valueForKey:@"iosLiveActivityId"] pushToken:[liveActivityData valueForKey:@"iosLiveActivityToken"]];
                }
            }];
        }
    }
}

- (IBAction)btnHandlergetSubscriptionID:(id)sender {
    if ([CleverPush isSubscribed]) {
        self.lblStatusDisplay.text = [NSString stringWithFormat:@"Subscribiton id %@",[CleverPush getSubscriptionId]];
    } else {
        self.lblStatusDisplay.text = @"Subscription Status is No";
    }
}

- (IBAction)btnHandlerSubscribeOff:(id)sender {
    [CleverPush unsubscribe:^(BOOL issubscribe) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lblStatusDisplay.text = [NSString stringWithFormat:@"Subscribiton Status %@",[CleverPush isSubscribed] ? @"Yes" : @"No"];
        });
    }];
}

- (IBAction)btnHandlerSubscriptionOn:(id)sender {
    [CleverPush subscribe:^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lblStatusDisplay.text = [NSString stringWithFormat:@"Subscribiton Status %@",[CleverPush isSubscribed] ? @"Yes" : @"No"];
        });
    }];
}
- (IBAction)btnHandlerRemoveastNotification:(id)sender {
//    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
//
//        NSMutableSet<NSString *> *deliveredIdentifiers = [NSMutableSet set];
//        for (UNNotification *notification in notifications) {
//            if (notification.request.identifier != nil) {
//                [deliveredIdentifiers addObject:notification.request.identifier];
//            }
//        }
//
//        NSArray *cleverPushNotifications = [CleverPush getNotifications];
//        for (CPNotification *cpNotification in cleverPushNotifications) {
//            NSString *identifier = cpNotification.notificationIdentifier;
//            if (identifier != nil && [deliveredIdentifiers containsObject:identifier]) {
//                [center removeDeliveredNotificationsWithIdentifiers:@[identifier]];
//            }
//        }
//    }];
    
    NSArray *TT = [CleverPush getNotifications];
    [CleverPush removeNotification:[[TT objectAtIndex:0] valueForKey:@"_id"] removeFromNotificationCenter:YES];
}

- (IBAction)btnHandlerRemoveAllNotification:(id)sender {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
        NSMutableArray *identifiersToRemove = [NSMutableArray array];
        for (UNNotification *notification in notifications) {
            [identifiersToRemove addObject:notification.request.identifier];
        }

        [center removeDeliveredNotificationsWithIdentifiers:identifiersToRemove];
    }];
}

- (IBAction)btnHandlerGetNotificationCount:(id)sender
{
    NSArray *notifications = [CleverPush getNotifications];
    NSUInteger newCount = notifications.count;

    self.lblNotificationCount.text = [NSString stringWithFormat:@"Count = %lu", (unsigned long)newCount];

}

#pragma mark - Other Functions
-(void)doneButtonPressed {
    [self.txtLiveActivityName resignFirstResponder];
}
@end
