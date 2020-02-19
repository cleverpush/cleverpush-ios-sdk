#import "CPNotificationCategoryController.h"

#define CATEGORY_FORMAT_STRING(notificationId) [NSString stringWithFormat:@"__CLEVERPUSH__%@", notificationId]

#define MAX_CATEGORIES_SIZE 128

@implementation CPNotificationCategoryController

+ (CPNotificationCategoryController *)sharedInstance {
    static CPNotificationCategoryController *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [CPNotificationCategoryController new];
    });
    return sharedInstance;
}

- (void)saveCategoryId:(NSString *)categoryId {
    NSMutableArray<NSString *> *mutableExisting = [self.existingRegisteredCategoryIds mutableCopy];
    
    [mutableExisting addObject:categoryId];
    
    if (mutableExisting && mutableExisting.count > MAX_CATEGORIES_SIZE) {
        [self pruneCategories:mutableExisting];
        
        [mutableExisting removeObjectsInRange:NSMakeRange(0, mutableExisting.count - MAX_CATEGORIES_SIZE)];
    }
    
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    [userDefaults setObject:mutableExisting forKey:@"CleverPush_NOTIFICATION_CATEGORIES"];
    [userDefaults synchronize];
}

- (NSArray<NSString *> *)existingRegisteredCategoryIds {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    if ([userDefaults objectForKey:@"CleverPush_NOTIFICATION_CATEGORIES"] != nil) {
        return [userDefaults objectForKey:@"CleverPush_NOTIFICATION_CATEGORIES"];
    }
    return [NSArray new];
}

- (void)pruneCategories:(NSMutableArray <NSString *> *)currentCategories {
    NSMutableSet<NSString *> *categoriesToRemove = [NSMutableSet new];
    
    for (int i = (int)currentCategories.count - MAX_CATEGORIES_SIZE; i >= 0; i--) {
        [categoriesToRemove addObject:currentCategories[i]];
    }
    
    NSMutableSet<UNNotificationCategory*>* existingCategories = self.existingCategories;
    
    NSMutableSet<UNNotificationCategory *> *newCategories = [NSMutableSet new];
    
    for (UNNotificationCategory *category in existingCategories)
        if (![categoriesToRemove containsObject:category.identifier])
            [newCategories addObject:category];
    
    [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:newCategories];
}

- (NSString *)registerNotificationCategoryForNotificationId:(NSString *)notificationId {
    NSString* categoryId = CATEGORY_FORMAT_STRING(notificationId ?: NSUUID.UUID.UUIDString);
    
    [self saveCategoryId:categoryId];
    
    return categoryId;
}

- (NSMutableSet<UNNotificationCategory*>*)existingCategories {
    __block NSMutableSet* allCategories;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    UNUserNotificationCenter* notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
        allCategories = [categories mutableCopy];
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [allCategories addObject:[self carouselCategory]];
    
    return allCategories;
}

- (UNNotificationCategory *)carouselCategory API_AVAILABLE(ios(8.0)){
    NSMutableArray* actionArray = [NSMutableArray new];
    
    UNNotificationAction* nextAction = [UNNotificationAction actionWithIdentifier:@"next"
      title:@"▶▶"
    options:UNNotificationActionOptionForeground];
    [actionArray addObject:nextAction];
    
    UNNotificationAction* previousAction = [UNNotificationAction actionWithIdentifier:@"previous"
                                                      title:@"◀◀" options:UNNotificationActionOptionForeground];
    [actionArray addObject:previousAction];
    
    UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:@"carousel"
              actions:actionArray
    intentIdentifiers:@[]
              options:UNNotificationCategoryOptionCustomDismissAction];
    
    return category;
}

@end
