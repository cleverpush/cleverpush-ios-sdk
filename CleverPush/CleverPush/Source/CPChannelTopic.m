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
    _externalId = [json objectForKey:@"externalId"];
    _customData = [json objectForKey:@"customData"];
    _defaultUnchecked = NO;
    
    if ([json objectForKey:@"defaultUnchecked"] != nil && ![[json objectForKey:@"defaultUnchecked"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"defaultUnchecked"] boolValue]) {
        _defaultUnchecked = YES;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [formatter dateFromString:[json objectForKey:@"createdAt"]];
    }
}

@end
