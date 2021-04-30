#import "CPTranslate.h"

@interface CPTranslate()

@end

@implementation CPTranslate

+ (NSString*)translate:(NSString*)message {
    NSString *defaultLang = @"en";
    NSDictionary *messages = @{
        @"en": @{
                @"subscribedTopics": @"Subscribed Topics",
                @"save": @"Save",
                @"deselectEverything": @"Deselect everything"
        },
        @"de": @{
                @"subscribedTopics": @"Abonnierte Themen",
                @"save": @"Speichern",
                @"deselectEverything": @"Alles abwählen"
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
