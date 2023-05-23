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

    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    CPStoryView *storyView = [[CPStoryView alloc]
       initWithFrame:CGRectMake(0.0, 83.0, self.view.frame.size.width, 125.0)
                                   backgroundColor:[UIColor greenColor]
                                   textColor:[UIColor blackColor]
                                   fontFamily:@"AppleSDGothicNeo-Bold"
                                   borderColor:[UIColor redColor]
                                   titleVisibility:true
                                   titleTextSize:10
                                   storyIconHeight:75
                                   storyIconWidth:75
                                   widgetId:@"fSs24ggBjeZWjTWHZ"];

       [self.view addSubview:storyView];


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
