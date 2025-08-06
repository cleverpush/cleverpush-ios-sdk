#import "CPNotification.h"
#import "CPUtils.h"
#import "NSDictionary+SafeExpectations.h"
#import "CleverPushUserDefaults.h"

@implementation CPNotification
#pragma mark - Initialise notifications by NSDictionary
+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    CPNotification *cpNotification = [CPNotification new];
    [cpNotification parseJson:json];
    return cpNotification;
}

#pragma mark - Parse json and set the data to the object variables
- (void)parseJson:(NSDictionary*)json {
    self.read = NO;
    
    if ([json objectForKey:@"_id"] != nil && ![[json objectForKey:@"_id"] isKindOfClass:[NSNull class]]) {
        self.id = [json objectForKey:@"_id"];
    }
    if ([json objectForKey:@"title"] != nil && ![[json objectForKey:@"title"] isKindOfClass:[NSNull class]]) {
        self.title = [json objectForKey:@"title"];
    }
    if ([json objectForKey:@"text"] != nil && ![[json objectForKey:@"text"] isKindOfClass:[NSNull class]]) {
        self.text = [json objectForKey:@"text"];
    }
    if ([json objectForKey:@"tag"] != nil && ![[json objectForKey:@"tag"] isKindOfClass:[NSNull class]]) {
        self.tag = [json objectForKey:@"tag"];
    }
    if ([json objectForKey:@"url"] != nil && ![[json objectForKey:@"url"] isKindOfClass:[NSNull class]]) {
        self.url = [json objectForKey:@"url"];
    }
    if ([json objectForKey:@"iconUrl"] != nil && ![[json objectForKey:@"iconUrl"] isKindOfClass:[NSNull class]]) {
        self.iconUrl = [json objectForKey:@"iconUrl"];
    }
    if ([json objectForKey:@"mediaUrl"] != nil && ![[json objectForKey:@"mediaUrl"] isKindOfClass:[NSNull class]]) {
        self.mediaUrl = [json objectForKey:@"mediaUrl"];
    }
    if ([json objectForKey:@"soundFilename"] != nil && ![[json objectForKey:@"soundFilename"] isKindOfClass:[NSNull class]]) {
        self.soundFilename = [json objectForKey:@"soundFilename"];
    }
    if ([json objectForKey:@"appBanner"] != nil && ![[json objectForKey:@"appBanner"] isKindOfClass:[NSNull class]]) {
        self.appBanner = [json objectForKey:@"appBanner"];
    }
    if ([json objectForKey:@"inboxAppBanner"] != nil && ![[json objectForKey:@"inboxAppBanner"] isKindOfClass:[NSNull class]]) {
        self.inboxAppBanner = [json objectForKey:@"inboxAppBanner"];
    }
    if ([json objectForKey:@"notificationIdentifier"] != nil && ![[json objectForKey:@"notificationIdentifier"] isKindOfClass:[NSNull class]]) {
        self.notificationIdentifier = [json objectForKey:@"notificationIdentifier"];
    }
    
    NSArray* actions = [json objectForKey:@"actions"];
    if (actions && ![actions isKindOfClass:[NSNull class]] && [actions count] > 0) {
        NSMutableArray* actionArray = [NSMutableArray new];
        [actions enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL *stop) {
            NSString* actionId = [NSString stringWithFormat: @"%@", @(idx)];
            
            NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
            
            [action setObject:actionId forKey:@"id"];
            if ([item cleverPushStringForKey:@"title"]) {
                [action setObject:[item cleverPushStringForKey:@"title"] forKey:@"title"];
            }
            if ([item cleverPushStringForKey:@"url"]) {
                [action setObject:[item cleverPushStringForKey:@"url"] forKey:@"url"];
            }
            if ([item cleverPushStringForKey:@"type"]) {
                [action setObject:[item cleverPushStringForKey:@"type"] forKey:@"type"];
            }
            if ([item cleverPushDictionaryForKey:@"customData"]) {
                [action setObject:[item cleverPushDictionaryForKey:@"customData"] forKey:@"customData"];
            }
            
            [actionArray addObject:action];
        }];
        self.actions = actionArray;
    }

    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]] && [json objectForKey:@"createdAt"] != nil && [[json objectForKey:@"createdAt"] length] > 0) {
        self.createdAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"createdAt"]];
    } else {
        self.createdAt = [NSDate date];
    }

    if ([[json objectForKey:@"expiresAt"] isKindOfClass:[NSString class]] && [json objectForKey:@"expiresAt"] != nil && [[json objectForKey:@"expiresAt"] length] > 0) {
        self.expiresAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"expiresAt"]];
    }
    
    self.chatNotification = NO;
    if ([json objectForKey:@"chatNotification"] && [json objectForKey:@"chatNotification"] != nil && ![[json objectForKey:@"chatNotification"] isKindOfClass:[NSNull class]]) {
        self.chatNotification = [[json objectForKey:@"chatNotification"] boolValue];
    }
    
    self.carouselEnabled = NO;
    if ([json objectForKey:@"carouselEnabled"] && [json objectForKey:@"carouselEnabled"] != nil && ![[json objectForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]]) {
        self.carouselEnabled = [[json objectForKey:@"carouselEnabled"] boolValue];
    }
    
    self.carouselItems = [json objectForKey:@"carouselItems"];
    
    if ([json objectForKey:@"customData"] && [json objectForKey:@"customData"] != nil && ![[json objectForKey:@"customData"] isKindOfClass:[NSNull class]]) {
        self.customData = [json objectForKey:@"customData"];
    } else {
        self.customData = [[NSDictionary alloc] init];
    }

    self.silent = NO;
    if ([json objectForKey:@"silent"] && [json objectForKey:@"silent"] != nil && ![[json objectForKey:@"silent"] isKindOfClass:[NSNull class]]) {
        self.silent = [[json objectForKey:@"silent"] boolValue];
    }
}

#pragma mark - Track notification clicked
- (void)trackInboxClicked {
    if (self.id) {
        [CleverPush trackInboxClicked:self.id];
    }
}

#pragma mark - Getters and Setters for read property
- (void)setRead:(BOOL)read {
    _read = read;
    
    if (read && self.id) {
        NSUserDefaults *userDefaults = [CPUtils getUserDefaultsAppGroup];
        if (!userDefaults) {
            return;
        }
        
        NSArray *readNotifications = [userDefaults arrayForKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
        NSMutableArray *updatedReadNotifications;
        
        if (readNotifications && [readNotifications isKindOfClass:[NSArray class]]) {
            updatedReadNotifications = [readNotifications mutableCopy];
        } else {
            updatedReadNotifications = [[NSMutableArray alloc] init];
        }
        
        if (![updatedReadNotifications containsObject:self.id]) {
            [updatedReadNotifications addObject:self.id];
            [userDefaults setObject:updatedReadNotifications forKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
            [userDefaults synchronize];
        }
    }
}

- (BOOL)getRead {
    NSUserDefaults *userDefaults = [CPUtils getUserDefaultsAppGroup];
    if (!userDefaults) {
        return _read;
    }
    
    NSArray *readNotifications = [userDefaults arrayForKey:CLEVERPUSH_READ_NOTIFICATIONS_KEY];
    if (readNotifications && [readNotifications isKindOfClass:[NSArray class]] && readNotifications.count > 0) {
        if (self.id && [readNotifications containsObject:self.id]) {
            return YES;
        } else {
            return _read;
        }
    } else {
        return _read;
    }
}

@end
