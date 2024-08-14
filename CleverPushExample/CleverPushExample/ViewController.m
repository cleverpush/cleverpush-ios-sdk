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

    _viewBG = [[UIView alloc] init];
    _viewBG.frame = CGRectMake(25, 100, self.view.frame.size.width - 50, 100);
    _viewBG.layer.cornerRadius = 10.0;
    CGFloat red = 198.0 / 255.0;
    CGFloat green = 226.0 / 255.0;
    CGFloat blue = 222.0 / 255.0;
    CGFloat alpha = 1.0;
    _viewBG.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];

    _SecondviewBG = [[UIView alloc] init];
    _SecondviewBG.frame = CGRectMake(25, 500, self.view.frame.size.width - 50, 250);
    _SecondviewBG.layer.cornerRadius = 10.0;
    red = 198.0 / 255.0;
    green = 226.0 / 255.0;
    blue = 222.0 / 255.0;
    alpha = 1.0;
    _SecondviewBG.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];

    _ThirdviewBG = [[UIView alloc] init];
    _ThirdviewBG.frame = CGRectMake(25, 700, self.view.frame.size.width - 50, 190);
    _ThirdviewBG.layer.cornerRadius = 10.0;
    red = 198.0 / 255.0;
    green = 226.0 / 255.0;
    blue = 222.0 / 255.0;
    alpha = 1.0;
    _ThirdviewBG.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];


    [self.view addSubview:_viewBG];
//    [self.view addSubview:_SecondviewBG];
//    [self.view addSubview:_ThirdviewBG];

}

#pragma mark - Button Actions
- (IBAction)btnHandlerStartLiveActivity:(id)sender {

    CPStoryView *storyView = [[CPStoryView alloc] initWithFrame:CGRectMake(15, 5.0, self.viewBG.frame.size.width - 30, 90) backgroundColor:[UIColor clearColor] textColor:[UIColor blackColor] fontFamily:@"AppleSDGothicNeo-Bold" borderColor:[UIColor yellowColor] titleVisibility:true titleTextSize:10 storyIconHeight:150 storyIconWidth:150 storyIconCornerRadius:10 storyIconSpacing:20 storyIconBorderVisibility:true storyIconBorderMargin:0 storyIconBorderWidth:2.5 storyIconShadow:true adjustToCollectionViewFrame:true unreadStoryCountVisibility:true unreadStoryCountBackgroundColor:[UIColor redColor] unreadStoryCountTextColor:[UIColor whiteColor] storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionInsideBottom storyWidgetShareButtonVisibility:false widgetId:@"CyELm3daayQGuSGTD"];

//    CPStoryView *storyView = [[CPStoryView alloc]
//    initWithFrame:CGRectMake(0.0, 83.0, self.view.frame.size.width, 125.0)
//                                backgroundColor:[UIColor greenColor]
//                                textColor:[UIColor blackColor]
//                                fontFamily:@"AppleSDGothicNeo-Bold"
//                                borderColor:[UIColor redColor]
//                                titleVisibility:true
//                                titleTextSize:10
//                                storyIconHeight:75
//                                storyIconWidth:105
//                                widgetId:@"CyELm3daayQGuSGTD"];


    [self.viewBG addSubview:storyView];

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

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_SEEN_STORIES_KEY];

    CPStoryView *storyView = [[CPStoryView alloc] initWithFrame:CGRectMake(15, 5.0, self.viewBG.frame.size.width - 30, 180) backgroundColor:[UIColor clearColor] textColor:[UIColor blackColor] fontFamily:@"AppleSDGothicNeo-Bold" borderColor:[UIColor greenColor] titleVisibility:true titleTextSize:8 storyIconHeight:70 storyIconWidth:50 storyIconCornerRadius:20 storyIconSpacing:20 storyIconBorderVisibility:true storyIconBorderMargin:0 storyIconBorderWidth:5 storyIconShadow:true adjustToCollectionViewFrame:true unreadStoryCountVisibility:true unreadStoryCountBackgroundColor:[UIColor yellowColor] unreadStoryCountTextColor:[UIColor blackColor] storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionInsideBottom storyWidgetShareButtonVisibility:false widgetId:@"RRqT6fhhKRPrctEqm"];

    [self.SecondviewBG addSubview:storyView];

    if ([CleverPush isSubscribed]) {
        NSLog(@"Subscription id = %@",[CleverPush getSubscriptionId]);
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
