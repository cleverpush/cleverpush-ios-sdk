#import <Foundation/Foundation.h>
#import "CPWidgetsStories.h"
#import "CleverPush.h"
NS_ASSUME_NONNULL_BEGIN
@interface CPWidgetModule : NSObject

+ (void)getWidgetsStories:(NSString*)widgetId completion:(void(^)(CPWidgetsStories *))callback;

@end
NS_ASSUME_NONNULL_END
