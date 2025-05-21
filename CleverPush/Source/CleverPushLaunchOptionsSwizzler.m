#import "CleverPushLaunchOptionsSwizzler.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static NSDictionary *swizzled_applicationLaunchOptions = nil;

@implementation CleverPushLaunchOptionsSwizzler

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class appDelegateClass = [UIApplication sharedApplication].delegate.class;
        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(swizzled_application:didFinishLaunchingWithOptions:);
        
        Method originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(appDelegateClass,
                                            swizzledSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            Method newSwizzledMethod = class_getInstanceMethod(appDelegateClass, swizzledSelector);
            method_exchangeImplementations(originalMethod, newSwizzledMethod);
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (BOOL)swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    swizzled_applicationLaunchOptions = launchOptions;
    return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
}

+ (NSDictionary *)getStoredLaunchOptions {
    return swizzled_applicationLaunchOptions;
}

@end
