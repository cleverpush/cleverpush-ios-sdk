#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "CleverPushSelectorHelpers.h"

#pragma mark - Instances Overrises selector.
BOOL checkIfInstanceOverridesSelector(Class instance, SEL selector) {
    Class instSuperClass = [instance superclass];
    return [instance instanceMethodForSelector: selector] != [instSuperClass instanceMethodForSelector: selector];
}

#pragma mark - get Class With Protocol In Hierarchy
Class getClassWithProtocolInHierarchy(Class searchClass, Protocol* protocolToFind) {
    if (!class_conformsToProtocol(searchClass, protocolToFind)) {
        if ([searchClass superclass] == nil)
            return nil;
        Class foundClass = getClassWithProtocolInHierarchy([searchClass superclass], protocolToFind);
        if (foundClass)
            return foundClass;
        return searchClass;
    }
    return searchClass;
}

#pragma mark - inject Selector
BOOL injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel) {
    Method newMeth = class_getInstanceMethod(newClass, newSel);
    IMP imp = method_getImplementation(newMeth);
    
    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
    
    BOOL existing = class_getInstanceMethod(addToClass, makeLikeSel) != NULL;
    
    if (existing) {
        class_addMethod(addToClass, newSel, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(addToClass, newSel);
        Method orgMeth = class_getInstanceMethod(addToClass, makeLikeSel);
        method_exchangeImplementations(orgMeth, newMeth);
    }
    else
        class_addMethod(addToClass, makeLikeSel, imp, methodTypeEncoding);
    
    return existing;
}

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
