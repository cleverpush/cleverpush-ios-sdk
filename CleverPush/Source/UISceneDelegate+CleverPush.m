#import "UISceneDelegate+CleverPush.h"
#import "CleverPushSelectorHelpers.h"
#import "CPDeepLinkTracker.h"
#import <objc/runtime.h>

@implementation CleverPushSceneDelegate

static NSMutableSet<Class> *swizzledSceneDelegateClasses;
static BOOL sceneObserversInstalled;

+ (BOOL)classDefinesSelector:(SEL)sel directlyOnClass:(Class)cls {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == sel) {
            found = YES;
            break;
        }
    }
    free(methods);
    return found;
}

+ (void)injectSelectorSafely:(SEL)targetSel
            intoDelegateClass:(Class)delegateClass
                  replacement:(SEL)cpSel
                 allowAddNew:(BOOL)allowAddNew {
    Method existing = class_getInstanceMethod(delegateClass, targetSel);
    if (existing == NULL && !allowAddNew) {
        return;
    }

    if (existing != NULL && ![self classDefinesSelector:targetSel directlyOnClass:delegateClass]) {
        class_addMethod(delegateClass,
                        targetSel,
                        method_getImplementation(existing),
                        method_getTypeEncoding(existing));
    }

    injectSelector(delegateClass, targetSel, [CleverPushSceneDelegate class], cpSel);
}

+ (void)injectSelectors {
    if (@available(iOS 13.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self installSceneObservers];
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                [self ensureInstalledForScene:scene];
            }
        });
    }
}

+ (void)installSceneObservers API_AVAILABLE(ios(13.0)) {
    if (sceneObserversInstalled) {
        return;
    }
    sceneObserversInstalled = YES;

    Class sceneClass = [UIScene class];
    injectSelector(sceneClass,
                   @selector(setDelegate:),
                   [CleverPushSceneDelegate class],
                   @selector(cleverPushSetSceneDelegate:));

    [[NSNotificationCenter defaultCenter] addObserverForName:UISceneWillConnectNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        UIScene *scene = note.object;
        if ([scene isKindOfClass:[UIScene class]]) {
            [CleverPushSceneDelegate ensureInstalledForScene:scene];
        }
    }];
}

- (void)cleverPushSetSceneDelegate:(id<UISceneDelegate>)delegate API_AVAILABLE(ios(13.0)) {
    if (delegate != nil) {
        [CleverPushSceneDelegate injectIntoSceneDelegateClass:[delegate class]];
    }
    if ([self respondsToSelector:@selector(cleverPushSetSceneDelegate:)]) {
        [self cleverPushSetSceneDelegate:delegate];
    }
}

+ (void)ensureInstalledForScene:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    if (scene == nil || scene.delegate == nil) {
        return;
    }
    [self injectIntoSceneDelegateClass:[scene.delegate class]];
}

+ (void)injectIntoSceneDelegateClass:(Class)delegateClass {
    if (delegateClass == nil) {
        return;
    }
    if (swizzledSceneDelegateClasses == nil) {
        swizzledSceneDelegateClasses = [NSMutableSet new];
    }
    if ([swizzledSceneDelegateClasses containsObject:delegateClass]) {
        return;
    }
    [swizzledSceneDelegateClasses addObject:delegateClass];

    [self injectSelectorSafely:@selector(scene:willConnectToSession:options:)
              intoDelegateClass:delegateClass
                    replacement:@selector(cleverPushScene:willConnectToSession:options:)
                   allowAddNew:NO];

    [self injectSelectorSafely:@selector(scene:openURLContexts:)
              intoDelegateClass:delegateClass
                    replacement:@selector(cleverPushScene:openURLContexts:)
                   allowAddNew:YES];
    [self injectSelectorSafely:@selector(scene:continueUserActivity:)
              intoDelegateClass:delegateClass
                    replacement:@selector(cleverPushScene:continueUserActivity:)
                   allowAddNew:YES];
}

- (void)cleverPushScene:(UIScene *)scene
  willConnectToSession:(UISceneSession *)session
               options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    [CPDeepLinkTracker captureFromConnectionOptions:connectionOptions];

    if ([self respondsToSelector:@selector(cleverPushScene:willConnectToSession:options:)]) {
        [self cleverPushScene:scene willConnectToSession:session options:connectionOptions];
    }
}

- (void)cleverPushScene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    [CPDeepLinkTracker captureFromOpenURLContexts:URLContexts];

    if ([self respondsToSelector:@selector(cleverPushScene:openURLContexts:)]) {
        [self cleverPushScene:scene openURLContexts:URLContexts];
    }
}

- (void)cleverPushScene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(13.0)) {
    [CPDeepLinkTracker captureFromUserActivity:userActivity];

    if ([self respondsToSelector:@selector(cleverPushScene:continueUserActivity:)]) {
        [self cleverPushScene:scene continueUserActivity:userActivity];
    }
}

@end
