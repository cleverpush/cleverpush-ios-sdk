#ifndef UISceneDelegate_CleverPush_h
#define UISceneDelegate_CleverPush_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CleverPushSceneDelegate : NSObject

+ (void)injectSelectors;
+ (void)ensureInstalledForScene:(UIScene *)scene API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END

#endif 
