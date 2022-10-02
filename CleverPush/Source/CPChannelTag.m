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
        
    if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
        _createdAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"createdAt"]];
    }
}

@end
