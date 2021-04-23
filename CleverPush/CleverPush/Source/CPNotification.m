#import "CPNotification.h"

@implementation CPNotification

+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    
    CPNotification *cpNotification = [CPNotification new];
    
    [cpNotification parseJson:json];
    return cpNotification;
}

- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
    
    _title = [json objectForKey:@"title"];
    _text = [json objectForKey:@"text"];
    _tag = [json objectForKey:@"tag"];
    _url = [json objectForKey:@"url"];
    
    _iconUrl = [json objectForKey:@"iconUrl"];
    _mediaUrl = [json objectForKey:@"mediaUrl"];
    
    _soundFilename = [json objectForKey:@"soundFilename"];
    
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
        _actions = actionArray;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [formatter dateFromString:[json objectForKey:@"createdAt"]];
    }
    if ([[json objectForKey:@"expiresAt"] isKindOfClass:[NSString class]]) {
        _expiresAt = [formatter dateFromString:[json objectForKey:@"expiresAt"]];
    }
    
    _silent = NO;
    if ([json objectForKey:@"silent"] && [json valueForKey:@"silent"] != nil && ![[json valueForKey:@"silent"] isKindOfClass:[NSNull class]]) {
        _silent = [[json objectForKey:@"silent"] boolValue];
    }
    
    _chatNotification = NO;
    if ([json objectForKey:@"chatNotification"] && [json valueForKey:@"chatNotification"] != nil && ![[json valueForKey:@"chatNotification"] isKindOfClass:[NSNull class]]) {
        _chatNotification = [[json objectForKey:@"chatNotification"] boolValue];
    }
    
    _carouselEnabled = NO;
    if ([json objectForKey:@"carouselEnabled"] && [json valueForKey:@"carouselEnabled"] != nil && ![[json valueForKey:@"carouselEnabled"] isKindOfClass:[NSNull class]]) {
        _carouselEnabled = [[json objectForKey:@"carouselEnabled"] boolValue];
    }
    _carouselItems = [json objectForKey:@"carouselItems"];
    
    _customData = [json objectForKey:@"customData"];
}

@end
