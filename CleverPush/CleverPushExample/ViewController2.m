#import "ViewController2.h"

#import <CleverPush/CleverPush.h>
#import <CleverPush/CPChatView.h>

@interface ViewController2 ()

@end

@implementation ViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CleverPush setBrandingColor:[UIColor blueColor]];
    
    NSSet *websiteDataTypes
    = [NSSet setWithArray:@[
                            WKWebsiteDataTypeDiskCache,
                            WKWebsiteDataTypeMemoryCache,
                            //WKWebsiteDataTypeLocalStorage,
                            //WKWebsiteDataTypeIndexedDBDatabases
                            ]];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
    }];

    CPChatView *chatView = [[CPChatView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) urlOpenedCallback:^(NSURL *url) {
        NSLog(@"CleverPush URL Opened: %@", [url absoluteString]);
    }  subscribeCallback:^() {
           NSLog(@"CleverPush Subscribe Callback");
    } headerCodes:@"<style>  </style>"];
    
    
    //[chatView loadChatWithSubscriptionId:@"F9MjLPCjRDyMSGqyu"];
    
    [self.view addSubview:chatView];
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        //[chatView lockChat];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
