#import "CPWidgetModule.h"
@interface CPWidgetModule()
@end

@implementation CPWidgetModule

#pragma mark - Get the Widgets & Stories details by api call and load the Widgets & Stories data in to class variables
+ (void)getWidgetsStories:(NSString*)widgetId completion:(void(^)(CPWidgetsStories *))callback {
    NSString* widgetsPath = [NSString stringWithFormat:@"story-widget/%@/config", widgetId];
    if ([CleverPush isDevelopmentModeEnabled]) {
        widgetsPath = [NSString stringWithFormat:@"%@&t=%f", widgetsPath, NSDate.date.timeIntervalSince1970];
    }
    
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"GET" path:widgetsPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            CPWidgetsStories *widgets = [[CPWidgetsStories alloc] initWithJson:result];
            if (widgets != nil) {
                callback(widgets);
                return;
            }
        }
    } onFailure:^(NSError* error) {
        NSLog(@"CleverPush Error: Failed getting widgets stories %@", error);
    }];
}
@end

