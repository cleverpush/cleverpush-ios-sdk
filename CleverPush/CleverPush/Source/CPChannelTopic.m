#import "CPChannelTopic.h"

@implementation CPChannelTopic

+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    
    CPChannelTopic *topic = [CPChannelTopic new];
    
    [topic parseJson:json];
    return topic;
}

- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
    
    _name = [json objectForKey:@"name"];
    _parentTopic = [json objectForKey:@"parentTopic"];
    
    _sort = [json objectForKey:@"sort"];
    
    _defaultUnchecked = NO;
    if ([json objectForKey:@"defaultUnchecked"]) {
        _defaultUnchecked = YES;
    }
    
    _fcmBroadcastTopic = [json objectForKey:@"fcmBroadcastTopic"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [formatter dateFromString:[json objectForKey:@"createdAt"]];
    }
}

@end
