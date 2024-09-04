#import <Foundation/Foundation.h>
#import "CPWidgetsStories.h"
#import "CleverPush.h"
NS_ASSUME_NONNULL_BEGIN
@interface CPWidgetModule : NSObject

+ (void)getWidgetsStories:(NSString*)widgetId completion:(void(^)(CPWidgetsStories *))callback;
+ (void)trackWidgetOpened:(NSString*)widgetId withStories:(NSArray<NSString*>*)stories onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;
+ (void)trackWidgetShown:(NSString*)widgetId withStories:(NSArray<NSString*>*)stories onSuccess:(CPResultSuccessBlock _Nullable)successBlock onFailure:(CPFailureBlock _Nullable)failureBlock;

@end
NS_ASSUME_NONNULL_END
