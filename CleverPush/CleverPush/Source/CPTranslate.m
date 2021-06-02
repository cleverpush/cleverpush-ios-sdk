#import "CPTranslate.h"

@interface CPTranslate()

@end

@implementation CPTranslate

#pragma mark - Localise static strings English/German
+ (NSString*)translate:(NSString*)message {
    NSString *defaultLang = @"en";
    NSDictionary *messages = @{
        @"en": @{
                @"deselecteverything": @"Deselect everything",
                @"subscribedTopics": @"Subscribed Topics",
                @"save": @"Save"
        },
        @"de": @{
                @"deselecteverything": @"Alles abwählen",
                @"subscribedTopics": @"Abonnierte Themen",
                @"save": @"Speichern"
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
