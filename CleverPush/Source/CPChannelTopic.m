#import "CPChannelTopic.h"

@implementation CPChannelTopic

#pragma mark - Initialise channel topic by NSDictionary
+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    CPChannelTopic *topic = [CPChannelTopic new];
    [topic parseJson:json];
    return topic;
}

#pragma mark - Parse json and set the data to the object variables
- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
    _name = [json objectForKey:@"name"];
    _parentTopic = [json objectForKey:@"parentTopic"];
    _sort = [json objectForKey:@"sort"];
    _fcmBroadcastTopic = [json objectForKey:@"fcmBroadcastTopic"];

    if ([json objectForKey:@"externalId"] != nil && ![[json objectForKey:@"externalId"] isKindOfClass:[NSNull class]]) {
        _externalId = [NSString stringWithFormat:@"%@", [json objectForKey:@"externalId"]];
    }

    _customData = [json objectForKey:@"customData"];

    _defaultUnchecked = NO;
    if ([json objectForKey:@"defaultUnchecked"] != nil && ![[json objectForKey:@"defaultUnchecked"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"defaultUnchecked"] boolValue]) {
        _defaultUnchecked = YES;
    }

    _nameTranslationEnabled = NO;
    if ([json objectForKey:@"nameTranslationEnabled"] != nil && ![[json objectForKey:@"nameTranslationEnabled"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"nameTranslationEnabled"] boolValue]) {
        _nameTranslationEnabled = YES;
    }

    id nameTranslationValue = [json objectForKey:@"nameTranslation"];
    if (nameTranslationValue != nil && ![[json objectForKey:@"nameTranslation"] isKindOfClass:[NSNull class]] && [nameTranslationValue isKindOfClass:[NSDictionary class]]) {
        _nameTranslation = (NSDictionary *)nameTranslationValue;
    }

    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"createdAt"]];
    }
}

@end
