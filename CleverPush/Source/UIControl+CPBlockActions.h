#import <UIKit/UIKit.h>

@interface UIControl (CPBlockActions)

#pragma mark - Event handler with contol events
- (void) addEventHandler:(void(^)(void))handler
        forControlEvents:(UIControlEvents)controlEvents;

@end
