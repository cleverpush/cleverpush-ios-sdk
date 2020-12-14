#import <UIKit/UIKit.h>

@interface UIControl (CPBlockActions)

- (void) addEventHandler:(void(^)(void))handler
        forControlEvents:(UIControlEvents)controlEvents;

@end

