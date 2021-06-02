#import "CPSubscription.h"

@implementation CPSubscription

#pragma mark - Initialise subscriptions by NSDictionary
+ (instancetype)initWithJson:(nonnull NSDictionary*)json {
    if (!json) {
        return nil;
    }
    CPSubscription *cpSubscription = [CPSubscription new];
    [cpSubscription parseJson:json];
    return cpSubscription;
}

#pragma mark - Parse json and set the data to the object variables
- (void)parseJson:(NSDictionary*)json {
    _id = [json objectForKey:@"_id"];
}

@end
