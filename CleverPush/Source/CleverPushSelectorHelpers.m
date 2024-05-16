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
<<<<<<< Updated upstream

void injectToProperClass(SEL newSel, SEL makeLikeSel, NSArray* delegateSubclasses, Class myClass, Class delegateClass) {
    for(Class subclass in delegateSubclasses) {
        if (checkIfInstanceOverridesSelector(subclass, makeLikeSel)) {
            injectSelector(myClass, newSel, subclass, makeLikeSel);
            return;
        }
    }
    injectSelector(myClass, newSel, delegateClass, makeLikeSel);
}

NSArray* ClassGetSubclasses(Class parentClass) {
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) {
        return nil;
    }

    int memSize = sizeof(Class) * numClasses;
    Class *classes = (__unsafe_unretained Class *)malloc(memSize);

    if (classes == NULL && memSize) {
        return nil;
    }

    numClasses = objc_getClassList(classes, numClasses);


    NSMutableArray *indexesToSwizzle = [NSMutableArray new];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];

        if (superClass == parentClass) {
            continue;
        }

        while (superClass && superClass != parentClass) {
            superClass = class_getSuperclass(superClass);
        }

        if (superClass != nil) {
            [indexesToSwizzle addObject:@(i)];
        }
    }

    NSMutableArray *subclasses = [NSMutableArray new];
    for (NSNumber *i in indexesToSwizzle) {
        NSInteger index = [i integerValue];
        [subclasses addObject:classes[index]];
    }

    free(classes);

    return [NSArray arrayWithArray:subclasses];
}
=======
>>>>>>> Stashed changes
