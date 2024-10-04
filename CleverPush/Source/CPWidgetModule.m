#import "CPWidgetModule.h"
#import "CPUtils.h"
#import "CPLog.h"

@interface CPWidgetModule()
@end

@implementation CPWidgetModule

#pragma mark - Get the Widgets & Stories details by api call and load the Widgets & Stories data in to class variables
+ (void)getWidgetsStories:(NSString*)widgetId completion:(void(^)(CPWidgetsStories *))callback {
    NSString* widgetsPath = [NSString stringWithFormat:@"story-widget/%@/config?platform=app", widgetId];
    if ([CleverPush isDevelopmentModeEnabled]) {
        widgetsPath = [NSString stringWithFormat:@"%@?t=%f", widgetsPath, NSDate.date.timeIntervalSince1970];
    }

    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_GET path:widgetsPath];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* result) {
        if (result != nil) {
            CPWidgetsStories *widgets = [[CPWidgetsStories alloc] initWithJson:result];
            if (widgets != nil) {
                callback(widgets);
                return;
            }
        }
    } onFailure:^(NSError* error) {
        [CPLog error:@"Failed getting widgets stories %@", error];
    }];
}

+ (void)trackWidgetOpened:(NSString*)widgetId withStories:(NSArray<NSString*>*)stories onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    NSString* widgetsPath = [NSString stringWithFormat:@"story-widget/%@/track-opened", widgetId];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:widgetsPath];
        NSDictionary* dataDic = @{
        @"stories": stories
    };
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* results) {
        if (successBlock) {
            successBlock(results);
        }
    } onFailure:^(NSError* error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

+ (void)trackWidgetShown:(NSString*)widgetId withStories:(NSArray<NSString*>*)stories onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock {
    NSString* widgetsPath = [NSString stringWithFormat:@"story-widget/%@/track-shown", widgetId];
    NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:HTTP_POST path:widgetsPath];
        NSDictionary* dataDic = @{
        @"stories": stories
    };
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    [request setHTTPBody:postData];
    [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* results) {
        if (successBlock) {
            successBlock(results);
        }
    } onFailure:^(NSError* error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

@end
