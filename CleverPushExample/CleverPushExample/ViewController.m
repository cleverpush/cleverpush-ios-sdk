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

    CPInboxView *inboxView = [[CPInboxView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                  combine_with_api:NO
                                                        read_color:UIColor.whiteColor
                                                      unread_color:UIColor.lightGrayColor
                                           notification_text_color:UIColor.blackColor
                                     notification_text_font_family:@"AppleSDGothicNeo-Reguler"
                                            notification_text_size:17
                                                   date_text_color:UIColor.blackColor
                                             date_text_font_family:@"AppleSDGothicNeo-Reguler"
                                                    date_text_size:12
                                                    divider_colour:UIColor.blackColor];
        [self.view addSubview:inboxView];



    
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

#pragma mark - Other Functions
-(void)doneButtonPressed
{
    [self.txtLiveActivityName resignFirstResponder];
}
@end
