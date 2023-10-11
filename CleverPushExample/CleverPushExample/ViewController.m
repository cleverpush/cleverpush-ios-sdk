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

    [CleverPush showAppBanner:@"CkmdcezjiA4MD4tnn"];


    return;

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
