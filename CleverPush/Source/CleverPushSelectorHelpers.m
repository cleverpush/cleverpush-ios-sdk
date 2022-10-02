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
    Class *classes = (Class*)malloc(sizeof(Class) * numClasses);
    
    objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        
        while(superClass && superClass != parentClass) {
            superClass = class_getSuperclass(superClass);
        }
        
        if (superClass)
            [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}
