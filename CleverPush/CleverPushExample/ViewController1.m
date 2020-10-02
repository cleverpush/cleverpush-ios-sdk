#import "ViewController1.h"
#import <CleverPush/CleverPush.h>

@interface ViewController1 ()

@end

@implementation ViewController1

- (IBAction)buttonClick:(id)sender {
    [CleverPush showTopicsDialog];
}

- (IBAction)switchChange:(id)sender {
    if ([sender isOn]) {
        [CleverPush subscribe];
    } else {
        [CleverPush unsubscribe];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CleverPush syncSubscription];
    
    [_mySwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    
    [_mySwitch setOn:[CleverPush isSubscribed]];
    
    [CleverPush trackPageView:@"https://www.rtl.de/cms/gzsz-anything" params:[NSDictionary dictionaryWithObjectsAndKeys: @"/rtl_portal/sendungen/gzsz", @"ivw", nil]];

    
    /*
    [CleverPush showAppBanners:^(NSString * url) {
        NSLog(@"CleverPush: Opened URL %@", url);
    }];
    */
    /*
    CPChatView *chatView = [[CPChatView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) urlOpenedCallback:^(NSURL *url) {
        NSLog(@"CleverPush URL Opened: %@", [url absoluteString]);
    }  subscribeCallback:^() {
           NSLog(@"CleverPush Subscribe Callback");
    } headerCodes:@"<style>  </style>"];
    */
    
    //[chatView loadChatWithSubscriptionId:@"F9MjLPCjRDyMSGqyu"];
    
    //[self.view addSubview:chatView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
