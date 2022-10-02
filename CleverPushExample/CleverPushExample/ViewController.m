#import "ViewController.h"
#import <CleverPush/CleverPush.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
@end
