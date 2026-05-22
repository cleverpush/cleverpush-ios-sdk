#import "CPTranslate.h"

@interface CPTranslate()

@end

@implementation CPTranslate

#pragma mark - Localise static strings
+ (NSString*)translate:(NSString*)message {
    NSString *defaultLang = @"en";
    NSDictionary *messages = @{
        @"en": @{
                @"deselectEverything": @"Deselect everything",
                @"subscribedTopics": @"Subscribed Topics",
                @"notificationsEmpty": @"No notifications available",
                @"save": @"Save",
                @"selectAll": @"Select All",
                @"removeAll": @"Remove All"
        },
        @"de": @{
                @"deselectEverything": @"Alles abwählen",
                @"subscribedTopics": @"Abonnierte Themen",
                @"notificationsEmpty": @"Keine Nachrichten verfügbar",
                @"save": @"Speichern",
                @"selectAll": @"Alle auswählen",
                @"removeAll": @"Alle entfernen"
        },
    };
    
    NSString *language = [[[NSLocale preferredLanguages] firstObject] substringToIndex:2];
    
    NSDictionary *dict = [messages objectForKey:language];
    if (!dict) {
        dict = [messages objectForKey:defaultLang];
    }
    
    return [dict objectForKey:message];
}

@end
