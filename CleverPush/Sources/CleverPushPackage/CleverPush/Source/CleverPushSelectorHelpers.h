#ifndef CleverPushSelectorHelpers_h
#define CleverPushSelectorHelpers_h
#pragma mark - Protocol Helpers.

BOOL checkIfInstanceOverridesSelector(Class instance, SEL selector);
Class getClassWithProtocolInHierarchy(Class searchClass, Protocol* protocolToFind);
NSArray* ClassGetSubclasses(Class parentClass);
void injectToProperClass(SEL newSel, SEL makeLikeSel, NSArray* delegateSubclasses, Class myClass, Class delegateClass);
BOOL injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel);

#endif /* CleverPushSelectorHelpers_h */
