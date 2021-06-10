#import "CPNotification.h"

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
    
    NSArray* actions = [json objectForKey:@"actions"];
    if (actions && ![actions isKindOfClass:[NSNull class]] && [actions count] > 0) {
        NSMutableArray* actionArray = [NSMutableArray new];
        [actions enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL *stop) {
            NSString* actionId = [NSString stringWithFormat: @"%@", @(idx)];
            
            NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
            
            [action setValue:actionId forKey:@"id"];
            if ([item valueForKey:@"title"]) {
                [action setValue:[item valueForKey:@"title"] forKey:@"title"];
            }
            if ([item valueForKey:@"url"]) {
                [action setValue:[item valueForKey:@"url"] forKey:@"url"];
            }
            if ([item valueForKey:@"type"]) {
                [action setValue:[item valueForKey:@"type"] forKey:@"type"];
            }
            if ([item valueForKey:@"customData"]) {
                [action setValue:[item valueForKey:@"customData"] forKey:@"customData"];
            }
            
            [actionArray addObject:action];
        }];
        self.actions = actionArray;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        self.createdAt = [formatter dateFromString:[json objectForKey:@"createdAt"]];
    }
    if ([[json objectForKey:@"expiresAt"] isKindOfClass:[NSString class]]) {
        self.expiresAt = [formatter dateFromString:[json objectForKey:@"expiresAt"]];
    }
    
    self.chatNotification = NO;
    if ([json objectForKey:@"chatNotification"] && [json valueForKey:@"chatNotification"] != nil && ![[json valueForKey:@"chatNotification"] isKindOfClass:[NSNull class]]) {
        self.chatNotification = [[json objectForKey:@"chatNotification"] boolValue];
    }
    
    self.carouselEnabled = NO;
    if ([json objectForKey:@"carouselEnabled"] && [json valueForKey:@"carouselEnabled"] != nil && ![[json valueForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]]) {
        self.carouselEnabled = [[json objectForKey:@"carouselEnabled"] boolValue];
    }
    self.carouselItems = [json objectForKey:@"carouselItems"];
    self.customData = [json objectForKey:@"customData"];
}

@end
