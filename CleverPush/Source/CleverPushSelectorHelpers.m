#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "CleverPushSelectorHelpers.h"

static NSDictionary *cleverPushStoredLaunchOptions = nil;

#pragma mark - inject Selector
BOOL injectSelector(Class targetClass, SEL targetSelector, Class myClass, SEL mySelector) {
    Method newMeth = class_getInstanceMethod(myClass, mySelector);
    IMP imp = method_getImplementation(newMeth);

    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
    BOOL existing = class_getInstanceMethod(targetClass, targetSelector) != NULL;

    if (existing) {
        Method orgMeth = class_getInstanceMethod(targetClass, targetSelector);
        IMP orgImp = method_getImplementation(orgMeth);

        if (imp == orgImp) {
            return existing;
        }

        class_addMethod(targetClass, mySelector, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(targetClass, mySelector);
        method_exchangeImplementations(orgMeth, newMeth);
    }
    else {
        class_addMethod(targetClass, targetSelector, imp, methodTypeEncoding);
    }

    return existing;
}

@implementation CleverPushSelectorHelpers

#pragma mark - Swizzling for Launch Options
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

+ (NSDictionary *)getStoredLaunchOptions {
    return cleverPushStoredLaunchOptions;
}

- (BOOL)swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    cleverPushStoredLaunchOptions = launchOptions;
    return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
