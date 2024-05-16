#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "CleverPushSelectorHelpers.h"

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
