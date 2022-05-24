#import "CPNotificationCategoryController.h"

#define CATEGORY_FORMAT_STRING(notificationId) [NSString stringWithFormat:@"__CLEVERPUSH__%@", notificationId]

#define MAX_CATEGORIES_SIZE 128

@implementation CPNotificationCategoryController

#pragma mark - Instance class of the Notification
+ (CPNotificationCategoryController *)sharedInstance {
    static CPNotificationCategoryController *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [CPNotificationCategoryController new];
    });
    return sharedInstance;
}

#pragma mark - Store Notification Id's to the UserDefaults
- (void)saveCategoryId:(NSString *)categoryId {
    NSMutableArray<NSString *> *mutableExisting = [self.existingRegisteredCategoryIds mutableCopy];
    
    [mutableExisting addObject:categoryId];
    
    if (mutableExisting && mutableExisting.count > MAX_CATEGORIES_SIZE) {
        [self pruneCategories:mutableExisting];
        
        [mutableExisting removeObjectsInRange:NSMakeRange(0, mutableExisting.count - MAX_CATEGORIES_SIZE)];
    }
    
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    [userDefaults setObject:mutableExisting forKey:CLEVERPUSH_NOTIFICATION_CATEGORIES_KEY];
    [userDefaults synchronize];
}

#pragma mark - Check the existance of the notification's categories stores in to UserDefault or not
- (NSArray<NSString *> *)existingRegisteredCategoryIds {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [[NSBundle mainBundle] bundleIdentifier]]];
    if ([userDefaults objectForKey:CLEVERPUSH_NOTIFICATION_CATEGORIES_KEY] != nil) {
        return [userDefaults objectForKey:CLEVERPUSH_NOTIFICATION_CATEGORIES_KEY];
    }
    return [NSArray new];
}

#pragma mark - eliminate the existance of the notification's categories stores in to UserDefault or not
- (void)pruneCategories:(NSMutableArray <NSString *> *)currentCategories {
    NSMutableSet<NSString *> *categoriesToRemove = [NSMutableSet new];
    
    for (int i = (int)currentCategories.count - MAX_CATEGORIES_SIZE; i >= 0; i--) {
        [categoriesToRemove addObject:currentCategories[i]];
    }
    if (@available(iOS 10.0, *)) {
        NSMutableSet<UNNotificationCategory*>* existingCategories = self.existingCategories;
        
        NSMutableSet<UNNotificationCategory *> *newCategories = [NSMutableSet new];
        
        for (UNNotificationCategory *category in existingCategories)
            if (![categoriesToRemove containsObject:category.identifier])
                [newCategories addObject:category];
        [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:newCategories];
    }
}

#pragma mark - Register notification category
- (NSString *)registerNotificationCategoryForNotificationId:(NSString *)notificationId {
    NSString* categoryId = CATEGORY_FORMAT_STRING(notificationId ?: NSUUID.UUID.UUIDString);
    
    [self saveCategoryId:categoryId];
    
    return categoryId;
}

#pragma mark - Get existing categories
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

#pragma mark - Carousel category
- (UNNotificationCategory *)carouselCategory API_AVAILABLE(ios(10.0)) {
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
