#ifndef UIApplicationDelegate_CleverPush_h
#define UIApplicationDelegate_CleverPush_h

@interface CleverPushAppDelegate : NSObject
#pragma mark - Initialise and register push notification before iOS 10
+ (void)injectPreiOS10MethodsPhase1;
+ (void)injectPreiOS10MethodsPhase2;

@end

#endif
