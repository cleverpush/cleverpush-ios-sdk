#import "CPChannelTag.h"

@implementation CPChannelTag

#pragma mark - Initialise channel tag by NSDictionary
+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    CPChannelTag *tag = [CPChannelTag new];
    [tag parseJson:json];
    return tag;
}

#pragma mark - Parse json and set the data to the object variables
- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
    _name = [json objectForKey:@"name"];
    _autoAssignPath = [json objectForKey:@"autoAssignPath"];
    _autoAssignFunction = [json objectForKey:@"autoAssignFunction"];
    _autoAssignSelector = [json objectForKey:@"autoAssignSelector"];
    _autoAssignVisits = [json objectForKey:@"autoAssignVisits"];
    _autoAssignSessions = [json objectForKey:@"autoAssignSessions"];
    _autoAssignSeconds = [json objectForKey:@"autoAssignSeconds"];
    _autoAssignDays = [json objectForKey:@"autoAssignDays"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [formatter dateFromString:[json objectForKey:@"createdAt"]];
    }
}

@end

