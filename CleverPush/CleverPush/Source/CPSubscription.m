#import "CPSubscription.h"

@implementation CPSubscription

+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    
    CPSubscription *cpSubscription = [CPSubscription new];
    
    [cpSubscription parseJson:json];
    return cpSubscription;
}

- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
}

@end

