#pragma mark - Protocol Helpers.

BOOL injectSelector(Class targetClass, SEL targetSelector, Class myClass, SEL mySelector);

@interface CleverPushSelectorHelpers : NSObject

+ (NSDictionary *)getStoredLaunchOptions;

@end
